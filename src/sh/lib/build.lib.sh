#!/usr/bin/env bash

### Build.lib: Frontends and shell toolkit for build system


build_lib_load ()
{
  true "${build_rules_defnames:=build-rules.txt .build-rules.txt .components.txt .meta/stat/index/components-local.list}"

  BUILD_SPECIAL_RE='[\+\@\:\%\&\*]'
  BUILD_VIRTUAL_RE='[\?\+-]'

  declare -g -A BUILD_NAME_SEPS=( [":"]=special ["/"]=filepath
    ["-"]=min ["+"]=plus
    ["?"]=qm
    ["&"]=amp ["@"]=at
    ["%"]=pct
    ["*"]=shexpand
  )

  #true "${BUILD_ENV_DEF:=defaults redo--}"

  test -n "${sh_file_exts-}" || sh_file_exts=".sh .bash"

  # Not sure what shells to restrict to, so setting it very liberal
  test -n "${sh_shebang_re-}" || sh_shebang_re='^\#\!\/bin\/.*sh\>'
}

build_lib_init () # sh:no-stat: OIl has trouble parsing heredoc
{
  build_env__define__from_package || return

  lib_require argv date match $BUILD_TOOL || return

  build_define_commands || return

  #build_init env_lookup components

  #build_env__define__build_rules || return

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
  BUILD_ENV_CACHE=${BUILD_ENV_CACHE:-}${BUILD_ENV_CACHE:+ }${1:?} &&
    test $# -eq 1
}

# Exported functions that are part of the build-env profile
build_add_handler ()
{
  BUILD_ENV_FUN=${BUILD_ENV_FUN:-}${BUILD_ENV_FUN:+ }${1:?} && test $# -eq 1
}

# Variables defined by the current build-env
build_add_setting ()
{
  BUILD_ENV_DEP=${BUILD_ENV_DEP:-}${BUILD_ENV_DEP:+ }${1:?} && test $# -eq 1
}

# Sources from which the current build-env was assembled
build_add_source ()
{
  BUILD_ENV_SRC="${BUILD_ENV_SRC:-}${BUILD_ENV_SRC:+ }${1:?}" && test $# -eq 1
}

# Run specs from BOOT_SPECS
build_boot () # (Build-Action) ~ <Argv...>
{
  case "${BUILD_ACTION:?}" in
    ( boot )
      ;;

    ( env )
      ;;

    ( * )
      ;;
  esac

  test $# -gt 0 || set -- ${BOOT_SPECS:?}

  local tag
  for tag in "$@"
  do
    build_env__boot__"${tag//-/_}" || return
  done
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

# Defer to script: build a (single) target using a source script. Normally,
# Redo selects nearest recipe (see redo-whichdo). This will load a 'do' part
# file with given name, or use the encoded target and lookup a *.do file
# elsewhere.
build_component__defer () # ~ <Target-name> [<Part-name>]
{
  local pn=${2:-${1:?}} part
  test -n "${2:-}" || pn="$(echo "$pn" | tr './' '_')"
  part=$( build_part_lookup "$pn.do" ${BUILD_PARTS_BASES:?} ) ||
    return ${_E_continue:-196}
  $LOG "info" ":defer:$2" "Building include" "$1"
  ${show_recipe:-false} && {
    echo "build-ifchange \"$part\""
  } || {
    build-ifchange "$part" || return
  }
  shift
  $LOG "debug" ":defer:$1" "Sourcing include" "$part"
  ${show_recipe:-false} && {
    echo "set -- \"${BUILD_TARGET:?}\" \"${BUILD_TARGET_BASE:?}\" \"${BUILD_TARGET_TMP:?}\""
    echo "source \"$part\""
  } || {
    set -- "${BUILD_TARGET:?}" "${BUILD_TARGET_BASE:?}" "${BUILD_TARGET_TMP:?}"
    source "$part"
  }
}

# Somewhat like alias, but this expands strings containing
# shell expressions.
#
# XXX: These can be brace-expansions, variables or even subshells.
build_component__expand () # ~ <Target-Name> <Target-Expressions...>
{
  shift
  build-ifchange $(eval "echo $*")
}

# XXX: Use command as output to fill single placeholder in pattern(s)
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
build_component__shlib () # ~ <Target> [<Function>] [<Libs>] [<Args>]
{
  local name=${1:?} func=${2:--}
  shift 2
  test "${func:-"-"}" != "*" ||
    func="build__$(mkvid "$BUILD_NAME_NS" && printf -- "$vid")"

  test "${func:-"-"}" != "-" ||
    func="build_$(mkvid "$name" && printf -- "$vid")"

  test $# -eq 0 || {
    set -- $(eval "echo $*")
    test -z "$1" -o "$1" = "--" || {
      build-ifchange "$(lib_path "$1" || return)" &&
      lib_require "$1" || return
    }
    shift
  }
  $func "$@"
}
build_component__function () # ~ <Target> [<Function>] [<Src...>] [<Args>]
{
  local name=${1:?} func=${2:--}
  shift 2
  test "${func:-"-"}" != "-" ||
    func="build_$(mkvid "$name" && printf -- "$vid")"

  test "${func:-"-"}" != "*" ||
    func="build_$(mkvid "$BUILD_TARGET" && printf -- "$vid")"

  test "${func:-"-"}" != ":" ||
    func="build_$(mkvid "$BUILD_TARGET_KEY" && printf -- "$vid")"

  test $# -eq 0 || {
    # XXX: function uses eval to expand vars
    set -- $(eval "echo $*")
    # FIXME: parse seq properly
    test -z "$1" -o "$1" = "--" || {
      build-ifchange "$1" &&
      source "$1" || return
    }
    shift
    test "${1:-}" != "--" || shift
  }
  $func "$@"
}

# Compose: build file from given function(s)
# TODO: as compose-names but do static analysis to resolve dependencies
build_component__compose () # ~ <Target> <Composed...>
{
  false
}

build_component__compose_names () # ~ <Target> <Composed...>
{
  shift || return ${_E_GAE:-193}
  : "${@:?"Expected one or more functions to typeset"}"
  local fun tp rs r
  for fun in "$@"
  do
    build_component__compose__resolve "$fun" || return
  done
  build-stamp < "${BUILD_TARGET_TMP:?}"
  typeset build_component__compose | build-stamp
}

build_component__compose__resolve ()
{
  # There are myriads of ways to start looking for a function definition,
  # and also to generate a typeset.

  { tp="$(type -t "${1:?}")" && test "$tp" = "function"
  } || {
    for rs in ${COMPO_RESOLVE:-tagsfile composure}
    do
      build_component__compose__resolve_function__${rs} "$1"; r=$?
      test $r -eq 0 && break ||
        test $r -eq ${_E_continue:-196} && continue
    done
    test $r -eq 0 || {
      test $r -eq ${_E_continue:-196} &&
        $LOG error "" "Failed to resolve" "$BUILD_TARGET:$1:$COMPO_RESOLVE" ||
        $LOG error "" "Error during resolve" "$BUILD_TARGET:$1"
      return $r
    }
  }
  #build_component__compose__typeset__${BUILD_COMPO_TGEN:-sh}
  $LOG info "" "Typesetting..." "$1"
  type "$1" | tail -n +2 > "${BUILD_TARGET_TMP:?}" || return
}

# TODO: look in users C_INC/which composure.sh
build_component__compose__resolve_function__composure ()
{
  return ${_E_continue:-196}
}

build_component__compose__resolve_function__tagsfile ()
{
  local tsrc
  tsrc=$(grep -m 1 "^$1"$'\t' ${TAGS:?} | awk '{print $2}') || {
    $LOG error "" "Unknown function" "$BUILD_TARGET:$1"
    return ${_E_continue:-196}
  }
  BASE=source . "$tsrc" || {
    $LOG error "" "Failed to include" "$BUILD_TARGET:$1:$tsrc" 1 || return
  }
  build-ifchange "$tsrc"
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
# XXX: this is not a simple glob but a map-path-pattern based on glob input
build_component__simpleglob () # ~ <Target-Name> <Target-Spec> <Source-Spec>
{
  local src match glob=$(echo "$3" | sed 's/%/*/')
  build-ifchange $( for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$2" | sed 's/\*/'"$match"'/'
    done )
}

# XXX: would need to expand all rules.
build_component_exists () # ~ <Target-name>
{
  false
}

build_component_types ()
{
  sh_fun_for_pref "build_component__" | cut -c 18- | tr '_' '-'
}

# Get directive line from build-rules based on name, and invoke
# build-component:* handler based on build rule type.
#
# Specs are read as-is except for whitespace and brace-expansions, and
# passed as arguments to the handler function.
# Any other sort of expansion (shell variables, file glob and other
# patterns) are left completely to the build-component:* handler.
#
# The directive line selection is based on grep, so any name pattern
# can be given to invoke a certain handler function for target names
# that follow a certain pattern (such as files or URI). This function
# by default selects an exact name, but it will always escape '/' so
# it can accept path names XXX: but it does not escape '.' or special
# regex meta characters.
build_components () # ~ <Name>
{
  local comptab
  comptab=$(build_rule_fetch "${1:?}") &&
    test -n "$comptab" || {
      error "No such component '$1" ; return 1
    }
  $LOG "note" "" "Building component '${1:?}' for target" "${BUILD_TARGET:?}"

  local name="${1:?}" name_ type_
  shift
  read_data name_ type_ args_ <<<"$comptab"
  test -n "$type_" || {
    error "Empty directive for component '$name" ; return 1
  }

  # Rules have to expand globs by themselves.
  set -o noglob; set -- $name_ $args_; set +o noglob
  $LOG "info" "" "Building as '$type_:$name_' component" "argv($#):$*"
  ${show_recipe:-false} && {
    echo "# build:rule: $name_ $type_ ( $args_ )"
    echo "set -- ${*@Q}"
    sh_fun_body build_component__${type_//-/_} | sed 's/^    //'
  } || {
    build_component__${type_//-/_} "$@"
  }
}

# Make build-* wrapper functions to actual builder
build_define_commands ()
{
  set -- $(builder_commands) || return
  local name cmd
  for name in "$@"
  do
    cmd="build${name:${#BUILD_TOOL}}"
    nameref="\${BUILD_TOOL:?}${name:${#BUILD_TOOL}}"
    sh_fun "$cmd" && {
      true
    } || {
      sh_fun "$name" && {
        eval "$(cat <<EOM
$cmd ()
{
$(sh_fun_body "$name")
}
EOM
        )"
      } || {
        eval "$(cat <<EOM
$cmd ()
{
  command "$nameref" "\$@"
}
EOM
        )"
      }
    }
  done
}

builder_commands ()
{
  local var=${BUILD_TOOL:?}_commands
  test -n "${!var-}" || {
    $LOG error "" "No build tool commands" "$BUILD_TOOL" 1
    return
  }
  echo "${!var-}"
}

# The build env takes care of bootstrapping the profile using a selected set
# of resolvers.
#
# TODO:
# The given tags are used as the initial set of build-env handlers.
# The handlers have a define and an optional build phase, and before building
# any dependent handlers will have to be defined (and build) as well.
# If there are built parts, these may need to be sourced as well before
# proceeding.
#
# The result of these handlers is a build profile with variables and script
# parts generated for a certain project folder.
# This output can be tailored for a certain start-up profile, keeping each
# build invocation as lightweight and customized as possible.
# But also provide a stepping stone to start more complicated profile boots,
# should certain targets require to do a lot of shell scripting.
# XXX: build-boot resolves parts
#
#

build_env () # ~ [<Handler-tags...>]
{
  ENV_START="$(date --iso=ns)"
  echo "ENV_START=\"\$(date --iso=ns)\""
  test $# -gt 0 || {
    set -- ${BUILD_ENV:-${BUILD_ENV_DEF:?"Missing build env"}}
  }
  # build_env__reset
  build_env__init
  local tag cache val
  for tag in "$@"
  do
    build_env__define__${tag//-/_} || return
    sh_fun build_env__build__${tag//-/_} && {
      build_env__build__${tag//-/_} || return
      # XXX: Output init/checks?
    }
    sh_fun build_env__boot__${tag//-/_} && {
      build_env__boot__${tag//-/_} || return
      build_add_handler build_env__boot__${tag//-/_}
      BOOT_SPECS="${BOOT_SPECS:-}${BOOT_SPECS:+ }$tag"
    }
    true
  done
  for tag in \
    ENV_START BUILD_ENV_ARGS BOOT_ENV_DEF BOOT_SPECS BUILD_ENV_DEF \
    BUILD_ENV_CACHE $BUILD_ENV_DEP BUILD_ENV_SRC
  do
    declare -p "$tag" 2> /dev/null || echo "$tag="
  done | sed 's/declare /declare -g /'
  for tag in $BUILD_ENV_FUN
  do
    sh_fun_type "$tag" || return
  done
  for cache in $BUILD_ENV_CACHE
  do
    echo "# Build env cache: $cache"
    cat "$cache"
  done
  echo "# Build env OK: '$*' completed"
  echo "ENV_AT=\"\$(date --iso=ns)\""
}

build_env__init ()
{
  true "${BOOT_SPECS:=}"
  true "${BUILD_ENV_CACHE:=}"
  true "${BUILD_ENV_FUN:=}"
  true "${BUILD_ENV_DEP:=}"
  true "${BUILD_ENV_SRC:=}"
  #declare -g \
  #  BOOT_SPECS= BUILD_ENV_CACHE= BUILD_ENV_FUN= BUILD_ENV_DEP= BUILD_ENV_SRC=
}

build_env__reset ()
{
  BOOT_SPECS=
  BUILD_ENV_CACHE=
  BUILD_ENV_FUN=
  BUILD_ENV_DEP=
  BUILD_ENV_SRC=
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


build_env__boot__attributes ()
{
  . "$attributes_sh"
}

build_env__boot__package ()
{
  { test -e ./.meta/package/envs/main.sh -a \
    ./.meta/package/envs/main.sh -nt package.yaml
  } || {
    htd package update && htd package write-scripts
  }
}

build_env__boot__redo_ ()
{
  source "${U_S:?}/src/sh/lib/build.lib.sh" &&
  source "${U_S:?}/src/sh/lib/redo.lib.sh" &&
    redo_lib_load &&
    build_lib_load &&
    build_define_commands
}

build_env__boot__redo_libs ()
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


build_env__boot__rule_params ()
{
  . "$params_sh"
}


build_env__build__attributes ()
{
  test -e "${attributes:-}" || {
    $LOG info "" "No attributes" "${attributes-null}"
    return 1
  }
  build_file "$attributes_sh" "$attributes" "" \
    attributes_sh "$attributes"
}

build_env__build__build_rules ()
{
  build_add_setting "BUILD_RULES"
}

build_env__build__package ()
{
  build_add_cache ./.meta/package/envs/main.sh
}

build_env__build__rule_params ()
{
  case "${ENV:=dev}" in
    ( ${build_env_devspec:="dev*"} ) build_rules || return ;;
    ( * )
        ${quiet:-false} || echo "No rules-build for non-dev: $ENV" >&2 ;;
  esac
  build_file "$params_sh" "${BUILD_RULES:?}" "" params_sh "$BUILD_RULES" &&
  build_add_cache "$params_sh" &&
  build_add_source "$BUILD_RULES" &&
  build_add_setting "BUILD_RULES params_sh"
}


build_env__define__attributes ()
{
  test -n "${attributes:-}" || {
    test -e ".meta/attributes" && attributes=.meta/attributes
    test -e ".attributes" && attributes=.attributes
  }

  attributes_sh="${PROJECT_CACHE:?}/attributes.sh"

  build_add_cache "$attributes_sh" &&
  build_add_source "$attributes" &&
  build_add_setting "attributes attributes_sh"
}

build_env__define__build_rules ()
{
  true "${BUILD_RULES:="$(PWD=$CWD out_fmt=one build_part_lookup \
      ${build_rules_defnames:?})"}"

  test -n "${BUILD_RULES:-}" || {
    test -e ".meta/stat/index/components-local.list" &&
      BUILD_RULES=.meta/stat/index/components-local.list
  }
  test -n "${BUILD_RULES:-}" || {
  # XXX: deprecate
    test -e ".components.txt" && BUILD_RULES=.components.txt
  }
  test -n "${BUILD_RULES:-}" || {
    test -e ".build-rules.txt" && BUILD_RULES=.build-rules.txt
  }
}

build_env__define__default_partsbases ()
{
  echo "$PWD"
  local pb rpwd=$(realpath "$PWD")
  for pb in ${UCONF:?} ${US_BIN:?} ${U_S:?}
  do
    test "$(realpath "$pb")" = "$rpwd" && continue
    echo "$pb"
  done
}

build_env__define__default_partsdirs ()
{
  test $# -gt 0 || set -- $(build_env__define__default_partsbases)
  local pb
  for pb in "$@"
  do
    test -d "$pb/tools/redo/parts" || continue
    echo "$pb/tools/redo/parts"
  done
}

build_env__define__defaults ()
{
  true "${UCONF:="$HOME/.conf"}"
  true "${U_S:="$HOME/project/user-scripts"}"
  true "${US_BIN:="$HOME/bin"}"

  true "${PROJECT_CACHE:=".meta/cache"}"
  build_add_setting PROJECT_CACHE

  true "${BUILD_PARTS_BASES:=$(build_env__define__default_partsdirs)}"
  true "${BUILD_TOOL:="redo"}"
  build_add_setting "BUILD_PARTS_BASES BUILD_TOOL"

  true "${build_main_targets:="all help build test"}"
  true "${build_all_targets:="build test"}"
  build_add_setting "build_main_targets build_all_targets"

  true "${quiet:=true}"
}

build_env__define__from_package ()
{
  true "${BUILD_TOOL:=${package_build_tool:?}}"
  true "${BUILD_RULES:=${package_build_rules_tab:?}}"

  #true "${init_sh_libs:="os sys str match log shell script ${BUILD_TOOL:?} build"}"

  true "${BUILD_PARTS_BASES:="$(for base in ${!package_tools_redo_parts_bases__*}; do eval "echo ${!base}"; done )"}"
  true "${build_main_targets:="${package_tools_redo_targets_main-"all help build test"}"}"
  true "${build_all_targets:="${package_tools_redo_targets_all-"build test"}"}"
  # dep package
  # vars BUILD_TOOL BUILD_PARTS_BASES BUILD_MAIN_TARGETS BUILD_ALL_TARGETS
}

build_env__define__redo_ ()
{
  build_add_handler "$(sh_fun_for_pref "build_which__")"\
" $(sh_fun_for_pref "build_target_with__")"\
" $(sh_fun_for_pref "build_for_target_with__")"\
" build_for_target build_which build_boot build_lib_load"\
" build_target build_resolver build_if"\
" build_part_lookup build_component__defer build_component__function"\
" build_rules build_components read_data sh_fun_body sh_fun_type"\
" build_env_rule_exists"\
" build_rule_exists build_rule_fetch"\
" fnmatch mkvid match_grep"\
" build_component__defer"\
" build_component__alias"
#" build_copy_changed"
}

build_env__boot__defaults ()
{
  build_lib_load
}

build_env__define__redo__ ()
{
  build_env__define__redo_ &&
  build_add_setting "BUILD_SPECIAL_RE BUILD_VIRTUAL_RE BUILD_NAME_SEPS" &&
  source "${U_S:?}/src/sh/lib/redo.lib.sh" && redo_lib_load &&
    build_define_commands || return

  local cmd
  for cmd in $(builder_commands)
  do
    build_add_handler "build${cmd:${#BUILD_TOOL}}"
  done
}

build_env__define__rule_params ()
{
  params_sh="${PROJECT_CACHE:?}/params.sh"
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

# XXX: old experiment writing real build frontend
build_run () # ~ <Target>
{
  grep -q "^$1 " "${BUILD_RULES:?}" && {
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

build_sh ()
{
  while read -r vname val
  do
    val="${!vname-null}"
    printf '%s=%s\n' "$vname" "${val@Q}"
  done
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
    while read_escaped_ name type args
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


# Show recipe commands that build-target would have executed.
# See also build-sh-for-target.
build_for_target () # TODO: show what content would have been generated
{
  show_recipe=true build_resolver \
    build_for_target_with__ ${BUILD_TARGET_METHODS:-}
}

build_for_target_with__env ()
{
  show_recipe=true build_target_with__env "$@"
}

build_for_target_with__parts ()
{
  show_recipe=true build_target_with__parts "$@"
}

build_for_target_with__rules ()
{
  show_recipe=true build_target_with__rules "$@"
}


# Helper for build-resolver handlers.
build_if () # ~ <Target...>
{
  ${inline_special:-false } && {
    $LOG error "" "TODO: inline special recipe lines"
    return 1
  } || {
    ${show_recipe:-false} && {
      echo "build-ifchange ${*@Q}"
    } || {
      build-ifchange "${@:?}" || return
    }
  }
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
  # XXX: preparing the dest dir is a recipe task under Redo, not a builder
  # responsibility
  local dest=$1 destdir=$(dirname "$1")
  shift 3 || return
  #test -d "$destdir" || mkdir -vp "$destdir" >&2
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
      ${lookup_first:-true} && return || r=0
    }
    shift
  done
  return $r
}

build_resolver ()
{
  local method r hpref=${1:?Handler name prefix expected}
  shift
  $LOG debug "" "Looking up build handler" "${BUILD_TARGET:?}"
  for BUILD_SPEC in $(build_which)
  do
    test "$BUILD_SPEC" = "$BUILD_TARGET" &&
      BUILD_TARGET_KEY= || BUILD_TARGET_KEY=${BUILD_TARGET:${#BUILD_SPEC}}

    #echo "Trying to resolve with '$BUILD_SPEC'..." >&2
    test $# -gt 0 || set -- env parts rules
    for method in "$@"
    do
      ${hpref:?}${method} "${BUILD_SPEC:?}" && {
        #echo "Target resolved at $method '$BUILD_SPEC'" >&2
        exit
      } || { r=$?
        test $r = ${_E_continue:-196} || {
          $LOG error "" "Failed at $method" "$BUILD_SPEC: E$r"
          exit $r
        }
      }
    done
  done
  #print_err "error" "" "Unknown target, see '$BUILD_TOOL help'" "$1"
  $LOG "error" ":build-target" "Unknown target, see '$BUILD_TOOL help'" \
    "${BUILD_TARGET:?}"
  return ${_E_failure:-195}
}

build_rules ()
{
  test "${BUILD_RULES_BUILD:-0}" = "1" && {
    ${show_recipe:-false} && {
      echo "build-ifchange \"${BUILD_RULES:?}\""
    } || {
      build-ifchange "${BUILD_RULES:?}" || return
    }
  } || {
    test "${BUILD_RULES_BUILD:-0}" = "0" || {
      BUILD_RULES=${BUILD_RULES_BUILD:?}
      ${show_recipe:-false} && {
        echo "build-ifchange \"${BUILD_RULES:?}\""
      } || {
        ${BUILD_TOOL:?}-ifchange "${BUILD_RULES:?}" || return
      }
    }
  }
}

# XXX: old
# TODO: could add dependencies for :env:* and also :rule:* pseudo targets.
build_rules_for_target () # ~ <Name> <Basename> <Tempfile>
{
  # XXX: now, show do path lookup similar to Redo?

  # Split function type directives with specific name pattern on first
  # colon, and use that as prefix to find a build rule for this group of
  # targets that can be handled with one generic build handler.

  test "${1:?}" != "${BUILD_RULES-}" -a -s "${BUILD_RULES-}" || {
    # Prevent redo self.id != src.id assertion failure
    $LOG alert ":build-rules:$1" \
      "Cannot build rules table from empty table" "${BUILD_RULES-null}" 1
    return
  }
}

# TODO: virtual target to build components-txt table, and to generate rules for
# every record.
build_table_for_targets () # ~ <>
{
  false
}

build_sh_for_target () # TODO: show recipe that would be used to generate target
{
  false
}


# Generic handler to dispatch build for different types of rules, recipes.
build_target ()
{
  build_resolver build_target_with__ ${BUILD_TARGET_METHODS:-}
}

build_target_with__env ()
{
  # XXX: Shortcut execution for simple aliases, but takes literal values only.
  #build_env_rule_exists "${1:-${BUILD_TARGET:?}}" && {

  #  set -o noglob; set -- ${BUILD_RULE:?}; set +o noglob
  #  build-ifchange "$@"
  #  exit
  #}

  local vid var
  mkvid "${1:-${BUILD_TARGET:?}}" &&
  var=build_${vid}_targets &&
  { test -n "${!var:-}" || return ${_E_continue:-196}; } &&
  { ${show_recipe:-false} && {
      echo "build-ifchange ${!var:?}"
    } || {
      build-ifchange ${!var:?}
    }
  }
}

build_target_with__parts ()
{
  # FIXME: should copy/symlink these files to proper location,
  # let Redo handle lookup and disable filestat here and focus on
  # alternate path formats.
  #fnmatch "dev*" "${ENV:?}"
  build_component__defer "${1:?}" "${2:-}"
}

build_target_with__rules ()
{
  build_rules &&

  # Run build based on matching rule in BUID_RULES table
  build_rule_exists "${1:?}" || {
    return ${_E_continue:-196}
  }

  # XXX: add if not added by build-rules?
  build_if "${BUILD_RULES:?}" &&

  $LOG "notice" ":build-rules" "Found build rule for target" "$1"
  build_components "$1" || return
}


# Step one to resolve a target is getting a lookup sequence, by examining the
# pattern(s) of the target name. See `Target name patterns` for
# definitions.
build_which () # ~ [<Target>]
{
  local target=${1:-${BUILD_TARGET:?}} method
  [[ "$target" =~ ^${BUILD_SPECIAL_RE:?} ]] &&
    method=${BUILD_NAME_SEPS[${target:0:1}]} || method=filepath
  build_which__"${method:?}" "$target"
}

build_which__amp ()
{
  echo "$1"
  echo "${1/&/:and:}"
  echo "${1/&/and-}"
}

build_which__at ()
{
  echo "$1"
  echo "${1/@/at-}"
  echo "${1/@/:at:}"
}

build_which__file_name ()
{
  local n=$(basename "${1:?}") b e _e h= dh def='%' # default
  test "${n:0:1}" = "." && { h=.; n=${n:1}; }
  { test -z "$h" || ! ${lookup_hidden_def:-false}; } && dh=false || dh=true
  b=${n/.*}
  e=${n#*.}
  test "$b" = "$e" && {
    echo "$h$b"
    ! $dh || echo ".$def"
    echo "$def"
  } || {
    echo "$h$b.$e"
    b="$def"
    ! $dh || echo ".$b.$e"
    while test -n "$e"
    do
      echo "$b.$e"
      ! $dh || echo ".$b.$e"
      _e=${e#*.}
      test "$e" != "$_e" || break
      e=$_e
    done
    echo "$b"
    ! $dh || echo ".$b"
  }
}

build_which__file_path ()
{
  local p=${1:?}
  while ! [[ "$p" =~ ^[/\.]$ ]]
  do
    echo "$p"
    p=$(dirname "$p")
  done
}

# Given a target with or without directory path, yield every lookup name.
# This mirrors redo-whichdo, but using Redo as frontend the default.do lookup
# has already finished. Now we can look at env or other systems for the recipe,
# using the same lookup path.
build_which__filepath ()
{
  local p n
  fnmatch "*/*" "${1:?}" && {
    fnmatch "*/" "$1" && p="${1}" || n=$(basename "$1")
    true "${p:=$(dirname "$1")}"
  } || n=$1

  local path name paths names
  test -z "${n:-}" || names=$(build_which__file_name "${n:?}")
  test -z "${p:-}" || paths=$(build_which__file_path "${p:?}" | sed 's/$/\//')

  local first=true
  for path in ${paths:-} ""
  do
    for name in ${names:-""}
    do echo "$path$name"
    done
    # Don't use the actual basename except at exact given pathname
    ! $first || {
      names=$(echo "$names" | tail -n +2)
      first=false
    }
  done
}

build_which__min ()
{
  echo "$1"
  echo "${1/-/::}"
  echo "${1/-/-}"
}

build_which__pct ()
{
  echo "$1"
  echo "${1/\%/:rules:pattern:}"
}

build_which__plus ()
{
  echo "$1"
  echo "${1/+/:in:}"
  echo "${1/+/in-}"
}

build_which__qm ()
{
  echo "$1"
  echo "${1/?/:target:recipe:}"
  echo "${1/?/:target:prerequisites:}"
}

# This is identical to handling directory paths, except '/' is the ':' char
build_which__special ()
{
  local p=${1:?}
  while test -n "$p"
  do
    echo "$p"
    p=${p%:*}
  done
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

. "${U_S:?}/tools/sh/parts/fnmatch.sh"
. "${U_S:?}/tools/sh/parts/str-id.sh"


# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test.
match_grep () # String
{
  echo "${1:?}" | sed -E 's/([^A-Za-z0-9{}(),?!@+_])/\\\1/g'
}

sh_fun ()
{
  test "$(type -t "${1:?}")" = "function"
}

sh_fun_for_pref ()
{
  compgen -A function | grep '^'"${1:?}"
}

sh_fun_body ()
{
  sh_fun_type "${1:?}" | sed 's/^\(\('"$1"' *() *\)\|\({ *\)\|}\)$//' | grep -v '^ *$'
}

sh_fun_type ()
{
  type "${1:?}" | tail -n +2
}

# Read only data, trimming whitespace but leaving '\' as-is.
# See read-escaped and read-literal for other modes/impl.
read_data () # (s) ~ <Read-argv...> # Read into variables, ignoring escapes and collapsing whitespacek
{
  read -r "$@"
}

# Read character data separated by spaces, allowing '\' to escape special chars.
# See also read-literal and read-content.
read_escaped ()
{
  #shellcheck disable=2162 # Escaping can be useful to ignore line-ends, and read continuations as one line
  read "$@"
}



build-env ()
{
  build_env "$@"
}

build-ood ()
{
  test $# -eq 0 || return ${_E_GAE:-$?}
  command ${BUILD_TOOL:?}-ood | grep -v '^'"${BUILD_VIRTUAL_RE:?}"
}

# XXX: tools generate
build_env__boot__ood=BUILD_TOOL

build-show ()
{
  BUILD_TARGET=${1}
  BUILD_TARGET_BASE=
  BUILD_TARGET_TMP=
  build_for_target
}

build-which ()
{
  build_which "$@"
}


test -n "${__lib_load-}" || {

  build_entry_point=${SCRIPTNAME:-$(basename -- "$0" .lib.sh )}
  case "$build_entry_point" in

    ( "build-" )
        BUILD_ACTION=${1:?}
        shift
        build_boot "$@" &&
        sh_fun "build_${BUILD_ACTION//-/_}" || {
          $LOG error "" "No such entrypoint" "$BUILD_ACTION" $?
          exit
        }
        build_"${BUILD_ACTION//-/_}" "$@"
        exit
      ;;

    ( "build-"* )
        BUILD_ACTION=${build_entry_point:6}
        sh_fun "$build_entry_point" || {
          $LOG error "" "No such entrypoint" "$build_entry_point" $?
          exit
        }
        build_boot "$@" && "${build_entry_point}" "$@"
        exit
      ;;

    ( "build" )
        export log_key=build-[$$]

        . "${U_S}/tools/redo/env.sh" || { r=$?
          test $r = 96 && {
            echo "E$r: Env recursion? [$log_key]" >&2
          }
          exit $r
        }

        test $# -gt 0 || set -- $build_all_targets
        while test $# -gt 0
        do
          build_run "$@" || {
            $LOG error ":run:$1" "" "E:$?"
            exit 1
          }
          shift
        done
      ;;

    ( * ) ;;
  esac
}
#
