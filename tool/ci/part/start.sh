#!/usr/bin/env bash

ci_announce "Starting CI session <$SUITE, $B>"

mkdir -p $B/reports/{Sh,CI,Main,Test}
export verbosity SUITE BUILD B

true "${SESSION_ID:="$(uuidgen)"}"
tmpf="$TMPDIR/sh-$SUITE-run-$SESSION_ID"

export passed="$tmpf.passed"
echo "# Status Command-Spec">"$passed"
export failed="$tmpf.failed"
echo "# Status Command-Spec">"$failed"
$LOG note "" "Started reporter session at" "$tmpf"

unset tmpf
