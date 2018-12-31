#!/usr/bin/env bash

lib_load build-test

## start with essential tests
note "Testing required specs '$REQ_SPECS'"
build_test_init "$REQ_SPECS"

# TODO: see +script_mpe

# From: script-mpe/0.0.4-dev tools/sh/build/test.sh
