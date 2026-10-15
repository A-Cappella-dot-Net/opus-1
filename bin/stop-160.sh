#!/bin/bash

APP_HOME="$(dirname "$(dirname "$(readlink -fm "$0")")")"

cd ${APP_HOME}/services/dev-tools/bin
./stop.sh _0

cd ${APP_HOME}/services/market-maker/bin
./stop.sh 0-0
#./stop.sh 1-0
#./stop.sh 0-1
#./stop.sh 1-1

cd ${APP_HOME}/services/mid-feed/bin
./stop.sh

cd ${APP_HOME}/services/lh/bin
./stop.sh -0_0
#./stop.sh -1_0

cd ${APP_HOME}/services/m-cache/bin
./stop.sh -0_0
#./stop.sh -1_0

cd ${APP_HOME}/services/sys/bin
./stop.sh _0

cd ${APP_HOME}/services/daemons-aeron/bin
./stop.sh -160

cd ${APP_HOME}/services/exchange/bin
./stop.sh -0
#./stop.sh -1

cd ${APP_HOME}/bin
