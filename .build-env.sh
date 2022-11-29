# Build properties. See .package.sh for main project data/settings, and
# README for main version, BUILD_RULES file.

sh_mode strict build

true "${SUITE:="Main"}"
#true "${BUILD_ENV:=stderr_ build-rules build-lib rule-params from-dist argv}"
#true "${BUILD_ENV_STATIC:=log-key build-env-cache}"

true "${PROJECT_CACHE:=".meta/cache"}"
true "${BUILD_RULES_BUILD:="${PROJECT_CACHE:?}/build-rules.list"}"
true "${BUILD_RULES:=".meta/stat/index/build-rules-us.list"}"
#true "${BUILD_ENV_STATIC:=build-boot}"
#true "${BUILD_TARGET_METHODS:=env context}"
BUILD_ENV="build-rules rule-params stderr- argv"
#BUILD_UNRECURSE=true
true "${redo_opts:="-j4 --debug-pids"}"

# XXX: for part:.meta/cache/components.list
BUILD_ENV_FUN=build_copy_changed

export verbosity="${verbosity:=${v:-4}}"
$LOG info ":U-s:Build:env" "Starting..." "v=$verbosity"

# Id: Users-Scripts/0.0.2-dev  .build-env.sh [2022-11-29; 2018-11-18]
