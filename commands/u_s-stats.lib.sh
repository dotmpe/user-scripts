#!/usr/bin/env bash

u_s_sh_stats ()
{
  echo "Build cache files line counts:"
  wc -l \
      .meta/cache/sh-files.list \
      .meta/cache/sh-libs.list \
      .meta/src/functions/*.func-deps || return

  d=${BUILD_BASE:?}
  echo "Sh files: $( sort -u $d/.meta/cache/sh-libs.list | wc -l | awk '{print $1}' )"
  echo "Sh libs: $( cut -d$'\t' -f 1 $d/.meta/cache/sh-libs.list | sort -u | wc -l | awk '{print $1}' )"
  echo "Dependencies: $( sort -u $d/.meta/src/functions/*/*.func-deps | wc -l | awk '{print $1}' )"
}

# Redo entry point to generate src statistics file
build_sh_stats ()
{
  build-ifchange \
      .meta/cache/sh-files.list \
      .meta/cache/sh-libs.list \
      .meta/src/functions/*.func-list \
      .meta/src/functions/*/*.func-deps || return

  set -- "${BUILD_TARGET:?}" "${BUILD_TARGET_BASE:?}" "${BUILD_TARGET_TMP:?}"
  u_s_sh_stats >"${3:?"Expected temporary build file"}"
  build_chatty && cat "$3" >&2
  build-stamp <"$3"
}

#
