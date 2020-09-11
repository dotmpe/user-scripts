#!/bin/sh

cp -v $HOME/.docker/config.json /tmp/docker-config.json
rm -vf \
    $HOME/.docker/config.json \
    $HOME/.cache/pip/log/debug.log \
    $HOME/.npm/anonymous-cli-metrics.json

# Sync: U-S:
