#!/bin/bash

APP_HOME="$(dirname "$(dirname "$(readlink -fm "$0")")")"

#cd ${APP_HOME}/services/exchange/bin
#./restart.sh -0
#sleep 1
#./restart.sh -1
#sleep 1

cd ${APP_HOME}/services/daemons-aeron/bin
./restart.sh -160
sleep 1

cd ${APP_HOME}/services/dev-tools/bin
./restart.sh _0
sleep 1

cd ${APP_HOME}/bin
