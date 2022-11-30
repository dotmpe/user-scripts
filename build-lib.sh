
### Local build routines for +U-s

# normally compiled into bootstrap/default.do


build__lib_load ()
{
  return 0

  build_install_parts \
      concat-rules .list "&build-rules"
}



## Util.


#assert_base_dir ()
assert_base_dir ()
{
  test_same_dir "$PWD" "$REDO_BASE"
}

#assert_start_dir ()
assert_start_dir ()
{
  test_same_dir "$PWD" "$REDO_STARTDIR"
}


#build_summary ()
build_summary ()
{
  declare r=$? sc tc ; test $r != 0 || r=
  sc=$(wc -l <<< "$(redo-sources)")
  tc=$(wc -l <<< "$(redo-targets)")
  stderr_ "Build ${r:+not ok: E}${r:-ok}, $sc source(s) and $tc target(s)" "${r:-0}"
}

#test_same_dir () # ~ <Dir-path-1> <Dir-path-2>
test_same_dir () # ~ <Dir-path-1> <Dir-path-2>
{
  test "$(realpath "${1:?}")" = "$(realpath "${2:?}")"
}



## Target handlers


#build__all ()
# 'all' default impl.
build__all ()
{
  ${BUILD_TOOL:?}-always && build_targets_ ${build_all_targets:?}
}

#build__build_env ()
# '@build-env' finished handler with info
build__build_env ()
{
  ctx=ENV=${ENV:-}:${XDG_SESSION_TYPE:-}:${UC_PROFILE_TP:-}:@${HOST:-}+${HOSTTYPE:-}
  build-stamp <<< "$ctx"
  $LOG warn ":(@build-env)" Finished "$ctx+v=${v:-}"
}

#build__meta_cache_source_dev_list ()
#
# XXX: it would be nice to have a build-if that returns non-zero if nothing was
# changed. Not sure if that is possible, many targets may still run but the
# conclusion may be that nothing had to be done.
# So, for example for configuration nothing needs to be reloaded.
# Of course can always build a target to do it...

# Source-dev: helper to reduce large source sets based on not-index @dev.
# XXX: Targets not present in index are ignored.
# If the target is listed, it must have @dev tag to be listed by this target.
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

#build__meta_cache_source_dev_sh_list ()
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

#build__usage_help ()
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


# Id: User-Scripts/ build-lib.sh  ex:ft=bash:
