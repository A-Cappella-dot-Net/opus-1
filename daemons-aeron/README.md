# daemons-aeron

The deployable messaging daemon application — a thin shell around [presto-aeron](../presto-aeron/README.md)'s `AeronDaemon`, which contains all the actual logic. There is no code here: the application is assembled from Spring wiring and configuration, and launched through `continuo.Main`.
