#!/usr/bin/env bash
# CI suite stage 6a. See .travis.yml
set -eu
export_stage success && announce_stage

#sh_include publish-docker-hub # Docker hub upload

close_stage
set +eu
# Sync: U-S:
