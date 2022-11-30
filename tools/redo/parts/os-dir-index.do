## Generic recipe to check for changes in directory listing

# XXX: parameterization needs work or maybe drop function
# The script has five parameters that allow to build a simple exclusive AND
# search-query based on file or path name, as well as tree-depth. Normally
# 'find' is executed to list everything at the first level, and the results
# are not stored anywhere but checksummed to determine changes.

# To store the listing, use a filepath for the target name, in the directory to
# check. Otherwise only the directory should be provided.

# - OS Dir Index MaxDepth := 1
# - OS Dir Index {I,}Name := *
# - OS Dir Index {I,}Path := *

sh_mode strict dev

# FIXME: need to store parameters as well
build_alias_part

declare maxdepth=${OS_DIR_INDEX_MAXDEPTH:-1}
declare match=
test -z "${OS_DIR_INDEX_IPATH:-}" ||
  match=$match\ -ipath\ "${OS_DIR_INDEX_IPATH:?}"
test -z "${OS_DIR_INDEX_PATH:-}" ||
  match=$match\ -path\ "${OS_DIR_INDEX_PATH:?}"
test -z "${OS_DIR_INDEX_INAME:-}" ||
  match=$match\ -iname\ "${OS_DIR_INDEX_INAME:?}"
test -z "${OS_DIR_INDEX_NAME:-}" ||
  match=$match\ -name\ "${OS_DIR_INDEX_NAME:?}"

sh_unset_ifset \
  OS_DIR_INDEX_MAXDEPTH \
  OS_DIR_INDEX_IPATH \
  OS_DIR_INDEX_PATH \
  OS_DIR_INDEX_INAME \
  OS_DIR_INDEX_NAME

declare dir outf
test ! -e "$1" -o -d "$1" && dir=$1 || {
  dir="$(dirname "$1")" || return
  outf="$1"
}

# @dev @test
test -d "$dir" || {
  stderr_ "! os-dir-index: Expected dir path '$dir': E$?" $? || return
}
! fnmatch "/*" "$dir" || {
  stderr_ "! os-dir-index: Expected relative path '$dir'" 1 || return
}

build-always

test -z "${outf:-}" && {
  declare index
  index=$(cd "$1" && find . -maxdepth ${maxdepth:?} ${match} ) || return
  build-stamp <<< "$index"
} || {
  (cd "$dir" && find . -maxdepth ${maxdepth:?} ${match} ) >| "$3" || return
  build-stamp <<< "$3"
}

$LOG info ":os-dir-index" "Dir index check done" "$1${match}"
