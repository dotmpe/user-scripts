#!/bin/sh
# Pub/dist

export publish_ts=$(date +%s.%N)
announce "Starting ci:publish"

lib_load vc vc-htd
