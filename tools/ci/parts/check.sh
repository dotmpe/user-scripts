#!/bin/sh

export ci_check_ts=$($gdate +"%s.%N")

# entry-point for CI pre-test phase, to do preflight checks, some verbose debugging
$LOG note "" "Entry for CI pre-test / check phase"
$LOG note "$scriptname:$stage:check" "Done"
# From: script-mpe/0.0.4-dev tools/ci/parts/check.sh
