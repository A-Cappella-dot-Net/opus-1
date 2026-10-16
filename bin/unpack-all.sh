#!/bin/bash

if [ ! -e "../logs" ] ; then
    mkdir "../logs"
fi

if [ ! -e "../services" ] ; then
    mkdir "../services"
fi

# global config lives in ../releases/config; expose it under services too
if [ -d "../services/config" ] && [ ! -L "../services/config" ] ; then
    echo "WARNING: ../services/config is a real directory, not a symlink; remove it to enable the link" >&2
else
    ln -sfn ../releases/config ../services/config
fi

for FILEPATH in ../releases/*.tar.gz ; do
    [ -e "$FILEPATH" ] || continue

    echo processing $FILEPATH

    ARTIFACT=$(basename "$FILEPATH" .tar.gz)

    SERVICE=$(basename "$ARTIFACT" -SNAPSHOT)
    SERVICE="${SERVICE%-*}"

    if [ ! -e "../logs/$SERVICE" ] ; then
        mkdir "../logs/$SERVICE"
    fi

    rm -rf "../releases/$ARTIFACT"
    tar xf "$FILEPATH" -C ../releases --warning=no-timestamp
    rm "$FILEPATH"
    if [ -e "../services/$SERVICE" ] ; then
       	rm ../services/$SERVICE
    fi
    ln -s ../releases/$ARTIFACT ../services/$SERVICE
    ln -s ../../logs/$SERVICE ../services/$SERVICE/logs
done
