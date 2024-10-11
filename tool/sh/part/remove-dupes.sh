# Sort into lookup table (with Awk) to remove duplicate lines
# Removes duplicate lines (unlike uniq -u) without sorting.
remove_dupes () # ~
{
  awk '!a[$0]++'
}

# Id: U-S:tool/sh/parts/remove-dupes.sh                           vim:ft=bash:
