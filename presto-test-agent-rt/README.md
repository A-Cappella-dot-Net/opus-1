# presto-test-agent-rt

The runtime half of [presto-test-agent](../presto-test-agent/README.md), loaded on the bootclasspath so the instrumented JDK socket classes can reach it: the proxy routing table and thread markers that decide which connections get redirected where.
