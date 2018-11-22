#!/usr/bin/env bash

export uname=${uname:-$(uname -s)}
export LOG=${LOG:-logger_log}

case "$uname" in
  Darwin )  export gdate=gdate gsed=gsed ggrep=ggrep ;;
  Linux )   export gdate=date gsed=sed ggrep=grep ;;
esac

case "$PATH" in
  *"$HOME/.basher/"* ) ;;
  * ) export PATH=$HOME/.basher/bin:$HOME/.basher/cellar/bin:$PATH ;;
esac
