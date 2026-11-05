#!/bin/bash

if [ ! -e "../logs" ] ; then
    mkdir "../logs"
fi

if [ ! -e "../services" ] ; then
    mkdir "../services"
fi

# global common dir lives in ../releases/common; expose it under services too
if [ -d "../services/common" ] && [ ! -L "../services/common" ] ; then
    echo "WARNING: ../services/common is a real directory, not a symlink; remove it to enable the link" >&2
else
    ln -sfn ../releases/common ../services/common
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
