#!/bin/bash

#############################################
# 'restart' script
# Usage: restart.sh {instance {springFile.xml}}
#############################################

./stop.sh $1 $2

./start.sh $1 $2
