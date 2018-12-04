#!/bin/sh

git_lib_load()
{
  test -n "$SRC_DIR" || SRC_DIR=/src
  test -n "$SCM_VND" || SCM_VND=github.com
  test -n "$VND_GH_SRC" || VND_GH_SRC=$SRC_DIR/$SCM_VND
  test -n "$GIT_SCM_SRV" || GIT_SCM_SRV=/srv/scm-git-local
  test -n "$PROJECT_DIR" || {
    test -e "/srv/project-local" &&
      PROJECT_DIR=/srv/project-local || PROJECT_DIR=$HOME/project
  }
}

git_lib_init()
{
  test -d "$SRC_DIR" &&
  test -d "$VND_GH_SRC" &&
  test -d "$GIT_SCM_SRV" &&
  test -d "$PROJECT_DIR"
}


# Checkout at $VND_GH_SRC tree, and make link to $PROJECT_DIR
git_src_get() # <user>/<repo>
{
  test -n "$1" || return

  test -e "$VND_GH_SRC/$1" || {

    note "Creating main user checkout for $1..."
    remote_name=$( get_cwd_volume_id "$SRC_DIR" )
    test -n "$remote_name" || remote_name=local

    git clone "$GIT_SCM_SRV/$1.git" "$VND_GH_SRC/$1" \
      --origin "$remote_name" --branch "$vc_br_def" || return
    ( cd  "$VND_GH_SRC/$1" &&
       git remote add "$vc_rt_def" "http://$SCM_VND/$1.git" || return
    )
  }

  name="$(basename "$1")"
  test -e "$PROJECT_DIR/$name" && {
    echo "$1: $PROJECT_DIR/$name -> $(readlink "$PROJECT_DIR/$name")"
  } || {
    test -h "$PROJECT_DIR/$name" && rm -v "$PROJECT_DIR/$name"
    ln -vs "$VND_GH_SRC/$1" "$PROJECT_DIR/$name"
  }
}

