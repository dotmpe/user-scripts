#!/usr/bin/env bash

u_s_sh_stats ()
{
  echo "Build cache files line counts:"
  wc -l \
      .meta/cache/sh-files.list \
      .meta/src/sh-libs.list \
      .meta/src/functions/*.func-list

  echo "Sh files: $( sort -u .meta/src/sh-libs.list | wc -l | awk '{print $1}' )"
  echo "Sh libs: $( cut -d$'\t' -f 1 .meta/src/sh-libs.list | sort -u | wc -l | awk '{print $1}' )"
  echo "Dependencies: $( sort -u .meta/src/functions/*/*.func-deps | wc -l | awk '{print $1}' )"
}

# Redo entry point to generate src statistics file
build_sh_stats ()
{
  build-ifchange \
      .meta/cache/sh-files.list \
      .meta/src/sh-libs.list
  # XXX: get lib/funcs \
  #    .meta/src/functions/*.func-list \
  #    .meta/src/functions/*/*.func-deps

  u_s_sh_stats >"${3:?"Expected temporary build file"}"
  build_chatty && cat "$3" >&2
  build-stamp <"$3"
}

#
