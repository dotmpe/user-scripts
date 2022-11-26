
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
  build-ifchange "$p" ; build_summary
}

# :if:change:% pseudo-target
build___if_change___ ()
{
  sh_mode strict dev build

  declare p
  p="${BUILD_TARGET:$(( ${#BUILD_SPEC} - 1 ))}"
  build-ifchange "$p" ; build_summary
}

build___if_scr_fun ()
{
  build___if__scr_fun__
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


# Source-dev: helper to reduce large source sets based on not-index @dev.
# XXX: Targets not present in index are ignored.
# If the target is listed, it must have @dev tag to be listed by this target.
build__meta_cache_source_dev_list ()
{
  sh_mode strict dev build
  build-ifchange :if:scr-fun:build-lib.sh:build__meta_cache_source_dev_list || return
  build-ifchange "${1:?}" "$REDO_BASE/index.list" &&
  declare sym src
  sym=$(build-sym "${1:?}") &&
  while read -r src
  do
    grep -qF "$src: " "$REDO_BASE/index.list" || continue

    grep -F "$src: " "$REDO_BASE/index.list" | grep -q ' @dev' &&
      continue

    echo "$src"
  done < "$sym"
}

build__meta_cache_source_dev_sh_list ()
{
  sh_mode strict dev build
  build-ifchange :if:scr-fun:build-lib.sh:build__meta_cache_source_dev_sh_list || return
  build-ifchange "${1:?}" "$REDO_BASE/index.list" &&
  declare sym src
  sym=$(build-sym "${1:?}") &&
  while read -r src
  do
    grep -qF "$src: " "$REDO_BASE/index.list" || continue

    grep -F "$src: " "$REDO_BASE/index.list" | grep -q ' @dev' &&
      continue

    echo "$src"
  done < "$sym"
}

build_summary ()
{
  declare r=$? sc tc ; test $r != 0 || r=
  sc=$(wc -l <<< "$(redo-sources)")
  tc=$(wc -l <<< "$(redo-targets)")
  stderr_ "Build ${r:+not ok: E}${r:-ok}, $sc source(s) and $tc target(s)" "${r:-0}"
}

# Id: User-Scripts/ build-lib.sh  ex:ft=bash:
