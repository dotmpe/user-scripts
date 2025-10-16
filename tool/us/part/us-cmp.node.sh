#!/usr/bin/env bash

# Compiled routines for us-cmp

uc_cmp ()
{
  local ns_here=$FUNCNAME ctx=${ENV_CTX:-[$$/$0]} lk=${lk:+$lk:$FUNCNAME}
  local ENV_CTX=$ctx
  : "${lk:=$(sh_call_context)}"
  : input "${*:?$FUNCNAME: Command args undefined, $ctx:$lk}"
  case "${1:?}" in

  ( :draft )
      TODO
    ;;

  ( :revise )
      TODO
    ;;

  ( :commit )
      TODO
    ;;

  ( :metafor )
      : param ':0 ~~ <To-var> <Key> [<Mode>] ...'
      : input ${2:?$FUNCNAME:$1: Destination variable, $ENV_CTX}
      : input ${3:?$FUNCNAME:$1:$2: Field name, $ENV_CTX}
      uc_cmp :metafor+${4:-one} ${2} "${3}"
}

