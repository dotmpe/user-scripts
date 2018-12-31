#!/bin/sh
# Pub/dist

# XXX: export publish_ts=$(epoch_microtime)
export publish_ts=$($gdate +%s.%N)
ci_stages="$ci_stages publish"

ci_announce "Starting ci:publish"

lib_load git vc vc-htd

set -- "bvberkum/script-mpe"
git_scm_find "$1" || {
  git_scm_get "$SCM_VND" "$1" || return
}

. "./tools/ci/parts/report-times.sh"

# FIXME: pubish

# From: script-mpe/0.0.4-dev tools/ci/parts/publish.sh
