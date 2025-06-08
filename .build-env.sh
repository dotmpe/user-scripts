# Build properties. See .package.sh for main project data/settings, and
# README for main version, BUILD_RULES file.

#sh_mode strict dev build

: "${SUITE:="Main"}"

: "${PROJECT_CACHE:=".meta/cache"}"
: "${BUILD_RULES_BUILD:="${PROJECT_CACHE:?}/build-rules.list"}"
: "${BUILD_RULES:=".meta/stat/index/build-rules-us.list"}"
# New format in-line with stattab
: "${BUILD_TARGETS:=".meta/stat/index/build-targets-us.list"}"
#: "${BUILD_ENV_STATIC:=build-boot}"
#: "${BUILD_TARGET_METHODS:=env context}"
BUILD_ENV="build-rules rule-params from-local stderr- argv"
#: "${BUILD_ENV:=stderr_ build-rules build-lib rule-params from-dist args}"
#: "${BUILD_ENV_STATIC:=log-key build-env-cache}"
#BUILD_UNRECURSE=true
: "${redo_opts:="-j4 --debug-pids"}"

# XXX: for part:.meta/cache/components.list
BUILD_ENV_FUN=build_copy_changed

: "${EWD:=$REDO_STARTDIR}"
: "${METADIR:=$EWD/.meta}"
: "${LCACHE:=$METADIR/cache}"

# Virtual ref for build root
: "${XREDO_GLOBAL:=@}"
: "${XREDO_BUILD:=${XREDO_GLOBAL}build:/}"
: "${XREDO_DATA:=$METADIR/build}"
: "${XREDO_CACHE:=$METADIR/build/cache}"

# Aliases
: "${A:=$XREDO_GLOBAL}"
: "${At_Build:=$XREDO_BUILD}"
: "${B:=$XREDO_DATA}"
: "${C:=$XREDO_CACHE}"

export verbosity="${verbosity:=${v:-4}}"

# Id: Users-Scripts/0.0.2-dev  .build-env.sh [2022-11-29; 2018-11-18]
