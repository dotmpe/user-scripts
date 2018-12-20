#!/bin/ash
# See .travis.yml

# FIXME: script & build, actual project lib testing
export_stage script && announce_stage
. $PWD/tools/git-hooks/pre-commit || print_red "ci:script" git:hook:$?

export_stage build && announce_stage
. ./tools/ci/build.sh || print_red "ci:script" build:$?

# Smoke run everything with make
  #- make test/baseline/realpath.tap
  #- make base
  #- make lint
  #- make units
  #- make specs

# Cleanup and run again wtih redo
  #- git clean -dfx test/
  #- redo

# XXX: . $ci_util/deinit.sh
