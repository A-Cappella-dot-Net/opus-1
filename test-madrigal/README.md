# test-madrigal

Standalone test and benchmark applications for [madrigal](../madrigal/README.md). The order exercisers (`ox`) drive orders through the line handler to the exchange, each exercising a specific feature of the order path end to end. The perf mixes (`perf`) generate order and market data load at different priorities and burst profiles to measure the system under realistic traffic. Launched with the same bin/config layout as the deployable applications.
