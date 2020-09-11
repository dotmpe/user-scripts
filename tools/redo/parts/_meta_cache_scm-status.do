#!/usr/bin/env bash
set -euo pipefail

redo-ifchange "$REDO_BASE/.git/index" "$REDO_BASE/.git/HEAD"

# TODO: generate proper SCM status
{ git describe --always && git status | md5sum - ; } >"$3"

redo-stamp <"$3"
