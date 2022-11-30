sh_error ()
{
  declare -g STATUS=$?
  test $# -eq 0 && {
    return ${STATUS:?}
  } || {
    # TODO: env-symbol "${1:?}" && { "${BIN}" "$STATUS" "$@" && ... ; return; }
    test "$STATUS" "$@" && {
      declare -g ERROR=$STATUS
      return ${STATUS:?}
    }
    return 0
  }
}
# Copy:
