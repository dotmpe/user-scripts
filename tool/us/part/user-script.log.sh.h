# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_LOG_SH
#define USER_SCRIPT_LOG_SH
if [ -z "${LOG-}" ]
then
  if [ -x ~/bin/tool/sh/log.sh ]
  then LOG=$HOME/bin/tool/sh/log.sh
  fi
fi
#:declare-ifndef -f failerr userscripts::core::echo_stderr_with_status
#endif
# Id: user-script.log.sh.h                       vim:set ft=bash sw=2 sts=2 et:
