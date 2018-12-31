#!/usr/bin/env bash

test .travis.yml -nt .htd/travis.json || { mkdir .htd
  jsotk yaml2json ".travis.yml" > .htd/travis.json; }

# TODO: Report on host load
uptime
#ping -c3 cdnjs.com
#ping -c3 traviscistatus.com
# FIXME: may want to get stats of running builds, backlog
# Don't really understant why there are so few container builds
echo '-------------------'
# From: script-mpe/0.0.4-dev tools/sh/build/dev.sh
