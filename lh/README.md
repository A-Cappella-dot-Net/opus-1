# lh

The deployable line handler (gateway) application. `LineHandler` is the venue-specific adapter that connects [madrigal](../madrigal/README.md)'s order management, market data, and login contracts to a concrete trading venue — the [cembalo](../cembalo/README.md) exchange, over its FIX protocol. A line handler for a different venue would follow the same shape. Wiring and configuration live in Spring XML, launched through `continuo.Main`.
