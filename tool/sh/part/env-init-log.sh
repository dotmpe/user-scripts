#!/usr/bin/env bash

log_name ()
{
  test -n "$sh_include_partid" && {
    true # $sh_include_base/$sh_include_partid.sh
  }
}

log_getlogger ()
{
  true
}

test -n "${LOG:-}" -a -x "${LOG:-}" -o \
  "$(type -t "${LOG:-}" 2>/dev/null )" = "function" &&
  LOG_ENV=1 INIT_LOG=$LOG || LOG_ENV=0 INIT_LOG=$U_S/tool/sh/log.sh


# Id: user-scripts/ tool/sh/parts/env-init-log.sh :vim:ft=sh:
