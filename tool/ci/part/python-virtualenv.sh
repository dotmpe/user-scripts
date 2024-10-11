#!/usr/bin/env bash

ctx_if @PythonEnv@Build || return 0

test -n "${ci_parts_pyvenv:-}" || {
  ci_parts_pyvenv=0

  { test "${SHIPPABLE:-}" = true || { python -c 'import sys;
  if not hasattr(sys, "real_prefix"): sys.exit(1)' >/dev/null 2>&1; }
  } && {

    $INIT_LOG info "tools/ci/env" "Using existing Python virtualenv"
  } || {

    test -d ~/.pyvenv/htd -a -e ~/.pyvenv/htd/bin/activate || {
      virtualenv ~/.pyvenv/htd || return
    }

    . ~/.pyvenv/htd/bin/activate || {
      $INIT_LOG error "tools/ci/env" "Error in Py venv setup ($?)" "" 1
    }
  }

  ci_parts_pyvenv=1
}

#
