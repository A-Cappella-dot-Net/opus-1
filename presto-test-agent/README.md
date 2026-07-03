# presto-test-agent

A Java agent used by presto's network-fault tests. It instruments `sun.nio.ch.SocketChannelImpl.connect` (via Byte Buddy) so that TCP connections opened by the code under test can be transparently rerouted through an in-process proxy — letting tests inject disconnects and other network issues deterministically. The runtime classes consulted by the instrumented code live in [presto-test-agent-rt](../presto-test-agent-rt/README.md); presto's `proxyAgentTest` Gradle task runs the tests that depend on both.
