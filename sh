#!/bin/sh

set -e

#scriptpath= SCRIPTPATH= bats test/baseline/mainlibs.bats
#scriptpath= SCRIPTPATH= bats test/baseline/{bash,realpath,git,bats,redo}*.bats
#scriptpath= SCRIPTPATH= bats test/unit/{os,lib,logger}*bats
#scriptpath= SCRIPTPATH= bats test/unit/{sys,shell,str,date}*bats
#scriptpath= SCRIPTPATH= bats test/unit/*bats
#scriptpath= SCRIPTPATH= bats test/spec/*bats

exec ./tools/sh/init-here.sh $HOME/bin "" "" "$(cat <<EOM

  lib_load script logger str logger-std

  lib_load env-d build user-env make mkvar

  lib_load build package build-test
  #package_init
  #build_test_init

  #env_d_boot
  #env_d_complete

  #echo "PWD" | make_op

EOM
)"
