#!/usr/bin/env bash

#lib_load build
test/lint.sh all
test/unit.sh all
test/spec.sh all
