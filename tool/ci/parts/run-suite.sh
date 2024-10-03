run_suite () # Run init, check, baselines or other part ~ Table Suite Prefix
{
  test $# -ge 2 || return 98
  local parts= tab="$1" suite="$2" ; shift 2
  test -n "$tab" || tab=build.txt
  head -n 1 "$tab" | grep -q "\<$suite\>" || return 97

  test $# -gt 0 && for phase in $@
  do
# XXX: cleanup
    stage=$suite.$phase
#    c_run=suite_run c_lbl="$stage" c-run "$tab" "$suite" "$phase"
    suite_run "$tab" "$suite" $phase || return

  done ||
    suite_run "$tab" "$suite" $phase
}

# Id: U-S:tools/ci/parts/run-suite.sh                              ex:ft=bash:
