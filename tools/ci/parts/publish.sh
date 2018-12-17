#!/bin/sh
# Pub/dist

export publish_ts=$(date +%s.%N)
announce "Starting ci:publish"

lib_load git vc vc-htd

set -- "bvberkum/script-mpe"
git_scm_find "$1" || {
  git_scm_get "$SCM_VND" "$1" || return
}
