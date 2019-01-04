#!/bin/ash

export ci_init_ts=$($gdate +"%s.%N")
ci_stages="$ci_stages ci_init"


$LOG note "" "Entry for CI pre-install / init phase"

$LOG note "" "PWD: $(pwd && pwd -P)"
$LOG note "" "Whoami: $( whoami )"
$LOG note "" "CI Env:"
{ env | grep -i 'shippable\|travis\|ci' | sed 's/^/	/' >&2; } || true


#. "$ci_util/parts/check-git.sh"
$LOG note "" "GIT version: $GIT_DESCRIBE"
ci_announce '---------- Finished CI setup'
echo "Terminal: $TERM"
echo "Shell: $SHELL"
echo "Shell-Options: $-"
echo "Shell-Level: $SHLVL"
echo
echo "Travis Branch: $TRAVIS_BRANCH"
echo "Travis Commit: $TRAVIS_COMMIT"
echo "Travis Commit Range: $TRAVIS_COMMIT_RANGE"
# TODO: gitflow comparison/merge base
#vcflow-upstreams $TRAVIS_BRANCH
# set env and output warning if we're behind
#vcflow-downstreams
# similar.
echo
echo "User Conf: $(cd ~/.conf 2>/dev/null && git describe --always)" || true
echo "User Composer: $(cd ~/.local/composer 2>/dev/null && git describe --always)" || true
echo "User Bin: $(cd ~/bin 2>/dev/null && git describe --always)" || true
echo "User static lib: $(find ~/lib 2>/dev/null)" || true
echo
echo "Script-Path:"
echo "$SCRIPTPATH" | tr ':' '\n'
echo "Script-Name: $scriptname"
echo "Verbosity: $verbosity"
echo "Color-Scheme: $CS"
echo "Debug: $DEBUG"
echo "Src-Prefix: $SRC_PREFIX"
echo "Vnd-Src-Prefix: $VND_SRC_PREFIX"
echo "Vnd-Gh-Prefix: $VND_GH_PREFIX"
echo
ci_announce '---------- Listing user checkouts'
./bin/u-s user-repos
echo
$LOG note "" "ci/parts/init Done"
ci_announce '---------- Starting build'
# From: script-mpe/0.0.4-dev tools/ci/parts/init.sh
