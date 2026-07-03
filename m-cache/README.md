# m-cache

The deployable managed cache application — a thin shell around [madrigal](../madrigal/README.md)'s `mcache` components. It hosts the managed subjects (orders, order states, sequence numbers, ...) that hold system state and answer snap requests, letting components bootstrap their state via SnS. Assembled from Spring wiring and configuration, and launched through `continuo.Main`.
