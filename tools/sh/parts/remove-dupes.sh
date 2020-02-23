# Sort into lookup table (with Awk) to remove duplicate lines
remove-dupes() # ~
{
  awk '!a[$0]++'
}

# XXX: move to env init: expand_aliases
shopt -s expand_aliases
type remove_dupes || alias remove_dupes=remove-dupes # FIXME: load proper file
# Id: U-S:tools/sh/parts/remove-dupes.sh                           vim:ft=bash:
