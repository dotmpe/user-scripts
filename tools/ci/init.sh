#!/usr/bin/env bash

set -o pipefail
set -o errexit
#!/bin/sh
# See .travis.yml

set -e

echo '---------- Check for sane GIT state'

GIT_COMMIT="$(git rev-parse HEAD)"
test "$GIT_COMMIT" = "$TRAVIS_COMMIT" || {

  # For Sanity: Travis won't complain if you accidentally
  # cache the checkout, but this should:
  git reset --hard $TRAVIS_COMMIT || {
    echo '---------- git reset:'
    env | grep -i Travis
    git status
    $LOG error ci:build "Unexpected checkout $GIT_COMMIT" "" 1
    return 1
  }
}



echo '---------- Starting build'
echo "Travis Branch: $TRAVIS_BRANCH"
echo "Travis Commit: $TRAVIS_COMMIT"
echo "Travis Commit Range: $TRAVIS_COMMIT_RANGE"
