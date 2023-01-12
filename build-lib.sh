
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

# U-S:shlibs-list
us_shlibs_list ()
{
  build-ifchange ${PROJECT_CACHE:?}/sh-libs.list &&
  cut -d ' ' -f 4 ${PROJECT_CACHE:?}/sh-libs.list | while read -r p
  do
    basename "$p" .lib.sh
  done
}

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

# U-S:build-target:from: index-tagged <Tag> [ <Array> | <Source-lists...> ] -- <Indices...>
#
# For every (content) line of all Source-lists, an entry must exist in any of
# the indices.
# Source-lists can be empty, to use DEPS (from 'if' rule handler) or but also
# another array name to use those as input values.
# XXX: the problem is while this accepts multiple index files, it does not know
# where to look, so it checks all and also when it does the source path has to
# be verbatim. Should want more direction and use of patterns or groups
# somehow.
# XXX: what about default tags value
#
build_target__from__index_tagged () # ~ <Tag> [ <Array> | <Source-lists...> ] -- <Indices...>
{
  sh_mode strict dev
  local self="build-target:from:index-tagged" stdp tag=${1:?} srca
  stdp="! $0: $self"
  shift

}

#
build_target__seq__list_filter () # ~ <Function> [ <Source-arr> | <Source-lists...> ] [ -- <Filter-args...> [ -- <Rule...> ] ]
{
  sh_mode strict dev
  local self="build-target:from:list-filter" ffun=${1:?}
  shift
  build-ifchange \
    :if-scr-fun:${U_S:?}/build-lib.sh:build_target__seq__list_filter \

  # Use array name if given, or array 'DEPS' if empty source-sequence is passed.
  argv_is_seq "${1:?}" && {
    srca=DEPS
  } || {
    ! fnmatch "*a*" "$(declare -p "${1:?}")" || {
      srca=$1
      shift
    }
  }
  test -n "${srca:-}" && {
    argv_is_seq "${1:?}" || {
      $LOG error :$self "Only one array for source argument expected"
      return 1
    }
    # Resolve given array entries to filepaths if symbols are given
    build_fsym_arr ${srca:?} sourcelists || {
      stderr_ "$stdp: build-fsym-arr $srca sourcelists: E$?" $? || return
    }
  } || {
    # Resolve sources to filepath when symbols are given
    build_file_arr SREFS sourcelists "$@" || {
      stderr_ "$stdp: build-file-arr REFS sourcelists: E$?" $? || return
    }
    test 0 -lt ${#sourcelists[*]} || {
      stderr_ "$stdp: Expected source list(s)" || return
    }
    shift ${#SREFS[@]} || return
  }
  test "${1:?}" = -- && shift || return

  # Read next sequence as argument for filter, and call function or command
  build_arr_seq FILTERARG "$@" || return
  shift "${#FILTERARG[*]}" || return
  filtered=$($ffun "${FILTERARG[@]}") || return

  test $# -gt 1 -a "${1:-}" = -- && {
    test -z "$filtered" &&
      declare -ga FILTERED=() || read -a FILTERED <<< "$filtered"
    shift
    build_target_rule "$@"
  } || {
    test -z "$filtered" || echo "$filtered"
  }
}

filter_by_manifest () # ~ <Tag> <Indices...>
{
  local tag=${1:?}
  shift
  # Resolve index files if symbols are given
  build_file_arr IREFS indices "$@" || {
    stderr_ "$stdp: build-file-arr IREFS indices: E$?" $? || return
  }
  test 0 -lt ${#indices[*]} || {
    stderr_ "$stdp: Expected index file(s)" || return
  }
  shift ${#IREFS[@]} || return
  ! argv_trail_seq "$@" || shift
  test $# -eq 0 || {
    $LOG error ":$self" "Surplus arguments in rule" "$*"
  }

  # Re-run if function or any listings or indices change
  build-ifchange \
    :if-scr-fun:${U_S:?}/build-lib.sh:filter_by_manifest \
    "${indices[@]}" || return

  $LOG notice ":$self" "Starting filter"
  declare list src idx count=0
  for list in "${sourcelists[@]}"
  do while read -r src
    do
      entry= found=false
      for idx in "${indices[@]}"
      do
        ! entry=$(grep -F "$src: " "$idx") || break
      done
      test -n "$entry" -o -n "${index_tagged_default:-}" || {
        #$LOG warn ":$self" "ignored unindexed" "$src"
        continue
      }
      # TODO: clean up by tags, start by selecting everything with dev
      echo "${entry:-"$src: $index_tagged_default"}" |
      grep -q " $tag\\($\\| \\)" || {
        #$LOG warn :$self "ignored non-dev" "$src"
        continue
      }
      count=$(( count + 1 ))
      echo "$src"
    done < "$list"
  done
  test $count -gt 0 &&
    $LOG notice ":$self($BUILD_TARGET)" "Filter done" "$count" ||
    $LOG warn ":$self($BUILD_TARGET)" "No entries"
}


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
