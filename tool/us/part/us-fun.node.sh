us-fun:meta ()
{
  us: group us
  us: shtype group
  us: shparts
}


if-ok () # ~ ...
{
  return
}

stderr () # ~ <Cmd...>
{
  "$@" >&2
}

str-globmatch () # ~ <String> <Glob-pattern> ...
{
  : copy "str.lib"
  case "${1:?}" in ${2:?} ) ;; ( * ) false ;; esac
}

str-suffix ()
{
  : copy "str.lib"
}
