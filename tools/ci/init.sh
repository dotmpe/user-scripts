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



echo '---------- Finished CI setup'
echo "Travis Branch: $TRAVIS_BRANCH"
echo "Travis Commit: $TRAVIS_COMMIT"
echo "Travis Commit Range: $TRAVIS_COMMIT_RANGE"
# TODO: gitflow comparison/merge base
#vcflow-upstreams $TRAVIS_BRANCH
# set env and output warning if we're behind
#vcflow-downstreams
# similar.
echo
echo "User Conf: $(cd ~/.conf && git describe --always)" || true
echo "User Composer: $(cd ~/.local/composer && git describe --always)" || true
echo "User Bin: $(cd ~/bin && git describe --always)" || true
echo "User static lib: $(find ~/lib )" || true
echo
echo '---------- Listing user checkouts'
for x in $HOME/build/*/
do
    test -e $x/.git && {
        echo "$x at GIT $( cd $x && git describe --always )"
        continue

    } || {
        for y in $x/*/
        do
            test -e $y/.git &&
                echo "$y at GIT $( cd $y && git describe --always )" ||
                echo "Unkown $y"
        done
    }
done
echo
echo '---------- Starting build'
