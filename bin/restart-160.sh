#!/bin/bash

APP_HOME="$(dirname "$(dirname "$(readlink -fm "$0")")")"

#export JAVA_HOME=/usr/lib/jvm/jdk1.7.0_80

cd ${APP_HOME}/services/exchange/bin
./restart.sh -0
#./restart.sh -1

cd ${APP_HOME}/services/daemons-aeron/bin
./restart.sh -160
sleep 1

cd ${APP_HOME}/services/sys/bin
./restart.sh _0
sleep 3

cd ${APP_HOME}/services/m-cache/bin
./restart.sh -0_0
#./restart.sh -1_0
sleep 1

cd ${APP_HOME}/services/serializer/bin
./restart.sh _0
sleep 1
#./restart.sh _1
#sleep 1

cd ${APP_HOME}/services/credentials/bin
./start.sh _0
sleep 4
./stop.sh _0

cd ${APP_HOME}/services/market-maker/bin
./restart.sh 0-0
#./restart.sh 1-0
#./restart.sh 0-1
#./restart.sh 1-1
sleep 1

cd ${APP_HOME}/services/lh/bin
./restart.sh -0_0
#./restart.sh -1_0
sleep 2

cd ${APP_HOME}/services/mid-feed/bin
./restart.sh

#cd ${APP_HOME}/services/dev-tools/bin
#./restart.sh _0

cd ${APP_HOME}/bin
