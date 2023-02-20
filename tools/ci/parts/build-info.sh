#!/usr/bin/env bash

# $B/reports/<suite>/<testgroup>.tap
du -hs $B/reports
wc -l $B/reports/*/*.tap || true
wc -l "$results_log" "$builds_log"
find ${STATUSDIR_ROOT:?} -type f || true

echo OK $( grep -i '^OK' $B/reports/*/*.tap | wc -l || true )
echo NOT OK $( grep -i '^NOT OK' $B/reports/*/*.tap | wc -l || true )

echo "Stages ($stage_cnt): $ci_stages"
echo Passed tests: $test_pass
echo Total tests: $test_cnt
echo Passed steps: $pass_cnt
echo Failed steps: $fail_cnt
echo Total steps: $step_cnt
