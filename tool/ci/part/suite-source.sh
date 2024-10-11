#!/usr/bin/env bash

suite_source () # ~ <Tab> <Col> [<Prefix>]
{
  sh_include $( suite_from_table "$1" Parts "$2" "${3:-}" )
}
# Id: U-S:                                                         ex:ft=bash:
