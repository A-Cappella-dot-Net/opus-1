#!/bin/bash

#############################################
# 'start' script
# Usage: start.sh {instance {springFile.xml}}
#############################################

APP_HOME="$(dirname "$(dirname "$(readlink -fm "$0")")")"

cd ${APP_HOME}

INSTANCE=$1
SPRING_XML=$2

. ${APP_HOME}/bin/setenv.sh

PROPERTIES_FILE=config/config.properties
if [ ! -f ${PROPERTIES_FILE} ] ; then
	echo "Properties file ${PROPERTIES_FILE} does not exist" >&2
	exit 1
fi

getProperty() {
	NAME=$1
	grep "${NAME}" ${PROPERTIES_FILE} | grep -v "^\s*#" | sed "s/\s*${NAME}\s*=\s*//;s/\r//"
}

APP_NAME_PROPERTY=appName
APP_NAME=`getProperty ${APP_NAME_PROPERTY}`

if [ -z "${APP_NAME}" ] ; then
        echo "Variable ${APP_NAME_PROPERTY} not defined in file ${PROPERTIES_FILE}" >&2
        exit 1
fi

echo ===============================================================================
echo '                           start '${APP_NAME}
echo ===============================================================================

if [ ! -f ${APP_HOME}/logs ] ; then
	mkdir -p ${APP_HOME}/logs
fi
if [ ! -f ${APP_HOME}/var ] ; then
	mkdir -p ${APP_HOME}/var
fi

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

PID_FILE=${APP_HOME}/var/${APP_NAME}${INSTANCE}.pid
if [ -f "$PID_FILE" ] ; then
	PID=$(cat ${PID_FILE})
	if /usr/bin/test -e "/proc/${PID}" ; then
		echo "Another instance is using ${PID_FILE}! Please run './stop.sh ${INSTANCE} to stop" >&2
		exit 1
	fi
fi

CURRENT_DATE=`date +%Y%m%d_%H%M%S`

LOG_NAME="${APP_HOME}/logs/${APP_NAME}${INSTANCE}-${CURRENT_DATE}.log"

GC_LOG_NAME="${APP_HOME}/logs/${APP_NAME}${INSTANCE}-${CURRENT_DATE}-gc.log"

ADD_OPENS="--add-opens java.base/sun.nio.ch=ALL-UNNAMED"

VM_ARGS="-Dinstance=${INSTANCE} -Xms${HEAP_SIZE} -Xmx${HEAP_SIZE} ${GC_ARGS}${GC_LOG_NAME} ${ADD_OPENS}"

CLASSPATH=${APP_HOME}/app:${APP_HOME}/lib/*:${APP_HOME}/lib/dependencies/*

${JAVACMD} -version

COMMAND="${JAVACMD} -Duser.dir=${APP_HOME} ${VM_ARGS} -cp ${CLASSPATH} net.a_cappella.continuo.Main ${SPRING_XML}"
echo ${COMMAND}

eval "${COMMAND} &echo \$! > ${PID_FILE}" > ${LOG_NAME} 2>&1

PID=$!

echo "Process PID: ${PID}"
