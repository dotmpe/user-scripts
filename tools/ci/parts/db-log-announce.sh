#!/bin/sh
# Announce build-start asap for listeners

export ci_announce_ts=$($gdate +"%s.%N")
ci_stages="$ci_stages travis_ci_timer ci_announce"

curl -sSf --connect-timeout 5 --max-time 15 https://$CI_DB_HOST/ || {
  $LOG warn "$scriptname" "No remote DB, skipped build-log announce"
  return 0
}
$LOG error "$scriptname" "TODO: announce travis build"

# From: Script.mpe/0.0.4-dev tools/ci/parts/db-log-announce.sh
