#!/usr/bin/env bash

# Initialize for ``sh-include PART..``

true "${U_S:="/srv/project-local/user-scripts"}"

. "$U_S/tools/sh/parts/fnmatch.sh"
. "$U_S/tools/sh/parts/include.sh"
. "$U_S/tools/ci/parts/print-err.sh"

# Id: U-s:tools/sh/init-include.sh
