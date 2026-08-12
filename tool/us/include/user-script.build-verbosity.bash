#
# Copyright 2018-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#
if [[ ${REDO_RUNID:+set} ]]
then
  : "${QUIET:=1}"
  : "${VERBOSE:=0}"
  declare -x QUIET VERBOSE
fi
#
# Id: user-script.build-verbosity.bash           vim:set ft=bash sw=2 sts=2 et:
