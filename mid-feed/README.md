# mid-feed

A simulated pricer: `MidFeedPublisher` publishes mid prices for a configured set of instruments at randomized intervals, giving the rest of the system (e.g. the [market-maker](../market-maker/README.md)) a price reference to work from. Assembled from Spring wiring and launched through `continuo.Main`.
