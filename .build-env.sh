sh_mode strict build

true "${SUITE:="Main"}"
#true "${BUILD_ENV:=stderr_ build-rules build-lib rule-params from-dist argv}"
#true "${BUILD_ENV_STATIC:=log-key build-env-cache}"

true "${PROJECT_CACHE:=".meta/cache"}"
true "${BUILD_RULES_BUILD:="${PROJECT_CACHE:?}/build-rules.list"}"
true "${BUILD_RULES:=".meta/stat/index/build-rules-us.list"}"
#true "${BUILD_ENV_STATIC:=build-boot}"
#true "${BUILD_TARGET_METHODS:=env}"
BUILD_ENV="build-rules rule-params stderr- argv"
true "${redo_opts:="-j4"}"

# XXX: for part:.meta/cache/components.list
BUILD_ENV_FUN=build_copy_changed


export verbosity="${verbosity:=${v:-4}}"
$LOG info ":U-s:Build:env" "Starting..." "v=$verbosity"
