
### Local build routines for +U-s

# normally compiled into bootstrap/default.do


build__lib_load ()
{
  return 0

  build_install_parts \
      concat-rules .list "&build-rules"
}


. "${U_S:?}/commands/u_s-stats.lib.sh"



## Util.


# UConf: -context-filelit-env

# U-S: assert-base-dir
# Test wheter PWD equals REDO_BASE
assert_base_dir ()
{
  test_same_dir "$PWD" "$REDO_BASE"
}

# C-INC: assert-inc-dir
# Test whether PWD or given variable equals dir that is same as C_INC
# /C-INC: assert-inc-dir

# U-S: assert-pattern-spec
# There may be other patterns, this checks the prefix
assert_pattern_spec () # ~ [<Sep>] # Sanity check for BUILD-SPEC handlers
{
  fnmatch "*${1:-:}" "${BUILD_SPEC:?}" && {

    test "${BUILD_SPEC:?}" = "${BUILD_TARGET:0:${#BUILD_SPEC}}" &&
    spec="${BUILD_TARGET:${#BUILD_SPEC}}"
    return
  } || {
    $LOG error :export-group "Handle pattern mismatch" \
      "${BUILD_SPEC//%/%%}:${BUILD_TARGET//%/%%}" 1 || return
  }
}

# U-S: assert-start-dir
# Test PWD is REDO_STARTDIR
assert_start_dir ()
{
  test_same_dir "$PWD" "$REDO_STARTDIR"
}

# C-Inc: assert-sym-dir # ~ <Path> [<Target>]
# Symlink to dir or group include

# C-Inc: bats-tab
# List Bats files from SCM

# U-S: build-summary
# Count sources and targets (of entire Redo DB, not just completed targets)
build_summary ()
{
  declare r=$? sc tc ; test $r != 0 || r=
  sc=$(wc -l <<< "$(redo-sources)")
  tc=$(wc -l <<< "$(redo-targets)")
  stderr_ "Build ${r:+not ok: E}${r:-ok}, $sc source(s) and $tc target(s)" "${r:-0}"
}
# /U-S: build-summary

# UConf: debug-target
# /UConf: debug-target

# C-Inc: inc-names
# Get include filenames from &compo-index

# U-S: test-same-dir () # ~ <Dir-path-1> <Dir-path-2>
test_same_dir () # ~ <Dir-path-1> <Dir-path-2>
{
  test "$(realpath "${1:?}")" = "$(realpath "${2:?}")"
}
# /U-S: test-same-dir

# UConf-install
# /UConf-install



## Target lookup handlers


# UConf:build-target :with :context



## Rule handlers


# UConf:build :seq :if-autocatalog

# U-S:build-target:from: cache-web
build_target__from__cache_web ()
{
  local nss=${BUILD_TARGET:11} lname url scheme
  lname=${nss//:*}
  url=${nss:$(( ${#lname} + 1 ))}
  scheme=${url//:*}

  # XXX: Redo bug: '://' in the URL seems to be replaced by :/
  # probably due to some path sanitizer cleaning up the '//' sequence
  url=${scheme}://${url:$(( ${#scheme} + 2 ))}

  local pname=${PROJECT_CACHE:?}/$lname cache tmp etag
  cache="$pname.$scheme"
  tmp="$pname.tmp.$scheme"
  #etag="$pname.etag.$scheme"

  # wget saves mtime
  wget "$url" -O "$tmp" || return
  #test ! -e "$etag" -o -s "$etag" || rm "$etag"
  #test -e "$etag" && {
  #  # Make conditional request
  #  curl -SSf "$url" -o "$tmp" --etag-compare "$etag" --xattr || return
  #  # XXX
  #  test -s "$tmp" || return
  #} || {
  #  # Fetch entity
  #  curl -SSf "$url" -o "$tmp" --etag-save "$etag" --xattr || return
  #  lsattr -l "$tmp"
  #  # Etag file is empty if parsing failed
  #  test ! -e "$etag" -o -s "$etag" || rm "$etag"
  #}
  test -e "$cache" && {
    diff -bq "$tmp" "$cache" && {
      $LOG debug :cache-web "Cached web resource is up-to-date" "$nss"
      rm "$tmp"
      return
    }
  }
  mv "$tmp" "$cache"
  build-stamp <"$cache"
  $LOG notice :cache-web "Updated cached web resource" "$nss"
}
# /U-S:build-target:from: cache-web



## Target handlers


# U-S:build :all
# 'all' default impl.
build__all ()
{
  ${BUILD_TOOL:?}-always && build_targets_ ${build_all_targets:?}
}

# U-S:build :build-env
# '@build-env' finished handler with info
build__build_env ()
{
  ctx=ENV=${ENV:-}:${XDG_SESSION_TYPE:-}:${UC_PROFILE_TP:-}:@${HOST:-}+${HOSTTYPE:-}
  build-stamp <<< "$ctx"
  $LOG warn ":(@build-env)" Finished "$ctx+v=${v:-}"
}

# C-Inc:build: :check
# UConf:build: :check
# Helper to check some stuff

# UConf:build: :env:
# Target depends on env var type and value.
# /UConf:build: :env:

# C-Inc:build: :env:update-parts
# Build dynamic parts in cache and compare with copies in working tree.
# /C-Inc:build: :env:update-parts

# C-Inc:build: :export-group
# Publish functions in group to file, and rebuild if group or sources change

# C-Inc:build: :export-groups

# C-Inc:build: :if-group-includes:<group-id>
# Rebuild tree of inc typeset copies, so we can check canonical script format
# /C-Inc:build: :if-group-includes

# C-Inc:build: :index
# Check indices against computed dependency listing for each function
# /C-Inc:build: :index

# UConf:build: :install
# No-op

# UConf:build: :namespaces
# Keep user namespace tables up to date
# /UConf:build: :namespaces

# UConf:build: :shell-profile

# UConf:build: :shell-profile:<flag>
# /UConf:build: :shell-profile:

# C-Inc:build: :update-index:<...>
# Consolidate cache, see :index
# /C-Inc:build: :update-index:

# U-S:build :meta-cache-source-dev-list
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
  build-ifchange \
    :if-scr-fun:${U_S:?}/build-lib.sh:build__meta_cache_source_dev_list \
    "${2:?}" "${BUILD_BASE:?}/index.list" || return
  declare sym src
  # Get filename for list and check for antries at dev
  sym=.meta/cache/source.list
  # FIXME: sym=$(build-sym "${1:?}") &&
  while read -r src
  do
    grep -qF "$src: " "${BUILD_BASE:?}/index.list" || {
      # $LOG warn ignored unindexed
      continue
    }

    grep -F "$src: " "${BUILD_BASE:?}/index.list" | grep -vq ' @dev' && {
      # $LOG warn ignored @dev
      continue
    }

    echo "$src"
  done < "$sym"
}
# /U-S:build :meta-cache-source-dev-list

# U-S:build :meta-cache-source-dev-sh-list
build__meta_cache_source_dev_sh_list ()
{
  sh_mode strict dev
  build-ifchange \
    :if-scr-fun:${U_S:?}/build-lib.sh:build__meta_cache_source_dev_sh_list \
    "${2:?}" "$REDO_BASE/index.list" || return
  declare sym src
  sym=.meta/cache/source-sh.list
  # FIXME: sym=$(build-sym "${1:?}") &&
  while read -r src
  do
    grep -qF "$src: " "$REDO_BASE/index.list" || continue

    grep -F "$src: " "$REDO_BASE/index.list" | grep -q ' @dev' &&
      continue

    echo "$src"
  done < "$sym"
}
# /U-S:build :meta-cache-source-dev-sh-list

# U-S:build :usage-help
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
