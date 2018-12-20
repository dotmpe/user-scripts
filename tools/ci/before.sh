#!/bin/ash
# See .travis.yml

export_stage before-script before_script && announce_stage

. $ci_util/deinit.sh
