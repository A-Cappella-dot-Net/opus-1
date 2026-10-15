#!/bin/bash

APP_HOME="$(dirname "$(dirname "$(readlink -fm "$0")")")"

cd ${APP_HOME}/services/dev-tools/bin
./stop.sh _0

cd ${APP_HOME}/services/market-maker/bin
./stop.sh 0-0
./stop.sh 0-1

cd ${APP_HOME}/services/mid-feed/bin
./stop.sh

cd ${APP_HOME}/services/lh/bin
./stop.sh -0_0
./stop.sh -0_1
./stop.sh -140_0
./stop.sh -140_1
./stop.sh -150_0
./stop.sh -150_1
./stop.sh -160_0
./stop.sh -160_1
./stop.sh -170_0
./stop.sh -170_1

cd ${APP_HOME}/services/m-cache/bin
./stop.sh -0_0
./stop.sh -0_1

cd ${APP_HOME}/services/sys/bin
./stop.sh _0
./stop.sh _1

cd ${APP_HOME}/services/serializer/bin
./stop.sh _0
./stop.sh _1

#cd ${APP_HOME}/services/daemons-chronicle/bin
cd ${APP_HOME}/services/daemons-aeron/bin
./stop.sh -160
./stop.sh -170

cd ${APP_HOME}/services/exchange/bin
./stop.sh -0
./stop.sh -1

cd ${APP_HOME}/bin
