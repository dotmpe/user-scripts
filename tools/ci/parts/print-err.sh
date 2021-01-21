# Print log-like to stderr
print_err ()
{
  test -n "${LOG:-}" -a -x "${LOG:-}" && {
    $LOG "$@"; return $?;
  }

  test -z "${verbosity:-}" -a -z "${DEBUG:-}" && return
  test -n "${2:-}" || set -- "$1" "${base:-"$(basename -- "$0" .sh)"}" "$3" "${4:-}" "${5:-}"
  # XXX:
  #test -z "${verbosity:-}" -a -n "${DEBUG:-}" || {

  #  case "$1" in [0-9]* ) true ;; * ) false ;; esac &&
  #    lvl=$(log_level_name "$1") ||
  #    lvl=$(log_level_num "$1")

  #  test $verbosity -ge $lvl || {
  #    test -n "${5:-}" && exit $5 || {
  #      return 0
  #    }
  #  }
  #}

  printf -- "%s\n" "[$2] $1: $3 <${4:-}> (${5:-})" >&2
  test -z "${5:-}" || exit $5 # NOTE: also exit on '0'
}
# Id: U-S:
