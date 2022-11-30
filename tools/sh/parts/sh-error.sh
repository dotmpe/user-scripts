sh_error ()
{
  STATUS=${?:-0}
  test $# -eq 0 && {
    return ${STATUS:?}
  } || {
    # TODO: env-symbol "${1:?}" && { "${BIN}" "$STATUS" "$@" && ... ; return; }
    test "${STATUS:?}" "${@:?}" && {
      ERROR=$STATUS
      return ${STATUS:?}
    }
    return 0
  }
}
# Copy:
