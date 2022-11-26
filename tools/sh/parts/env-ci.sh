#!/usr/bin/env bash

: "${ci_stages:=}"
: "${stages_done:=}"

: "${BRANCH_NAME:="${TRAVIS_BRANCH-}"}"
: "${BRANCH_NAME:="$(git rev-parse --abbrev-ref HEAD)"}" # NOTE: may report HEAD in detached state

test -n "${TRAVIS_TIMER_START_TIME:-}" || {
  true "${gdate:=date}"
  : "${TRAVIS_TIMER_START_TIME:=$(${gdate:?} +%s%N)}"
}

travis_ci_timer_ts=$(echo "${TRAVIS_TIMER_START_TIME:?}"|sed 's/\([0-9]\{9\}\)$/.\1/')

true "${SESSION_ID:="$(uuidgen)"}"
: "${TRAVIS_BRANCH:=${BRANCH_NAME:?}}"
: "${TRAVIS_JOB_ID:=}"
: "${TRAVIS_JOB_NUMBER:=}"
: "${TRAVIS_BUILD_ID:=${SESSION_ID:?}}"
: "${GIT_COMMIT:="$(git rev-parse HEAD)"}"
: "${TRAVIS_COMMIT:="$GIT_COMMIT"}"
: "${TRAVIS_COMMIT_RANGE:="$COMMIT_RANGE"}"
: "${BUILD:=".build"}" ; B=$BUILD
: "${JOB_NR:=$TRAVIS_JOB_NUMBER}"
: "${JOB_ID:=$TRAVIS_JOB_ID}"
BUILD_ID=${TRAVIS_BUILD_ID:-$SESSION_ID}

: "${SHIPPABLE:=}"

: "${USER:="`whoami`"}"

: "${U_S:="$HOME/.basher/cellar/packages/dotmpe/user-scripts"}"
: "${u_s_version:="feature/docker-ci"}"
: "${package_build_tool:="redo"}"
: "${sh_tools:="$CWD/tools/sh"}"
: "${ci_tools:="$CWD/tools/ci"}"
# XXX: rename or reserve or something
: "${script_util:="$sh_tools"}"
export scriptname=${scriptname:-"`basename -- "$0"`"}

: "${verbosity:=4}"
: "${LOG:="$CWD/tools/sh/log.sh"}"
: "${INIT_LOG:=$LOG}"

# Sync: U-S:
