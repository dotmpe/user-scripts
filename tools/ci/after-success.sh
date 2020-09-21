#!/usr/bin/env bash

# CI suite stage 6a.

export_stage success && announce_stage

export BUILD_STATUS=success
sh_include publish
#sh_include publish-docker-hub # Docker hub upload

close_stage
# Id: U-S:
