
### Local build routines for +U-s

# normally compiled into bootstrap/default.do


build__lib_load ()
{
  return 0

  build_install_parts \
      concat-rules .list "&build-rules"
}


build__all ()
{
  ${BUILD_TOOL:?}-always && build_targets_ ${build_all_targets:?}
}

build__build_env ()
{
  ctx=ENV=${ENV:-}:${XDG_SESSION_TYPE:-}:${UC_PROFILE_TP:-}:@${HOST:-}+${HOSTTYPE:-}
  build-stamp <<< "$ctx"
  $LOG warn ":(@build-env)" Finished "$ctx+v=${v:-}"
}

build__usage_help ()
{
  ${BUILD_TOOL:?}-always
  echo "Usage: ${BUILD_TOOL-(BUILD_TOOL unset)} [${build_main_targets// /|}]" >&2
  echo "Default target (all): ${build_all_targets-(unset)}" >&2
  echo "Version: ${APP-(APP unset)}" >&2
  echo "Env: ${ENV-(unset)}" >&2
  echo "Build env: ${BUILD_ENV-(unset)}" >&2
  echo "For more complete listings of profile, sources and targets see '${BUILD_TOOL:?} -- -info'" >&2
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
  sh_mode strict dev

  declare p
  p="${BUILD_TARGET:${#BUILD_SPEC}}"
  build-ifchange "$p" ; build_summary
}

# :if:change:% pseudo-target
build___if_change___ ()
{
  sh_mode strict dev

  declare p
  p="${BUILD_TARGET:$(( ${#BUILD_SPEC} - 1 ))}"
  build-ifchange "$p" ; build_summary
}

# Source-dev: helper to reduce large source sets based on not-index @dev.
# XXX: Targets not present in index are ignored.
# If the target is listed, it must have @dev tag to be listed by this target.
build____meta_cache_source_dev_list ()
{
  false
}

build__meta_cache_source_dev_list ()
{
  sh_mode strict dev
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
  sh_mode strict dev
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
