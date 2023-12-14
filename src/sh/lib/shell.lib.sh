#!/usr/bin/env bash

shell_lib__load()
{
  lib_require os sys str log || return

  # Dir to record env-keys snapshots:SD-Shell-Dir
  test -n "${SD_SHELL_DIR-}" || SD_SHELL_DIR="${STATUSDIR_ROOT:-$HOME/.local/statusdir/}shell"

  # Set defaults for required vars
  #test -n "$ENV_NAME" || ENV_NAME=development

  # XXX: env-name, cs, base and sh-id....
  test -n "${MPE_ENV_NAME-}" || MPE_ENV_NAME=dev
  test -n "${CS-}" || CS=dark
  test -n "${base-}" || base=$(test -e "$0" && basename -- "$0" .sh || printf -- "%s" "$0")

  # Shell Name depends on env SHELL
  test -h "$SHELL" &&
    SHELL_NAME=$(basename -- "$(readlink -- "$SHELL")") ||
    SHELL_NAME="$(basename -- "$SHELL")"
}

# Init env by testing for key vars, set <SHELL>_SH=[01] based on name,
# and IS_<SHELL>_SH=[01] to indicate actual detected shell. Shells are
# hardcoded bash, z, k (Korn), dash/ash (Debian-Almquist shells), and ofcourse
# sh usually used as alias/symlinked '/bin/sh' mode with bash and others.
# Here also a BusyBox [bb] and Heirloom Bourne shell [heir] are detected.
#
# TODO: z-shell builtins table, add others as well
# NOTE: that leaves a host of other popular, novell or modern shells untested;
# fish, posh, yash, and osh are candidates to be added.
# XXX: also these checks are snapshots w/o version checks, also maybe other
# variations in bi/sbi/a/bin may invalidate thise code.
#
# See shell-check, shell-test-sh and sh-env-init,
# and also <doc/shell-builtins.tab>
shell_lib__init()
{
  test -z "${shell_lib_init-}" || return $_
  #lib_assert os sys str log || return

  test -n "${SH_SID-}" || SH_SID=$(get_uuid) || return

  shell_init_mode || return

  req_init_log us || return
  local log_key="$scriptname/$$":u-s:shell:lib:init

  log_key=$log_key $us_log debug "" "Running final shell.lib init"

  shell_check && sh_init_mode && shell_def &&
  log_key=$log_key $us_log info "" "Loaded shell.lib" "$0"
}

# is-bash check, expect no typeset (ksh) TODO: zshell bi table.
shell_check () #
{
  type typeset >/dev/null 2>&1 && {
    test 1 -eq "${K_SHELL:?}" \
      -o 1 -eq "${Z_SHELL:?}" \
      -o 1 -eq "${DA_SHELL:?}" \
      -o 1 -eq "${BA_SHELL:?}" || {

      # Not spent much time outside GNU, busybox or BSD 'sh' & Bash.
      {
        echo "Found typeset cmd, expected Bash or Z-Sh ($0: $SHELL_NAME)" >&2
        shell_bin=$(command -v -- "$SHELL_NAME")
        test ! -e "$shell_bin" || ls -la $shell_bin
        type typeset
        echo SHELL:$SHELL
        echo END
      } >&2
      return 1
    }
  } || true
}

shell_init_mode ()
{
  # Try to figure out what we are.. and how to keep it Bourne Shell compatible
  test "$SHELL_NAME" = "bash" && BA_SHELL=1 || BA_SHELL=0
  test "$SHELL_NAME" = "zsh" && Z_SHELL=1 || Z_SHELL=0
  test "$SHELL_NAME" = "ksh" && K_SHELL=1 || K_SHELL=0
  test "$SHELL_NAME" = "dash" && DA_SHELL=1 || DA_SHELL=0
  test "$SHELL_NAME" = "ash" && A_SHELL=1 || A_SHELL=0
  test "$SHELL_NAME" = "sh" && B_SHELL=1 || B_SHELL=0
}

# If running in /bin/sh 'mode', still detect which shell we are dealing with.
# Will set IS_<SHELL>_SH=1 based on the type signature of a select few
# execnames. See shell-detect-sh.
# Then will set IS_<SHELL>=1 for bash, dash, ash or Heirloom sh.
# TODO: broather support if possible. TOTEST on different shells
sh_init_mode ()
{
  IS_BASH_SH=0
  IS_DASH_SH=0
  IS_BB_SH=0
  IS_HEIR_SH=0

  # Nothing to test if SHELL_NAME is not given as 'ash'
  test "$SHELL_NAME" != "sh" || {
    shell_detect_sh
  }

  test $BA_SHELL -eq 1 -o $IS_BASH_SH -eq 1 && IS_BASH=1 || IS_BASH=0

  test $DA_SHELL -eq 1 -o $IS_DASH_SH -eq 1 && IS_DASH=1 || IS_DASH=0
  test $DA_SHELL -eq 1 -o $A_SHELL -eq 1 -o $IS_DASH_SH -eq 1 && IS_A=1 || IS_A=0
  # FIXME A_SHELL=..

  #test $BB_SH -eq 1 -o $IS_BB_SH -eq 1 && IS_BB=1 || IS_BB=0
  # XXX: do Korn or Z have Sh-modes?

  test $IS_HEIR_SH -eq 1 && IS_HIER=1 || IS_HIER=0
  HEIR_SH=$IS_HEIR_SH
}

# Try to detect Shell variant based on specific commands.
# See <doc/shell-builtins.tab>
shell_detect_sh ()
{
  sh_is_type_bi 'bind' && IS_BASH_SH=1 || {

    sh_is_type_sbi 'local' && {
      sh_is_type_bi 'let' && IS_BB_SH=1 || IS_DASH_SH=1

    } || {
      sh_is_type_bin 'false' &&
        # Assume heirloom shell
        IS_HEIR_SH=1 || false # unknown Sh
    }
  }
}


# Define sh-env. to get plain env var name/value list, including local vars
shell_def ()
{
  req_init_log || return

  # XXX: test other shells.. etc. etc.
  test $IS_BASH -eq 1 && {
    $us_log info shell.lib "Choosing bash sh-env-init"

    sh_als() # Is name of shell alias # sh:no-stat
    {
      test "$(type -t "$1")" = "alias"
    }

    sh_bi()
    {
      test "$(type -t "$1")" = "builtin"
    }

    sh_env() # sh:no-stat
    {
      {
        set | grep '^[_A-Za-z][A-Za-z0-9_]*=.*$'
        env
      } | sort -u
    }

    sh_fun() # Is name of shell funtion # sh:no-stat
    {
      test "$(type -t "$1")" = "function"
    }

    sh_isset() # sh:no-stat
    {
      test "${!1-unset}" != "unset"
    }

    sh_kw()
    {
      test "$(type -t "$1")" = "keyword"
    }

    sh_normalize_ws ()
    {
      declare line repl=${1:-[$'\t\n']} sub=${2:-" "}
      while read -r line
      do
        if_ok "$(str_glob_replace "$line" "$repl" "$sub" )" &&
        str_collapse "$_" "$sub" ||
          return
      done
    }

  } || {
    $us_log info shell.lib "Choosing non-bash sh-env-init"
    sh_env() # sh:no-stat
    {
      set
    }
    sh_isset() # sh:no-stat
    {
      sh_env | grep -qi "^$1="
    }
  }
  sh_isenv() # XXX: Exported vars? @Base # sh:no-stat
  {
    env | grep -q "^$1="
  }
  sh_genv() # Grep for var names # sh:no-stat
  {
    sh_env | grep "$1"
  }
}


# Test true if CMD is a builtin command
sh_is_type_bi() # CMD
{
  type "$1" | grep -q '^[^ ]* is a shell builtin$'
}

# Test true if CMD is a special builtin command
sh_is_type_sbi() # CMD
{
  type "$1" | grep -q '^[^ ]* is a special shell builtin$'
}

# Test true if CMD is an shell command alias
sh_is_type_a() # CMD
{
  type "$1" | grep -q '^[^ ]* is \(aliased to\|an alias for\) .*$'
}

# Test true if CMD resolves to an executable at path
sh_is_type_bin() # CMD
{
  type "$1" | grep -q '^[^ ]* is /[^ ]*$'
}

# Test true if CMD is not builtin or executable, or any of the above
sh_is_type_na() # CMD
{
  type "$1" | grep -q '^.* not found$'
}


# Tell what CMD definition for given ALIAS is defined (extended Sh-mode covering
# common shell)
sh_aliasinfo_sh() # ALIAS
{
  sh_is_type_a "$1" || return
  type "$1" | sed -E 's/^[^ ]* is (aliased to|an alias for) .(.*)./\2/g'
}

# Tell what given CMD name is, like `type`
sh_aliasinfo() # ALIAS
{
  sh_aliasinfo_sh "$1"
}


# Tell what given CMD name is, like `type` but as a short lower-case abbrev
sh_execinfo() # run execinfo-inner for each arg ~ CMD...
{
  local i= ; test $# -gt 1 && i=":\$1"
  s= p= act=sh_execinfo_ foreach_do "$@"
}

# Inner foreach-do routine for sh-execinfo
sh_execinfo_() # echo shell symbol type code ~ CMD
{
  sh_is_type_na "$1" && {

    echo na$i
    return 2
  }

  sh_is_type_sbi "$1" && eval echo \"sbi$i\"
  sh_is_type_bi "$1" &&  eval echo \"bi$i\"
  sh_is_type_a "$1" &&   eval echo \"a$i:"\$(sh_aliasinfo "$1")"\"
  sh_is_type_bin "$1" && eval echo \"bin$i:"\$(command -v "$1")"\"
  true
}

sh_deps() # Fetch script callees by Oil-shell compiler ~
{
  oshc deps
}

# TODO: maybe use env with shell-test/detect etc. And/otherwise move this,
# env.lib.sh? Consolidate user-conf first.

# Record env keys only; assuming thats safe, no literal dump b/c of secrets
record_env_keys()
{
  test -n "$1" || return
  env_keys > "$SD_SHELL_DIR/$1.sh"
}

record_env_ls()
{
  test -n "$1" && set -- "$$$1" || set -- "$SD_PREF"
  for name in "$SD_SHELL_DIR/$1"*
  do
    echo "$(ls -la "$name") $( count_lines "$name") keys"
  done
}

env_keys()
{
  sh_env | sed 's/=.*$//' | grep -v '^_$' | sort -u
}

record_env_diff_keys()
{
  req_init_log || return

  test -n "$1" || set -- "$(ls "$SD_SHELL_DIR" | head -n 1)" "$2"
  test -n "$2" || set -- "$1" "$(ls "$SD_SHELL_DIR" | tail -n 1)"

  # FIXME:
  #test -e "$1" -a -e "$2" || stderr "record-env-keys-diff" '' 1
  #test -e "$SD_SHELL_DIR/$1" -a -e "$SD_SHELL_DIR/$2" || $us_log error env "record-env-keys-diff" "" 1

  $us_log info shell.lib "comm -23 '$SD_SHELL_DIR/$2' '$SD_SHELL_DIR/$1'"
  comm -23 "$SD_SHELL_DIR/$2" "$SD_SHELL_DIR/$1"
}

# Id: U-s
