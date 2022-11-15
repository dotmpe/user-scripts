build__lib_load ()
{
  return 0

  build_install_parts \
      concat-rules .list "&build-rules"
}

build___if__lines ()
{
  sh_mode strict dev build

  p="${BUILD_TARGET:${#BUILD_SPEC}}"
  p="${p:1}"

  build-stamp <<< "$(grep -Ev '^\s*\(#.*|\s*)$' "${p:?}")"
  $LOG info ":if:lines" "File lines check done" "$p"
}
