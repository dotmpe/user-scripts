#!/bin/sh

. "$script_util/parts/env-init-log.sh"
. "$script_util/parts/env-ucache.sh"
. "$script_util/parts/env-scriptpath.sh"



#var_default=__value_or_eval_default
#env_default=__reg_env_or_eval_default
#$var_default env_finish __env_finish
#$var_default var_default_scriptcmd \${env_finish}
#test -n "$1" || set -- $var_default_scriptcmd



$INIT_LOG "debug" "user-env" "Script-Path:" "$SCRIPTPATH"

# Id: user-scripts/0.0.2-dev tools/sh/user-env.sh
