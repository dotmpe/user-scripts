#!/bin/sh

export_stage install && announce_stage

# Call for dev setup, see +U_s
$script_util/parts/init.sh all

# Give private user-script repoo its place
# TODO: test user-scripts instead/also +U_s +script_mpe
test -d $HOME/bin/.git || {
  test "$USER" = "travis" || return 100

  rm -rf $HOME/bin || true
  ln -s $HOME/build/bvberkum/script-mpe $HOME/bin
}


ci_announce "Sourcing env (II)..."
unset SCRIPTPATH ci_env_ sh_env_ sh_util_ ci_util_
. "${BASH_ENV:="$CWD/tools/ci/env.sh"}"


#set +o nounset
. "./tools/sh/init.sh"


close_stage

. "$ci_util/deinit.sh"
