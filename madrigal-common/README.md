# madrigal-common

The transport-independent core of the madrigal trading system. madrigal-common defines the domain model and contracts without committing to a transport, while `madrigal-aeron` supplies the transport-dependent side. Built on presto, so all madrigal data flows with SnS (snap and subscribe) semantics.

- **Domain objects** (`obj`) — the pooled objects published between madrigal components: orders (`OrderObj`, `FinalizeOrderObj`), ECN instruments, prices, and imbalances (`Ecn*Obj`), mid-feed prices (`MidFeedObj`), market and user status, and credentials.
- **Vocabulary** (`constants`) — the madrigal-wide enums: sides, order types and statuses, time in force, instrument phases and statuses, market status, gateway types, failover actions, and more.
- **Contracts** (`interfaces`) — the interfaces components implement to plug into the system: message processing, connection and date-roll listeners, record publishing, id generation, and Swing UI beans.
- **Shared utilities** (`utils`, `beans`) — trade-date handling, CSV parsing/writing, id generators, users and credentials.
