
# Local build routines for +U-s


build__lib_load ()
{
  return 0

  build_install_parts \
      concat-rules .list "&build-rules"
}


# Psuedo-target so that we can invoke redo (with options) but make it act like
# redo-ifchange (which does not accept options).
build___if__ ()
{
  build___if_change__ "$@"
}

# :if:% pseudo-target
build___if___ ()
{
  build___if_change___ "$@"
}

# Same as build :if but when other :if:* rules might match as well use this
# :if:change psuedo-target handler instead.
build___if_change__ ()
{
  sh_mode strict dev build

  declare p
  p="${BUILD_TARGET:${#BUILD_SPEC}}"
  build-ifchange "$p" &&
  summary
}

# :if:change:% pseudo-target
build___if_change___ ()
{
  sh_mode strict dev build

  declare p
  p="${BUILD_TARGET:$(( ${#BUILD_SPEC} - 1 ))}"
  build-ifchange "$p" &&
  summary
}

# Pseudo-target: depend on file targets, but validate on content lines
# (excluding blank lines and comments)
build___if__lines__ ()
{
  sh_mode strict dev build

  declare p
  p="${BUILD_TARGET:${#BUILD_SPEC}}"
  build-ifchange "$p"
  build-stamp <<< "$(grep -Ev '^\s*\(#.*|\s*)$' "${p:?}")"
  $LOG info ":if:lines" "File lines check done" "$p"
}

# Pseudo-target: depend on certain function typeset. To invalidate without
# having prerequisites of its own, it uses build-always.
# See always if:scr-fun for a better alt.
build___if__fun__ ()
{
  sh_mode strict dev build

  declare p
  p="${BUILD_TARGET:${#BUILD_SPEC}}"
  typeset -f "$p" | build-stamp
  build-always
  $LOG info ":if:fun" "Function check done" "$p"
}

# Pseudo-target: depend on file and function typeset. This does not source
# anything, but allows to generate targets to check certain function definitions
# without using build-always.
build___if__scr_fun__ ()
{
  sh_mode strict dev build

  declare s f
  s="${BUILD_TARGET:${#BUILD_SPEC}}"
  f="${s//*:}"
  s="${s//:*}"

  build-ifchange :if:lines:$s || return
  typeset -f "$f" | build-stamp
  $LOG info ":if:fun" "Script function check done" "$s:$f"
}

build___if__line_col1__ ()
{
  sh_mode strict dev build
  build-ifchange :if:scr-fun:build-lib.sh:build___if__line_col1__ || return

  declare s file key
  s="${BUILD_TARGET:${#BUILD_SPEC}}"
  file="${s//*:}"
  # Key may contain any number of colons
  key="${s:0:$(( ${#s} - ${#file} - 1 ))}"

  build-ifchange "$file"
  build-stamp <<< "$(grep "^$key " "$file")"

  $LOG info ":if:line-col1" "File line-key check done" "$key:$file"
}

summary ()
{
  declare r=$? ; test $r != 0 || r=
  stderr_ "Build ${r:-ok}${r:+not ok}, $(wc -l <<< "$(redo-sources)") source(s) and $(wc -l <<< "$(redo-targets)") target(s)" $r
}

# Id: User-Scripts/ build-lib.sh  ex:ft=bash:
