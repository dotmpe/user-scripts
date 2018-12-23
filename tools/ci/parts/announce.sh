#!/bin/sh
# Announce build-start asap for listeners

export travis_ci_timer_ts=$(echo "$TRAVIS_TIMER_START_TIME"|sed 's/\([0-9]\{9\}\)$/.\1/')
export ci_announce_ts=$($gdate +"%s.%N")
ci_stages="$ci_stages travis_ci_timer ci_announce"

. "$ci_util/parts/init-docker-build-cache.sh"

# From: script-mpe/0.0.4-dev tools/ci/parts/announce.sh
