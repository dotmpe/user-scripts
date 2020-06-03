#!/bin/sh

test -z "${U_S-}" && u_s= || u_s=$U_S
test -e "${U_S-}" || US=

test -e "$U_S" || {
  test -d "$HOME/project/user-scripts/.git" &&
    U_S=$HOME/project/user-scripts
}
test -e "$U_S" || {
  test -d "/srv/project-local/user-scripts/.git" &&
    U_S=/srv/project-local/user-scripts
}
test -e "$U_S" || {
  test -d "$HOME/build/user-tools/user-scripts/.git" &&
    U_S=$HOME/build/user-tools/user-scripts
}
test -e "$U_S" || {
  test -d "$HOME/build/dotmpe/user-scripts/.git" &&
    U_S=$HOME/build/dotmpe/user-scripts
}
test -e "$U_S" || U_S=$u_s
scriptname=$scriptname:env-0-u_s scriptpid=$$ \
  $INIT_LOG "info" "" "Using U-s:" "$U_S"
unset u_s


# Id: user-scripts/  tools/sh/parts/env-0-u_s.sh
