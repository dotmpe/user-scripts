#!/usr/bin/env bash

## Sys: dealing with vars, functions, env.

# Some of these are essential helpers, others are examples of standard ways
# to do things but which could easily be done in-line.

# XXX: sys currently is a helpers/util collection for user-scripts.
# shouldnt this just deal with actual system?

sys_lib__load ()
{
  lib_require str os || return

  : "${LOG:?"No LOG env"}"
  if_ok "${OS_UNAME:=$(uname -s)}" &&
  if_ok "${OS_HOSTNAME:=$(hostname -s)}" || return

  sys_debug_fun=sys_debug,sys_debug_tag,sys_match_select,sys_debug_mode,sys_exc,sys_source_trace,std_findent,sys_callers,if_ok,fnmatch,str_prefix
}

sys_lib__init ()
{
  [[ "${sys_lib_init-}" = "0" ]] || {
    [[ "$LOG" && ( -x "$LOG" || "$(type -t "$LOG")" = "function" ) ]] \
      && sys_lib_log="$LOG" || sys_lib_log="$U_S/tools/sh/log.sh"
    [[ "$sys_lib_log" ]] || return 108

    throw ()  # Id Msg Ctx
    {
      local lk=${1:?}:sys.lib/throw ctx
      ctx="${3-}${3+:$'\n'}$(sys_exc "$1" "$2")"
      $LOG error "$lk" "${2-Exception}" "$ctx" ${_E_script:-2}
    }

    sys_tmp_init || return

    ! sys_debug -dev -debug -init ||
      $sys_lib_log notice "" "Initialized sys.lib" "$(sys_debug_tag)"
  }
}


# Add an entry to PATH, see add-env-path-lookup for solution to other env vars
add_env_path() # Prepend-Value Append-Value
{
  : source "sys.lib.sh"
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
  : TODO "Rewrite to and implement sys-wordv-{{ap,pre}pend,add,remove}"
  : "And sys-wordv-*-all <var> <words>"
  test $# -ge 2 -a $# -le 3 || return 64
  local val="${!1:?}"
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

aarr_pickglob () # ~ <Array> <Match-expr> # Output tsv for matching keys
# Pick assoc-arr key(s) by globmatch
{
  : about "Output tsv for matching keys"
  : extended "Pick assoc-arr key(s) by globmatch"
  : param "<Array> <Match-expr>"
  : group "sys/arr"
  : source "sys.lib.sh"
  local -n arr=${1:?}

  local k glob=${2:?}
  for k in "${!arr[@]}"
  do
    str_globmatch "$k" "$glob" && {
      printf '%s\t%s\n' "$k" "${arr["$k"]}"
    } || continue
  done
}

arr_cpy () # ~ <Arr> <Arr>
{
  : about "Copy first to second array"
  : group "sys/arr"
  : source "sys.lib.sh"
  local -n __arr_in=${1:?} __arr_out=${2:?}
  local -i i
  for i in "${!__arr_in[@]}"
  do
    __arr_out[i]=${__arr_in[i]}
  done
}

arr_contains () # ~ <Array> <Value>
{
  : about "Test each value and return true on match or false on none"
  : group "sys/arr"
  : source "sys.lib.sh"
  local -n __us_arr=${1:?}
  for ((i=0; i<${#__us_arr[@]}; i++))
  do
    [[ "${__us_arr[i]}" = "${2-}" ]] && return
  done
  false
}
# Alias: in-array, array-item-exists

# Dump array for re-reading, one item per line. See also kpdump to select keys
# from associative array based on prefix.
arr_dump () # ~ <Array>
{
  : about "Dump array data"
  : extended "Write oneline shell declaration for every array index or key"
  : group "sys/arr"
  : source "sys.lib.sh"
  local __us_arr_key
  local -n __us_arr=${1:?}
  for __us_arr_key in "${!__us_arr[@]}"
  do
    : "$__us_arr_key"
    echo "$1[\"$_\"]=${__us_arr["$_"]@Q}"
  done
}

arr_kcpy () # ~ <Assoc-arr> <Arr> # Copy keys, adding them as items to array
{
  : about "Copy keys, adding them as items to array"
  : param "<Assoc-arr> <Arr>"
  : group "sys/arr"
  : source "sys.lib.sh"
  local -n __arr_in=${1:?} __arr_out=${2:?}
  local key
  for key in "${!__arr_in[@]}"
  do
    __arr_out+=( "$key" )
  done
}

arr_kdump () # ~ <Array> <Keys...>
{
  : about "Dump array data by key"
  : extended "Write oneline shell declaration for each given key"
  : param "<Array> <Keys...>"
  : group "sys/arr"
  : source "sys.lib.sh"
  local __arr_key __arr_name=${1:?}
  local -n __arr=${1:?}
  shift
  for __arr_key
  do
    : "$__arr_key"
    echo "${__arr_name}[\"$_\"]=${__arr["$_"]@Q}"
  done
}

arr_kpdump () # ~ <Array> <Key-prefix>
{
  : about "Dump array data by key prefix"
  : extended "Write oneline shell declaration for each matching key"
  : param "<Array> <Key-prefix>"
  : group "sys/arr"
  : source "sys.lib.sh"
  local __us_arr_key
  local -n __us_arr=${1:?}
  for __us_arr_key in "${!__us_arr[@]}"
  do
    [[ $__us_arr_key =~ ^${2:?} ]] || continue
    : "$__us_arr_key"
    echo "$1[\"$_\"]=${__us_arr["$_"]@Q}"
  done
}

arr_sub () # ~ <Array> ( <Match> <Replace> )+
{
  : param "<Array> ( <Match> <Replace> )+"
  : group "sys/arr"
  : source "sys.lib.sh"
  local -n __us_arr_sub=${1:?}
  shift &&
  while true
  do
    for ((i=0; i<${#__us_arr_sub[@]}; i++))
    do
      [[ "${__us_arr_sub[i]}" != "${1-}" ]] || __us_arr_sub[$i]=$2
    done
    shift 2 || return
  done
}

# Use third assoc array to track and add (append) only unique items from arr-in
# to arr-out
arr_unique () # ~ <Arr-in> <Arr-out>
{
  : param "<Arr-in> <Arr-out>"
  : group "sys/arr"
  : source "sys.lib.sh"
  local -A arr_unique
  local -n __arr_in=${1:?} __arr_out=${2:?}
  local item
  for item in "${__arr_in[@]}"
  do
    [[ ${__arr_unique["$item"]+set} ]] || {
      __arr_unique["$item"]=
      __arr_out[${#__arr_out[*]}]=$item
    }
  done
}

# Merge all associative arrays into first. Last index takes preference.
assoc_concat () # ~ <To-array> <From-arrays...>
{
  declare -n dest=${1:?} src
  shift
  declare k
  for src
  do
    for k in "${!src[@]}"
    do
      dest[$k]=${src[$k]}
    done
  done
}

# Merge all associative arrays into first, but do not overwrite existing
# indices. Ie. first index takes preference.
assoc_merge () # ~ <To-array> <From-arrays...>
{
  #shellcheck disable=SC2178 # shellcheck does not recognize -n
  declare -n dest=${1:?} src
  shift
  declare k
  for src
  do
    for k in "${!src[@]}"
    do
      test "unset" = "${dest[$k]-unset}" || continue
      dest[$k]=${src[$k]}
    done
  done
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
  sys_var "${1}stdout" "$out"
  sys_var "${1}stderr" "$(<"${stderr_fp}")"
  rm "$stderr_fp"
  return ${stat}
}

cmd_exists()
{
  set -- "${1:?}" "$(command -v "$1")" &&
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

# This does exactly the same as cwd-lookup-path w/o args, but may be more
# appropiate for other cases.
cwd_path () # ~ ...
{
  local cwd=${cwd:-$PWD}
  until test $cwd = /
  do
    echo "$cwd"
    cwd="$(dirname "$cwd")"
  done
}

cwd_arr () # ~ <Arr-name>
{
  sys_arr "${1:?}" cwd_path
}

cwd_rarr () # ~ <Arr-name>
{
  sys_arr "${1:?}" cwd_path &&
  sys_rarr "${1:?}"
}

# Return non-zero if default was set, or present value does not match default
default_env() # ~ VAR-NAME DEFAULT-VALUE [Level]
{
  test -n "${1-}" -a $# -eq 2 || return ${_E_GAE:-193}
  local vid cid v='' c
  vid=$(str_word "${1^^}")
  cid=$(str_id "$1")
  v="$(eval echo \$$vid 2>/dev/null )"
  test -n "${3-}" || set -- "$1" "$2" "debug"
  test -n "$v" && {
    test "$v" = "${2-}" || c=$?
    test ${c:-0} -eq 0 &&
      $3 "Default $cid env ($vid)" ||
      $3 "Custom $cid env ($vid): '${2-}'"
    return ${c:-0}
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

# Execute arguments as command, or return on first failure, empty args, or no cmdlines
execa_cmd () # ~ CMDLINE [ -- CMDLINE ]...
{
  test $# -gt 0 || return 98
  local execs=$(setup_tmpf .execs) execnr=0
  str_arg_seqs "$@" | while read -r execline
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

# XXX: Read script from stdin and evaluate it for each expansion somehow?
#exec_exp () # (s) ~ <Expression>
#{
#}

# Execute expansion of initial argument with command-line from rest arguments
# XXX: run cmd for each result of combined glob/brace expression
exec_expa () # ~ <Expression> <Cmd-strfmt-or-line...> # Run for each glob/braces expansion
{
  local expression=${1:?} result cmd
  [[ $# -eq 2 && "$2" =~ ^.*%.*$ ]] || cmd="${*:2}"
  declare -a values &&
  if_ok "$(eval "printf '%s\n' $expression")" &&
  <<< "$_" mapfile -t values || return
  test 0 -lt "${#values[@]}" || return ${_E_nsk:?}
  $LOG info "${lk:-:exec-exp}" "Expanded to ${#values[@]} results" &&
  for result in "${values[@]}"
  do
    test -n "${cmd-}" && {
      $cmd "$result" || {
        test ${_E_next:-196} -eq $? && continue
        return $_
      }
    } || {
      if_ok "$(printf "${2:-"echo \"%s\""}" "$result")" &&
      eval "$_" || {
        test ${_E_next:-196} -eq $? && continue
        return $_
      }
    }
  done
}

# TODO: execute sequence of functions/commands for each expansion with callback
# args?
#exec_expaa () # ~ ~ <Expression> <Callbacks...>
#{
#}

exec_glob () # ~ <Glob-expression> <Cmd-strfmt-or-line...> #
{
  local glob=${1:?} result cmd
  [[ $# -eq 2 && "$2" =~ ^.*%.*$ ]] || cmd="${*:2}"
  declare -a values &&
  if_ok "$(compgen -G "$glob")" &&
  <<< "$_" mapfile -t values || return
  test 0 -lt "${#values[@]}" || return ${_E_nsk:?}
  $LOG info "${lk:-:exec-exp}" "Expanded to ${#values[@]} results" &&
  for result in "${values[@]}"
  do
    test -n "${cmd-}" && {
      $cmd "$result" || {
        test ${_E_next:-196} -eq $? && continue
        return $_
      }
    } || {
      if_ok "$(printf "$2" "$result")" &&
      eval "$_" || {
        test ${_E_next:-196} -eq $? && continue
        return $_
      }
    }
  done
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

getidx() # ~ <Array> <Key>
{
  test 2 -eq $# || return ${_E_GAE:?}
  set -- "${1:?}[${2:?}]"
  sys_get "$@"
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
  for name in ${OS_NAME-} ${OS_UNAME:?} Generic
  do
    local user_PATH=$UCONF/path/$name
    if test -d "$user_PATH"
    then
      add_env_path $user_PATH
    fi
  done
}

# Sh var-based increment
incr () # ~ <Var-name> [<Amount=1>] [<Default=0>]
{
  local incr_amount=${2:-1}
  declare -n curval=${1:?"$(sys_exc sys:incr "Variable ref expected")"}
  curval=$(( ${curval-${3-0}} + incr_amount ))
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

source_all ()
{
  while [[ $# -gt 0 ]]
  do . "${1:?}" || return
    shift
  done
}

# fixed indentation
std_findent () # ~ <Indentation> <Cmd ...>
{
  "${@:2}" | str_indent "${1:?}"
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
  "$@" 2>/dev/null
}
# alias for std-noerr

std_silent ()
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

stderr ()
{
  "$@" >&2
}

# stderr-format-line-from-env
stderr_lfmtv () # ~ <String-expression> <Var-names...>
{
  sys_fmtv "$1\n" "${@:2}" >&2
}

stdin_from_ () # ~ <Cmd...>
{
  declare str
  str=$("$@") || ignore_sigpipe || return
  exec <<< "$str"
}

stdin_from_nonempty () # ~ [<File>]
{
  test -n "${1-}" &&
  test -s "$_" &&
  exec < "$_"
}

sys_aappend () # ~ <Array> <Item> # Append new unique item to indexed array
{
  declare -n arr=${1:?}
  shift
  local item
  for item
  do
    "${sys_aap_ne:-true}" ||
      [[ "$item" ]] || continue
    # Dont compare against unitialized array
    ! [[ "${arr+set}" ]] || {
      for ((i=0;i<${#arr[*]};i++))
      do
        [[ "${arr[i]}" != "$item" ]] || continue 2
      done
    }
    arr+=( "$item" )
  done
}

# Store variables (name and current value) at associative array
# old assoc_from_env
sys_aarrv () # ~ <Array> <Vars...>
{
  declare -n arr=${1:?} var
  shift
  for var
  do arr["${!var}"]=$var
  done
}
# XXX: sys-assoc-array-from-variables

sys_loop () # ~ <Callback> <Items ...>
{
  local fun=${1:?}
  shift
  while [[ $# -gt 0 ]]
  do
    "$fun" "${1:?}" && break
    test ${_E_done:-200} -eq $? && return
    test ${_E_continue:-195} -eq $_ || return $_
    shift
  done
}

# system-array-from-command
# Read stdout of given command into array, if command returns zero status.
sys_arr () # ~ <Array> <Cmd...> # Read stdout (lines) into array
{
  if_ok "$("${@:2}")" &&
  <<< "$_" mapfile ${mapfile_f:--t} "${1:?}"
}
# rename sys_arr > sys-vaarr

# system array from arguments: for reference/normally inline. to show how to
# move several strings onto an array, and/or use array variable by name
sys_arra () # ~ <Variable-name> <Strings...>
{
  declare -n arr=${1:?}
  arr+=( "${@:2}" )
}

# system-array-from-variable-values, see also system-assoc-from-variable-values
sys_arrv () # ~ <Array-name> <Var-names...>
{
  local var
  declare -n values=${1:?}
  for var in "${@:2}"
  do values+=( "${!var-}" )
  done
}

# system-array-default
# XXX:
sys_arr_def () # ~ <Var-name> <Defaults...>
{
  declare -n arr=${1:?}
  test 0 -lt ${#arr[@]} || sys_arr_set "$@"
}

# (Re)set array to given arguments
sys_arr_set () # ~ <Var-name> <Elements...>
{
  declare -n arr=${1:?}
  arr=("${@:2}")
}

# Ensure variable is set without using inspection, simply declare using current
# or given value but else fail.
sys_assert () # ~ <Var-name> [<Value>] ...
{
  declare -n ref
  ref=${1:?"$(sys_exc sys:assert-var:ref@_1 "Variable name expected")"}
  ref="${ref-${2?"$(sys_exc sys:assert "Empty or value expected")"}}"
}

# As sys-assert but current or given must be non-empty as well
sys_assert_nz () # ~ <Var-name> <Value> ...
{
  declare -n ref
  ref=${1:?"$(sys_exc sys:assert-var:ref@_1 "Variable name expected")"}
  ref="${ref:-${2:?"$(sys_exc sys:assert-nz "Non-empty value expected")"}}"
}

# XXX: new function: ignore last status if test succeeds, or return it
sys_astat () # ~ ( <Test-flag> <Test-value> )*
{
  : source "sys.lib.sh"
  local stat=$?
  while [[ $# -gt 0 ]]
  do
    test $stat "$1" "$2" || return $stat
    shift 2
  done
}

# Return function call stack
sys_callers () # ~ [<Frame>]
{
  : source "sys.lib.sh"
  local i
  for (( i=${1-0}; 1; i++ ))
  do caller $i || break
  done
}

sys_cd () # ~ <Dir> <Cmd...> # Change PWD before executing
{
  # TODO: silence output, return cmd state
  pushd "${1:?}" &&
  "${@:2}" &&
  popd
}

# sys-confirm PROMPT
sys_confirm () # ~ <Prompt-string> # Read one character (key-press)
{
  local choice_confirm=
  sys_prompt "$1" choice_confirm -n 1 &&
  trueish "$choice_confirm"
}

# A simple handler to determine when to run optional script branches for more
# log/stderr verbosity or other computationally expensive but otherwise non-
# essential tasks during normal operations.
sys_debug () # ~ <Modes...> # Test tags with sys-debug-mode, and do !<mode> ?<mode> handling
{
  : source "sys.lib.sh"
  [[ $# -gt 0 ]] || set -- debug
  sys_match_select "" "" sys_debug_mode "$@"
}

sys_debug_mode () # (y) ~ <Mode> # Determine wheter given mode is active
# based on one or more env settings. In general QUIET overrides modes that have
# only implications for log generation/stdout verbosity, and VERBOSE overrides
# QUIET. Neither value is ever given a default, so that is up to the user or
# calling script.
#
# DEV, DEBUG, DIAG, ASSERT, INIT all mostly default to false, but are never
# defaulted either so this can be done on a per-script context. The exception is
# DIAG that defaults to true one time, and only in 'exceptions' mode and if
# VERBOSE is not already true.
#
# See user-script-loadenv for examples.
{
  : source "sys.lib.sh"
  local lk=${lk-}:us:sys.lib:debug-mode
  case "$1" in
  ( assert ) ## \
    # Trigger more verbose responses about what exactly precipitates failures,
    # maybe do a bit more checking in the meanwhile but such actions normally
    # should be triggered by DIAG instead.
    ! "${QUIET:-false}" && "${ASSERT:-${DIAG:-${DEBUG:-${DEV:-false}}}}" ;;
  ( debug ) ## \
    # Provide more log level events, especially info and debug level
    # messages which would be far to verbose and many to generate normally.
    # Still, more detail should be configured on a per-script basis.
    ! "${QUIET:-false}" && "${DEBUG:-${DEV:-false}}" ;;
  ( dev ) ## \
    # Its not production, it just has to work and act sensibly and without
    # pressure. Dev also triggers assert and debug modes.
    ! "${RELEASE:-false}" && "${DEV:-false}" ;;
  ( diag ) ## \
    # Go further than assert, and perform additional checks during normal
    # scripts, and even trigger completely diagnostic script branches.
    "${DIAG:-${INIT:-${DEBUG:-false}}}" ;;
  ( exceptions )## \
    # To provide some very specific but verbose (stack) data for a user to see,
    # but normally turned off at quiet runs.
    "${VERBOSE:-false}" || "${DIAG:-true}" || ! "${QUIET:-false}" ;;
  ( init ) ## \
  # Like debug, but specifically to distinguish 'init' scripts that do setup,
  # from parts actually in the sub command run.
    "${INIT:-false}" ;;
  ( quiet ) ## \
    # Setting verbose is the only env that overrides the quiet setting.
    ! "${VERBOSE:-false}" || "${QUIET:-false}" ;;
  ( release ) ## \
    # Its not production, it just has to work and act sensibly and without
    # pressure. Dev also triggers assert and debug modes.
    "${RELEASE:-false}" && ! "${DEV:-false}" ;;
  ( verbose )
    "${VERBOSE:-false}" || ! "${QUIET:-false}"  ;;

  ( * ) $LOG alert "$lk" "No such mode" "$1" ${_E_script:?"$(sys_exc "$lk")"}
  esac
}

# XXX: hook to test for envd/uc and defer, returning cur bool value for setting
sys_debug_ () # ~ [<...>]
{
  : source "sys.lib.sh"
  sys_debug "$@" && echo true || echo false
}

sys_debug_tag ()
{
  : source "sys.lib.sh"
  local var tagstr
  # TODO: implement different out-fmt
  case "${1-}" in
    --oneline ) fmt=oneline; shift
  esac
  [[ $# -gt 0 ]] || set -- DEV DEBUG DIAG ASSERT INIT
  tagstr=$(sys_selector_tag "$@")
  tagstr="${tagstr//$'\n'/,}"
  [[ ${tagstr-} ]] || return 0
  [[ ! ${v:-${verbosity-}} ]] && {
    echo "$tagstr"
  } || {
    ! "${DEBUG:-false}" || printf '%s,v=%i' "$tagstr" "${v:-$verbosity}"
  }
}

# Ensure variable is set or use argument(s) as value
sys_default () # ~ <Name> <Value> ...
{
  : source "sys.lib.sh"
  declare -n ref=${1:?"$(sys_exc sys:default:ref@_1 "Variable name expected")"}
  [[ "set" = "${ref+set}" ]] || ref=${2-}
}

sys_each () # ~ <Exec-names...>
{
  local __us_sys_each_cmdname
  for __us_sys_each_cmdname
  do
    "${__us_sys_each_cmdname:?}" || return
  done
}

# An exception helper, e.g. for inside ${var?...} expressions
sys_exc () # ~ <Head>: <Label> <Vars...> # Format exception-id and message
{
  : source "sys.lib.sh"
  local \
    sys_exc_id=${1:-us:exc:$0:${*// /:}} \
    sys_exc_msg=${2-Expected}
  ! "${DEBUG:-$(sys_debug_ exceptions)}" &&
  echo "$sys_exc_id${sys_exc_msg:+: $sys_exc_msg}" ||
    "${sys_on_exc:-sys_source_trace}" "$sys_exc_id" "$sys_exc_msg" 3 "${@:3}"
}

# Expand shell string expression (with braces and or globs) and put expansion
# into array. XXX: does not handle space escapes
sys_exparr () # ~ <Arr> <Expr>
{
  #local __sys_exparr_arr=${1:?} __sys_exparr_expr=${2:?}
  # XXX: declare -ga ${1:?}
  "${UC_STATIC_ENV:-true}" && {
    if_ok "$(eval "echo ${2:?}")" &&
    test -n "$_" &&
    mapfile -t ${1:?} <<< "${_// /$'\n'}" || return
  } || {
    #shellcheck disable=2162
    test -n "$2" &&
    read -a ${1:?} <<< "${_//:/ }"
  }
}

# Expand spec or use existing path value to fill array
sys_expparr () # ~ <Arr> <Var-name>
{
  #local __sys_expparr_arr=${1:?} __sys_expparr_var=${2:?}
  : "${2:?}"
  : "${!_:?"$(sys_exc uc:annex:dirs-var-ref "Expected $_")"}"
  test -n "$_" || return
  "${UC_STATIC_ENV:-true}" "$_" && {
    if_ok "$(eval "echo ${_:?}")" &&
    mapfile -t ${1:?} <<< "${_// /$'\n'}" || return
  } || {
    #shellcheck disable=2162
    read -a ${1:?} <<< "${_//:/ }"
  }
}

# system-format-from-variables
sys_fmtv () # ~ <String-expression> <Var-names...>
{
  : source "sys.lib.sh"
  declare vars=() fmt
  fmt=${1:?"$(sys_exc us:sys.lib)"}
  sys_arrv vars "${@:2}" &&
  printf "$fmt" "${vars[@]}"
}

sys_for_arg () # (s) ~ <Args...> # Run each command line on stdin with arguments
{
  local sfa_cmd &&
  while read -ra sfa_cmd
  do "${sfa_cmd[@]}" "$@" || return; done
}

sys_for_do () # (s) ~ <Cmd...> # Run command for each argument line on stdin
{
  local sfd_args &&
  while read -ra sfd_args
  do "$@" "${sfd_args[@]}" || return; done
}

sys_get () # ~ <Var>
{
  : "${1:?"$(sys_exc sys.lib:get:@_1: "Variable name expected")"}"
  echo "${!_:?}"
}

sys_iref () # ~ <Path> [<Var-key=sys_iref_>]
{
  : "${2:-sys_iref_}"
  local -n \
    __sys_iref_ino=${_}ino \
    __sys_iref_mnt=${_}mnt
  if_ok "$(stat -c '%i %m' "${1:?}")" &&
  read -r __sys_iref_{ino,mnt} <<< "$_"
}

# system-join-array, system-collapse-array
sys_join () # ~ <Concat> <Array>
{
  declare -n __arr=${2:?} &&
  declare _i_ __c=${1?} &&
  : "" &&
  for _i_ in "${!__arr[@]}"
  do : "$_${_:+$__c}${__arr[_i_]}"
  done &&
  echo "$_"
}

# XXX: theoretically could accept variable len pref key
sys_match_select () # ~ <inc="-"> <exc="+"> <fun> <inputs...>
{
  : source "sys.lib.sh"
  local all=true fail p inc=${1:-"+"} exc=${2:-"-"} fun=${3:?}
  shift 3 || return
  while [[ $# -gt 0 ]]
  do
    case "$1" in
      ( "$exc"* ) p=1 all=false ;; ( * ) p=0 all=true
    esac
    case "${1:$p}" in
      ( "$inc"* ) incr p
          ! "$fun" "${1:$p}" || return
        ;;
      ( * )
          "$fun" "${1:$p}"
        ;;
    esac && {
            ! "${all:?}" && return || fail=false
          } || {
            "${all:?}" && return 1 || fail=true
          }
    shift
  done
  ! "${fail:-true}"
}

sys_nejoin () # ~ <Concat> <Array>
{
  declare -n __arr=${2:?} &&
  declare _i_ __c=${1?} &&
  : "" &&
  for _i_ in "${!__arr[@]}"
  do : "${_:+$_${__arr[_i_]:+$__c}}${__arr[_i_]}"
  done &&
  echo "$_"
}

# Test for fail/false status exactly, or return status. Ie. do not mask all
# non-zero statusses, but one specifically. See also sys-astat.
sys_not ()
{
  "$@"
  [[ $? -eq ${_E_fail:-1} ]]
}

sys_out () # ~ <Var> <Cmd...> # Capture command output
{
  local -n var=${1:?}
  var=$("${@:2}")
  # XXX: at least this creates a global variable
  #if_ok "$("${@:2}")" &&
  #read -r ${1:?} <<< "$_"
}

# system-path-output
sys_path () # ~ # TODO??
{
  : source "sys.lib.sh"
  echo "${PATH//:/$'\n'}" | sys_path_fmt
}

sys_path_fmt ()
{
  : source "sys.lib.sh"
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

# system-paths-depthfirst: a simple line-reader that indexes paths by their
# depth and index for that depth. Upon reading all lines, deeper paths are then
# output first.
sys_paths_df () # (s) ~ ...
{
  : source "sys.lib.sh"
  local path depth maxdepth seqidx
  declare -A depths
  # Sort
  while read -r path
  do
    [[ ${path:0:1} = / ]] && path=${path:0:1}
    [[ ${path:$(( ${#path} - 1 ))} = / ]] && path=${path%/}
    : "${path//[^\/]}"
    depth=${#_}
    #sys_default "depths[$depth]" 0
    incr "depths[$depth]" 1
    seqidx=${depths["$depth"]}
    depths["$depth.$seqidx"]=$path
    [[ $depth -lt $maxdepth ]] || maxdepth=$depth
  done
  # Output
  for (( depth=$maxdepth; depth>=0; depth-- ))
  do
    for (( seqidx=${depths["$depth"]}; seqidx>0; seqidx-- ))
    do
      echo "${depths["$depth.$seqidx"]}"
    done
  done
}

sys_paths_maxdepth ()
{
  local path depth maxdepth
  declare -A depths
  while read -r path
  do
    [[ ${path:0:1} = / ]] && path=${path:0:1}
    [[ ${path:$(( ${#path} - 1 ))} = / ]] && path=${path%/}
    : "${path//[^\/]}"
    depth=${#_}
    [[ $depth -lt $maxdepth ]] || maxdepth=$depth
  done
  echo $maxdepth
}

sys_prefix () # ~ <Prefix> <File>
{
  local tmpfile
  tmpfile=$(mktemp) &&
  cp "${2:?}" "$tmpfile" &&
  < "$tmpfile" str_prefix "${1:?}" >| "${2:?}" &&
  rm "$tmpfile"
}

sys_prompt () # ~ <Prompt> <Var> <Read-argv...>
{
  local -r prompt=${1?"$(sys_exc sys.lib:-prompt "Prompt text expected")"}
  local -r var=${2:-sys_prompt_input}
  test $# -gt 2 || set -- "$@" -n 1
  printf '%s' "$prompt"
  read "${@:3}" ${var?} &&
  printf '\n'
}

# Reverse array items
sys_rarr () # ~ <Arr-name>
{
  declare -a temp
  #shellcheck disable=2178 # 'dest' still used as array afaics
  sys_rarr2 "${1:?}" temp &&
  declare -n dest=${2:?} &&
  dest=( "${temp[@]}" )
}

# Reverse copy items from array to array
sys_rarr2 () # ~ <Arr-from> <Arr-to>
{
  declare -n __from=${1:?} __to=${2:?}
  local _i_
  for (( _i_=$(( ${#__from[@]} - 1 )); _i_>=0; _i_-- ))
  do
    __to+=( "${__from[$_i_]}" )
  done
}

# XXX: use concat sep or not
sys_selector_tag () # ~ <Var-names...>
{
  local var
  for var
  do
    [[ false = "${!var:-}" ]] && printf -- "-%s\n" "${var,,}"
    [[ true = "${!var:-}" ]] && printf "+%s\n" "${var,,}"
  done
}

# Set variable to value, creates new global variable if name is undeclared.
sys_set () # ~ <Var-name> [<Value>] ...
{
  local var val=${2-} &&
  var=${1:?"$(sys_exc sys:set-var:var@_1 "Variable name expected")"} &&
  declare -n ref=$var &&
  ref=$val
}

# XXX: like set-var but require non-zero string as well
sys_set_ne () # ~ <Var-name> <Value> ...
{
  local var val &&
  var=${1:?"$(sys_exc sys:set-var-ne:var@_1 "Variable name expected")"} &&
  val=${2:?"$(sys_exc sys:set-var-ne:val@_2 "Value expected")"} &&
  declare -n ref=$var &&
  ref=$val
}

# system-source-trace: Helper to format callers list including custom head.
sys_source_trace () # ~ [<Head>] [<Msg>] [<Offset=2>] [ <var-names...> ]
{
  : source "sys.lib.sh"
  ! "${US_SRC_TRC:-true}" && {
    echo "${1:-us:source-trace: E$? source trace (disabled):}${2+ ${2-}}"
  } || {
    echo "${1:-us:source-trace: E$? source trace:}${2+ ${2-}}" &&
    std_findent "  - " sys_callers "${3-2}"
  }
  [[ 3 -ge $# ]] && return
  echo "Variable context ($(( $# - 3 )) vars):"
  local -n var &&
  for var in "${@:4}"
  do
    if_ok "$(declare -p ${!var})" &&
    fnmatch "declare -n *" "$_" && {
      printf '- %s\n  %s\n' "$_" "${!var}: ${var@Q}"
    } || echo "$_"
  done | str_prefix '  '
}

sys_stat ()
{
  return ${1:-$?}
}

# Check for RAM-fs or regular temporary directory, or set to given
# directory which must also exist. Normally, TMPDIR will be set on Unix and
# POSIX systems. If it does not exist then TMPDIR will be set to whatever
# is given here or whichever exists of /dev/shm/tmp or $RAM_TMPDIR. But the
# directory will not be created.
sys_tmp_init () # DIR
{
  local tag=:sys.lib:tmp-init
  [[ "${RAM_TMPDIR-}" ]] || {
    # Set to Linux ramfs path
    [[ -d "/dev/shm" ]] && {
      RAM_TMPDIR=/dev/shm/tmp
    }
  }

  [[ "${RAM_TMPDIR-}" ]] || {
    # XXX: find existing parent dir
    _RAM_TMPDIR="$(set -- $RAM_TMPDIR; while [[ ! -e "$1" ]]; do set -- $(dirname "$1"); done; echo "$1")"
    [[ -w "$_RAM_TMPDIR" ]] && {
      [[ -d "$RAM_TMPDIR" ]] || mkdir $RAM_TMPDIR
    } || {
      [[ -d "$RAM_TMPDIR" ]] && {
        $sys_lib_log warn $tag "Cannot access RAM-TmpDir" "$RAM_TMPDIR"
      } ||
        $sys_lib_log warn $tag "Cannot prepare RAM-TmpDir" "$RAM_TMPDIR"
    }
    unset _RAM_TMPDIR
  }

  [[ -e "${1-}" && -z "${RAM_TMPDIR-}" ]] || set -- "$RAM_TMPDIR"
  [[ -e "${1-}" && -z "${TMPDIR-}" ]] || set -- "$TMPDIR"
  [[ "${1-}" ]] && {
    [[ "${TMPDIR-}" ]] || export TMPDIR=$1
  }
  [[ -d "$1" ]] || {
    $sys_lib_log warn $tag "No RAM tmpdir/No tmpdir found" "" 1
  }
  sys_tmp="$1"
}

sys_tsvars () # ~ VARNAMES... # Read fields from TSV line
{
  local line &&
  IFS=$'\n' read -r line &&
# Unfortenately, Bash read insists on reading non-zero values. So we use
  # something (\f ie. ASCII form-feed character) that is does accept as value
  # and clear that afterwards. FIXME: but it does seem doing our own read would
  # improve performance.
  : "${line//$'\t\t'/$'\t-\t'}" &&
  : "${_//$'\t\t'/$'\t-\t'}" &&
  : "${_/#$'\t'/$'-\t'}" &&
  : "${_/%$'\t'/$'\t-'}" &&
  IFS=$'\t\n' read -r $* <<< "$_" &&
  for var
  do [[ ${!var?} != '-' ]] || eval "$var="
  done
}

sys_varstab () # ~ VARNAMES... # Write fields to TSV line
{
  local varname
  : ""
  for varname
  do
    : "$_${!varname?}"$'\t'
  done
  : "${_%$'\t'}"
  echo "$_"
}

# Error unless non-empty and true-ish value
trueish () # ~ <String>
{
  [[ $# -eq 1 && -n "${1-}" ]] || return
  case "$1" in [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1) return 0;;
    * ) return 1;;
  esac
}
# Id: sh-trueish

try_exec_func()
{
  [[ "${1-}" ]] || return 97
  [[ "${sys_lib_log-}" ]] || return 108
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
  [[ $# -gt 1 ]] && {
    value="$(eval echo "\"\${$(echo_local "$@")-}\"" || return )"
  } || {
    #shellcheck disable=1083 # { is literal, yes
    value="$(eval echo \"\${${1-}-}\" || return )"
  }
  [[ "$value" ]] || return 1
  echo "$value"
}

# TODO: redesign @Dsgn
try_var () # ~ <Var-name>
{
  : "${!1:-}"
  [[ "$_" ]] &&
  echo "$_"
}

user_lookup_path () # ~ [<User-paths...>] -- <Local-paths...>
{
  declare -a user_paths
  while [[ "${1:?}" != "--" ]]
  do
    user_paths+=( "$1" )
    shift
    [[ $# -gt 0 ]] || break
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
work_env ()
{
  # Get name for shell profile
  [[ -z "$ENV_NAME" ]] && {
    [[ ${OS_HOSTNAME-} ]] || exit 110
    LENV="$OS_HOSTNAME"
  } || {
    LENV="$ENV_NAME"
  }

  # Check for python v-env
  [[ "0" = "$PYVENV" ]] || {
    LENV="$LENV,pyvenv"
  }
  printf '%s' "$LENV"
}

# Sync: BIN:
