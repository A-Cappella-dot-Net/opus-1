# cembalo

The core of a securities exchange. Cembalo implements the matching engine and everything around it — order matching, FIX connectivity, market data, and trading-session phases. The deployable application that wires and runs it lives in the `exchange` module; cembalo itself is the engine.

Built directly on [continuo](../continuo/README.md) (pooled messages, pipe/sink sockets).

- **Matching engine** — one `Matcher` per `Instrument`, combining a `ContinuousOrderBook` for regular trading with open/close `AuctionOrderBook`s. Orders (`Order`, `ActiveOrders`) follow the standard lifecycle: new, replace, cancel, partial/full fills, rejects.
- **FIX protocol** (`fix`, `generated`, `generator`) — `FixMessage` and friends encode/decode FIX messages; `FixConstants` is generated from a FIX dictionary by the `generator` package (Gradle task `genFixConstants`). Note: this is a deliberately simple, incomplete FIX implementation. It exists for the circumstances where developers have no access to a real exchange but need to test their programs (e.g. the madrigal components) against something that behaves like one. A production deployment would use a real FIX engine instead.
- **Server and client** — `ExchangeServer` accepts FIX-speaking clients over continuo sockets, manages sessions and credentials (`TraderManager`), and guarantees redelivery of execution reports missed while a client was disconnected. `ExchangeClient` is the client-side counterpart used by trading apps and tests.
- **Market data** (`beans`, `Send*`) — market data snapshots, auction imbalances, and instrument status broadcasts to connected clients.
- **Trading sessions** (`timer`, `constants`) — an internal timer drives instruments through their daily phases (pre-open, open auction, continuous trading, close auction, ...), with schedules adjustable at startup.
- **Instruments** — `Instrument`, `Bond`, and `InstrumentsCache` describe what is tradeable; the instrument universe is loaded from XML by the hosting application.
