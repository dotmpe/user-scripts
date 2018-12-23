#!/bin/sh

export_stage install && announce_stage



# Call for dev setup
$script_util/parts/init.sh all

test -d $HOME/bin/.git || {
  rm -rf $HOME/bin || true
  ln -s $HOME/build/bvberkum/script-mpe $HOME/bin
}


sudo ln -s $HOME /srv/home-local


# TODO: see +Us Call for dev setup
$script_util/parts/init.sh all || true

announce "Sourcing env (II)..."
unset SCRIPTPATH
. "${BASH_ENV:="$PWD/tools/ci/env.sh"}"


#set +o nounset
. "./tools/sh/init.sh"


close_stage

. "$ci_util/deinit.sh"
