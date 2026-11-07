#!/bin/bash

VM_VERSION=21
HEAP_SIZE=100M
SOFT_HEAP_SIZE=50M

if [ "$VM_VERSION" == "8" ]; then
    JAVA_HOME="/usr/lib/jvm/java8"
    GC_ARGS="-XX:+UseConcMarkSweepGC -XX:SurvivorRatio=1 -XX:NewRatio=1 -XX:+DisableExplicitGC -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:"
elif [ "$VM_VERSION" == "21" ]; then
    JAVA_HOME="/usr/lib/jvm/java21"
    GC_ARGS="-XX:SoftMaxHeapSize=$SOFT_HEAP_SIZE -XX:+UseZGC -XX:+ZGenerational -XX:+UseLargePages -XX:+AlwaysPreTouch -Xlog:gc*:file="
#    GC_ARGS="-XX:SoftMaxHeapSize=$SOFT_HEAP_SIZE -XX:+UseZGC -XX:+ZGenerational -XX:+UseLargePages -XX:+AlwaysPreTouch -Xlog:gc*,safepoint:file="
fi

export JAVA_HOME
export GC_ARGS

echo "JAVA_HOME = $JAVA_HOME"
echo "GC_ARGS = $GC_ARGS"

# Onload acceleration for the LH<->exchange TCP leg (used by lh and exchange start.sh).
# Set USE_ONLOAD=0 (from the environment) to start without Onload (plain-kernel baseline for A/B).
USE_ONLOAD=${USE_ONLOAD:-0}
export USE_ONLOAD

# Loopback mode (used by daemons-aeron start.sh; can be overridden from the environment):
#   1: SOFTWARE - software loopback
#   2: HARDWARE - hardware loopback (needs full-feature firmware variant)
#   3: IPC      - IPC loopback (set AeronClient._useIpcLoopback to true)
#   any other value: NONE - no Onload environment variables are exported
# Note: must be in sync with common/config.properties use.ipc.loopback
# i.e., use.ipc.loopback=true  <=> USE_LOOPBACK=3
#   and use.ipc.loopback=false <=> USE_LOOPBACK!=3
USE_LOOPBACK=${USE_LOOPBACK:-0}
export USE_LOOPBACK
