#!/bin/bash

# invoke this script from the bin directory

# set -x

MAIN_CLASS="StreamStat"
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

COMMAND="${JAVACMD} -cp ${CLASSPATH} io.aeron.samples.${MAIN_CLASS}"
echo ${COMMAND}

eval "${COMMAND}"
