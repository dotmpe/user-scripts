#!/bin/sh

{ cat <<EOM
export TERM=xterm-256color
export U_S=\$PWD
export ENV_DEV=1
export SCRIPT_SHELL=bash
export CS=dark
EOM
} > ~/.profile

{ cat <<EOM
. ~/.profile
set -euTEo pipefail
#shopt -s extdebug
#. ./script/bash-uc.lib.sh
#trap bash_uc_errexit ERR
EOM
} > test-env.sh

# Id: U-S
