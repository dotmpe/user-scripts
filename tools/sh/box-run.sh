#!/bin/sh
set -e

# Helper wrapper for dckr-compose scripts
# Execute from package dir to boot

test -n "$*" || exit

# XXX: run from prefix ...
scriptbase="$(dirname "$0")"
test -n "$scriptcwd" || scriptcwd="$(pwd)"
cd "$scriptbase"
rscriptbase="$(dirname "$(realpath "$0")")"
export scriptcwd scriptbase rscriptbase

__box_run_args "$@"

# Only execute known subcmd
test -e "run.d/$1.sh" -o -e "$HOME/.conf/dckr/run.d/$1.sh" || exit
export scriptcmd=$1 ; shift
test -n "$scriptname" || scriptname="$(basename "$0" .sh)"
export scriptname

# Save arguments for eval inside init-here script string below
test -z "$*" && scriptargs= ||
  scriptargs="$(for x in "$@";do printf "\"%s\" " "$x";done)"
export scriptargs
set --

# Start entrypoint for user script, in user's shell
shellname=$(basename "$SHELL")

$scriptpath/tools/$shellname/init-here.sh "$scriptbase:$rscriptbase" "$(cat <<EOM

set -e

lib_load

test ! -e ./env.sh || {
  . ./env.sh || exit \$?
}

lib_load run

test -z "\$lib_load" || {
  lib_load \$lib_load || exit \$?
}

eval set -- $scriptargs

run-scr "\$scriptcmd" "\$@"
EOM
)"
