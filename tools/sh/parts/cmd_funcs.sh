#!/bin/sh


# List function names from file with spec if present, or as subcmd names if
# autocomplete=1. Scan each from src if given, or set to local frontend.
# XXX: only includes non-posix hyphened func names, excludes
# underscore in match. Not sure about any pre/suffixing or name mangling yet.
# With zsh_spec and complete output with "help" for z-shell tab-completion
# suggestions. XXX: would be tempted to include usage, but need cached or
# multi-pass parsing to get function comments; instead keep this simple grep
# on function lines, can include more usage info before '~' char [to designate
# ref. to func. name]
sh_cmd_funcs()
{
  local grep_re=$1
  test -n "${src:-}" && {
    eval set -- $src || return 97
  } || {
    set -- $0 $CWD/tools/sh/*.d/*.*
  }

  local src_
  for src_ in "${@:?}"
  do
    test "${complete:-}" = "1" && {
      test "${zsh_spec:-}" = "1" && {

        grep '^'"$grep_re"'[a-z0-9-]*()' "$src_" | sed \
          -e 's/()\ # \(.*\)$/:\1/' \
          -e 's/()\ *\([#{].*\)*//'

      } || {
        grep '^'"$grep_re"'[a-z0-9-]*()' "$src_" | sed 's/()\ *\([#{].*\)*//'
      }

    } || {
      grep '^'"$grep_re"'[a-z0-9-]*()' "$src_" | sed 's/()\ # /: /'
    }
  done
}

# Id: U-S:                                     ex:filetype=bash:colorcolumn=80:
