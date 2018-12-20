#!/bin/ash
# See .travis.yml

export_stage script && announce_stage

. $PWD/tools/git-hooks/pre-commit

. $ci_util/deinit.sh


  - export_stage script && announce_stage
  - . ./tools/ci/build.sh
# Smoke run everything with make
  #- make test/baseline/realpath.tap
  #- make base
  #- make lint
  #- make units
  #- make specs
# Cleanup and run again wtih redo
  #- git clean -dfx test/
  #- redo

