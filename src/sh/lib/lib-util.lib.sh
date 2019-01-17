#!/bin/sh

# Module to setup env for lib_load; based on particular OS setup

lib_util_lib_load()
{
	test -n "$uname" || export uname="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$uname" in darwin ) default_lib="$default_lib Darwin" ;; esac

  test -n "$lib_util_env_d_default" ||
      lib_util_env_d_default=init-log\ ucache\ scriptpath
  test -n "$sh_tools" || {
      test -n "$scriptpath" || return 106
      sh_tools=$scriptpath/tools/sh
  }
}

# Helper for Htd env, setup env helped by any parts in tools/sh/
# TODO: [this] build[s] around init.sh again
lib_util_init()
{
  # XXX: want glob expansion, but theoretically env could inter-depend; ie.
  # need delayed eval/macro; see env-d.lib. And local tools/{ci,sh}/env.sh
  # setup

  test -n "$sh_tools" || return 103 # NOTE: sanity

  # FIXME: instead going with hardcoded sequence for env-d like for lib.
  for env_d in $lib_util_env_d_default
  do
    . $sh_tools/parts/env-$env_d.sh
  done
  $INIT_LOG "info" "" "Env initialized from parts" "$lib_util_env_d_default"

  # XXX: interesting but not covered currently
  test -n "$SCRIPTPATH" && {
    test -n "$scriptpath" || {
      scriptpath="$(echo "$SCRIPTPATH" | sed 's/^.*://g')"
    }
  }

  script_env=$scriptpath/tools/sh/user-env.sh
  test ! -e "$script_env" || {
    $INIT_LOG "info" "" "User-Env..." "$script_env"
    . "$script_env" || return 104
  }
}

lib_util_deinit()
{
  $INIT_LOG "info" "" "Util completed"

  # XXX: deinit grouping
  test -n "$LOG_ENV" &&
        unset util_mode LOG_ENV INIT_LOG ||
        unset util_mode LOG_ENV INIT_LOG LOG
}
