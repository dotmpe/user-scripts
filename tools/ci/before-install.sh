#!/bin/ash

export VND_SRC_PREFIX=$HOME/build
: "${CWD:="$PWD"}"

echo "Sourcing env (I)..."
. "${BASH_ENV:="$PWD/tools/ci/env.sh"}" || true


export_stage before-install before_install


# XXX: split-out sh & ci env, init and check stanza's to parts files

  # Leave loading env parts to sh/env, but sets may diverge..
  # $script_util/parts/env-*.sh
  # $ci_util/parts/env-*.sh
#script_env_init=tools/ci/parts/env.sh . ./tools/sh/env.sh

. "$ci_util/parts/announce.sh"


# Get checkouts, tool installs and rebuild env (PATH etc.)
. "$ci_util/parts/init-user-repo.sh"


test "$(whoami)" = "travis" || {
  export sudo=sudo

  test -x "$(which apt-get)" && {
    test -z "$APT_PACKAGES" ||
    {
      echo sudo=$sudo APT_PACKAGES=$APT_PACKAGES
      {
        $sudo apt-get update &&
        $sudo apt-get install $APT_PACKAGES

      } || error "Error installing APT packages" 1
    }
  }
}

# FIXME: replace ./install-dependencies.sh basher

pip uninstall -qy docopt || true
#./install-dependencies.sh test bats-force-local
for x in composer.lock .Gemfile.lock
do
  test -e $x || continue
  rsync -avzui $x .htd/$x
done


test "$(whoami)" = "travis" || {
  pip install -q --upgrade pip
}

pip install -q keyring requests_oauthlib
pip install -q gtasks

test -x "$(which tap-json)" || npm install -g tap-json
test -x "$(which any-json)" || npm install -g any-json
npm install nano

which github-release || go get github.com/aktau/github-release

test "$(whoami)" = "travis" || {
  not_falseish "$SHIPPABLE" && {
    cpan reload index
    cpan install CAPN
    cpan reload cpan
    cpan install XML::Generator
    test -x "$(which tap-to-junit-xml)" ||
      basher install jmason/tap-to-junit-xml
    tap-to-junit-xml --help || true
  }
}

gem install travis

# FIXME: merge gh-pages into master
#bundle install

# FIXME: npm install parse-torrent lodash

# FIXME: htd install json-spec


script_env_init=tools/ci/parts/env.sh . ./tools/sh/env.sh


. "$ci_util/parts/check-git.sh"


. "$ci_util/parts/init.sh"


close_stage


. "$ci_util/deinit.sh"
# Id: /0.0 tools/ci/before-install.sh
