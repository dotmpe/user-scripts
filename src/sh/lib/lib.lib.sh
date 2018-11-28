#!/bin/sh

# Module for lib_load

# FIXME: comment format:
# [return codes] [exit codes] func-id [flags] pos-arg-id.. $name-arg-id..
# Env: $name-env-id
# Description.


lib_lib_load()
{
  test -n "$LOG" || return 102
  test -n "$default_lib" ||
      export default_lib="os sys str src shell"
      # XXX export default_lib="os sys str src argv match vc shell"

  test -n "$lib_loaded" || lib_loaded=
}

# Lookup and load sh-lib on SCRIPTPATH
lib_load()
{
  test -n "$LOG" || exit 102
  local lib_id= f_lib_loaded= f_lib_path=

  # __load_lib: true if inside util.sh:lib-load
  test -n "$__load_lib" || local __load_lib=1

  #test -n "$1" || set -- $default_lib
  test -n "$1" || return 1

  while test -n "$1"
  do
    lib_id=$(printf -- "${1}" | tr -Cs 'A-Za-z0-9_' '_')
    test -n "$lib_id" || {
      $LOG error lib "err: lib_id=$lib_id" "" 1 || return
    }
    f_lib_loaded=$(eval printf -- \"\$${lib_id}_lib_loaded\")

    test -n "$f_lib_loaded" || {

        # Note: the equiv. code using sys.lib.sh is above, but since it is not
        # loaded yet keep it written out using plain shell.
        f_lib_path="$( echo "$SCRIPTPATH" | tr ':' '\n' | while read sp
          do
            test -e "$sp/$1.lib.sh" || continue
            echo "$sp/$1.lib.sh"
            break
          done)"

        test -n "$f_lib_path" || {
          $LOG error "lib" "No path for lib '$1'" "" 1 || return
        }
        . "$f_lib_path"

        # again, func_exists is in sys.lib.sh. But inline here:
        type ${lib_id}_lib_load  2> /dev/null 1> /dev/null && {
          ${lib_id}_lib_load || {
            $LOG error "lib" "in lib-load $1 ($?)" 1 || return
          }
        }

        eval "ENV_SRC=\"$ENV_SRC $f_lib_path\""
        eval ${lib_id}_lib_loaded=1
        # FIXME $LOG info "lib" "Finished loading ${lib_id}: OK"
        unset lib_id
    }
    shift
  done
}
