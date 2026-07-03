# presto-aeron

The [Aeron](https://aeron.io/) transport binding of [presto](../presto/README.md). Data moves over Aeron's shared-memory/UDP transport encoded with SBE.

- **AeronDaemon** — a presto collective member (election, fault tolerance, and membership work exactly as in presto) that also hosts an embedded Aeron `MediaDriver`. Threading mode, idle strategies, and CPU pinning are all configurable for latency tuning. The deployable daemon application lives in the `daemons-aeron` module.
- **AeronClient** — the client-side counterpart: applications publish and subscribe through it, with the SnS (snap and subscribe) semantics of presto preserved over the Aeron transport.
- **SBE codecs** (`obj`, `sbe/schema.xml`) — objects are encoded with [Simple Binary Encoding](https://github.com/aeron-io/simple-binary-encoding); the Java codecs are generated from the schema at build time (`generateSbeSources`), and per-type coders (`MapCoder`, `SeqNoCoder`, ...) bridge presto's pooled objects to SBE buffers.
