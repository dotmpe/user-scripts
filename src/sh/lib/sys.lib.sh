#!/bin/sh

# Sys: dealing with vars, functions, env.

sys_lib_load()
{
  test -n "$uname" || uname="$(uname -s | tr 'A-Z' 'a-z')"
  test -n "$HOST" || HOST="$(hostname -s | tr 'A-Z' 'a-z')"
  test -n "$hostname" || hostname="$HOST"
}

sys_lib_init()
{
  test "${sys_lib_init:-}" = "0" || {
    test -n "$LOG" -a \( -x "$LOG" -o "$(type -t "$LOG")" = "function" \) \
      && sys_lib_log="$LOG" || sys_lib_log="$U_S/tools/sh/log.sh"
    test -n "$sys_lib_log" || return 108

# XXX: cleanup
if [ -z "$(which realpath)" ]
then # not perfect?
realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#.}"
}
fi
    $sys_lib_log debug "" "Initialized sys.lib" "$0"
  }
}


# Sh var-based increment
incr() # VAR [AMOUNT=1]
{
  local incr_amount
  test -n "${2-}" && incr_amount=$2 || incr_amount=1
  v=$(eval echo \$$1)
  eval $1=$(( $v + $incr_amount ))
}

getidx()
{
  test -n "$1" || error getidx-array 1
  test -n "$2" || error getidx-index 1
  test -z "$3" || error getidx-surplus 1
  local idx=$2
  set -- $1
  eval echo \$$idx
}

# Error unless non-empty and true-ish value
trueish() # Str
{
  test $# -eq 1 -a -n "${1:-}" || return
  case "$1" in [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1) return 0;;
    * ) return 1;;
  esac
}
# Id: sh-trueish

# No error on empty, or not trueish match
not_trueish()
{
  test -n "$1" || return 0
  trueish "$1" && return 1 || return 0
}

# Error unless non-empty and falseish
falseish()
{
  test $# -eq 1 -a -n "${1:-}" || return
  case "$1" in
    [Oo]ff|[Ff]alse|[Nn]|[Nn]o|0)
      return 0;;
    * )
      return 1;;
  esac
}

# No error on empty, or not-falseish match
not_falseish() # Str
{
  test -n "$1" || return 0
  falseish "$1" && return 1 || return 0
}

cmd_exists()
{
  test -n "$1" || return

  set -- "$1" "$(which "$1")" || return

  test -n "$2" -a -x "$2"
}

func_exists()
{
  type $1 2> /dev/null 1> /dev/null || return $?
  # XXX bash/bsd-darwin: test "$(type -t $1)" = "function" && return
  return 0
}

try_exec_func()
{
  test -n "$1" || return 97
  test -n "$sys_lib_log" || return 108
  $sys_lib_log debug "sys" "try-exec-func '$1'"
  func_exists $1 || return $?
  local func=$1
  shift 1
  $func "$@" || return $?
}

# TODO: redesign @Dsgn
try_var()
{
  local value="$(eval echo "\$$1")"
  test -n "$value" || return 1
  echo $value
}

# Get echo-local output, and return 1 on empty value. See echo-local spec.
try_value()
{
  local value=
  test $# -gt 1 && {
    value="$(eval echo "\"\$$(echo_local "$@")\"")"
  } || {
    value="$(echo $(eval echo "\$$1"))"
  }
  test -n "$value" || return 1
  echo "$value"
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

# setup-tmp [(RAM_)TMPDIR]
setup_tmpd()
{
  test $# -le 2 || return
  while test $# -lt 2 ; do set -- "$@" "" ; done
  test -n "$1" || set -- "$base-$(get_uuid)" "$2"
  test -n "$RAM_TMPDIR" || {
        test -w "/dev/shm" && RAM_TMPDIR=/dev/shm/tmp
      }
  test -n "$2" -o -z "$RAM_TMPDIR" || set -- "$1" "$RAM_TMPDIR"
  test -n "$2" -o -z "$TMPDIR" || set -- "$1" "$TMPDIR"
  test -n "$2" ||
        $sys_lib_log warn sys "No RAM tmpdir/No tmpdir settings found" "" 1

  test -d $2/$1 || mkdir -p $2/$1
  test -n "$2" -a -d "$2" || $sys_lib_log error sys "Not a dir: '$2'" "" 1
  echo "$2/$1"
}

# Echo path to new file in temp. dir. with ${base}- as filename prefix,
# .out suffix and subcmd with uuid as middle part.
# setup-tmp [ext [uuid [(RAM_)TMPDIR]]]
setup_tmpf() # [Ext [UUID [TMPDIR]]]
{
  test $# -le 3 || return
  while test $# -lt 3 ; do set -- "$@" "" ; done
  test -n "$1" || set -- .out "$2" "$3"
  test -n "$2" || set -- $1 $(get_uuid) "$3"
  test -n "$1" -a -n "$2" || $sys_lib_log error sys "empty arg(s)" "" 1

  test -n "$3" || set -- "$1" "$2" "$(setup_tmpd)"
  test -n "$3" -a -d "$3" || $sys_lib_log error sys "Not a dir: '$3'" "" 1

  test -n "$(dirname $3/$2$1)" -a "$(dirname $3/$2$1)" \
    || mkdir -p "$(dirname $3/$2$1)"
  echo $3/$2$1
}

# sys-prompt PROMPT [VAR=choice_confirm]
sys_prompt()
{
  test -n "$1" || $sys_lib_log error sys "sys-prompt: arg expected" "" 1
  test -n "$2" || set -- "$1" choice_confirm
  test -z "$3" || $sys_lib_log error sys "surplus-args '$3'" "" 1
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

# Add an entry to PATH, see add-env-path-lookup for solution to other env vars
add_env_path() # Prepend-Value Append-Value
{
  test -e "$1" -o -e "$2" || {
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
  # XXX: to export or not to launchctl
  #test "$uname" != "darwin" || {
  #  launchctl setenv "$1" "$(eval echo "\$$1")" ||
  #    echo "Darwin setenv '$1' failed ($?)" >&2
  #}
}

# Add an entry to colon-separated paths, ie. PATH, CLASSPATH alike lookup paths
add_env_path_lookup() # Var-Name Prepend-Value Append-Value
{
  local val="$(eval echo "\$$1")"
  test -e "$2" -o -e "$3" || {
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

remove_env_path_lookup()
{
  local newval="$( eval echo \"\$$1\" | tr ':' '\n' | while read oneval
    do
      test "$2" = "$oneval" -o "$(realpath "$2")" = "$(realpath "$oneval")" &&
        continue ;
      echo "$oneval" ;
    done | tr '\n' ':' | strip_last_nchars 1 )"

  export $1="$newval"
}

init_user_env()
{
  local key= value=
  for key in UCONFDIR HTDIR DCKR_VOL TMPDIR
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
  # Add path dirs in $UCONFDIR to $PATH
  local name
  for name in $uname $(uname -s) Generic
  do
    local user_PATH=$UCONFDIR/path/$name
    if test -d "$user_PATH"
    then
      add_env_path $user_PATH
    fi
  done
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

update_env()
{
  test -n "$PYVENV" || {
    PYVENV=$(htd ispyvenv) || PYVENV=0
    export PYVENV
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

my_env_git_bash_prompt()
{
  LENV="$(work_env)"
  [[ $1 != 0 ]] && ERRMSG="[$1]" || ERRMSG=
  case "$TERM" in
    screen ) TITLE="\033k$(vc.sh screen)\033\\ " ;;
    ansi ) TITLE="\[\033]0;$(vc.sh screen)\007\]" ;;
    xterm* ) TITLE="\[\033]0;$(vc.sh screen)\007\]" ;;
  esac
  export PS1="$TITLE$RED$ERRMSG$NORMAL\n$MAGENTA\# $NORMAL$AOSEP\u$PAT\h$PSEP$($HOME/bin/vc.sh ps1)$LENV$APSEP\n$ISEP $TSEP\t $CYAN\$ $NORMAL"
}


# Update function for the GNU Screen title
# http://code-and-hacks.peculier.com/bash/setting-terminal-title-in-gnu-screen/
settitle()
{
	if [ -n "$STY" ] ; then         # We are in a screen session
		printf "\033k%s\033\\" "$@"
		screen -X eval "at \\# title $@" "shelltitle \"$@\""
	else
		printf "\033]0;%s\007" "$@"
	fi
}

# Return 1 if env was provided, or 0 if default was set
default_env() # VAR-NAME DEFAULT-VALUE
{
  test -n "$1" -a $# -eq 2 || error "default-env requires two args ($*)" 1
  local vid= sid= id=
  trueish "$title" && upper= || {
    test -n "$upper" || upper=1
  }
  mkvid "$1"
  mksid "$1"
  unset upper
  test -n "$(eval echo \$$vid)" || {
    debug "No $sid env ($vid), using '$2'"
    eval $vid="$2"
    return 0
  }
  return 1
}


rnd_passwd()
{
  test -n "$1" || set -- 11
  cat /dev/urandom | LC_ALL=ascii tr -cd 'a-z0-9' | head -c $1
}

# Capture cmd/func output in file, return status. Set out_file to provide path.
# The fourth argument signals to pass current stdin or the given file to the
# subshell pipeline.
capture() # CMD [RET-VAR=ret_var] [OUT-FILE-VAR=out_file] [-|FILE]
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
capture_var() # CMD [RET-VAR=ret_var] [OUT-VAR=out_var] [ARGS...]
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

  test -n "$pref" && {
      local tmp="$(${pref} $cmd_name || echo $?>$failed)"
    } || {
      local tmp="$($cmd_name "$@" || echo $?>$failed)"
    }

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

# Execute arguments, or return on first failure, empty args, or no cmdlines
exec_arg() # CMDLINE [ -- CMDLINE ]...
{
  test -n "$*" || return 2
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
