# Low-Latency Host Tuning Runbook

Reproducible steps to configure a Linux host for the trading system's busy-spin
threads: CPU isolation, tickless cores, RCU offload, IRQ steering, per-thread pinning,
and running Aeron over a Solarflare NIC (two-box setup). Reference host: **duras**
(8 cores, single socket). Second host: **scorilo** (32 cores, 2 sockets, Solarflare
X2522 — see the scorilo host-variant and Aeron-over-Solarflare sections).

Core principle learned on duras: **one dedicated, isolated core per busy-spin
thread.** Two non-yielding spin threads on one core, or a hot thread floating on a
shared/housekeeping core, both produce ~ms latency spikes. Keep ≥1–2 cores free for
the OS / GC / JIT (the "housekeeping" cores).

---

## Step 0 — Discovery (read-only; do this first on a new host)

The exact core ranges and IRQ steering depend on the host, so gather these before
changing anything:

```bash
lscpu                                              # cores, sockets, NUMA
nproc
grep -E 'CONFIG_NO_HZ_FULL|CONFIG_RCU_NOCB|CONFIG_HZ=' /boot/config-$(uname -r)
tuned-adm active                                   # current profile (parent to inherit)
cat /proc/cmdline                                  # existing isolcpus/nohz_full etc.
systemctl is-active irqbalance
ls -l /sys/class/net/                              # find the NIC interface(s)
```

For a NIC host also:
```bash
ethtool -i <iface>                                 # driver (sfc = Solarflare)
cat /sys/class/net/<iface>/device/numa_node        # NIC's NUMA node
grep -E 'CPU|<iface>|sfc' /proc/interrupts         # NIC IRQ → CPU mapping
```

Decide the core plan from this: which cores are housekeeping (OS/GC/JIT) and which
are isolated (one per hot thread), keeping hot threads and NIC IRQs on the NIC's
NUMA node if multi-socket.

**duras reference plan (8 cores, single socket):**

| Core | Role |
|---|---|
| 0, 1 | housekeeping (OS, GC, JIT, StatsReporter) |
| 2 | LH ExchangeClient PipeThread (TCP to exchange) |
| 3 | exchange SinkThread |
| 4 | serializer |
| 5 | LH TightLoopThread (bus + order processing) |
| 6 | free spare |
| 7 | Aeron media driver (`ThreadingMode=SHARED`, 1 thread) |

---

## Step 1 — CPU isolation via TuneD (single source of truth)

TuneD owns the kernel cmdline. Create a custom profile that inherits the current
latency profile (duras: `network-latency`, which supplies
`skew_tick=1 tsc=reliable rcupdate.rcu_normal_after_boot=1`) and adds the three
isolation params. Replace `2-7` with the host's isolated range.

```bash
sudo mkdir -p /etc/tuned/madrigal-lowlat && sudo tee /etc/tuned/madrigal-lowlat/tuned.conf >/dev/null <<'EOF'
[main]
summary=Madrigal low-latency: isolate the trading-system cores
include=network-latency

[variables]
isolated_cores=2-7

[bootloader]
cmdline_madrigal=isolcpus=${isolated_cores} nohz_full=${isolated_cores} rcu_nocbs=${isolated_cores}
EOF
```

If the host has hand-edited `isolcpus`/`nohz_full` in `/etc/default/grub`, back it up
and blank those `GRUB_CMDLINE_LINUX*` lines so TuneD is the only source:

```bash
sudo cp /etc/default/grub /etc/default/grub.bak
```

Apply and rebuild the bootloader, then reboot:

```bash
sudo tuned-adm profile madrigal-lowlat && sudo update-grub
sudo reboot
```

### Verify (after reboot)

```bash
cat /proc/cmdline                                  # each param once, no dups
cat /sys/devices/system/cpu/isolated               # -> isolated range
cat /sys/devices/system/cpu/nohz_full              # -> isolated range
tuned-adm active && tuned-adm verify
```

Tickless-under-load check (run while the app is running): busy isolated cores should
add ~0 over 10 s; housekeeping cores add ~10k/s at HZ=1000:

```bash
grep LOC /proc/interrupts; sleep 10; grep LOC /proc/interrupts
```

---

## Step 2 — Interrupts / IRQ steering

On duras the residual isolated-core ticks were block/device-mapper kworkers
(µs-level, left alone). On a NIC host this step is essential — keep NIC interrupts
off the hot cores.

Stop irqbalance so it can't move IRQs back:
```bash
sudo systemctl disable --now irqbalance
```

Steer device IRQs (NIC queues, NVMe/SATA, dm) to housekeeping cores. For each IRQ
number from `/proc/interrupts`:
```bash
echo 0-1 | sudo tee /proc/irq/<IRQ>/smp_affinity_list
```

Restrict unbound/writeback workqueues to housekeeping (suppresses the dm/block
kworker ticks seen on duras); `3` = 0b11 = CPUs 0,1:
```bash
echo 3 | sudo tee /sys/devices/virtual/workqueue/cpumask /sys/bus/workqueue/devices/writeback/cpumask
```

Re-check the `LOC` delta and `/proc/interrupts` under load to confirm the isolated
cores are quiet.

### Solarflare NIC (scorilo)

- **Kernel TCP path:** steer the NIC RX/TX queue IRQs (`sfc-*` in `/proc/interrupts`)
  either onto the isolated core that busy-polls that socket (co-locate) or onto
  housekeeping — decide per design; keep them on the NIC's NUMA node.
- **Onload / ef_vi kernel-bypass:** the data path skips kernel IRQs entirely; still
  steer any residual NIC IRQs off the hot cores, and keep irqbalance off.
- For a **persistent** version of the steering (systemd oneshot), see the scorilo
  host-variant section below.

---

## Step 3 — App-level thread pinning

Not OS config — per-process knobs, one dedicated isolated core per busy-spin thread.

| Config | Sets | duras value |
|---|---|---|
| LH `pin.to.cpu` | ExchangeClient PipeThread (TCP) | 2 |
| LH `pin.tlt.to.cpu` | TightLoopThread (bus + order proc) | 5 |
| exchange `pin.to.cpu` | exchange SinkThread | 3 |
| serializer `pin.tlt.to.cpu` | serializer | 4 |
| Aeron media driver | `ThreadingMode=SHARED` (1 thread) | core 7 |

Each process logs its placement at startup — confirm in the app log:
`Pinned to CPU N of {housekeeping set}`.

---

## Host variant: scorilo (NUMA, real Solarflare NIC)

scorilo differs from duras in three ways that change the plan. Status as of
2026-10-25: upgraded to Ubuntu 26.04 / kernel 7.0 — see "scorilo on Ubuntu 26.04"
below, which supersedes the 18.04-era notes in this section (kept for history).
App-level NUMA binding is still open.

**1. (Historical, 18.04 / kernel 4.15) Kernel couldn't do tickless/RCU-offload.**
That kernel had `# CONFIG_NO_HZ_FULL is not set` and no `CONFIG_RCU_NOCB`, so
`isolcpus` was the only isolation primitive and isolated busy cores kept the periodic
tick (HZ=250). **No longer applies:** the 7.0 kernel has `CONFIG_NO_HZ_FULL=y` and
`CONFIG_RCU_NOCB_CPU=y`, and scorilo now uses `nohz_full`/`rcu_nocbs` like duras.

**2. NUMA — the NIC is on node0.** 32 cores, 2 sockets: node0 = CPU 0–15 (holds both
`sfc` cards), node1 = CPU 16–31. All hot threads must live on **node0**, co-located
with the card; node1 is a QPI hop from the NIC and useless for this workload. Use
node0 cores 2–7 for the hot threads (mirrors duras's map exactly). The existing
`isolcpus=2-7,26-31` also isolates 26–31 on node1 — idle for the hot path, but
**deliberately kept** (reserved for tests); do not shorten the list.

**3. Real NIC → IRQ steering matters and must be made persistent.** But note the
baseline test is host-local loopback, so it does **not** traverse the card — the IRQ
steering only affects numbers once the setup goes over the wire (two machines) or
Onload TCP loopback accel is enabled.

### What was applied on scorilo (all persistent)

- `isolcpus=2-7,26-31` — already in the kernel cmdline (hand-set; left as-is rather
  than fighting the old TuneD's `[bootloader]` integration, which wasn't injecting
  `$tuned_params`).
- `sudo systemctl disable --now irqbalance` — persistent (survives reboot).
- **sfc IRQ steering via a systemd oneshot** (chosen over a TuneD `[script]` — more
  deterministic ordering, independent of TuneD). Steers all 64 `sfc0`/`sfc1` IRQs to
  node0 housekeeping cores 0–1:

  `/usr/local/sbin/steer-sfc-irqs.sh`:
  ```sh
  #!/bin/sh
  # Pin Solarflare sfc IRQs to node0 housekeeping cores 0-1, off isolated hot cores 2-7.
  set -u
  n=0
  for irq in $(grep -E 'sfc[01]' /proc/interrupts | awk -F: '{print $1}' | tr -d ' '); do
      if echo 0-1 > /proc/irq/$irq/smp_affinity_list 2>/dev/null; then n=$((n+1));
      else echo "WARN: could not set affinity for irq $irq" >&2; fi
  done
  echo "steer-sfc-irqs: set $n sfc IRQ(s) to CPUs 0-1"
  ```
  `/etc/systemd/system/steer-sfc-irqs.service`:
  ```ini
  [Unit]
  Description=Pin Solarflare sfc IRQs to housekeeping cores 0-1
  After=sys-subsystem-net-devices-sfc0.device

  [Service]
  Type=oneshot
  RemainAfterExit=yes
  ExecStart=/usr/local/sbin/steer-sfc-irqs.sh

  [Install]
  WantedBy=multi-user.target
  ```
  `sudo chmod +x /usr/local/sbin/steer-sfc-irqs.sh && sudo systemctl daemon-reload && sudo systemctl enable --now steer-sfc-irqs.service`
- Thread pinning — same `config.properties` values as duras (all node0): `pin.to.cpu=2`
  (LH pipe), `pin.tlt.to.cpu=5` (LH TLT), exchange `pin.to.cpu=3`, serializer
  `pin.tlt.to.cpu=4`, media driver SHARED on 6/7.

### Verify on scorilo (post-reboot)

```bash
systemctl is-active steer-sfc-irqs.service; systemctl is-enabled steer-sfc-irqs.service
journalctl -b -u steer-sfc-irqs.service --no-pager        # "set 64 sfc IRQ(s)"
systemctl is-active irqbalance; cat /sys/devices/system/cpu/isolated
grep LOC /proc/interrupts; sleep 10; grep LOC /proc/interrupts   # while app is loaded
```

Reading the `LOC` delta on scorilo: hot cores **2–7 ≈ 250/s** (the HZ=250 tick — this
IS the no-`nohz_full` shortcoming; duras was ~0), isolated-idle **26–31 ≈ 0/s**
(tickless), housekeeping busy with hrtimers. A clean ~250/s on 2–7 with no more also
confirms each hot core runs a single pinned thread (no co-runner).

**IRQ-steering caveat (important):** `smp_affinity_list` will read `0-1`, but
`effective_affinity_list` only migrates a queue on its *next* interrupt. With the card
**uncabled/idle** (or on a loopback-only test) the queues never fire, so
`effective_affinity_list` still shows the boot-time spread across all cores — this is
expected, not a failure. Re-verify once there's a link + traffic: active queues should
then land on 0/1, off 2–7.

### Open items on scorilo

- **NUMA-bind the JVMs** to node0 (not yet done): launch each trading process under
  `numactl --cpunodebind=0 --membind=0 <java …>` so heaps + non-pinned threads stay on
  node0 with the hot threads and NIC. The LOC delta showed housekeeping busy on node1
  (16–25), i.e. the JVMs currently span both sockets → cross-QPI heap access. Launch
  flag only, no code change. Verify: node1 cores 16–25 go quiet afterward.
- **Verify sfc IRQ steering under traffic.** The link to duras is now up (25 Gb/s), so
  check that active `sfc1` queues land on CPUs 0/1 (`effective_affinity_list`) during
  a run (see caveat above). Onload bypass traffic fires few kernel IRQs, so test with
  kernel traffic too.
- **Investigate the Onload latency tail** (≥99.9% step to ~8–9 µs, 125 µs max in the
  sockperf baseline): compare `LOC`/`/proc/interrupts` deltas on the pinned cores of
  both scorilo and duras during a run to find which host and source (timer, IRQ, SMI).
- **Run the trading system over the sfc link** (exchange on one host, LH + market
  maker on the other, Aeron `interface=10.10.10.0/24`, under `onload`) and compare with
  the loopback baseline.
- **Clean up leftovers on duras** (harmless): the old `~/onload` source tree
  (commit `9f330e70`) and `/usr/src/onload-7.1.0.265*`.
- **Node1 isolation (`26-31`)** — intentionally kept for tests; not an open item.

---

## scorilo on Ubuntu 26.04 (kernel 7.0): upgrade, TuneD, TSC skew, Onload

Done 2026-10-25. scorilo went 18.04 → 20.04 → 22.04 → 24.04 → 26.04.1 with
`do-release-upgrade` (no direct 18→26 path; each LTS must be fully
`apt full-upgrade`d and rebooted before the next hop; 26.04 is offered once 26.04.1
is out, no `-d` needed). Answers used: restart services automatically = yes; keep the
local version of every modified config file (`sshd_config`, `/etc/default/grub`,
`/etc/tuned/bootcmdline`). Before the first hop, `onload-dkms` and `sfc-dkms` were
purged so DKMS wouldn't try to rebuild them for every intermediate kernel; the stock
kernel then drove the X2522 (`sfc0`/`sfc1`) from 20.04 on.

### TuneD profile (`/etc/tuned/profiles/madrigal-lowlat/tuned.conf`)

The profile is **self-contained** (not `include=network-latency`) because it must not
inherit `tsc=reliable` (see next section). `isolcpus=2-7,26-31` stays hand-set in
`/etc/default/grub` (which already carries `$tuned_params`); the profile adds the rest:

```ini
[main]
summary=Madrigal low-latency: network-latency settings minus tsc=reliable, tickless + RCU offload on the isolated cores
include=latency-performance

[variables]
isolated_cores=2-7,26-31

[vm]
transparent_hugepages=never

[sysctl]
net.core.busy_read=50
net.core.busy_poll=50
net.ipv4.tcp_fastopen=3
kernel.numa_balancing=0
kernel.hung_task_timeout_secs = 600
kernel.nmi_watchdog = 0
vm.stat_interval = 10
kernel.timer_migration = 0

[bootloader]
cmdline_madrigal=skew_tick=1 rcupdate.rcu_normal_after_boot=1 nohz_full=${isolated_cores} rcu_nocbs=${isolated_cores}

[rtentsk]
```

Apply with `sudo tuned-adm profile madrigal-lowlat` and reboot. Expected
`/proc/cmdline`: `isolcpus=2-7,26-31 skew_tick=1 rcupdate.rcu_normal_after_boot=1
nohz_full=2-7,26-31 rcu_nocbs=2-7,26-31`; `tuned-adm verify` passes. irqbalance is no
longer installed; `steer-sfc-irqs.service` survived the upgrade (now steers 50 IRQs).

### TSC skew between sockets — do NOT use `tsc=reliable` on scorilo

The BIOS leaves socket 1 (CPUs 16–31) ~6000–9000 s behind socket 0 on the TSC (value
differs on every cold boot; kernel logs `[Firmware Bug]: TSC ADJUST`). `tsc=reliable`
(set by the stock `network-latency` profile) makes the kernel skip the TSC sync test
that repairs this, so `CLOCK_MONOTONIC`/`System.nanoTime()` jump when a thread crosses
sockets, and Onload logged `WARNING: cpu_khz computed to be <garbage>`. Without
`tsc=reliable` the kernel logs `TSC ADJUST compensate: CPU16 observed … warp` at boot,
the clocksource stays `tsc`, and the offsets drop to a few µs. Check after any
kernel/BIOS/profile change with a per-CPU `rdtsc` pin test (read TSC on CPU0, CPU n,
CPU0 again; offset = b − (a+d)/2; all CPUs should be within a few thousand ticks).
Hot threads stay on node0 regardless, so this mostly protects anything that strays
onto node1 — another reason for the `numactl` node0 binding.

### Onload on kernel 7.0

Built from git master (`a9451255`, 9.2 line — the README's supported range is kernels
6.1–7.0 on the head of the tree; tags lag), as DEB packages with DKMS:

```bash
sudo apt install -y build-essential git dkms linux-headers-$(uname -r) libcap-dev \
  libpcap-dev libmnl-dev libnl-3-dev libnl-route-3-dev libssl-dev \
  debhelper dh-dkms devscripts fakeroot dpkg-dev dh-python python3-all pybuild-plugin-pyproject
git clone https://github.com/Xilinx-CNS/onload.git && cd onload
./scripts/onload_mkpackage          # rm leftover onload-*.tgz first if re-running
sudo apt install -y ./onload-dkms_*.deb ./onload-user_*.deb ./onload-dev_*.deb
sudo onload_tool reload             # first load without rebooting
```

The DKMS package builds Onload's own `sfc`, `sfc_char`, `sfc_resource` and `onload`
modules (replacing the in-kernel `sfc`) and rebuilds them on kernel updates. Modules
auto-load at boot. Verified: `onload_stackdump` lists a stack for a socket bound on an
`sfc1` address under `onload python3 …` (so the card's licence is accepted) and shows
`khz: 2095147`.

**duras uses the same build.** Its old manual `onload_install` (commit `9f330e70`) had
no modules for newer kernels (6.8.0-147) after a kernel update. It was replaced on
2026-10-25: `sudo onload_uninstall`, then the same three `.deb` files (copied from
scorilo with `scp`) installed with `apt`; DKMS now rebuilds the modules per kernel.
Back-to-back link: scorilo `sfc1` = `10.10.10.172/24`, duras `sfc1` = `10.10.10.162/24`
(persistent via duras's `/etc/netplan/99_config.yaml`), 25 Gb/s full duplex,
ping RTT ~15–50 µs. After `onload_tool reload` an interface can come back
administratively down on duras — `sudo ip link set sfc1 up`.

### Reference baseline: sockperf UDP ping-pong over the sfc link (kernel vs Onload)

Measured 2026-10-25 between scorilo (client) and duras (server), direct 25 Gb/s link
(`10.10.10.172` ↔ `10.10.10.162`), `madrigal-lowlat` profile on scorilo, Onload build
`0~a945125` on both ends. Both processes pinned to isolated core 2 (node0 on scorilo).
`sockperf` reports **one-way** latency (half the round trip); 64-byte messages, 20 s:

```bash
# server (duras)
[onload --profile=latency] taskset -c 2 sockperf server -i 10.10.10.162 -p 11111
# client (scorilo)
[onload --profile=latency] taskset -c 2 sockperf ping-pong -i 10.10.10.162 -p 11111 -m 64 -t 20
```

| One-way latency | Kernel | Onload (`--profile=latency`) |
|---|---|---|
| Average (std-dev) | 4.33 µs (0.50) | **1.11 µs** (0.28) |
| Median | 4.28 µs | 1.09 µs |
| Minimum | 4.06 µs | 1.02 µs |
| 99th percentile | 4.65 µs | 1.23 µs |
| 99.9th percentile | 12.0 µs | 8.3 µs |
| 99.99th percentile | 12.8 µs | 9.3 µs |
| Worst observation | 163 µs | 125 µs |
| Messages in 20 s | 2.3 M | 8.9 M |

Conclusions:
- Onload cuts the median from ~4.3 µs to ~1.1 µs (≈4×) and raises message rate by the
  same factor; 0 drops/duplicates/reordering in both runs. This confirms the full
  chain works: scorilo and duras Onload builds, card licence, tuning, cabling.
- The plain-kernel path is already good (4.3 µs) thanks to `busy_read`/`busy_poll`,
  the performance governor and isolated cores.
- The body of the Onload distribution is very tight (25th–99th percentile within
  1.075–1.23 µs). The tail is not: a regular step to ~8–9 µs at ≥99.9% and rare
  spikes (125 µs max). The kernel run shows a similar step (12 µs at 99.9%), so it is
  not caused by Onload. Not yet investigated; if it matters, compare `LOC` and
  `/proc/interrupts` deltas on the pinned cores of **both** hosts while the test runs
  to find which side (timer, IRQ, SMI) causes it.
- Always confirm the `oo:<app>[pid]: Using Onload …` banner appears on both sides —
  without it the run is not accelerated and the numbers mean nothing.

Harmless dmesg noise: `pcie_tph_get_cpu_st error(-22)`; `ethtool`
prints `netlink error: Operation not permitted` without sudo.

---

## Aeron over the Solarflare card (two-box setup)

By default the internal Aeron bus runs over **loopback** (endpoints on localhost /
same host), so it never touches the NIC — which is why single-host latency runs are
unaffected by any NIC/IRQ tuning. To put Aeron on the Solarflare card you need traffic
that is genuinely **remote** over the sfc link between two boxes.

**Prerequisites on each box:**
- Card bound to the in-tree `sfc` driver: `lspci -nn | grep -i solarflare`,
  `lspci -k -s <addr>` (→ `Kernel driver in use: sfc`). The in-tree `sfc` driver ships
  with the kernel and supports the X2522 on modern kernels — **no Onload needed for
  plain kernel UDP.**
- **Cabled** to the peer (direct DAC/fibre, or a switch). Confirm carrier:
  `ethtool sfc0 | grep -i 'link detected'` → `yes`, and `ip -br link show sfc0` shows
  `UP` + `LOWER_UP`. An uncabled port reads `!RUNNING` in `ifconfig` (flags without
  `RUNNING`) and carries nothing (`RX/TX packets 0`).

**Give the sfc link its own subnet** (not the management LAN — sharing it causes
routing ambiguity). The sfc interfaces come up with **no IP**, so assign one each end:
```bash
# scorilo
sudo ip addr add 10.10.10.1/24 dev sfc0 && sudo ip link set sfc0 up
# peer (duras)
sudo ip addr add 10.10.10.2/24 dev sfc0 && sudo ip link set sfc0 up
```
(Persist later via netplan / systemd-networkd once proven.) Sanity-check the wire:
`ping -I sfc0 10.10.10.2` from scorilo.

**Aeron channel URL** — `endpoint` = the *remote* address, `interface` = the *local*
sfc subnet, so Aeron binds to sfc0 rather than the management NIC:
```
aeron:udp?endpoint=10.10.10.2:40123|interface=10.10.10.0/24
```
`interface=` accepts an exact local IP or a subnet CIDR; it selects the local NIC that
owns a matching address. **Split the processes across the two boxes** so the flow is
genuinely remote (e.g. exchange on one, LH + market-maker on the other) — a same-host
endpoint is delivered via loopback and will *not* cross the card even with `interface=`
set.

**Kernel-UDP vs Onload:**
- **Plain kernel UDP over sfc** needs only driver + cable + IP. Good first baseline;
  do this before any Onload work.
- **Onload acceleration** (kernel bypass) is a separate, optional layer: run the media
  driver / app under `onload`. It's per-host (each end accelerates its own sockets;
  versions need not match across boxes) and needs a **current Onload build for that
  host's kernel** (e.g. duras 6.8 needs a fresh build from github.com/Xilinx-CNS/onload
  — an old 4.15 build won't compile against 6.8). Card AppFlex licence is per-adapter,
  so no relicensing when moving a card.

**Verify once traffic flows:** sfc rows in `/proc/interrupts` start climbing (and,
because the queues finally fire, `effective_affinity_list` migrates onto the steered
cores 0/1 — see the scorilo IRQ-steering caveat), and the Aeron logs show the sfc
endpoint connected.

---

## Notes / gotchas

- `nohz_full` only keeps a core tickless with **≤1 runnable task**; two busy-spin
  threads on one core defeat it (and reintroduce ~1 scheduler-quantum spikes).
- GC was never the STW culprit (ZGC STW ≤108 µs); the residual sub-ms tail on duras
  was safepoint time-to-safepoint. Cutting GC/safepoint frequency (bigger heap) is
  the next lever, separate from isolation.
- `tsc=reliable` (from `network-latency`) is only safe on hosts whose TSCs are really
  synchronized (duras, single socket). On multi-socket scorilo the BIOS leaves a
  per-boot TSC offset between sockets that only the kernel's sync test repairs — see
  "TSC skew between sockets".
- `/proc/cmdline` is the source of truth for what's active — not `/etc/default/grub`,
  since TuneD composes several sources.
