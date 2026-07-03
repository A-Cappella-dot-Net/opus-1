# madrigal

Madrigal gathers together the components of a trading system: order management, market data, users, credentials, instruments, caches, and a web pub-sub tool. It does not contain everything a complete system would want — it is a starting point. Built on [madrigal-common](../madrigal-common/README.md) / [madrigal-aeron](../madrigal-aeron/README.md), so components communicate over presto with SnS semantics.

- **Line handler — order management** (`lh.om`) — the gateway side facing a trading venue. `OrderManagerService` implements tactics at the gateway level that allow more efficient higher-level algo implementations, such as size amend up without losing queue position, or sniper orders. `OrderManagerClient` is how applications submit and track orders. The deployable line handler application lives in the `lh` module.
- **Line handler — market data** (`lh.md`) — `MarketDataService` publishes the venue's prices into the system.
- **Users and credentials** (`user`, `credentials`) — login/user management for the system and credentials caches for venue sessions.
- **Instruments** (`instrument`) — the cache of tradeable instruments.
- **Managed caches** (`mcache`) — presto managed caches that hold system state (orders, order states, sequence numbers) and answer snap requests, so components can bootstrap via SnS.
- **View server and frontend** (`devtools`, `frontend/`) — a Jetty/WebSocket bridge that exposes presto subjects as JSON to a React web frontend, primarily used for development purposes.
