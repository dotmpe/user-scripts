#!/bin/sh

## Sys: dealing with vars, functions, env.

# XXX: sys currently is a helpers/util collection for user-scripts.
# shouldnt this just deal with actual system?

sys_lib__load ()
{
  lib_require os || return

  : "${LOG:?"No LOG env"}"
  if_ok "${uname:=$(uname -s)}" &&
  if_ok "${HOST:=$(hostname -s)}" || return
  : "${hostname:=${HOST,,}}"
}

sys_lib__init ()
{
  test "${sys_lib_init-}" = "0" || {
    test -n "$LOG" -a \( -x "$LOG" -o "$(type -t "$LOG")" = "function" \) \
      && sys_lib_log="$LOG" || sys_lib_log="$U_S/tools/sh/log.sh"
    test -n "$sys_lib_log" || return 108

    sys_tmp_init &&
    $sys_lib_log debug "" "Initialized sys.lib" "$0"
  }
}


activate()
{
  local update=false
  test -e "$HOME/.pyvenv/$1/bin/activate" && { update=true

    {  . "$HOME/.pyvenv/$1/bin/activate" &&
      export PYVENV=$HOME/.pyvenv/$1
    } || return $?
  }

  if $update ; then update_env ; fi
}

# Add an entry to PATH, see add-env-path-lookup for solution to other env vars
add_env_path() # Prepend-Value Append-Value
{
  test $# -ge 1 -a -n "${1-}" -o -n "${2-}" || return 64
  test -e "$1" -o -e "${2-}" || {
    echo "No such file or directory '$*'" >&2
    return 1
  }
  test -n "$1" && {
    case "$PATH" in
      $1:* | *:$1 | *:$1:* ) ;;
      * ) eval PATH=$1:$PATH ;;
    esac
  } || {
    test -n "$2" && {
      case "$PATH" in
        $2:* | *:$2 | *:$2:* ) ;;
        * ) eval PATH=$PATH:$2 ;;
      esac
    }
  }
}

# Add an entry to colon-separated paths, ie. PATH, CLASSPATH alike lookup paths
add_env_path_lookup() # Var-Name Prepend-Value Append-Value
{
  test $# -ge 2 -a $# -le 3 || return 64
  local val="$(eval echo "\$$1")"
  test -e "$2" -o -e "${3-}" || {
    echo "No such file or directory '$*'" >&2
    return 1
  }
  test -n "$2" && {
    case "$val" in
      $2:* | *:$2 | *:$2:* ) ;;
      * ) test -n "$val" && eval $1=$2:$val || eval $1=$2;;
    esac
  } || {
    test -n "$3" && {
      case "$val" in
        $3:* | *:$3 | *:$3:* ) ;;
        * ) test -n "$val" && eval $1=$val:$3 || eval $1=$3;;
      esac
    }
  }
}

# Capture cmd/func output in file, return status. Set out_file to provide path.
# The fourth argument signals to pass current stdin or the given file to the
# subshell pipeline.
capture () # CMD [RET-VAR=ret_var] [OUT-FILE-VAR=out_file] [-|FILE]
{
  local exec_name="$1" _ret_var_="$2" _out_var_="$3" input="$4"
  shift 4 # Regard rest as func/cmd-args
  test -n "$_ret_var_" || _ret_var_=ret_var
  test -n "$_out_var_" || _out_var_=out_file

  stdout="$(eval echo \"\$$_out_var_\")"
  test -n "$stdout" || stdout=$(setup_tmpf .capture-stdout)

  local return_status=
  test -n "$input" && {
    test "$input" != "-" && {
      test -f "$input" ||
        $sys_lib_log error sys "Input file '$input' expected" "" 1
    } || {
      input=$(setup_tmpf .capture-input)
      cat >"$input"
    }

    return_status="$(cat "$input" | $exec_name "$@" >"$stdout" ; echo $?)"
  } || {
    return_status="$($exec_name "$@" >"$stdout" ; echo $?)"
  }

  eval $_ret_var_=$return_status
  eval $_out_var_="$stdout"
}

# Capture cmd/func output in var, status
# env: pref= set_always=
# don't use names cmd_name, _ret_var_ or _out_var_; those would overlap with
# local vars
capture_var () # CMD [RET-VAR=ret_var] [OUT-VAR=out_var] [ARGS...]
{
  test -n "$2" || set -- "$1" "ret_var" "$3"
  local cmd_name="$1" _ret_var_="$2" _out_var_="$3"

  $sys_lib_log note sys "Capture: $1 $2 $3"
  shift 3
  test -n "$_out_var_" || {
    fnmatch "* *" "$cmd_name" && _out_var_=out_var || _out_var_=$cmd_name
  }

  # Execute, store return value at path and capture stdout in tmp var.
  local failed=$(setup_tmpf .capture-failed)

  local tmp="$(${pref-} $cmd_name || echo $?>$failed)"

  $sys_lib_log note sys "Captured: $_out_var_: $tmp"

  # Set return var and cleanup
  test -e "$failed" && {
      eval $_ret_var_=$(head -n1 "$failed")
      trueish "$set_always" && {
          eval $_out_var_="$tmp"
      } || true
      rm "$failed"
    } || {
      eval $_ret_var_=0
      eval $_out_var_="$tmp"
    }
}

capture_vars () # ~ <Varkey> <Command...>
{
  test $# -ge 2 || return ${_E_MA:?}
  test -n "$1" || return ${_E_GAE:?}
  local out stat stderr_fp
  : "${*:2}"
  test -n "$_" || return ${_E_GAE:?}
  : "${_//\//-}"
  : "${_//./__}"
  : "${_// /_}"
  stderr_fp=${RAM_TMPDIR:?}/$_.stderr
  out=$("${@:2}" 2>${stderr_fp})
  stat=$?
  var_set "${1}stdout" "$out"
  var_set "${1}stderr" "$(<"${stderr_fp}")"
  rm "$stderr_fp"
  return ${stat}
}

cmd_exists()
{
  test -n "${1-}" || return

  set -- "$1" "$(command -v "$1")" || return

  test -n "$2" -a -x "$2"
}

cwd_lookup_globs () # (cwd) ~ <Glob-patterns...>
{
  TODO
}

cwd_lookup_path ()
{
  cwd_lookup_paths | std_lookup_path "$@"
}

# Find specific files and other paths, or build a lookup path.
cwd_lookup_paths () # (cwd) ~ [ <Local-Paths...> ] # Look rootward for path(s)
{
  local cwd=${cwd:-$PWD} sub
  until test $cwd = /
  do
    test $# -gt 0 && {
      for sub in "$@"; do test -e "$cwd/$sub" || continue; echo "$cwd/$sub"; done
    } ||
      echo "$cwd"
    cwd="$(dirname "$cwd")"
  done
  #| sys_path_fmt
}

# Return non-zero if default was set, or present value does not match default
default_env() # VAR-NAME DEFAULT-VALUE [Level]
{
  test -n "${1-}" -a $# -eq 2 || error "default-env requires two args ($*)" 1
  local vid= cid= id= v= c=0
  trueish "${title-}" && upper= || {
    test -n "${upper-}" || upper=1
  }
  mkvid "$1"
  mkcid "$1"
  unset upper
  v="$(eval echo \$$vid 2>/dev/null )"
  test -n "${3-}" || set -- "$1" "$2" "debug"
  test -n "$v" && {
    test "$v" = "${2-}" || c=$?
      test $c -eq 0 &&
        $3 "Default $cid env ($vid)" ||
        $3 "Custom $cid env ($vid): '${2-}'"
    return $c
  } || {
    $3 "No $cid env ($vid), using default '${2-}'"
    eval $vid="${2-}"
    return 0
  }
}

env_var_mapping_update ()
{
  local IFS=$'\n' from to; for mapping in ${!1}
  do
    IFS=$' \t\n'; to="${mapping// *}"; from="${mapping//* }"
    test "${!to-}" = "$(echo ${!from})" || {
      test -n "${!to-}" &&
        echo "${!to} != ${!from}" ||
          echo "${to}=\"$(echo ${!from})\""
      eval "${to}=\"$(echo ${!from})\""
    }
  done
}

# Execute arguments, or return on first failure, empty args, or no cmdlines
exec_arg() # CMDLINE [ -- CMDLINE ]...
{
  test $# -gt 0 || return 98
  local execs=$(setup_tmpf .execs) execnr=0
  exec_arg_lines "$@" | while read -r execline
    do
      test -n "$execline" || continue
      echo "$execline">>"$execs"
      execnr=$(count_lines "$execs")
      $sys_lib_log debug sys "Execline: $execnr. '$execline'"
      $execline || return 3
    done
  test ! -e "$execs" || { execnr=$(count_lines "$execs"); rm "$execs"; }
  $sys_lib_log info sys "Exec-arg: executed $execnr lines"
  test $execnr -gt 0 || return 1
}

# Turn '--' seperated argument seq. into lines
exec_arg_lines()
{
  local exec=
  while test $# -gt 0
  do
    test "$1" = "--" && { echo "$exec"; exec=; shift; continue; }
    test -n "$exec" && exec="$exec $1" || exec="$1"
    shift
  done
  test -z "$exec" || echo "$exec"
}

# Error unless non-empty and falseish
falseish()
{
  test $# -eq 1 -a -n "${1-}" || return 1
  case "$1" in
    [Oo]ff|[Ff]alse|[Nn]|[Nn]o|0)
      return 0;;
    * )
      return 1;;
  esac
}

func_exists()
{
  type $1 2> /dev/null 1> /dev/null || return $?
  # XXX bash/bsd-darwin: test "$(type -t $1)" = "function" && return
  return 0
}

getidx()
{
  test 2 -eq $# || return ${_E_GAE:?}
  set -- "${1:?}[${2:?}]"
  var_get "$@"
}

init_user_env()
{
  local key= value=
  for key in UCONF HTDIR DCKR_VOL TMPDIR
  do
    value=$(eval echo \$$key)
    default=$(eval echo \$DEFAULT_$key)
    test -n "$value" || value=$default
    test -n "$value" || continue
    export $key=$value
    test -e "$value" || {
      $sys_lib_log warn sys "path for $key does not exist: $value"
    }
  done
}

init_uconfdir_path()
{
  # Add path dirs in $UCONF to $PATH
  local name
  for name in $uname $(uname -s) Generic
  do
    local user_PATH=$UCONF/path/$name
    if test -d "$user_PATH"
    then
      add_env_path $user_PATH
    fi
  done
}

# Sh var-based increment
incr () # ~ <Var-name> [<Amount=1>]
{
  local v incr_amount=${2:-1}
  v=$(var_get "${1:?incr: Variable ref expected}") &&
  var_set $1 $(( v + incr_amount ))
}

# Find first or every existing Local-path in Dirs, or fail.
# Default <lookup-first=true>. List one result per line.
lookup_exists () # ~ <Local-path> <Dirs...>
{
  local name="${1:?}"
  shift
  while test 0 -lt $#
  do
    test -e "${1:?}/$name" && {
      echo "$1/$name"
      "${lookup_first:-true}" && return
    }
    shift
  done
  # Cannot reach this unless lookup-first=false and no results found
  ! "${lookup_first:-true}"
}

lookup_expand () # ~ <Glob-pattern> <Dirs...>
{
  local glob="${1:?}" match
  shift
  while test 0 -lt $#
  do
    for match in $(sys_evals "${1:?}/$glob")
    do
      test -e "$match" && {
        echo "$match"
        "${lookup_first:-true}" && return
      }
    done
    shift
  done
  # Cannot reach this unless lookup-first=false and no results found
  ! "${lookup_first:-true}"
}

# lookup-path List existing <local-path>, fail on missing arguments or
# lookup-test handler, and if no existing paths was found.
# lookup-test: command to test equality with [default: test_exists]
# lookup-first: boolean setting to stop after first success
lookup_path () # (lt:=lookup-exists) ~ <Var-name> <Local-path>
{
  test $# -eq 2 || return ${_E_GAE:-193}
  test -n "${lookup_test-}" || local lookup_test="lookup_exists"
  func_exists "$lookup_test" || {
    $LOG error "" "No lookup-test handler" "$lookup_test"
    return 2
  }

  local path found=false
  for path in $( lookup_path_list ${1:?} )
    do
      eval "$lookup_test \"${2:?}\" \"${path:?}\"" && {
        found=true
        "${lookup_first:-true}" && break || continue
      } || continue
    done
  "$found"
}

# List individual entries/paths in lookup path env-var (ie. PATH or CLASSPATH)
lookup_path_list () # VAR-NAME
{
  test $# -eq 1 -a -n "${1-}" || error "lookup-path varname expected" 1
  eval echo \"\$$1\" | tr ':' '\n'
}

# Test if local path/name is overruled. Lists paths for hidden LOCAL instances.
lookup_path_shadows() # VAR-NAME LOCAL
{
  test $# -eq 2 || return 64
  local r=
  tmpf=$(setup_tmpf .lookup-shadows)
  lookup_first=false lookup_path "$@" >$tmpf
  lines=$( count_lines $tmpf )
  test "$lines" = "0" && { r=2
    } || { r=0
      test "$lines" = "1" || { r=1
          cat $tmpf
          #tail +2 "$tmpf"
      }
    }
  rm $tmpf
  return $r
}

# Same implementation as lookup-path except combine any local-path with any
# basedir from lookup sequence. This may sometimes be usefull, but this still
# only returns one path on lookup-first even if multiple local paths are given.
lookup_paths () # (lt:lookup-exists) ~ <Var-name> <Local-paths...>
{
  test $# -eq 2 || return ${_E_GAE:-193}
  test -n "${lookup_test-}" || local lookup_test="lookup_exists"
  local varname=$1 base path found=false
  shift ; for base in $( lookup_path_list $varname )
    do
      for path in "$@"
      do
        eval $lookup_test \""$path"\" \""$base"\" && {
          found=true
          "${lookup_first:-true}" && break 2 || continue
        } || continue
      done
    done
  "${found}"
}

# No error on empty, or not-falseish match
not_falseish() # Str
{
  test -n "${1-}" || return 0
  ! falseish "$1"
}

# No error on empty, or not trueish match
not_trueish()
{
  test -n "${1-}" || return 0
  ! trueish "$1"
}

remove_env_path_lookup ()
{
  local newval="$( eval echo \"\$$1\" | tr ':' '\n' | while read oneval
    do
      test "$2" = "$oneval" -o "$(realpath "$2")" = "$(realpath "$oneval")" &&
        continue ;
      echo "$oneval" ;
    done | tr '\n' ':' | strip_last_nchars 1 )"

  export $1="$newval"
}

# require vars to be initialized, regardless of value
req_vars()
{
  for varname in "$@"
  do
    #sh_isset "$varname" || { error "Missing req-var '$varname' ($SHELL_NAME)"; return 1; }
    sh_isset "$varname" || {
      $LOG error "" "Missing req-var '$varname' ($SHELL_NAME)"
      return 1
    }
  done
}

rnd_str () # ~ <Len> # Generate ASCII string with urandom data
{
  test -n "${1:-}" || set -- 11
  cat /dev/urandom | LC_ALL=ascii tr -cd 'a-z0-9' | head -c ${1:?}
}

# setup-tmpd [ SUBDIR [ (RAM_)TMPDIR ]]
# Get (create) fresh subdir in TMPDIR or fail.
setup_tmpd () # Unique-Name
{
  test $# -le 2 || return 98
  test -n "${2-}" || set -- "${1-}" "$sys_tmp"
  test -d "$2" ||
    $sys_lib_log error sys "Need existing tmpdir, got: '$2'" "" 1
  test -n "${1-}" || set -- "$base-$SH_SID" "${2-}"
  test ! -e "$2/$1" ||
    $sys_lib_log error sys "Unique tmpdir sub exists: '$2'" "" 1
  mkdir -p $2/$1
  echo "$2/$1"
}

# Echo path to new file in temp. dir. with ${base}- as filename prefix,
# .out suffix and subcmd with uuid as middle part.
# setup-tmp [ext [uuid [(RAM_)TMPDIR]]]
setup_tmpf() # [Ext [UUID [TMPDIR]]]
{
  test $# -le 3 || return 98
  test -n "${1-}" || set -- .out "${2-}" "${3-}"
  test -n "${2-}" || set -- ${1-} $(get_uuid) "${3-}"
  test -n "$1" -a -n "$2" || $sys_lib_log error sys "empty arg(s)" "" 1

  test -n "${3-}" || set -- "$1" "$2" "$sys_tmp"
  test -n "$3" -a -d "$3" || $sys_lib_log error sys "Not a dir: '$3'" "" 1

  test -n "$(dirname $3/$2$1)" -a "$(dirname $3/$2$1)" \
    || mkdir -p "$(dirname $3/$2$1)"
  echo "$3/$2$1"
}

std_lookup_path ()
{
  std_read_path
}

std_noerr ()
{
  "$@" 2>/dev/null
}

std_noout ()
{
  "$@" >/dev/null
}

std_quiet ()
{
  "$@" >/dev/null 2>&1
}

std_utf8_en()
{
    export LANG="en_US.UTF-8"
    export LC_COLLATE="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"
    export LC_MESSAGES="en_US.UTF-8"
    export LC_MONETARY="en_US.UTF-8"
    export LC_NUMERIC="en_US.UTF-8"
    export LC_TIME="en_US.UTF-8"
    export LC_ALL=
}

stdin_first () # (s) ~ <Var> <Test...>
{
  test 1 -le $# || return ${_E_MA:?}
  typeset var=${1:?stdin-first: Variable name expected} part
  shift
  test 0 -lt $# || set -- test -n
  while read -r part
  do ! "$@" "$part" || {
      var_set "$var" "$part"
      return
    }
  done
  false
}

stdin_from_ () # ~ <Cmd...>
{
  typeset str
  str=$("$@") || ignore_sigpipe || return
  exec <<< "$str"
}

stdin_from_nonempty () # ~ [<File>]
{
  test -n "${1-}" &&
  test -s "$_" &&
  exec < "$_"
}

sys_arr () # ~ <Var-name> <Cmd...> # Read stdout (lines) into array
{
  if_ok "$("${@:2}")" &&
  <<< "$_" mapfile ${mapfile_f:--t} "${1:?}"
}

sys_arr_def () # ~ <Var-name> <Defaults...>
{
  declare -n v=${1:?}
  test 0 -lt ${#v[@]} || sys_arr_set "$@"
}

sys_arr_set () # ~ <Var-name> <Elements...>
{
  # XXX: didnt manage to find a way to use declare (like var-set)
  eval "$1=( \"\${@:2}\" )"
}

# Execute commands from arguments in sequence, reading into array one segment at
# a time. Empty sequence can be used to break-off current sys-cmd-seq run, and
# pass entire rest of arguments to sys-csd. sys-csp is the prefix put before
# each command.
sys_cmd_seq () # ~ <cmd> <args...> [ -- <cmd> <args...> ]
{
  declare cmd=()
  while ${sys_csa:-argv_seq} cmd "$@"
  do
    test 0 -lt "${#cmd[*]}" && shift $_ || {
      test 0 -eq $# && return
      "${sys_cse:-false}" && cmd=( "${sys_csd:---}" ) || return
    }
    : "${sys_csp-}${sys_csp+ }"
    : "$_${cmd[*]}"
    $LOG info "${lk-}" "Calling command" "${_//%/%%}"
    ${sys_csp-} "${cmd[@]:?}" || return
    argv_is_seq "$@" && { shift || return; }
    test 0 -lt $# || break
    cmd=()
  done
}

sys_eval_seq () # ~ <script...> [ -- <script...> ]
{
  declare cmd=()
  while argv_seq cmd "$@"
  do
    test 0 -lt "${#cmd[*]}" &&
    shift $_ &&
    : "${cmd[*]}" &&
    $LOG info "${lk-}" "Evaluating script" "${_//%/%%}" &&
    eval "${cmd[*]}" || return
    argv_is_seq "$@" && shift && test 0 -lt $# ||
      break
    cmd=()
  done
}

# Check for RAM-fs or regular temporary directory, or set to given
# directory which must also exist. Normally, TMPDIR will be set on Unix and
# POSIX systems. If it does not exist then TMPDIR will be set to whatever
# is given here or whichever exists of /dev/shm/tmp or $RAM_TMPDIR. But the
# directory will not be created.
sys_tmp_init () # DIR
{
  local tag=:sys.lib:tmp-init
  test -n "${RAM_TMPDIR:-}" || {
    # Set to Linux ramfs path
    test -d "/dev/shm" && {
      RAM_TMPDIR=/dev/shm/tmp
    }
  }

  test -z "${RAM_TMPDIR:-}" || {
    # XXX: find existing parent dir
    _RAM_TMPDIR="$(set -- $RAM_TMPDIR; while test ! -e "$1"; do set -- $(dirname "$1"); done; echo "$1")"
    test -w "$_RAM_TMPDIR" && {
      test -d "$RAM_TMPDIR" || mkdir $RAM_TMPDIR
    } || {
      test -d "$RAM_TMPDIR" && {
        $sys_lib_log warn $tag "Cannot access RAM-TmpDir" "$RAM_TMPDIR"
      } ||
        $sys_lib_log warn $tag "Cannot prepare RAM-TmpDir" "$RAM_TMPDIR"
    }
    unset _RAM_TMPDIR
  }

  test -e "${1-}" -o -z "${RAM_TMPDIR-}" || set -- "$RAM_TMPDIR"
  test -e "${1-}" -o -z "${TMPDIR-}" || set -- "$TMPDIR"
  test -n "${1-}" && {
    test -n "${TMPDIR-}" || export TMPDIR=$1
  }
  test -d "$1" || {
    $sys_lib_log warn $tag "No RAM tmpdir/No tmpdir found" "" 1
  }
  sys_tmp="$1"
}

#
sys_path () # ~ <Cmd...> # TODO??
{
  echo "${PATH//:/$'\n'}" | sys_path_fmt
}

sys_path_fmt ()
{
  case "${out_fmt:-path}" in
    one|first ) head -n 1 ;;
    last ) tail -n 1 ;;
    head ) head -n +2 ;;
    tail ) tail -n +2 ;;
    path ) tr '\n' ':' ;;
    list ) cat ;;
    * ) error "cwd-lookup-path: out-fmt: ${out_fmt:-}?" 1 ;;
  esac
}

# sys-prompt PROMPT [VAR=choice_confirm]
sys_prompt()
{
  test -n "${1-}" || $sys_lib_log error sys "sys-prompt: arg expected" "" 1
  test -n "${2-}" || set -- "$1" choice_confirm
  test -z "${3-}" || $sys_lib_log error sys "surplus-args '$3'" "" 1
  echo $1
  read -n 1 $2
}

# sys-confirm PROMPT
sys_confirm()
{
  local choice_confirm=
  sys_prompt "$1" choice_confirm
  trueish "$choice_confirm"
}

# Error unless non-empty and true-ish value
trueish () # ~ <String>
{
  test $# -eq 1 -a -n "${1-}" || return
  case "$1" in [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1) return 0;;
    * ) return 1;;
  esac
}
# Id: sh-trueish

try_exec_func()
{
  test -n "${1-}" || return 97
  test -n "$sys_lib_log" || return 108
  $sys_lib_log debug "sys" "try-exec-func '$1'"
  func_exists "$1" || return
  local func=$1
  shift 1
  $func "$@" || return
}

# Get echo-local output, and return 1 on empty value. See echo-local spec.
try_value()
{
  local value=
  test $# -gt 1 && {
    value="$(eval echo "\"\${$(echo_local "$@")-}\"" || return )"
  } || {
    value="$(eval echo \"\${${1-}-}\" || return )"
  }
  test -n "$value" || return 1
  echo "$value"
}

# TODO: redesign @Dsgn
try_var () # ~ <Var-name>
{
  : "${!1:-}"
  test -n "$_" || return
  echo "$_"
}

update_env()
{
  test -n "${PYVENV-}" || {
    PYVENV=$(htd ispyvenv) || PYVENV=0
    export PYVENV
  }
}

user_lookup_path () # ~ [<User-paths...>] -- <Local-paths...>
{
  declare -a user_paths
  while test "${1:?}" != "--"
  do
    user_paths+=( "$1" )
    shift
    test $# -gt 0 || break
  done
  shift
  # FIXME: remove pipeline
  { out_fmt=list cwd_lookup_paths "$@"
    printf '%s\n' "${user_paths[@]}"
  } | remove_dupes
}

# This is called every time a PS1 PROMPT_COMMAND is executed, to get a simple
# string describing the host and perhaps CWD,PATH,PROJECT env. Especially
# when these are variants on the normal user profile, the normal name is
# ENV_NAME, which should be an ID describing ENV (or BASH_ENV, etc.). But
# additional formatting and IDs are added for
work_env()
{
  # Get name for shell profile
  test -z "$ENV_NAME" && {
    test -n "$hostname" || exit 110
    LENV="$hostname"
  } || {
    LENV="$ENV_NAME"
  }

  # Check for python v-env
  test "0" = "$PYVENV" || {
    LENV="$LENV,pyvenv"
  }
  printf -- "$LENV"
}

var_get ()
{
  : "${1:?var-get: Variable name expected}"
  echo "${!_:?}"
}

var_get_sh ()
{
  : "${1:?var-get-sh: Variable name expected}"
  eval echo \"\$$_\"
}

var_set () # ~ <Var-name-ref> <Value> # Reset local:<var> or <var> to <val>
{
  local var=${1:?var-set: Variable name expected} val=${2-}
  test local: = "${var:0:6}" && {
    eval "${var:6}=\"$val\"" || return
  } ||
    declare -g "$var=$val"
  # NOTE: above global declaration would not work for typeset vars, and Bash<=5.0
  # cannot tell wether $var already is declared typeset in an outter function
  # scope. Even more typeset or set are/seem useless, so its eval to the rescue.
}

# Sync: BIN:
