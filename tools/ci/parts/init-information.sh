#!/usr/bin/env bash

export ci_init_ts=$($gdate +"%s.%N")
ci_stages="$ci_stages ci_init"

ci_announce 'Finished CI setup'
echo "Terminal: $TERM"
echo "Shell: $SHELL"
echo "Shell-Options: $-"
echo "Shell-Level: $SHLVL"
echo
( . /etc/os-release
  echo "OS: $NAME/$VERSION"
)
echo "User: $(whoami)/${USER:-} ($(groups)) $(id -u):$(id -g)"
echo "Host: $(hostname -f)/${HOST:-}"
echo "UName: $(uname -a)"
echo
echo "Travis Branch: ${TRAVIS_BRANCH:-}"
echo "Travis Commit: ${TRAVIS_COMMIT:-}"
echo "Travis Commit Range: ${TRAVIS_COMMIT_RANGE:-}"
echo
test -n "${BUILD_ID:-}" && {
  echo "Session ID: $SESSION_ID" # Set on CI start, not before
  echo "Build ID: $BUILD_ID"
  echo "Job NR: $JOB_NR"
  echo "Job ID: $JOB_ID"
  echo
}
echo "User-Scripts: ${U_S:-}"
echo "Script-Path: ${SCRIPTPATH:-}"
echo "Script-Name: ${scriptname:-}"
echo "Verbosity: ${verbosity:-}"
echo "Log: ${LOG:-}"
echo "Init-Log: ${INIT_LOG:-}"
echo "Color-Scheme: ${CS:-}"
echo "Debug: ${DEBUG:-}"
echo "Src-Prefix: ${SRC_PREFIX:-}"
echo "Vnd-Src-Prefix: $VND_SRC_PREFIX"
echo "Vnd-Gh-Src: $VND_GH_SRC"
echo "Scm-Vnd: $SCM_VND"
echo "Keep-Going: '${keep_going:-}'"
echo "Lib-Loaded: '${lib_loaded:-}'"
echo "User-Scripts version: $( cd $U_S && git describe --always )" # No-Sync
echo
ci_announce 'Listing user checkouts'
u-s user-repos

echo
$INIT_LOG note "" "ci/parts/init Done"

ci_announce 'Starting build'
# Id: user-script/ tools/ci/parts/init.sh
