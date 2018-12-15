#!/bin/sh


# OS: files, paths

os_lib_load()
{
  test -n "$uname" || uname="$(uname -s)"
  test -n "$os" || os="$(uname -s | tr '[:upper:]' '[:lower:]')"

  test -n "$gsed" || case "$uname" in
      Linux ) gsed=sed ;; * ) gsed=gsed ;;
  esac
  test -n "$ggrep" || case "$uname" in
      Linux ) ggrep=grep ;; * ) ggrep=ggrep ;;
  esac
  test -n "$gdate" || case "$uname" in
      Linux ) gdate=date ;; * ) gdate=gdate ;;
  esac
  test -n "$gstat" || case "$uname" in
      Linux ) gstat=stat ;; * ) gstat=gstat ;;
  esac
}



