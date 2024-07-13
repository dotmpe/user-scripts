#!/usr/bin/env bash


export_stage()
{
  test -n "${1:-}" || return 100
  test -n "${2:-}" || set -- "$1" "$(str_id $1)"

  export stage=$1 stage_id=$2 ${2}_ts="$($gdate +%s.%N)"
  ci_stages="${ci_stages-}${ci_stages+" "}$stage_id"
}

announce_stage () # ~
{
  test $# -le 2 || return 98

  test -n "${1:-}" || set -- "$stage"
  test -n "${2:-}" || set -- "$1" "$stage_id"
  test -n "$2" || set -- "$1" "$1"

  local ts="$(eval echo \$${2}_ts)"
  announce_time "$ts" "Starting stage... <$stage>"
}

announce_time () # ~ # Report time since start
{
  test -n "${travis_ci_timer_ts-}" && {

    deltamicro="$(echo "$1 - $travis_ci_timer_ts" | bc )"
    print_yellow "$scriptname:$stage" "${deltamicro}s: $2"
  } || {

    print_yellow "$scriptname:$stage" "???s: $2"
  }
}

close_stage()
{
  test -n "${1:-}" || set -- "Done"

  local ts=$($gdate +%s.%N)
  export ${stage_id}_end_ts="$ts"
  stages_done="$stages_done $stage_id"
  announce_time "$ts" "$1"
}

ci_announce()
{
  local ts=$($gdate +%s.%N)
  announce_time "$ts" "$1"
}

ci_bail()
{
  test $# -gt 0 || return 98
  test $# -gt 1 || set -- "$1" 1
  print_red "" "$1" >&2 ; return $2
}

ci_abort()
{
  test $# -gt 0 || exit 98
  test $# -gt 1 || set -- "$1" 1
  print_red "" "$1" >&2 ; exit $2
}

ci_cleanup()
{
  local exit=$? ; test ${exit:-0} -gt 0 || return 0 ; sync
  echo '------ ci-cleanup: Exited: '$exit  >&2
  # NOTE: BASH_LINENO is no use at travis, 'secure'
  echo "At $BASH_COMMAND:$LINENO"
  echo "In 0:$0 scriptname:$scriptname"
  test "$USER" = "travis" || return $exit
  sleep 5 # Allow for buffers to clear?
  return $exit
}

ci_env() # Var
{
  ${INIT_LOG:?} "header2" "${2:-}$1" "$(eval echo \"\$$1\")"
}

ci_check() # Label Command-Line...
{
  local label="$1" vid stat
  upper=true str_vid vid "$1"; shift
  eval ${vid}_LABEL=\"$label\"
  "$@" && stat=1 || stat=0
  eval ${vid}=$stat
}

# Check for presence of commit-message tags (lower case)
ci_tags() # Str Tags...
{
  test $# -ge 2 || return 98
  local str="$(echo "$1"|tr '[:upper:]' '[:lower:]')" ; shift
  while test $# -gt 0
  do
    case "$str" in

        *"[$1]"* | \
        *"[$1, "*"]"* | *"["*", $1, "*"]"* | *"["*", $1]"* )
            return 0;
          ;;

        * ) ;;

    esac
    shift
  done
  return 1
}

ci-run () # ~ <Test-cmd <...>> # Execute/test one cmdline
{
  test $# -ge 1 -a -n "${1:-}" || return 98
  : "${ci_lbl:="Step"}"
  : "${ci_run:="$SCRIPT_SHELL -c"}"
  print_yellow "" "Running $ci_lbl $ci_run '$1'..."

  {
    $ci_run "$@" | {
      # NOTE: output stderr at lvl >= 3, stdout at 4 and above
    # FIXME: this does not get stderr!
      test ${verbosity:-4} -ge 3 && {
        test ${verbosity:-4} -ge 4 && {
          cat
        } || {
          cat >/dev/null
        }
      } || {
        cat >/dev/null 2>&1
      }
    }
  } && {
    ci-pass "$ci_lbl $ci_run $1"
    print_green "OK" "$ci_lbl: $ci_run '$1'"

  } || {

    ci-fail "$ci_lbl $ci_run $*"
    print_red "Not OK: $failed_ret" "$ci_lbl: $ci_run '$1'"
    trueish "$keep_going" || return $failed_ret
  }
}

ci-pass()
{
  passed_cmd="$_" passed_ret=$?
  test $# -eq 0 || passed_cmd="$1"
  test -f "${passed:-}" || return 97
  echo "$passed_ret $passed_cmd" >>"$passed"
}

ci-fail()
{
  failed_cmd="$_" failed_ret=$?
  test $# -eq 0 || failed_cmd="$1"
  test -f "${failed:-}" || return 97
  echo "$failed_ret $failed_cmd" >>"$failed"
}

# TODO: manage TAP reports
ci_test()
{
  local out
  out="${B:?}/reports/$SUITE/$(for t in "${@:?}";do basename "$t" .bats;done|tr '\n' '-'|sed 's/-$//').tap"

  { bats "$@" || r=$?
  } | {
    test ${verbosity:-4} -ge 5 && {
      tee $out
    } || {
      cat - > $out
    }
  }
  return $?
}

ci_test_negative()
{
  local r= out
  out="$B/reports/$SUITE/$(for t in "$@";do basename "$t" .bats;done|tr '\n' '-'|sed 's/-$//').tap"
  test ! -e "$out" || return 97
# TODO: check for failure of all tests, not just one or a couple.
# TODO: check for expected failure(s)

  { bats "$@" || r=$?
  } | {
    test ${verbosity:-4} -ge 5 && {
      tee $out
    } || {
      cat - > $out
    }
  }

  $ggrep -qi '^NOT OK ' "$out" &&
    $ggrep -qvi '^OK ' "$out"
}

# Id: user-scripts/0.0.2-dev tools/ci/parts/std-ci-helper.sh
