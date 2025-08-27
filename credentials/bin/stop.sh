#!/bin/bash

#############################################
# 'stop' script
# Usage: stop.sh {instance}
#############################################

APP_HOME="$(dirname "$(dirname "$(readlink -fm "$0")")")"

cd ${APP_HOME}

INSTANCE=$1

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
echo '                           stop '${APP_NAME}
echo ===============================================================================

PID_FILE=${APP_HOME}/var/${APP_NAME}${INSTANCE}.pid
if [ ! -f "$PID_FILE" ] ; then
	echo "Instance PID file ${PID_FILE} not found" >&2
	exit 1
fi

killProcess() {
	PID=$1
	echo "Stopping process: ${PID}"
	if /usr/bin/test -e "/proc/${PID}" ; then
		kill ${PID}
		echo "Process ${PID} has been stopped"
	fi
}

killProcess `cat ${PID_FILE}`
rm -f ${PID_FILE}