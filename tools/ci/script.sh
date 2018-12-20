#!/bin/ash
# See .travis.yml


# FIXME: script & build, actual project lib testing


# Smoke run everything with make
  #- make test/baseline/realpath.tap
  #- make base
  #- make lint
  #- make units
  #- make specs


# Cleanup and run again wtih redo
  #- git clean -dfx test/
  #- redo


export_stage script && announce_stage

announce 'Check project commit'

. $PWD/tools/git-hooks/pre-commit || print_red "ci:script" git:hook:$?

announce 'Check project baseline'

bats test/baseline/1-shell.bats || print_red "" shell
bats test/baseline/2-bash.bats || print_red "" bash
bats test/baseline/3-project.bats || print_red "" project
scriptpath= SCRIPTPATH= bats test/baseline/4-mainlibs.bats ||
  print_red "" mainlibs

bats test/baseline/bats.bats ||
  print_red "" bats

scriptpath= SCRIPTPATH= bats test/baseline/{realpath,git,redo}*.bats ||
  print_red "" others

exit $?

#scriptpath= SCRIPTPATH= bats test/unit/{os,lib,logger}*bats
#scriptpath= SCRIPTPATH= bats test/unit/{sys,shell,str,date}*bats
#scriptpath= SCRIPTPATH= bats test/unit/*bats
#scriptpath= SCRIPTPATH= bats test/spec/*bats

# OK, fire it up
announce 'Running user-script init.sh helpers'
./tools/sh/init-here.sh "" "" "" "echo foo"
. ./tools/sh/init.sh
exit $?

# Again
./tools/sh/init-here.sh "" "" "" "echo foo"

# More
mkdir -vp $HOME/build/user-tools/my-new-project
cd $HOME/build/user-tools/my-new-project

git init
. $U_S/tools/sh/init-from.sh
find ./ -not -path '*.git*'
git status

# Return for lib smoketesting
cd $HOME/build/bvberkum/user-scripts

sh ./sh-init-here
#lib_load script logger str logger-std
#lib_load env-d build user-env make mkvar
#lib_load build package build-test
#lib_init

announce "OK"


# XXX: . $ci_util/deinit.sh
