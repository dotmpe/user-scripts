#!/usr/bin/env bash
# See .travis.yml

export VND_SRC_PREFIX=$HOME/build
: "${DEBUG:=""}"
: "${CWD:="$PWD"}"

set -euo pipefail

export scriptname=U-s

ci_cleanup()
{
  echo '------ Exited' >&2
  test "$USER" = "travis" &&
    sleep 2 # Allow for buffers to clear
  sync
}

trap ci_cleanup EXIT

: "${script_util:="$CWD/tools/sh"}"
: "${ci_util:="$CWD/tools/ci"}"
init_sh_boot=null

# Get checkouts, tool installs and rebuild env (PATH etc.)
$script_util/parts/init.sh init-deps dependencies.txt

echo "Sourcing env (I)... <${BASH_ENV:-} $CWD $PWD>" >&2
. "${ci_util}/env.sh" || echo "Ignored: ERR:$?" >&2
ci_stages="$ci_stages ci_env_1 sh_env_1"
ci_env_1_ts=$ci_env_ts sh_env_1_ts=$sh_env_ts sh_env_1_end_ts=$sh_env_end_ts

export_stage before-install before_install && announce_stage

. "$ci_util/parts/announce.sh"

# FIXME: replace ./install-dependencies.sh basher
#./install-dependencies.sh test bats-force-local

test "$USER" = "travis" || sudo=sudo
${sudo} gem install travis

# FIXME: merge gh-pages into master
#bundle install

# FIXME:
npm install parse-torrent lodash

# FIXME:
#htd install json-spec

#pip uninstall -qy docopt || true

# XXX: enter lock files back into cache
for x in composer.lock .Gemfile.lock
do
  test -e $x || continue
  rsync -avzui $x .htd/$x
done

# Update PIP stops the yamme.. chattiness.
test "$(whoami)" = "travis" || {
  pip install -q --upgrade pip
}

#pip install -q keyring requests_oauthlib
#pip install -q gtasks

#test -x "$(which tap-json)" || npm install -g tap-json
#test -x "$(which any-json)" || npm install -g any-json
#npm install nano

. "$ci_util/parts/init-shippable-ci-packages.sh"
#. "$ci_util/parts/init-shippable-ci-cpan.sh"

# Sanity check that Travis-Commit matches actual checkout to catch setup fail
. "$ci_util/parts/check-git.sh"

echo Starting baseline check >&2
scriptname=sh-main:baseline ./sh-main spec sh-baseline.tab '*' &&
  echo "Baseline check OK" >&2 || echo "Baseline check fail $?" >&2

# End with some settings and listings for current env.
. "$ci_util/parts/init-information.sh"

stage_id=before_install close_stage
set +u
# Id: /0.0 tools/ci/before-install.sh
