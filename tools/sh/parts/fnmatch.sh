#!/usr/bin/env bash

# fnmatch() { case "$2" in $1 ) return ;; * ) return 1 ;; esac; }

fnmatch ()
{
    case "${2:?NAME}" in
        "${1:?PATTERN}")
            return 0
        ;;
        *)
            return 1
        ;;
    esac
}

# Id: U-S:
