#!/usr/bin/env bash

## A basic main project redo script (root default.do) deriving from +U-s std.do @dev

# Created: 2022-11-30


# First remove settings from file so they don't affect all builds.

# FIXME: using .build-static.sh for now @dev @env-build
. ./.build-static.sh >&2 || exit $?

for BUILD_SEED in \
  ${REDO_STARTDIR:?}/.env.sh \
  ${REDO_STARTDIR:?}/.build-env.sh
do
  test ! -e "${BUILD_SEED:?}" && continue
  . "${BUILD_SEED:?}" >&2 || exit $?
done

# Now start standardized redo for build.lib
. "${UCONF:?}/tools/redo/local.do"

# Derive: Us:tools/redo/std.do
# Id: Us:tools/redo/derive-dev.do                                  ex:ft=bash:
