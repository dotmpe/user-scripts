sh_mode dev build strict

build_target_reset_group

# Some targets need to re-run after the filetree changes.

# XXX: try to use git index as trigger
true "${GITDIR:=$(git rev-parse --git-dir)}"
build-ifchange "${GITDIR:?}/index"
