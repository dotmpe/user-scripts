#!/usr/bin/env bash

fnmatch() { case "$2" in $1 ) return ;; * ) return 1 ;; esac; }

# Id: U-S:
