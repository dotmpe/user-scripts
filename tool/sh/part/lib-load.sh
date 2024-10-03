#!/usr/bin/env bash

test -z "${DEBUG:-}" || {
  set -x || true;
}

. "$U_S/tools/sh/init.sh" || return

test -z "${DEBUG:-}" || {
  set +x || true;
}

# Id: tools/sh/parts/lib-load.sh
