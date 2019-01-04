#!/usr/bin/env bash
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


set -u
export_stage script && announce_stage

./sh-main spec
#./sh-main project

# XXX: restore or move to other earlier stage
#ci_announce 'Checking project tooling, host env, 3rd party setup...'
#. ./tools/ci/parts/baseline.sh

# XXX: see +script-mpe, cleanup
failed=/tmp/htd-build-test-$(get_uuid).failed
. "./tools/ci/parts/build.sh"

#ci_announce 'Running unit tests...'
#scriptpath= SCRIPTPATH= bats test/unit/{os,lib,logger}*bats
#scriptpath= SCRIPTPATH= bats test/unit/{sys,shell,str,date}*bats
#scriptpath= SCRIPTPATH= bats test/unit/*bats

#ci_announce 'Running other specs, features etc...'
#scriptpath= SCRIPTPATH= bats test/spec/*bats

#lib_load script logger str logger-std
#lib_load env-d build user-env make mkvar
#lib_load build package build-test
#lib_init

# XXX: old shippable-CI hack
test "$SHIPPABLE" = true || test ! -e "$failed"

close_stage && ci_announce "Done"
set +u
