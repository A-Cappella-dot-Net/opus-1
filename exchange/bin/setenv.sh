#!/bin/bash

VM_VERSION=21
HEAP_SIZE=100M
SOFT_HEAP_SIZE=50M

if [ "$VM_VERSION" == "8" ]; then
    JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-amd64"
    GC_ARGS="-XX:+UseConcMarkSweepGC -XX:SurvivorRatio=1 -XX:NewRatio=1 -XX:+DisableExplicitGC -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:"
elif [ "$VM_VERSION" == "21" ]; then
    JAVA_HOME="/usr/lib/jvm/java-1.21.0-openjdk-amd64"
    GC_ARGS="-XX:SoftMaxHeapSize=$SOFT_HEAP_SIZE -XX:+UseZGC -XX:+ZGenerational -XX:+UseLargePages -XX:+AlwaysPreTouch -Xlog:gc*:file="
fi

export JAVA_HOME
export GC_ARGS

echo "JAVA_HOME = $JAVA_HOME"
echo "GC_ARGS = $GC_ARGS"
