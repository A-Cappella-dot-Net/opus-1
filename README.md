# opus-1 — Presto and Madrigal

[![GitHub Clones](https://img.shields.io/badge/dynamic/json?color=success&label=Clone&query=count&url=https://gist.githubusercontent.com/puiuvlad/fb3fab8c668ce09abffd28ca5daa0a01/raw/clone.json&logo=github)](https://github.com/A-Cappella-dot-Net/opus-1)
[![GitHub Views](https://img.shields.io/badge/dynamic/json?color=success&label=Views&query=count&url=https://gist.githubusercontent.com/puiuvlad/fb3fab8c668ce09abffd28ca5daa0a01/raw/views.json&logo=github)](https://github.com/A-Cappella-dot-Net/opus-1)

Opus-1 gathers together the components of a trading system, built from the ground up for low-latency, allocation-free operation: a foundation library, messaging middleware with pluggable transports, the core of a securities exchange, and the trading-system components that tie them together. It does not contain everything a complete system would want — it is a starting point.

## Modules

**Foundation**

- [continuo](continuo/README.md) — the foundation library: pooled objects, wire messages, pipe/sink NIO sockets

**Messaging (presto)**

- [presto](presto/README.md) — messaging middleware: SnS (snap and subscribe) pub/sub, content filtering, fault-tolerant collective — transport independent
- [presto-aeron](presto-aeron/README.md) — the Aeron transport binding (shared memory/UDP, SBE)
- [daemons-aeron](daemons-aeron/README.md) — deployable messaging daemon
- [serializer](serializer/README.md) — deployable serializer: global sequence numbers for explicitly serialized streams

**Exchange (cembalo)**

- [cembalo](cembalo/README.md) — the core of a securities exchange: matching engine, FIX connectivity, trading sessions
- [exchange](exchange/README.md) — deployable exchange application

**Trading system (madrigal)**

- [madrigal-common](madrigal-common/README.md) — transport-independent domain model and contracts
- [madrigal-aeron](madrigal-aeron/README.md) — the Aeron transport binding of the domain model
- [madrigal](madrigal/README.md) — the trading-system components: order management, market data, users, caches
- [lh](lh/README.md) — deployable line handler (gateway) to the exchange
- [m-cache](m-cache/README.md) — deployable managed cache
- [sys](sys/README.md) — deployable system services: monitoring, user management
- [credentials](credentials/README.md) — deployable credentials publisher
- [mid-feed](mid-feed/README.md) — deployable simulated pricer
- [market-maker](market-maker/README.md) — a starting point for a market making application
- [dev-tools](dev-tools/README.md) — deployable web pub-sub tool for development

**Testing and publishing**

- [test-presto](test-presto/README.md) — standalone presto test and benchmark applications
- [test-madrigal](test-madrigal/README.md) — standalone madrigal test and benchmark applications
- [opus-1-bom](opus-1-bom/README.md) — Maven BOM aligning the published module versions

## Building

```
./gradlew build
```

License (See LICENSE file for full license)
-------------------------------------------
Copyright 2026 Vladimir Ivanov

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
