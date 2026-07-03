# market-maker

A starting point for a market making application. `MarketMaker` quotes both sides of an instrument around a mid price (from [mid-feed](../mid-feed/README.md)), with configurable normal and wide spreads, adjusting its quotes as instrument status and trading phases change. It submits and manages its orders through madrigal's order management, exercising the full path from strategy to venue. Assembled from Spring wiring and launched through `continuo.Main`.
