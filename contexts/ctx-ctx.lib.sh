#!/usr/bin/env bash

ctx_lib__load ()
{
  true "${CTX:=""}"
  true "${CTX_P:=""}"
}

ctx_lib__init ()
{
  true
}

ctx_lib_import ()
{
  true
}

ctx_if_lib ()
{
  true
}

ctx_if ()
{
  fnmatch "* $1 *" " $CTX $CTX_P "
}

# Id: U-S:
