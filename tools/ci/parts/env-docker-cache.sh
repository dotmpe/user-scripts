#!/usr/bin/env bash

: "${TRAVIS_REPO_SLUG:="$NS_NAME/user-scripts"}" # No-Sync
PROJ_LBL=$(basename "$TRAVIS_REPO_SLUG")
: "${TRAVIS_BRANCH:="$(git rev-parse --abbrev-ref HEAD)"}"
ledge_tag="$(printf %s "$PROJ_LBL-$TRAVIS_BRANCH" | tr -c 'A-Za-z0-9_-' '-')"

sd_logsdir="${STATUSDIR_ROOT:-$HOME/.local/statusdir/}log"
builds_log="$sd_logsdir/travis-$PROJ_LBL.list"
results_log="$sd_logsdir/builds-$PROJ_LBL.list"

touch "$builds_log" "$results_log"
