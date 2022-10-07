#!/usr/bin/env bash

build_lib_load ()
{
  true "${PROJECT_CACHE:="$PWD/.meta/cache"}"

  test -n "${sh_file_exts-}" || sh_file_exts=".sh .bash"

  # Not sure what shells to restrict to, so setting it very liberal
  test -n "${sh_shebang_re-}" || sh_shebang_re='^\#\!\/bin\/.*sh\>'
}

build_lib_init () # sh:no-stat: OIl has trouble parsing heredoc
{
  build_define_with_package || return

  lib_require argv date match $BUILD_TOOL || return

  build_define_commands || return

  #build_init env_lookup components

  # List of targets for build tool
  test -n "${BUILD_RULES-}" || {
    true "${COMPONENTS_TXT:="$(PWD=$CWD out_fmt=one cwd_lookup_path build-rules.txt .build-rules.txt)"}"

    BUILD_RULES=$COMPONENTS_TXT
  }

  # Toggle or alternate target for build tool to build build-rules.txt
  #test -n "${BUILD_RULES_BUILD-}" ||
  #  BUILD_RULES_BUILD=${COMPONENTS_TXT_BUILD:-"1"}

  true "${COMPONENT_TARGETS:="$PROJECT_CACHE/component-targets.list"}"

  # Targets for CI jobs
  test -n "${build_txt-}" || build_txt="${BUILD_TXT:-"build.txt"}"

  test -n "${dependencies_txt-}" || dependencies_txt="${DEPENDENCIES_TXT:-"dependencies.txt"}"
}

build ()
{
  command "${BUILD_TOOL:?}" "$@"
}

# Cache part files of current build-env profile
build_add_cache ()
{
  BUILD_ENV_CACHE="${BUILD_ENV_CACHE:-}${BUILD_ENV_CACHE:+ }${1:?}"
}

# Exported functions that are part of the build-env profile
build_add_handler ()
{
  BUILD_ENV_FUN=${BUILD_ENV_FUN:-}${BUILD_ENV_FUN:+ }${1:?}
}

# Variables defined by the current build-env
build_add_setting ()
{
  BUILD_ENV_DEP=${BUILD_ENV_DEP:-}${BUILD_ENV_DEP:+ }${1:?}
}

# Sources from which the current build-env was assembled
build_add_source ()
{
  BUILD_ENV_SRC="${BUILD_ENV_SRC:-}${BUILD_ENV_SRC:+ }${1:?}"
}

build_boot () # ~ <Tags...>
{
  test $# -gt 0 || set -- redo-
  build_add_source BUILD_ENV_BOOT
  local tag
  while test $# -gt 0
  do
    test "$(type -t build_define__${1//-/_})" = "function" && {
      build_define__${1//-/_} || return
    }
    build_add_handler build_init__${1//-/_}
    BUILD_ENV_BOOT="${BUILD_ENV_BOOT:-}${BUILD_ENV_BOOT:+ }${1:?}"
    shift
  done &&
  build_env &&
  for tag in $BUILD_ENV_BOOT
  do
    echo "build_init__${tag//-/_}"
  done
}

build_boot_for_target () # ~ <Target>
{
  # TODO: per-target boot tags
  build_boot redo-
}

# Alias target: defer to other targets
build_component__alias () # <Name> <Targets...>
{
  shift
  #shellcheck disable=SC2046
  set -- $(eval "echo $*")
  # XXX: not sure if this can something with spaces/other special characters
  # properly. May be test such later...
  #eval "set -- $(echo $* | lines_printf '"%s"')"
  build-ifchange "$@"
}

# Defer to script: build a (single) target using a source script that can build multiple targets
build_component__defer () # ~ <Target-Name> <Part-Name>
{
  local part
  part=$(sh_lookup "$2" $build_parts_bases )
  source "$part"
}

# Almost like alias, except this expands strings containing shell expressions.
# These can be brace-expansions, variables or even subcommands.
build_component__expand () # ~ <Target-Name> <Target-Expressions...>
{
  shift
  build-ifchange $(eval "echo $*")
}

#
build_component__expand_all () # ~ <Target-Name> <Source-Command...> -- <Target-Formats...>
{
  local source_cmd=
  shift

  while argv_has_next "$@"
  do source_cmd="$source_cmd $1";
    shift
  done
  argv_is_seq "$@" || return
  shift

  build-ifchange $( $source_cmd | while read nameparts
    do
      for fmt in "$@"
      do
        eval "echo $( expand_format "$fmt" $nameparts )"
      done
    done )
}

# Function target: invoke function with build-args.
# If function is '-' then it is set to `mkvid build_$BUILD_TARGET`. A special
# case is made for '*' type, which is identical to '-' but uses  BUILD_NAME_NS
# instead of the target name. These functions can use BUILD_NAME_PARTS to
# access the rest of the name.
#
# To specify a sh lib to load both lib-require and lib-path must be available.
#
# The final sequence is passed as arguments to the handler.
build_component__function () # ~ <Target> [<Function>] [<Lib>] [<Args>]
{
  local libs name=${1:?} func=${2:--}
  shift 2
  test "${func:-"-"}" != "*" ||
    func="build__$(mkvid "$BUILD_NAME_NS" && printf -- "$vid")"

  test "${func:-"-"}" != "-" ||
    func="build_$(mkvid "$name" && printf -- "$vid")"

  test $# -eq 0 || {
    test -z "$1" -o "$1" = "--" || {
      build-ifchange "$(lib_path "$1" || return)" &&
      lib_require "$1" || return
    }
    shift
  }
  $func "$@"
}

# Symlinks: create each dest, linking to srcs
build_component__symlinks () # ~ <Target-Name> <Source-Glob> <Target-Format>
{
  local src match dest grep="$(glob_spec_grep "$2")" f
  ${quiet:-false} || f=-v

  shopt -s nullglob
  for src in $2
  do
    dest=$(eval "echo \"$(
        expand_format "$3" "$(echo "$src" | sed 's/'"$grep"'/\1/g' )" || return
      )\"")

    test ! -e "$dest" -o -h "$dest" || {
      $LOG "" "File exists and is not a symlink" "$dest"; return 1
    }
    test -h "$dest" && {
      test "$src" = "$(readlink "$dest")" || rm ${f-} "$dest" >&2
    }
    test -h "$dest" || {
      test -d "$(dirname "$dest")" || mkdir ${f-} "$(dirname "$dest")" >&2
      ln ${f:-"-"}s "$src" "$dest" >&2
    }
  done
  shopt -u nullglob
}

# Simpleglob: defer to target paths obtained by expanding source-spec
#build_component_glob () # ~ <Name> <Target-Pattern> <Source-Globs...>
build_component__simpleglob () # ~ <Target-Name> <Target-Spec> <Source-Spec>
{
  local src match glob=$(echo "$3" | sed 's/%/*/')
  build-ifchange $( for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$2" | sed 's/\*/'"$match"'/'
    done )
}

# XXX: would need to expand all rules
build_component_exists () # ~ <Target-name>
{
  false
}

build_component_types ()
{
  compgen -A function | grep '^build_component__' | cut -c 18- | tr '_' '-'
}

# XXX: The build target arguments $1,$2,$3 are
# stored in BUILD_TARGET{,_{BASE,TMP}} so they are accessible by the recipe as
# well.

# Get directive line from build-rules based on name, and invoke
# build-component--* handler based on build rule type.
#
# Specs are read as-is except for whitespace and brace-expansions, and passed
# as arguments to the handler function.
# Any other sort of expansion (shell variables, file glob and other patterns)
# are left completely to the build-component-* handler.
#
# The directive line selection is based on grep, so any name pattern can be
# given to invoke a certain handler function for target names that follow a
# certain pattern (such as files or URI). This function by default selects
# an exact name, but it will always escape '/' so it can accept path names
# but it does not escape '.' or special regex meta characters.
build_components () # ~ <Name>
{
  local comptab
  comptab=$(build_rule_fetch "${1:?}") &&
    test -n "$comptab" || {
      error "No such component '$1" ; return 1
    }
  $LOG "note" "" "Building component for target" "${1:?}"

  local name="${1:?}" name_ type_
  shift
  read_data name_ type_ args_ <<<"$comptab"
  test -n "$type_" || {
    error "Empty directive for component '$name" ; return 1
  }

  # Rules have to expand globs by themselves.
  set -o noglob; set -- $name_ $args_; set +o noglob
  $LOG "info" "" "Building as '$type_:$name_' component" "$*"
  build_component__${type_//-/_} "$@"
}

build_define_commands ()
{
  local var=${BUILD_TOOL}_commands cmd
  test -n "${!var-}" || {
    $LOG error "" "No build tool commands" "$BUILD_TOOL" 1
    return
  }
  for name in ${!var-}
  do
    cmd="build${name:${#BUILD_TOOL}}"
    eval "$(cat <<EOM
$cmd ()
{
  $name "\$@"
}
EOM
    )"
  done
}

build_define_with_package ()
{
  true "${BUILD_TOOL:=${package_build_tool:?}}"

  #true "${init_sh_libs:="os sys str match log shell script ${BUILD_TOOL:?} build"}"

  true "${build_parts_bases:="$(for base in ${!package_tools_redo_parts_bases__*}; do eval "echo ${!base}"; done )"}"
  true "${build_parts_bases:="${UCONF:?}/tools/redo/parts ${HOME:?}/bin/tools/redo/parts ${U_S:?}/tools/redo/parts"}"
  true "${build_main_targets:="${package_tools_redo_targets_main-"all help build test"}"}"
  true "${build_all_targets:="${package_tools_redo_targets_all-"build test"}"}"
}


# The build env takes care of bootstrapping the profile using a selected set
# of resolvers.
build_env () # ~ [<Handler-tags...>]
{
  #env_amend build "$@"
  ENV_START=$(date --iso=ns)
  BUILD_ENV_ARGS="$*"
  true "${ENV_BOOT_DEF:=$PWD/.meta/cache/env.sh}"
  test -e "${ENV_BOOT:-$ENV_BOOT_DEF}" && {
    true "${ENV_BOOT:=$ENV_BOOT_DEF}"
    . "$ENV_BOOT" || return
  } || {
    build_lib_load || return
  }
  build_env_init || return
  test "${1:-}" != all || shift
  test $# -gt 0 || set -- ${BUILD_ENV_DEF:-attributes rule-params}
  local tag cache
  for tag in "$@"
  do
    build_env__${tag//-/_} || continue #return
  done
  for tag in \
    ENV_START BUILD_ENV_ARGS ENV_BOOT_DEF ENV_BOOT BUILD_ENV_DEF \
    BUILD_ENV_CACHE $BUILD_ENV_DEP BUILD_ENV_SRC
  do
    echo "$tag=\"${!tag-null}\""
  done
  for tag in $BUILD_ENV_FUN
  do
    #typeset "$tag"
    type "$tag" | tail -n +2
  done
  for cache in $BUILD_ENV_CACHE
  do
    echo "# Build env cache: $cache"
    cat "$cache"
  done
  echo "# Build env OK: '$*' completed"
  echo "ENV_AT=\"$(date --iso=ns)\""
}

build_env_rule_exists ()
{
  local vid var val
  case "${1:?}" in
    ( "@"* )
        mkvid "${1:1}" || return
        var=build_at_${vid}_targets
      ;;
    ( * )
        mkvid "$1" || return
        var=build_${vid}_targets
      ;;
  esac
  val=${!var-}
  test -n "$val" && BUILD_RULE="$val"
}

build_env_sh ()
{
  build_env_vars | build_sh
  #build_env "$@"
  #| build_sh
}

build_sh ()
{
  while read -r vname val
  do
    val="${!vname-null}"
    printf '%s=%s\n' "$vname" "${val@Q}"
  done
}

build_env_targets ()
{
  set -o noglob; set -- ${BUILD_RULE:?}; set +o noglob
  build-ifchange "$@"
}

build_init__package ()
{
  { test -e ./.meta/package/envs/main.sh -a \
    ./.meta/package/envs/main.sh -nt package.yaml
  } || {
    htd package update && htd package write-scripts
  }
}

build_env__package ()
{
  build_add_cache ./.meta/package/envs/main.sh
}


build_define__redo_ ()
{
  build_add_handler build_part_lookup
}

build_init__redo_ ()
{
  source "${U_S:?}/src/sh/lib/build.lib.sh" &&
  source "${U_S:?}/src/sh/lib/redo.lib.sh" &&
    redo_lib_load &&
    build_lib_load &&
    build_define_commands &&
    build_define_with_package
}

build_init__redo_libs ()
{
  {
    sh_include_path_langs="redo main ci bash sh" &&
    . "${U_S:?}/tools/sh/parts/include.sh" &&
    sh_include lib-load &&
    package_build_tool=redo &&
    lib_load match redo build &&
    . "${UCONF:?}/tools/redo/env.sh"
  } || return
}

build_init__redo_env_target_ ()
{
  . "${U_S:?}/src/sh/lib/sys.lib.sh" &&
  . "$U_S/src/sh/lib/str.lib.sh"
}

build_init__redo_libs_ ()
{
  scriptname="default.do"
  . "${U_S:?}/src/sh/lib/os.lib.sh" &&
  . "$U_S/src/sh/lib/match.lib.sh" &&
  . "$U_S/tools/sh/parts/lib_util.sh" &&
  . "$U_S/src/sh/lib/lib.lib.sh" &&
  lib_lib_load && lib_lib_init &&
  test ! -e "$CWD/build-lib.sh" || {
    . "$CWD/build-lib.sh" || return
    build_add_source "$CWD/build-lib.sh"
  }
  INIT_LOG=$LOG match_lib_init
}


build_env__redo_libs ()
{
  false
}


build_env_init ()
{
  test -n "${BUILD_RULES:-}" || {
    test -e ".meta/stat/index/components-local.list" &&
      BUILD_RULES=.meta/stat/index/components-local.list
  # XXX: deprecate
    test -e ".components.txt" && BUILD_RULES=.components.txt
    test -e ".build-rules.txt" && BUILD_RULES=.build-rules.txt
  }

  test -n "${attributes:-}" || {
    test -e ".meta/attributes" && attributes=.meta/attributes
    test -e ".attributes" && attributes=.attributes
  }

  attributes_sh="${PROJECT_CACHE:?}/attributes.sh"

  build_add_setting PROJECT_CACHE
}

build_env__attributes ()
{
  test -e "${attributes:-}" || {
    $LOG info "" "No attributes" "${attributes-null}"
    return 0
  }
  build_file "$attributes_sh" "$attributes" "" \
    attributes_sh "$attributes" &&
  build_add_cache "$attributes_sh" &&
  build_add_source "$attributes" &&
  build_add_setting "attributes attributes_sh"
}

build_env__rule_params ()
{
  params_sh="${PROJECT_CACHE:?}/params.sh"
  case "${ENV:=dev}" in
    ( ${build_env_devspec:="dev*"} ) build_rules || return ;;
    ( * )
      ${quiet:-false} ||
        echo "No rules-build for non-dev: $ENV" >&2
      true "${BUILD_RULES:=${BUILD_RULES:?}}" ;;
  esac
  build_file "$params_sh" "$BUILD_RULES" "" \
    params_sh "$BUILD_RULES" &&

  build_add_cache "$params_sh" &&
  build_add_source "$BUILD_RULES" &&
  build_add_setting "BUILD_RULES params_sh"
}

# Try to give the user an informative view of current build environment.
build_env_vars ()
{
  {
    echo "${!APP*}"
    echo "${!package_*}"
    echo "${!components_*}"
    echo "${!BUILD*}"
    echo "${!build_*}"
    eval "echo \"\${!${BUILD_TOOL^^}*}\""
    eval "echo \"\${!${BUILD_TOOL}*}\""
    echo lib_loaded verbosity v
    echo "${!LIB*}"
    echo "${!ENV*}"
  } | tr ' ' '\n' | grep -v '^[ \t]*$'
}

build_fetch_component () # Path
{
  read_nix_style_file "$BUILD_RULES" |
    while read target_name type target_spec source_specs
  do
    case "$type" in

      alias | function ) ;;

      simpleglob )
          fnmatch "$target_spec" "$1" && {
            echo "$type $target_spec $source_specs"
            return
          }
        ;;

      * ) $LOG error "" "Unknown target type '$type'" "$target_name $1" 1 ;;
    esac
  done
  return 1
}

build_rule_exists () # ~ <Rule-target>
{
  grep_f=-q build_rule_fetch "$@"
}

build_rule_fetch () # ~ <Rule-target>
{
  local name=${1:?} name_p
  fnmatch "*/*" "$name" && name_p="$(match_grep "$name")" || name_p="$name"
  grep ${grep_f:--m1} "^$name_p"'\($\| \)' "${BUILD_RULES:?}"
}

build_run () # ~ <Target>
{
  grep -q "^$1 " "$BUILD_RULES" && {
    build_components "$@"
    return $?
  }

  test -e "$COMPONENT_TARGETS.do" || {
    { cat <<EOM
#!/usr/bin/env bash

cd \$REDO_BASE
ENV_NAME=redo \
  . ./tools/redo/env.sh &&
  build-ifchange "\$BUILD_RULES" &&
  build_fetch_rules
EOM
    } > "$COMPONENT_TARGETS.do"
  }
  redo-ifchange "$(realpath --relative-to=$PWD "$COMPONENT_TARGETS")"

  local name
  name=$( grep -F " $1 " "$COMPONENT_TARGETS" | cut -d' ' -f1 ) && {

    case "$(grep "^$name " "$BUILD_RULES" | cut -d' ' -f2)" in
      ( simpleglob )
          build-ifchange "$1"
          return $?
        ;;
    esac
  }

  build-ifchange "$1"
}

build_fetch_alias_rules () # ~ <Group-Name> <Prerequisites...>
{
  local group="$1"
  shift
  while test $# -gt 0
  do
    echo "$group $1"
    shift
  done
}

build_fetch_expand_rules () # ~ <Group-Name> <Brace-Pattern...>
{
  local group="$1" a
  shift
  for a in $(eval "echo $*")
  do
    echo "$group $a"
  done
}

build_fetch_expand_all_rules () # ~ <Target> <Cmd...> -- <Tpl-Pattern...>
{
  local group=$1 source_cmd=
  shift

  while argv_has_next "$@"
  do source_cmd="$source_cmd $1";
    shift
  done
  argv_is_seq "$@" || return
  shift

  for a in $( $source_cmd | while read nameparts
    do
      for fmt in "$@"
      do
        eval "echo $( expand_format "$fmt" $nameparts )"
      done
    done )
  do
    echo "$group $a"
  done
}

build_fetch_function_rules () # ~ <Group-Name> <Func-Name> <Libs...>
{
  local group="$1"
  shift
  echo "$group - type:$*"
}

build_fetch_simpleglob_rules () # ~ <Group-Name> <Target-Spec> <Source-Spec>
{
  local src match glob=$(echo "$3" | sed 's/%/*/')
  for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$1 $(echo "$2" | sed 's/\*/'"$match"'/') $(echo "$glob" | sed 's/\*/'"$match"'/')"
    done
}

# Produce a list of <Group> <Target> <Sources> from c.txt
build_fetch_rules ()
{
  read_nix_style_file "$BUILD_RULES" | {
    while read name type args
    do
      set -o noglob; set -- $name $args; set +o noglob
      build_fetch_${type//-/_}_rules "$@"
    done
  }
}

build_fetch_symlinks_rules () # ~ <Group-Name> <Target-Spec> <Source-Spec>
{
  local group=$1 src match dest grep="$(glob_spec_grep "$2")" f
  ${quiet:-false} || f=-v

  shopt -s nullglob
  for src in $2
  do
    dest=$(eval "echo \"$(
        expand_format "$3" "$(echo "$src" | sed 's/'"$grep"'/\1/g' )" || return
      )\"")
    echo "$group $dest"
  done
  shopt -u nullglob
}

# Virtual target that shows various status bits about build system
build_info ()
{
  {
    echo "Package: ${package_name-null}/${package_version-null}"
    echo "Env: | "
    build_env_vars | build_sh | sed 's/^/    /'

    echo "Builder: $(${BUILD_TOOL:?} --version) ($BUILD_TOOL)"

    echo "Build rule types: "
    build_component_types | sed 's/^/  - /'

    echo "Build sources: "
    build-sources | sed 's/^/  - /'

    echo "Build targets: "
    build-targets | sed 's/^/  - /'

    echo "Build status: "
    for name in $build_main_targets
    do
      test "$name" != :info || continue
      echo "  - $name: | "
      { build-log $name 2>&1 || true
      } | sed 's/^/      /'
    done
  } >&2
}

# TODO: add TTL impl.
build_file () # ~ <File-target> <File-source> <TTL> <Command-argv...>
{
  test -e "${1:?}" && {
    test -n "${2:-}" && {
      # age1 < age2 && return
      test "$1" -nt "$2" && return
      # age1 - TTL < age2 && return
      false
    }
    test -n "${3:-}" && {
      # age1 < TTL && return
      false
    }
  }
  local dest=$1 destdir=$(dirname "$1")
  shift 3 || return
  test -d "$destdir" || mkdir -vp "$destdir" >&2
  "$@" > "$dest"
}

# Translate Lookup path element and given/local name to filesystempath,
# or return err-stat.
# Copy of lookup_exists
build_part_lookup () # NAME DIRS...
{
  local name="$1" r=1
  shift
  while test $# -gt 0
  do
    test -e "$1/$name" && {
      echo "$1/$name"
      test ${lookup_first:-1} -eq 1 && return || r=0
    }
    shift
  done
  return $r
}

build_rules ()
{
  true "${BUILD_RULES:=${package_build_rules_tab:?}}"
  test "${BUILD_RULES_BUILD:-0}" = "1" && {
    build-ifchange "$BUILD_RULES" || return
  } || {
    test "${BUILD_RULES_BUILD:-0}" = "0" || {
      BUILD_RULES=${BUILD_RULES_BUILD:?}
      build-ifchange "$BUILD_RULES" || return
    }
  }
}

# TODO: can use build-ifchange to add dependencies for target, also add
# build-stamp on only the rule part for given target.
build_rules_for_target () # ~ <Name> <Basename> <Tempfile>
{
  build_rules &&

  # Redo only has REDO_TARGET, but not the basename or temporary file in env.
  BUILD_TARGET=$1
  BUILD_TARGET_BASE=$2
  BUILD_TARGET_TMP=$3

  true "${BUILD_NAME_SEPS:=":"}"

  # Split function type directives with specific name pattern on first
  # colon, and use that as prefix to find a build rule for this group of
  # targets that can be handled with one generic build handler.

  # FIXME: handle root (empty initial name part) properly
  local nsep
  for nsep in $BUILD_NAME_SEPS
  do
    fnmatch "$nsep*$nsep*" "$1" && {
      set -- "${1#:*}"
      BUILD_NAME_NS=${1//$nsep*}
      set -- "$nsep$BUILD_NAME_NS$nsep"
      BUILD_NAME_PARTS=${BUILD_TARGET:${#1}}
      set -- "$1[^ ]*"
    } || true
  done

  test "$1" != "${BUILD_RULES-}" -a -s "${BUILD_RULES-}" || {
    # Prevent redo self.id != src.id assertion failure
    $LOG alert ":build-component:$1" \
      "Cannot build rules table from empty table" "${BUILD_RULES-null}" 1
    return
  }

  # Shortcut execution for simple aliases, but takes literal values only
  { build_init__redo_env_target_ || return
  } >&2
  build_env_rule_exists "$1" && {
    build_env_targets
    exit
  }

  # Run build based on matching rule in BUID_RULES table

  build_rule_exists "$1" || {
    #print_err "error" "" "Unknown target, see '$BUILD_TOOL help'" "$1"
    $LOG "error" "" "Unknown target, see '$BUILD_TOOL help'" "$1" $?
    return
  }

  $LOG "notice" ":exists:$1" "Found build rule for target" "$1"
  { build_init__redo_libs_ "$1" || return
  } >&2
  build_components "$1" || return

  # Add dependency on
  build_rule_fetch "$1" | build-stamp
}

# TODO: virtual target to build components-txt table, and to generate rules for
# every record.
build_table_for_targets () # ~ <>
{
  false
}


# Return first globbed part, given glob pattern and expanded path.
# Returned part is everything matched from first to last wildcard glob,
# so this works on globstar and to a degree with multiple wildcards.
glob_spec_var () # ~ <Pattern> <Path>
{
  set -- "$@" "$(glob_spec_grep "$1")"
  echo "$2" | sed 's/'"$3"'/\1/g'
}

glob_spec_grep ()
{
  # Escape all special regex characters, then turn glob in there into
  # a match group. Multiple globs turn into one group as well, including string
  # parts in between.
  match_grep "$1" | sed 's/\*\(.*\*\)\?/\(\.\*\\)/'
}

list_src_files () # Generator Newer-Than Magic-Regex [Extensions-or-Globs...]
{
  local generator="${1:-"vc_tracked"}" nt=${2:-} mrx=${3:-}
  shift 3
  { test $generator = - || $generator; } | while read -r path ; do

# Cant do anything with dirs or empty files
    test ! -d "$path" -a -s "$path" || continue

# Allow for faster updates by checking only changed files
    test -z "$nt" || {
        test "$path" -nt $nt || continue
    }

# Scan name extension or glob match first
    test $# -eq 0 || {
        local m
        for m in "$@"
        do
            test ${m:0:1} != . || m="*$m"
            fnmatch "$m" "$path" || continue
            echo "$path"
            continue 2
        done
        continue
    }

# Or grep for sha-bang pattern
    test -z "$mrx" || {
      head -n1 "$path" | grep -qm 1 $mrx || continue
    }
    echo "$path"
  done
}

# List any /bin/*sh or non-empty .sh/.bash file, from everything checked into SCM
list_sh_files () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" "$sh_shebang_re" $sh_file_exts
}

list_lib_sh_files () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" "" ".lib.sh"
}

list_executables () # _ [Newer-Than]
{
  list_src_files find_executables "${2-}" ""
}

find_executables ()
{
  find . -executable -type f | cut -c3-
}

list_scripts () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" '^\#\!'
}

build_chatty () # Level
{
  test ${quiet:-$(test $verbosity -lt ${1:-3} && printf true || printf false )} -eq 0
}

build_copy_changed ()
{
  { test -e "$2" && diff -bqr "$1" "$2" >/dev/null
  } || {
    cp "$1" "$2"
    echo "Updated <$2>" >&2
  }
}

expand_format () # ~ <Format> <Name-Parts>
{
  local format="$1"
  shift
  for part in "$@"
  do
    case "$format" in
      *'%*'* ) echo "$format" | sed 's#%\*#'"$part"'#g' ;;
      *'%_'* ) mkvid "$part"; echo "$format" | sed 's/%_/'"$vid"'/g' ;;
      *'%-'* ) mksid "$part"; echo "$format" | sed 's/%-/'"$sid"'/g' ;;
      * ) return 98 ;;
    esac
  done
}

attributes_sh ()
{
  grep -Ev '^\s*(#.*|\s*)$' "$@" |
  awk '{ st = index($0,":") ;
      key = substr($0,0,st-1) ;
      gsub(/[^A-Za-z0-9]/,"_",key) ;
      print toupper(key) "=\"" substr($0,st+2) "\"" }'
}

params_sh ()
{
  grep -Po '^#  *@\K[A-Za-z_-][A-Za-z0-9/\\_-]*: .*' "$@" |
  awk '{ st = index($0,":") ;
      key = substr($0,0,st-1) ;
      gsub(/[^A-Za-z0-9_]/,"_",key) ;
      print "build_" key "_targets=\"" substr($0,st+2) "\"" }'
}

fnmatch ()
{
    case "$2" in
        $1)
            return 0
        ;;
        *)
            return 1
        ;;
    esac
}

# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test.
match_grep() # String
{
  echo "$1" | $gsed -E 's/([^A-Za-z0-9{}(),?!@+_])/\\\1/g'
}


test -n "${__lib_load-}" || {

  case "${build_entry_point:-$(basename -- "$0" .lib.sh )}" in

    ( "build-" )
        true "${quiet:=true}"
        subcmd=${1:?}
        shift
        build_"${subcmd//-/_}" "$@" || exit
      ;;

    ( "build" )
        . "${U_S}/tools/redo/env.sh" || { r=$?
          test $r = 96 && {
            echo "E$r: Env recursion?" >&2
          }
          exit $r
        }

        test $# -gt 0 || set -- $build_all_targets
        while test $# -gt 0
        do
          build_run "$@" || {
            $LOG error "$1" "" "E:$?"
            exit 1
          }
          shift
        done
      ;;

    ( * ) ;;
  esac
}
#
