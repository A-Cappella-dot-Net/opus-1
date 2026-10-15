#!/bin/bash

# Invoke this script from the bin directory.

# The filter criteria options are:
#
# type: This is the type id of the counter; 0 is system counters; 1-4 are some of the stream counters.
# identity: The key which identifies the counter within its type scope.
# session: Session id to be used with position counters.
# stream: Stream id to be used with position counters.
# channel: Channel to be used with position counters.
#
# The filter criteria are regular expressions which can be useful for filtering out a range of streams.

# Examples:
#
# All system counters: type=0
# For just the count of errors: type=0 identity=15
# All position counters: type=[1-4]
# The counters for a specific stream: type=[1-4] session=123456 stream=10 'channel=aeron:udp\?endpoint=localhost:40123'

# set -x

MAIN_CLASS="AeronStat"
VM_ARGS="-Daeron.dir=/dev/shm/aeron-puiu"
CLASSPATH=$(JARS=(../lib/*.jar); IFS=:; echo "${JARS[*]}")

if [ -z "$JAVA_HOME" ] ; then
        JAVACMD=`which java`
else
        JAVACMD="$JAVA_HOME/bin/java"
fi

if [ ! -x "$JAVACMD" ] ; then
        echo "The JAVA_HOME environment variable is not defined correctly" >&2
        echo "JAVA_HOME should point to a JDK not a JRE" >&2
        exit 1
fi

${JAVACMD} -version

COMMAND="${JAVACMD} -cp ${CLASSPATH} io.aeron.samples.${MAIN_CLASS}" $1 $2 $3 $4
echo ${COMMAND}

eval "${COMMAND}"
