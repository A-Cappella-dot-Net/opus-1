#!/bin/bash

APP_HOME="$(dirname "$(dirname "$(readlink -fm "$0")")")"

#export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
#export JAVA_HOME=/usr/lib/jvm/java-1.21.0-openjdk-amd64

cd ${APP_HOME}/services/exchange/bin
./restart.sh -0
#./restart.sh -1

#cd ${APP_HOME}/services/daemons-chronicle/bin
cd ${APP_HOME}/services/daemons-aeron/bin
./restart.sh -0_0
#./restart.sh -170
sleep 1

cd ${APP_HOME}/services/sys/bin
./restart.sh _0
sleep 3
#./restart.sh _1
#sleep 3

cd ${APP_HOME}/services/m-cache/bin
./restart.sh -0_0
sleep 1
#./restart.sh -0_1
#sleep 1

cd ${APP_HOME}/services/serializer/bin
./restart.sh _0
sleep 1
#./restart.sh _1
#sleep 1

cd ${APP_HOME}/services/credentials/bin
./start.sh
sleep 2
./stop.sh

cd ${APP_HOME}/services/market-maker/bin
./restart.sh 0-0
sleep 1
#./restart.sh 0-1
#sleep 1

cd ${APP_HOME}/services/lh/bin
./restart.sh -0_0
#./restart.sh -140_0
#./restart.sh -150_0
#./restart.sh -160_0
#./restart.sh -170_0
sleep 2
#./restart.sh -0_1
#./restart.sh -140_1
#./restart.sh -150_1
#./restart.sh -160_1
#./restart.sh -170_1
#sleep 2

cd ${APP_HOME}/services/mid-feed/bin
./restart.sh


cd ${APP_HOME}/services/dev-tools/bin
./restart.sh _0

cd ${APP_HOME}/bin
