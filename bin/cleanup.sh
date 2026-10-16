#!/bin/bash

cd /chr
rm -rf *

for i in /opt/madrigal/logs/* ; do
  if [ -d "$i" ]; then
    rm -rf "$i"/*
  fi
done
