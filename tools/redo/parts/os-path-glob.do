## Generic recipe to check for changes in directory listing (2)

# The output cannot be stored, but the target is used as a 'find . -ipath'
# expression to list files beneath the REDO_STARTDIR.

# This recipe is always executed, because I do not know of another validator.

sh_mode strict dev build

build_alias_part

build-always

declare index
index=$(find . -ipath "./${1}" ) || return
build-stamp <<< "$index"

$LOG info ":os-path-glob" "Path glob check done" "$1"
