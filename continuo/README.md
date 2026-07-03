# continuo

The foundation library of opus-1. Like the basso continuo in baroque music, it underpins every other module: all higher-level components (presto, cembalo, madrigal, ...) build on the primitives defined here. It has no dependencies on other opus-1 modules.

Continuo provides the building blocks for low-latency, allocation-free messaging between processes:

- **Managed objects and pooling** (`managed`) — `ObjectManager` and `Pool` recycle `Poolable` instances so that steady-state operation allocates no new objects (and triggers no GC). Messages and data objects are acquired from pools and released back with `stopUsing()`.
- **Messages** (`msg`) — `Msg` is the base class for everything sent over the wire; `MsgCoder` encodes/decodes messages to and from byte buffers. Built-in messages cover connection registration, disconnects, and testing.
- **Self-describing objects** (`obj`) — `Obj` plus per-type metadata (`obj.meta`) describe payload fields and types, enabling generic encoding, publication, and type checking.
- **Socket transport** (`socket`) — non-blocking NIO primitives: `BaseClientPipe` (outgoing client connection) and `BaseServerSink` (server side accepting many clients), with a registration handshake between them. "Pipe" and "sink" are the vocabulary used throughout opus-1 for the two ends of a connection.
- **Identity** (`collective`) — `AppInfo` and `ConnInfo` identify applications and their network endpoints.
- **Pub/sub contracts** (`ps`) — interfaces for subscription handling and merging, implemented by higher-level modules.
- **Utilities** (`utils`, `datatypes`) — tight-loop threads, string interning, delay queues, stats logging (HdrHistogram), and pooled date/time types.

External dependencies are limited to low-latency staples: Agrona (idle strategies), Trove (primitive collections), HdrHistogram, and thread affinity.
