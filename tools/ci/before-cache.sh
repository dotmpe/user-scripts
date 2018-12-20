#!/bin/sh

export_stage before-cache before_cache && announce_stage
rm -f $HOME/.cache/pip/log/debug.log

. $ci_util/deinit.sh
