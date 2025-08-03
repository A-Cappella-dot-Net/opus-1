echo off

SET VM_VERSION=21

SET HEAP_SIZE=100M
SET SOFT_HEAP_SIZE=50M

if "%VM_VERSION%"=="8" (
    set JAVA_HOME=C:\Java\jdk1.8.0_281
    set "GC_ARGS=-XX:+UseConcMarkSweepGC -XX:SurvivorRatio=1 -XX:NewRatio=1 -XX:+DisableExplicitGC -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:"
) else if "%VM_VERSION%"=="21" (
    set JAVA_HOME=C:\Java\jdk-21.0.7+6
    set "GC_ARGS=-XX:SoftMaxHeapSize=%SOFT_HEAP_SIZE% -XX:+UseZGC -XX:+ZGenerational -XX:+UseLargePages -XX:+AlwaysPreTouch -Xlog:gc*:file="
)

@REM echo JAVA_HOME = %JAVA_HOME%
@REM echo GC_ARGS = %GC_ARGS%
