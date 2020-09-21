# Expand to realpath if exists, remove duplicates

unique_paths () # PATHNAME...
{
  for path in "$@"
  do
    test -e "$path" && realpath "$path" || echo "$path"
  done | remove_dupes
}
# Id: U-S:tools/sh/parts/unique-paths.sh :vim:ft=bash:
