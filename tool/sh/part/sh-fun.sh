
sh_fun ()
{
  declare -F "${1:?}" 2>/dev/null >&2
}

# Id: U-S:sh-fun
