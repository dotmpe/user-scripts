#!/usr/bin/env bash

test -z "${DEBUG:-}" || {
  set -x || true;
}

. "$U_S/tool/sh/init.sh" || return

test -z "${DEBUG:-}" || {
  set +x || true;
}

# Id: tool/sh/parts/lib-load.sh
