sh_mode dev strict


# Some targets need to re-run after the filetree changes.

# XXX: try to use git index as trigger
true "${GITDIR:=$(git rev-parse --git-dir)}"
build-ifchange "${GITDIR:?}/index"
