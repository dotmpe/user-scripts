#!/bin/sh

{ cat <<EOM
export TERM=xterm-256color
export U_S=\$PWD
export ENV_DEV=1
export SCRIPT_SHELL=bash
export CS=dark
export STATUSDIR_ROOT=$HOME/.local/share/statusdir/
export U_S=$HOME/project
export PATH=\$PATH:\$U_S/src/sh/lib:\$U_S/src/bash/lib:\$U_S/commands:\$U_S/contexts
EOM
} >| ~/.profile

{ cat <<EOM
. ~/.profile

. \${U_S:?}/tools/sh/parts/fnmatch.sh
. \${U_S:?}/tools/sh/parts/sh-mode.sh
#sh_mode build
sh_mode strict dev log-init
EOM
} >| ./.test-env.sh

echo "Tools CI setup script done" >&2
# Id: U-S
