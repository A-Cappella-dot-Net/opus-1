# sys

The deployable system services application. It wires [presto](../presto/README.md)'s `MonitorService` with staling monitors, predicates, and actions (watching for stale data and instances), together with [madrigal](../madrigal/README.md)'s user manager. Assembled from Spring wiring and configuration, and launched through `continuo.Main`.
