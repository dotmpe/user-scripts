#!/usr/bin/env bash

## Build tree of statusdirs on all ledges

# Only travis-* (build announcements) and builds-* (results) for this project.

./bin/u-s pullall && ./bin/u-s listfiles

redo-stamp
# Id: U-S:tools/redo/parts/_meta_cache_ledges.list.do              ex:ft=bash:
