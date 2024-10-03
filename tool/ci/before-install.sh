#!/usr/bin/env bash

# CI suite stage 1.

SCRIPTPATH="$PWD/src/sh/lib:$PWD/commands:$PWD/contexts"

. ${PWD}/tools/sh/init-include.sh

ci_env_= . "./tools/ci/env.sh"

echo "Sourcing $SUITE env (I) <$CWD, $ci_tools>" >&2

# Save times of first env.sh source, because it re-evaluate after stage install
ci_stages="$ci_stages sh_env_1 ci_env_1"
ci_env_1_ts=$ci_env_ts
sh_env_1_ts=$sh_env_ts
sh_env_1_end_ts=$sh_env_end_ts
ci_env_1_end_ts=$ci_env_end_ts

# Set timestamps for each stage start/end XXX: and stack
export_stage before-install before_install && announce_stage

$LOG note "" "Sourcing init parts" "$(suite_from_table "$build_txt" Parts $SUITE 1 | tr '\n' ' ')"
suite_source "$build_txt" $SUITE 1
test $SKIP_CI -eq 0 || {
    $LOG "warn" "" "Abort requested by SKIP-CI"
    exit 0
}

stage_id=before_install close_stage
# Id: /0.0 tools/ci/before-install.sh
