#!/bin/sh

### File archives in plain shell vars

# This allows to define a file and directory tree as a set of plain shell
# variables (the 'template').

# TODO: rename fs-tpl.lib.sh

# Base-Var-Id should include trailing _ btw, see basevar

# Setup only names matching Name-Value
setup_sh_tpl_name() # Name-Value Base-Var-Id
{
  test $# -eq 2 || return 98
  for index in $( setup_sh_tpl_name_index "$@" )
  do
    setup_sh_tpl_item "$index" "$2"
  done
}

# List all tpl indices and names for names matching Name-Value (can be glob or
# literal path name).
setup_sh_tpl_name_index() # Name-Value Base-Var-Id
{
  test $# -eq 2 || return 98
  test -n "$1" || error "setup-sh-tpl: name-index arg:1 '$*'" 1
  test -n "$2" || error "setup-sh-tpl: name-index arg:2 '$*'" 2

  local i=1 name="" type=""
  while true
  do
    name="$(eval echo \"\${${2}_${i}__name-}\")"
    test -n "$name" -o -n "$type" || break
    test -z "$name" || {
        { test "$1" = "$name" || fnmatch "$1" "$name"; } &&
            { echo "$i"; return; }; }
    i=$(( i + 1 )) ; name= type=
  done
  return 1
}

# Setup single item from tpl.
setup_sh_tpl_item() # Index-Nr Base-Var-Id
{
  test $# -eq 2 || return 98
  test -n "$1" || error "setup-sh-tpl: item arg:1 '$*'" 1
  test -n "$2" || error "setup-sh-tpl: item arg:2 '$*'" 2

  name="$(eval echo \"\${${2}_${1}__name-}\")"
  type="$(eval echo \"\${${2}_${1}__type-}\")"
  test -n "$name" -o -n "$type" || return 1

  test -n "$type" || type=file
  setup_${type}_from_sh_tpl "$@" || return 2

  mtime="$(eval echo \"\${${2}_${1}__mtime-}\")"
  test -z "$mtime" || {
    note "Modified '$mtime' '$name'"
    touch_ts "@$mtime" "$name" || return 3
  }
}

# Setup file-type tpl item.
setup_file_from_sh_tpl() # Index-Nr Base-Var-Id
{
  test $# -eq 2 || return 98
  test -n "$1" || error "setup-file-from-sh-tpl arg:1 '$*'" 1
  test -n "$2" || error "setup-file-from-sh-tpl arg:2 '$*'" 2

  test -n "${name-}" || { name="$(eval echo \"\$${2}_${1}__name\")" || return; }

  note "Setup file '$name'..."
  test -d "$(dirname "$name")" || mkdir -p "$(dirname "$name")"

  contents="$(eval echo \"\$${2}_${1}__contents\")" || return
  echo "$contents" >"$name"
}

# Get tpl var-name prefix including one trialing '_'
setup_sh_tpl_basevar()
{
  test $# -eq 1 || return 98
  basename -- "$1" .sh | tr -c 'A-Za-z0-9_' '_' | tr -s '_' '_'
}

# Main shell-template-file template handler, setup entire Tpl in Dir.
setup_sh_tpl() # SH-Tpl-File [Base-Var-Id] [Dest-Dir]
{
  test $# -ge 1 || return 98
  test -n "${2-}" || set -- "$1" "$(setup_sh_tpl_basevar "$1")" "${3-}"
  local i=1 cwd="$PWD" name="" type="" contents="" mtime="" r
  test -z "${3-}" || cd "$3"
  test -e "$cwd/$1" && set -- "$cwd/$1" "$2" "$3"
  . "$1"
  while true
  do
    setup_sh_tpl_item "$i" "$2" || { r=$?; test "$r" = 1 && r=; break; }
    i=$(( i + 1 )) ; name="" type="" contents="" mtime=""
  done
  test -z "${3-}" || cd "$cwd"
  return $r
}
