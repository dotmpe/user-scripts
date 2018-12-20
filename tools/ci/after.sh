#!/bin/sh
export_stage after && announce_stage
  #- . ./tools/ci/parts/after.sh
  #- . ./tools/ci/parts/publish.sh
announce "End of $scriptname"
echo Done
. $ci_util/deinit.sh
