#!/usr/bin/env bash

ctx_if @GitHub@Build || return 0

test -n "${GITHUB_TOKEN:-}" || {
  . ~/.local/etc/profile.d/github-user-scripts.sh || exit 101
}
