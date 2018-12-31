#!/bin/ash

export VND_SRC_PREFIX=$HOME/build
: "${CWD:="$PWD"}"

echo "Sourcing env (I)... <${BASH_ENV:-} $CWD $PWD>"
: "${ci_util:="$CWD/tools/ci"}"
. "${BASH_ENV:="$PWD/tools/ci/env.sh"}" || echo "Ignored: ERR:$?"

export_stage before-install before_install


. "$ci_util/parts/announce.sh"

# Get checkouts, tool installs and rebuild env (PATH etc.)
. "$ci_util/parts/init-user-repo.sh"

. "$ci_util/parts/init-shippable-ci-packages.sh"

# FIXME: replace ./install-dependencies.sh basher

#pip uninstall -qy docopt || true
##./install-dependencies.sh test bats-force-local
#for x in composer.lock .Gemfile.lock
#do
#  test -e $x || continue
#  rsync -avzui $x .htd/$x
#done
#
#test "$(whoami)" = "travis" || {
#  pip install -q --upgrade pip
#}
#
#pip install -q keyring requests_oauthlib
#pip install -q gtasks

#test -x "$(which tap-json)" || npm install -g tap-json
#test -x "$(which any-json)" || npm install -g any-json
#npm install nano
#
#which github-release || go get github.com/aktau/github-release

. "$ci_util/parts/init-shippable-ci-cpan.sh"

#gem install travis

# FIXME: merge gh-pages into master
#bundle install

# FIXME: npm install parse-torrent lodash

# FIXME: htd install json-spec

. "$ci_util/parts/check-git.sh"

. "$ci_util/parts/init.sh"

close_stage

. "$ci_util/deinit.sh"
# Id: /0.0 tools/ci/before-install.sh
