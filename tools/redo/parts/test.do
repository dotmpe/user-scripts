#!/usr/bin/env bash

build-always &&
build-ifchange .meta/cache/components.list &&
build-ifchange bats-baseline bats-unit
#
