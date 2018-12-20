#!/bin/ash

# Simple from-github provisioning script for user-script repos

# TODO: list versions/tags per supportlib or checkout latest tag


update_supportlib()
{
  test -n "$1" || set -- "master" "$2"
  test -n "$2" || set -- "$1" "origin"
  git fetch --all && git fetch --tags && git reset --hard $2/$1
}


list_supportlibs()
{

  #echo user-tools/user-scripts
  echo user-tools/user-scripts-incubator
  #echo user-tools/user-conf

  echo bvberkum/script-mpe
  echo bvberkum/user-scripts
  echo bvberkum/user-scripts-incubator
  echo bvberkum/user-conf
  echo bvberkum/script-mpe

  echo ztombol/bats-file
  echo ztombol/bats-support
  echo ztombol/bats-assert

}


test -d "$VND_GH_SRC" -a -w "$VND_GH_SRC" ||
  $LOG error ci:install "Writable Github vendor dir expected" "$VND_GH_SRC" 1


list_supportlibs | while read supportlib
do

  ns_name="$(dirname "$supportlib")"
  test -d "$VND_GH_SRC/$ns_name" || mkdir -p "$VND_GH_SRC/$ns_name"

  # Create clone at path, check for Git dir to not be fooled by any cache/mount
  test -e "$VND_GH_SRC/$supportlib/.git" || {

    test ! -e "$VND_GH_SRC/$supportlib" || rm -rf "$VND_GH_SRC/$supportlib"
    git clone https://github.com/$supportlib "$VND_GH_SRC/$supportlib"
  }

  cd "$VND_GH_SRC/$supportlib" && update_supportlib
done
