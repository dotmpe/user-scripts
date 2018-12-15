#!/bin/sh
# See .travis.yml

announce 'Check project baseline'
bats test/baseline/project.bats

#./.init.sh all
scriptpath= SCRIPTPATH= bats test/baseline/mainlibs.bats

scriptpath= SCRIPTPATH= bats test/baseline/{bash,realpath,git,bats,redo}*.bats
#scriptpath= SCRIPTPATH= bats test/unit/{os,lib,logger}*bats
#scriptpath= SCRIPTPATH= bats test/unit/{sys,shell,str,date}*bats
#scriptpath= SCRIPTPATH= bats test/unit/*bats
#scriptpath= SCRIPTPATH= bats test/spec/*bats

# OK, fire it up
announce 'Running user-script init.sh helpers'
./tools/sh/init-here.sh "" "" "" "echo foo"
. ./tools/sh/init.sh

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
