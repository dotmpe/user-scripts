#!/usr/bin/env bash

# XXX: $script_util/parts/init.sh all

sh_include init

init-all()
{
  init-basher || return
  check-bats
}
