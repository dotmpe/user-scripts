#!/bin/sh

test -n "$UCACHE" || UCACHE=$HOME/.cache/local
test -d "$UCACHE/user-env" || mkdir -p "$UCACHE/user-env"

test -n "$LOG" -a -x "$LOG" && INIT_LOG=$LOG || INIT_LOG=$PWD/tools/sh/log.sh

test -n "$BASH" -a \( "$BASH" != "/bin/sh" \) && IS_BASH=1 || IS_BASH=0

# To be sourced with "$@" pattern

# XXX: cannot properly defer lookup without function, ie. remind the ID and
# to lookup value on request. And fail if some var fails to expand.
__value_or_eval_default()
{
  local val="$(eval echo \$$1)"
  test -n "$val" || {
    eval $1="$2"
  }
}

# Register var
__env_var_or_default()
{
  __isset $1 && set -- "__env_d_$1" "\$$1" || set -- __env_d_$1 "$2"

  $1=$2
}

__env_expand()
{
  default() { true; }

  for var in $env_d
  do
    eval echo "\$env_d_$var"
    echo "$var: \$$var"
  done
}

__reg_env_or_eval_default()
{
  # Store as regular value but don't eval yet, also look for set keys,
  # not non-empty valaues.
  __env_var_or_default "$@"
  env_d="$env_d $1"
}

__env_finish()
{
  __env_dump
  __env_expand
  __env_dump
  export $env_d
}

__env_dump()
{
  for var in $env_d
  do
    eval echo "$var: \$$var"
  done >&2
}

test $IS_BASH -eq 1 && {
  sh_env()
  {
    set | grep '^[a-zA-Z_][0-9a-zA-Z_]*=.*$'
  }
} || {
  sh_env()
  {
    set
  }
}
__isset()
{
  sh_env | grep -q "^$1="
}
__isenv()
{
  env | grep -q "^$1="
}


#var_default=__value_or_eval_default
#env_default=__reg_env_or_eval_default
#$var_default env_finish __env_finish
#$var_default var_default_scriptcmd \${env_finish}
#test -n "$1" || set -- $var_default_scriptcmd

. "$script_util/parts/env-scriptpath.sh"

$INIT_LOG debug user-env "Script-Path:" "$SCRIPTPATH"

# Id: user-scripts/0.0.2-dev tools/sh/user-env.sh
