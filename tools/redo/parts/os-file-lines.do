
sh_mode strict dev build

build_alias_part

build-stamp <<< "$(grep -Ev '^\s*\(#.*|\s*)$' "${1:?}")"

$LOG info ":os-file-lines" "File lines check done" "$1"
