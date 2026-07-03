# madrigal-aeron

The Aeron transport binding of [madrigal-common](../madrigal-common/README.md), built on [presto-aeron](../presto-aeron/README.md). It makes the madrigal domain model publishable over Aeron.

- **SBE coders** (`obj`) — one coder per madrigal-common domain object (`OrderCoder`, `EcnPriceCoder`, `MarketStatusCoder`, ...) bridging the pooled objects to SBE-encoded buffers, plus converters for the madrigal enums.
- **SBE schema** (`sbe/schema.xml`) — the wire format definition; Java codecs are generated from it at build time (`generateSbeSources`).
