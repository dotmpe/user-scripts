#!/usr/bin/env bash

### Build.lib: Frontends and shell toolkit for build system


build_lib_load ()
{
  true "${BUILD_TOOL:=null}"

  true "${build_rules_defnames:=$(echo {,.}build-rules.{txt,list} .components.txt .meta/stat/index/components-local.list)}"

  true "${build_tools_parts:=sh build ci ${BUILD_TOOL:?}}"
  true "${build_tools_src_specs:=${build_tools_parts// /,}}"

  # A bunch of names for sh files to inject, if found for cold bootstraps
  # Hidden first, then normal, generic local first, then more specifc, or shared
  true "${build_envs_defnames:=$(echo {.,}{attributes,package,env,params,build-env})}"
  #shellcheck disable=SC1083 # Yes, these are literal braces patterns, expanded
  # by echo
  true "${build_libs_defnames:=$(echo {.,}lib {.,}build-lib tools/{${build_tools_src_specs}}/lib)}"

  true "${sh_file_exts:=.sh .bash}"

  true "${sh_exts:=${sh_file_exts:?}}"

  # Not sure what shells to restrict to, so setting it very liberal
  test -n "${sh_shebang_re-}" || sh_shebang_re='^\#\!\/bin\/.*sh\>'
}

build_lib_init () # ~
{
  return 0

  #shellcheck disable=2086
  # build_env_reset
  build_env_init &&
  build_boot ${BUILD_ENV:?Missing build env boot load arguments} || return

  #env__define__from_package || return

  #lib_require argv date match "$BUILD_TOOL" || return

  build_define_commands || return

  #build_init env_lookup components

  #env__define__build_rules || return

  # Toggle or alternate target for build tool to build build-rules.txt
  #test -n "${BUILD_RULES_BUILD-}" ||
  #  BUILD_RULES_BUILD=${COMPONENTS_TXT_BUILD:-"1"}

  true "${COMPONENT_TARGETS:="$PROJECT_CACHE/component-targets.list"}"

  # Targets for CI jobs
  test -n "${build_txt-}" || build_txt="${BUILD_TXT:-"build.txt"}"

  test -n "${dependencies_txt-}" || dependencies_txt="${DEPENDENCIES_TXT:-"dependencies.txt"}"
}


build__declare ()
{
  :
}

build_actions ()
{
  declare var=${BUILD_TOOL:?}_commands
  test -n "${!var-}" || {
    $LOG error "" "No build tool actions" "$BUILD_TOOL" 1
    return
  }
  echo "${!var-}"
}

# Cache part files of current build-env profile
build_add_cache ()
{
  BUILD_ENV_CACHES=${BUILD_ENV_CACHES:-}${BUILD_ENV_CACHES:+ }${1:?} &&
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

# Helper for recipes to auto-install as part for targets on TARGET_ALIAS
build_alias_part ()
{
  test -z "${TARGET_ALIAS:-}" || {
    true "${part:?Aliased build with tools part needs path to recipe}"
    declare pnals alsp
    pnals=$(echo "${BUILD_TARGET:?}" | tr './' '_')
    alsp="${REDO_STARTDIR:?}/tools/redo/parts/$pnals.do"
    ! test -h "$alsp" || {
      test -e "$alsp" || {
        rm "$alsp" || return
      }
    }
    test -e "$alsp" || {
      ln -s "$part" "$alsp" || return
    }
    build_unalias
  }
}

# Build two arrays for given arguments, resolving symbols
build_file_arr ()
{
  declare refa_vname=${1:?} fpa_vname=${2:?}
  shift 2
  # Build first array: mixed symbol and file target arguments
  build_arr_seq $refa_vname "$@" || return
  # Build second array: resolve all with Build-FSym-Re char prefix
  build_fsym_arr $refa_vname $fpa_vname
}

build_fsym_arr ()
{
  declare ref refa_vname=${1:?} refa fpa_vname=${2:?}
  refa=${!refa_vname}
  build-ifchange "${refa[@]:?}" || return
  eval "declare -ga $fpa_vname=()" || return
  readarray -t $fpa_vname <<< "$(for target in "${refa[@]}"
    do
      [[ "${target:0:1}" =~ ^${BUILD_FSYM_RE:?}$ ]] && {
        # FIXME: sym=$(build-sym "${target:?}") &&
        declare name_ type_ comptab
        comptab=$(build_rule_fetch "$target") &&
        read_data name_ type_ args_ <<< "$comptab"
        case "$type_" in
            # FIXME: what about file path names with spaces
          ( expand )
              eval "echo $args_"
              #eval "printf %s $args_"
            ;;
          ( expand-eval ) eval "$args_" ;;
          ( expand-all|* )
              stderr_ "FIXME: merge recipe handlers" 1
            ;;
        esac
        #stderr_ "file-arr: '$target' is '$args_' is '$(eval "echo $args_")'"
      } ||
        echo "$target"
    done)"
}

# Helper for rule-part directives. Returns non-zero for empty sequence but
# ignores presence of next sequence.
build_arr_seq () # ~ <Var-name> [ <Items <...>> ] [ -- <...> ]
{
  declare vname=${1:?}
  shift
  eval "declare -ga $vname=()" || return
  while argv_has_next "$@"
  do
    eval "$vname+=( \"\$1\" )"
    shift
  done
}

# Call env:define:* routines for all given Ids, this can be called repeatedly
# during execution to bootstrap new functions.
#
build_boot () # (Build-Action) ~ <Argv...>
{
  test "$PWD" != "/" || {
    $LOG error ":build-boot:${BUILD_ACTION:?}" "! Build cannot do that" "root"
    return 1
  }

  declare env_boot=true

  #shellcheck disable=2086
  test $# -gt 0 || set -- ${BUILD_ENV:?Missing build env}
  test "${BUILD_ACTION:?}" = target &&
    $LOG debug ":build-boot(${BUILD_TARGET//%/%%})" "@@@ Bootstrapping target" "$*" ||
    $LOG debug ":build-boot" "@@@ Bootstrapping @@@ '${BUILD_ACTION:?}'..." "$*"

  declare tag ret
  test "unset" != "${ENV_DEF[*]-unset}" || declare -gA ENV_DEF=()
  test "unset" != "${ENV_PART[*]-unset}" || declare -gA ENV_PART=()
  while test $# -gt 0
  do
    tag=${1:?}
    { env_boot=true build_env_declare "$tag"
    } || { ret=$?
      test $ret -eq "${_E_break:-197}" && return $ret
      test $ret -eq "${_E_retry:-198}" || {
        $LOG error ":build-boot" "Error defn/decl" "E$ret:tag=$tag" ; return $ret
      }
      for pen in ${ENV_PENDING:?Pending expected for \"$tag\" E$ret = E198}
      do
        ! env_declared "$pen" || { $LOG error ":build-boot:pending" \
              "Unable to resolve/error with '$pen' for '$tag'"
          return 1
        }
      done
      #shellcheck disable=2086
      set -- $ENV_PENDING "$@"
      unset ENV_PENDING
      continue
    }
    shift
  done
}

build_chatty () # Level
{
  "${quiet:-$(test "$verbosity" -lt "${1:-3}" && printf true || printf false )}"
}

build_copy_changed ()
{
  { test -e "$2" && diff -bqr "$1" "$2" >/dev/null
  } || {
    cp "$1" "$2" || return
    echo "Updated <$2>" >&2
  }
}

# Make build-* wrapper functions to actual builder
build_define_commands ()
{
  set -- $(build_actions)
  test $# -gt 0 || return
  declare name cmd
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

build_env () # ~ [<Handler-tags...>]
{
  #test $# -gt 0 || set -- ${BUILD_ENV:?Missing build env}
  #build_env_init && build_boot "$@" || return

  build_env_require || {
    $LOG error :build-env "Missing env"
    echo "defs: ${!ENV_DEF[*]}" >&2
    echo "parts: ${ENV_PART[*]}" >&2
  }
  declare tag cache
  for tag in \
    BUILD_ENV_CACHES $BUILD_ENV_DEP BUILD_ENV_SRC BUILD_ENV_CACHE
  do
    declare -p "$tag" 2> /dev/null || echo "$tag="
  done
  # | sed 's/declare /declare -g /'
  for tag in $BUILD_ENV_FUN
  do
    sh_fun_type "$tag" || return
  done
  for cache in $BUILD_ENV_CACHES
  do
    echo "# Build env cache: $cache"
    cat "$cache"
  done
  echo "# Build env OK: '$*' completed"
}

# TODO: Provide boostrap for default.do tools/sh/parts/default-do-env@dev
build_env_build ()
{
  mkdir -vp ${PROJECT_CACHE:?} >&2 || return
  test -e .attributes && set -- attributes
  test -e ${BUILD_RULES:?} && set -- "$@" rule-params

  declare r
  build_boot "$@" build-env-cache || r=$?
  test ${r:-0} -eq ${_E_break:-197} && {

    test "${BUILD_TARGET:?}" = "${BUILD_ENV_CACHE:-}" && {
      test -z "${BUILD_ENV_CACHES?}" || {
        build-ifchange ${BUILD_ENV_CACHES//:/ } || return
        echo BUILD_ENV_CACHE[$BUILD_TARGET]: caches: ${BUILD_ENV_CACHES:-} >&2
      }
      test -z "${ENV_BUILD_ENV?}" || {
        build-ifchange ${ENV_BUILD_ENV//:/ } || return
        echo BUILD_ENV_CACHE[$BUILD_TARGET]: seed: ${ENV_BUILD_ENV:-} >&2
      }
    }
    return ${r:-}
  }

  #build_boot default-do-env-default
  #build_boot default-redo-env
  test -z "${BUILD_ENV:-}" || build_boot $BUILD_ENV || return
  return ${r:-0}
}

# Make every env group declare itself; its requirements, its variables and its
# functions.
build_env_declare ()
{
  declare tag fun line script
  while test $# -gt 0
  do
    tag=${1:?}
    env_declared "$tag" || {
      sh_fun env__define__"${tag//-/_}" || {
        env_boot=false env_require $tag || return
      }
      ! sh_fun env__declare__"${tag//-/_}" || {
        build_add_handler env__declare__"${tag//-/_}" &&
        env__declare__"${tag//-/_}" || return
      }
      #! sh_fun env__build__"${tag//-/_}" || {
      #  env__build__"${tag//-/_}" || return
      #}
      build_add_handler env__define__"${tag//-/_}" &&
      env__define__"${tag//-/_}" || return
      ENV_DEF[$tag]=1
    }
    shift
  done
}


build_env_init ()
{
  true "${BUILD_ENV_CACHES:=}"
  true "${BUILD_ENV_FUN:=}"
  true "${BUILD_ENV_DEP:=}"
  true "${BUILD_ENV_SRC:=}"
  #declare -g \
  #  BUILD_ENV_CACHES= BUILD_ENV_FUN= BUILD_ENV_DEP= BUILD_ENV_SRC=
}

# Find every environment part, and see that it is declared and defined by
# calling the env:declare:<part> routine, env:define:<part> routine and then
# setting ENV_DEF[<part>] to 1. The caller should handle E:pending (E198) by
# inspecting ENV_PENDING and ENV_BUILDING.
#
# Unless env_dev=true, the presence of keys in ENV_BOOT and ENV_CACHE will
# override the default declare/define and source that sequence instead, but
# only if each target is UTD. Like with ENV_DEF, because all these parts are
# now part of the profile their ENV_D keys are set.
#
# This is like env:require, except heuristics are tailored to run as part
# of a build. To run a target's recipe, there are parts needed in the
# build-env, parts to configure the current project, and as well for the given
# target, and then parts needed to dispatch the target with build.lib.
# There may as well be build-env specific to the user, host or directory or
# any other parameter. All these can be configured using some basic parts that
# configure others.
#
# If cache parts and or boot part are declared, build-env-require can use
# build-ifdone on those targets, and use those instead of going through further
# declare/defines when all we need is to boot into the generated environment.
# But it also prevents individual targets that would load this profile from
# getting
# direct dependencies on generic files.
#
# In fact build.lib is setup, so that such profile is instead is generated as
# part of certain root targets, and using other more abstract targets.
#
build_env_require ()
{
  test -n "${BUILD_ENV_FUN:-}" &&
  test -n "${BUILD_ENV_DEP:-}"
  #test -n "${BUILD_ENV_SRC:-}"
}

build_env_reset ()
{
  BUILD_ENV_CACHES=
  BUILD_ENV_FUN=
  BUILD_ENV_DEP=
  BUILD_ENV_SRC=
}

build_env_rule ()
{
  declare vid var val
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
  #| build_sh
}

# Load all libs to do development build.
#
# This picks up any build-lib.sh along the current build path, and executes
# build:lib-load if defined with each build-lib, and unsets the definition.
#
# This means the most specific project gets priority on setting defaults, and
# ultimately +User-script or another super-project and all intermediate build
# dirs can supplement or veto setting.
#
# After all this the standard build.lib is loaded and build-lib-load executed.
build_env_sources ()
{
  $LOG info ":build-env-sources" "Sourcing function libs..." "${BUILD_TARGET//%/%%}"
  test "unset" != ${CWD-unset} || declare -l CWD
  test -n "${BUILD_PATH:-}" || declare -l BUILD_PATH
  true "${CWD:=$PWD}"
  test "unset" != "${build_source[*]-unset}" || env__define__build_source

  declare rp
  rp=$(realpath "$0")
  build_source[$rp]=$0

  # Projects should execute their own BUILD_PATH, a default is set by this lib
  # but +U-s does not have super-projects.
  # test "$rp" != "$(realpath "$U_S")/src/sh/lib/build.lib.sh" || BUILD_PATH=$U_S

  # Either set initial build-path as argument, or provide entire
  # Env-Buildpath as env. Standard is to use hard-coded default sequence, and
  # only establish that sequence determined after loading specififed or or
  # local build-lib, the former must exist while the latter is optional.
  test $# -eq 0 && {
    ! test -e "$CWD/build-lib.sh" || {
      build_source "$CWD/build-lib.sh" || return
    }
  } || {
    test -e "$1/build-lib.sh" ||
      $LOG error :build-env-default "Expected build-lib" "$1" 1 || return
    build_source "$1/build-lib.sh" || return
  }

  # true "${BUILD_PATH:=$CWD ${BUILD_BASE:?} ${BUILD_STARTDIR:?}}"

  declare -l dir
  for dir in ${BUILD_PATH:?}
  do
    test "unset" = "${build_source[$dir]-unset}" ||
    test -e "$dir/build-lib.sh" || continue
    build_source "$dir/build-lib.sh" || return
    set -- "$@" "$dir"
  done
  $LOG debug :build-env-default "Found build libs" "$*"

  # If this script is the entry point, there is no need to load it again.
  # Could make this a lot shorter but want to warn about Build-Entry-Point.
  { test -n "${BUILD_SCRIPT:-}" &&
    fnmatch "build*" "${BUILD_SCRIPT:-}"
  } && {

    # If the entry point is build*, then this is the /expected/ source.
    # however we already added the entry-point script above
    local bl="${U_S:?}/src/sh/lib/build.lib.sh"
    rp=$(realpath "$bl")
    ! test "unset" = "${build_source[$rp]-unset}" ||
      $LOG warn ":build-env-default" \
        "Expected build.lib entry point but was" "$0" && false

  } || {
    build_source "${U_S:?}/src/sh/lib/build.lib.sh"
  }

  $LOG debug :build-env-default "Done"
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

build_fetch_alias_rules () # ~ <Group-Name> <Prerequisites...>
{
  declare group="$1"
  shift
  while test $# -gt 0
  do
    echo "$group $1"
    shift
  done
}

build_fetch_expand_rules () # ~ <Group-Name> <Brace-Pattern...>
{
  declare group="$1" a
  shift
  for a in $(eval "echo $*")
  do
    echo "$group $a"
  done
}

build_fetch_expand_all_rules () # ~ <Target> <Cmd...> -- <Tpl-Pattern...>
{
  declare group=$1 source_cmd=
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
  declare group="$1"
  shift
  echo "$group - type:$*"
}

# Produce a list of <Group> <Target> <Sources> from c.txt
build_fetch_rules ()
{
  read_nix_style_file "${BUILD_RULES:?}" | {
    while read_escaped_ name type args
    do
      set -o noglob; set -- $name $args; set +o noglob
      build_fetch_${type//-/_}_rules "$@"
    done
  }
}

build_fetch_simpleglob_rules () # ~ <Group-Name> <Target-Spec> <Source-Spec>
{
  declare src match glob=$(echo "$3" | sed 's/%/*/')
  for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$1 $(echo "$2" | sed 's/\*/'"$match"'/') $(echo "$glob" | sed 's/\*/'"$match"'/')"
    done
}

build_fetch_symlinks_rules () # ~ <Group-Name> <Target-Spec> <Source-Spec>
{
  declare group=$1 src match dest grep="$(glob_spec_grep "$2")" f
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

# Given target, generate from sources if too old using command.
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
  declare dest=$1 destdir=$(dirname "$1")
  shift 3 || return
  "$@" >| "$dest"
}


# Show recipe commands that build-target would be executed by build-target
build_for_target () # ~ # Show build recipe for target
{
  show_recipe=true build_resolver \
    build_for_target__with__ ${BUILD_TARGET_METHODS:-}
}

# Handler for build-resolver
build_for_target__with__env ()
{
  show_recipe=true build_target__with__env "$@"
}

# Handler for build-resolver
build_for_target__with__parts ()
{
  show_recipe=true build_target__with__parts "$@"
}

# Handler for build-resolver
build_for_target__with__rules ()
{
  show_recipe=true build_target__with__rules "$@"
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
build_from_rules () # ~ <Name>
{
  declare comptab lk btf
  lk=":from-rules(${1//%/%%})"
  btf=${BUILD_TARGET//%/%%}

  comptab=$(build_rule_fetch "${1:?}") &&
    test -n "$comptab" || {
      $LOG error "$lk" "No such symbolic rule" "$btf" ; return 1
    }
  $LOG debug "$lk" "Building rule for target" "$btf"

  declare name="${1:?}" name_ type_ args_ rf
  shift
  read_data name_ type_ args_ <<<"$comptab"
  test -n "$type_" || {
    $LOG error "$lk" "Empty directive for rule" "symbol=$name" ; return 1
  }

  rf=${args_// -- /::}
  rf=${rf/ /:}
  $LOG notice "$lk" "Building rule for target" "$btf:$type_:$rf"

  # Rules have to expand globs by themselves.
  set -o noglob; set -- $type_ $args_; set +o noglob
  $LOG debug "$lk" "Building as '$type_:$name_' rule" "($#):$*"

  ${quiet:-false} || test -n "${BUILD_ID:-}" ||
    echo "# build:rule: $name_ $type_ ($#) '$args_'"

  build_target_rule "$@"
}

# Take rule for target and run that. TODO: merge with build-from-rules,
# see also build-target:from:symbol
build_from_rule_for ()
{
  declare name="${1:?}" name_ type_ comptab
  comptab=$(build_rule_fetch "$name") || {
    stderr_ "! $0: build-target:from:symbol: Symbol expected" || return
  }
  read_data name_ type_ args_ <<<"$comptab"
  set -o noglob; set -- $type_ $args_; set +o noglob
  $LOG info "" "Deferring to build-target-rule" "$*"
  build_target_rule "$@"
}

# XXX: resolve files for symbol
build_expand_symbols ()
{
  declare name name_ type_ comptab
  for name in "${@:?}"
  do
    comptab=$(build_rule_fetch "$name") || {
      stderr_ "! $0: build-target:from:symbol: Symbol expected" || return
    }
    read_data name_ type_ args_ <<<"$comptab"
    # XXX: should probably want these to expand on lines, not to words
    eval "echo $args_"
  done
}

build_install_parts ()
{
  test "${BUILD_RULES_BUILD:-0}" != "0" || {
    stderr_ "! Set Build-Rules-Build to auto-install rules"
    return 1
  }
  declare br in
  test "${BUILD_RULES_BUILD:-0}" = "1" &&
    br=${BUILD_RULES:?} || br=${BUILD_RULES_BUILD:?}
  test -z "${BUILD_TARGET:-}" -o "$br" != "${BUILD_TARGET:-}" || {
    stderr_ "! Install during build-rules build '$br' '$BUILD_TARGET'"
    return 1
  }
  test "$br" = "${BUILD_TARGET:-}" && { in=$br; br=$BUILD_TARGET_TMP; }
  while test $# -gt 0
  do
    grep -qF "${1:?} " "${in:-${br:?}}" || {
      part=$1
      target=$3
      test -n "$2" -a "${2:0:1}" != "." && cache="$2" ||
        cache="$(printf '${PROJECT_CACHE:?}/%s' "$1$2")"
      {
        echo "$target expand $cache"
        echo "$target:* defer $part"
      } >> "$br"
    }
    shift 3
  done
}

build_install_rule ()
{
  test "${BUILD_RULES_BUILD:-0}" != "0" || {
    stderr_ "! Set Build-Rules-Build to auto-install rules"
    return 1
  }
  declare br in
  test "${BUILD_RULES_BUILD:-0}" = "1" &&
    br=${BUILD_RULES:?} || br=${BUILD_RULES_BUILD:?}

  test -z "${BUILD_TARGET:-}" -o "$br" != "${BUILD_TARGET:-}" || {
    stderr_ "! Install during build-rules build '$br' '$BUILD_TARGET'"
    return 1
  }
  test "$br" = "${BUILD_TARGET:-}" && { in=$br; br=$BUILD_TARGET_TMP; }

  grep -qF "${1:?} " "${in:-${br:?}}" || echo "$*" >>"${br:?}"
}

build_main_target ()
{
  build_target_group "all ${build_main_targets:?}"
}

build_env_target ()
{
  build_target_group "${build_at_env_targets:?}"
}

build_target_group ()
{
  #test "${1:-${BUILD_TARGET:?}}" = "all"
  case " ${1:?} " in *" ${BUILD_TARGET:?} "* )
    ;; * ) false ;;
  esac
}

# Encode target as filename, replacing ext and dir separators
build_target_name__filename ()
{
  declare fn=${1:-${BUILD_TARGET:?}}
  # Strip './' prefix
  ! ${BUILD_STRIP_LF:-true} || fn=${1/.\/}
  # Replace special, don't squeeze but keep 1:1 strlen
  fn="$(echo "$fn" | tr '/.' '_')"
  echo "$fn"
}

# Encode target as function name
build_target_name__function ()
{
  declare fun=${1:-${BUILD_TARGET:?}}
  # Strip './' prefix
  ! ${BUILD_STRIP_LF:-true} || fun=${1/.\/}
  # Or Strip special prefix XXX: BUILD_SPECIAL_RE is not set
  # XXX: hidden file prefix gets stripped as well, but do'nt mind this
  #! [[ "${fun:0:1}" =~ ^$BUILD_SPECIAL_RE$ ]] || fun=${fun:1}
  [[ "${fun:0:1}" =~ ^[A-Za-z]$ ]] || fun=${fun:1}
  fun=${fun//:/__}
  # Replace non-alphanumeric, but don't squeeze and keep 1:1 strlen
  fun=${fun//[^[:alnum:]_]/_}
  echo "$fun"
}

# Go through target lookup sequence generated by build-which, and let each
# handler method (env, parts or rules) try to handle build. Handlers should
# return E:continue if resolution failed.
build_resolver ()
{
  declare method r hpref=${1:?Handler name prefix expected} br_handler brhref
  shift
  declare -g BUILD_HANDLER=
  test $# -gt 0 || set -- ${BUILD_TARGET_METHODS:-env parts rules}
  $LOG debug ":build:resolve[${BUILD_TARGET//%/%%}]" "Starting lookup for target" "$*"
  mapfile -t specs <<< $(build_which)
  for BUILD_SPEC in "${specs[@]}"
  do
    test "$BUILD_SPEC" = "$BUILD_TARGET" &&
      BUILD_TARGET_KEY= || BUILD_TARGET_KEY=${BUILD_TARGET:${#BUILD_SPEC}}

    for method in "$@"
    do
      br_handler=${hpref:?}${method}
      # @debug @lookup
      ! ${BUILD_LOOKUP_DEBUG:-false} ||
        $LOG debug ":build:resolve" "Checking with $br_handler" "${BUILD_SPEC//%/%%}"
      $br_handler "${BUILD_SPEC:?}" && {
        brhref=$br_handler
        brhref=${brhref//--/__}
        brhref=${brhref//__/:}
        brhref=${brhref//_/-}
        BUILD_HANDLER=$brhref
        $LOG debug ":build:resolve" "Target handled at ${brhref} '${BUILD_SPEC//%/%%}'" >&2
        ${show_recipe:-false} && return
        exit 0
      } || { r=$?
        test $r = "${_E_next:-196}" && continue
        $LOG error "" "Failed at $method" "${BUILD_SPEC//%/%%}: E$r"
        ${show_recipe:-false} && return $r
        exit $r
      }
    done
  done
  $LOG "error" ":build-target" "Unknown or unexpected target, see '$BUILD_TOOL ${HELP_TARGET:-help}'" \
    "${BUILD_TARGET//%/%%}"
  return ${_E_failure:-195}
}

# Do a quiet build-rule-fetch to check wether tehre is a rule for target
build_rule_exists () # ~ <Rule-target>
{
  grep_f=-q build_rule_fetch "$@"
}

# Retrieve one Build Rules line verbatim based on name (using grep)
# TODO: If the target name contains un-escaped regex meta characters (such as forward
# slash or dot) it will be turned into a regex using match-grep.
build_rule_fetch () # ~ <Rule-target>
{
  declare name=${1:?} name_p
  # FIXME: need to ignore pre-made regexes?
  fnmatch "*/*" "$name" && name_p="$(match_grep "$name")" || name_p="$name"
  grep ${grep_f:--m1} "^$name_p"'\($\| \)' "${BUILD_RULES:?}"
}

build_set_dependencies ()
{
  declare -ga BUILD_DEPS=()
  declare tag boottag fun line script prereq
  for tag in "${!ENV_DEF[@]}"
  do
    for boottag in "${ENV_BOOT[@]}"
    do
      test "$tag" = "$boottag" || continue
      continue 2
    done
    BUILD_DEPS+=( "$tag" )
  done
  test 0 -eq ${#BUILD_DEPS[*]} && return
  build_targets_ $( for tag in "${BUILD_DEPS[@]}"
    do
      fun=env__define__"${tag//-/_}"
      read -r fun line script <<< $(declare -F "$fun")
      # XXX: script=$(realpath --relative-to=$PWD "$script")
      prereq=${BUILD_NS_:?}if-scr-fun:$script:$fun
      echo "$prereq"
    done)
}

# Track build libs as they are loaded, and execute lib-load handlers as well.
build_source ()
{
  declare -p build_source >/dev/null 2>&1 || env__define__build_source

  declare rp bll
  test "${1:0:1}" != "/" || set -- "$(realpath "$1" --relative-to "${CWD:?}")"

  test -e "$1" && rp=$(realpath "$1") || {
    $LOG error :build:source "No such file" "$1:E$?" ; return 1
  }
  test -n "${build_source[$rp]-}" && return
  $LOG info :build:source "Found build source" "$1"
  {
    build_source[$rp]=$1 &&
    source "$1"
  } || {
    $LOG error :build:source "Error loading source" "$1:E$?" ; return 1
  }
  $LOG debug :build:source "Loading build source" "$1"
  ! sh_fun build__lib_load && return
  build__lib_load || bll=$?
  # XXX: may be keep this per-source path but dont need it anyway..
  #build_source_[]=$(typeset -f build__lib_load)
  unset -f build__lib_load
  return ${bll:-0}
}


# Start build for target sequence
build_run () # ~ <Target <...>>
{
  build_targets_ "${@:?}"
}


build_sh ()
{
  while read -r vname val
  do
    val="${!vname-null}"
    printf '%s=%s\n' "$vname" "${val@Q}"
  done
}

build_show_recipe ()
{
  BUILD_TARGET=${BUILD_TARGET:1}
  BUILD_TARGET_BASE=${BUILD_TARGET_BASE:1}
  BUILD_TARGET_TMP=${BUILD_TARGET_TMP:1}
  ${BUILD_TOOL:?}-always && build_ for-target "${BUILD_TARGET:?}"
}

build_which_names ()
{
  BUILD_TARGET=${BUILD_TARGET:2}
  BUILD_TARGET_BASE=${BUILD_TARGET_BASE:2}
  BUILD_TARGET_TMP=${BUILD_TARGET_TMP:2}
  ${BUILD_TOOL:?}-always && build_ which "${BUILD_TARGET:?}"
}

build_what_parts ()
{
  false # See build-symbol
}

# Helper for build-resolver handlers.
build_targets_ () # ~ <Target...>
{
  ${inline_special:-false } && {
    $LOG error "" "TODO: inline special recipe lines"
    return 1
  } || {
    ${list_sources:-false} && {
      printf '%s\n' "$@"
      return
    }
    ${show_recipe:-false} && {
      echo "build-ifchange ${*@Q}"
    } || {
      test -z "${BUILD_ACTION:-}" && {
        $LOG notice "::" "??" "$0:${*//%/%%}"
      } ||
        test "${BUILD_ACTION:-}" = target &&
          $LOG notice ":build-target::" "Sub" "${*//%/%%}" ||
          $LOG notice ":build[$BUILD_ACTION]:" "Internal" "${*//%/%%}"
      build-ifchange "${@:?}" || return
    }
  }
}


# Alias target: defer to other targets.
#
# This uses Target-Parent env to give the lookup of sub targets additional
# entries to lookup Build-Rules with. To prevent Redo from being smart by
# calling those/that target directly (since the current one is virtual) this
# needs build-always so that the sub-target never misses the needed env to
# build the lookup sequence.
build_target__from__alias () # <Targets...>
{
  #shellcheck disable=SC2046
  # XXX: not sure if this can something with spaces/other special characters
  # properly. May be test such later...
  #eval "set -- $(echo $* | lines_printf '"%s"')"
  #shellcheck disable=2124
  TARGET_PARENT="${BUILD_TARGET:?}}" TARGET_GROUP="${@@Q}" build_targets_ "${@:?}"
}

# Defer execution: build a (single) target by invoking another command
# executable
#
# XXX: This encodes the target name in any of the specified schemes, and then
# acts like 'exec' if command -v actually can resolve the command.
# Alternatively, the command and arguments can be provided verbatim.
#
# There will not be any further evaluation, and currently no support for local
# env.
# If the first word in the command line does not match any executable name,
# then 'defer' changes to 'tools' or 'parts'.
#
# Normally, Redo selects nearest recipe (see redo-whichdo) for a target.
# Using build.lib's 'defer' type target, we can 'redirect' to any given script
# and fork the process to produce the target.
#
# This will encode the target and lookup a *.do file based on that name. It can
# then execute it, but also symlink the part.
# XXX: this is needed for Redo to be able to re-build Target Alias or Target
# Parent parameterized builds.
# XXX: Currently Target Parent parameters are used with build-always in the parent
# target so the env is never missing. This allows to use generic recipe
# scripts.
# But for Target Alias the recipe will have to need to handle installation of
# the recipe as a target. For that it can call build_alias_part to install a
# symlinked part, and still have the build env always loaded because the target
# is build through default.do.
#
# Alternatively the recipe can create a redo file that works as well, but that
#
build_target__from__defer () # ~ [<Cmd-name <Argv...>>|<Part-name>]
{
  declare cmdname="${1:--}" execfile

  case "$cmdname" in
    "-" ) cmdname="$(echo "${BUILD_TARGET:?}" | tr '/.' '_')" ;;
  esac

  execfile=$(command -v -- "$cmdname") && {
    shift
    build_target__from__exec "$cmdname $*"
    return
  }

  # XXX: replace this with redo-part instead after all projects switched to
  # source-part instead of defer rules
  #build_target__seq__source_do "$@"
  build_target__from__part "$@"
}

# Sometimes, one generic recipe part is not enough.
build_target__from__defer_sequence () # ~ <Target-name> <Part-names <...>>
{
  declare pn
  for pn in "$@"
  do build_target__from__defer "$pn" || return
  done
}

# Initial argv sequence is used as a list of prerequisite targets to run part.
# Same as 'if ... -- defer ...'
build_target__from__defer_with () # ~ <Prerequisites...> -- <Part-name <...>>
{
  build_target_dep_seq DEPS "$@" || return
  test 0 -eq "${#DEPS[*]}" && shift || {
    shift ${#DEPS[*]} && shift
  }
  build_target__from__defer_sequence "${BUILD_TARGET:?}" "$@" &&
  build-always
}

# Wrapper for generic recipe part 'os-dir-index' that simply stamps the dir
# listing.
# XXX: same as 'defer os-dir-index'?
build_target__from__dir_index () # ~ <Dirs...>
{
  #shellcheck disable=2124
  TARGET_PARENT="${BUILD_TARGET:?}}" TARGET_GROUP="${@@Q}" TARGET_ALIAS=os-dir-index build_targets_ "$@"
}

build_target__from__eval () # ~ <Command...>
{
  $LOG warn ":eval" "Evaluating command" "$*"
  eval "${*:?}" > "${BUILD_TARGET_TMP:?}" || return
  test -s "${BUILD_TARGET_TMP:?}" &&
    build-stamp < "$BUILD_TARGET_TMP" || rm "$BUILD_TARGET_TMP"
}

build_target__from__exec () # ~ <Command...>
{
  $LOG warn ":exec" "Running command" "$*"
  command "${@:?}" > "${BUILD_TARGET_TMP:?}" || return
  test -s "${BUILD_TARGET_TMP:?}" &&
    build-stamp < "$BUILD_TARGET_TMP" || rm "$BUILD_TARGET_TMP"
}

# Somewhat like alias, but this expands strings containing
# shell expressions.
#
# XXX: These can be brace-expansions, variables or even subshells.
build_target__from__expand () # ~ <Target-expressions...>
{
  local self="build-target:from:expand"
  #shellcheck disable=2046
  set -- $(eval "echo $*")
  test 0 -lt $# || {
    $LOG warn ":$self($BUILD_TARGET)" "Expanded to empty set"
    return
  }
  # XXX: build-always
  #shellcheck disable=2124
  TARGET_PARENT=${BUILD_TARGET:?} TARGET_GROUP="${@@Q}" build_targets_ "${@:?}"
}

# Take list of values and generate targets from pattern.
# The initial source argument can be a function or executable and the entire
# source-sequences is invoked as is, and else the source arguments are treated
# as a sequence of (one or more) file(s) or symbolic target(s) to files.
#
# FIXME: another function/cmd to do cat on such targets would be handy
build_target__from__expand_all () # ~ <Source...> -- <Target-Formats...>
{
  local self="build-target:from:expand-all" stdp
  stdp="! $0: $self:"
  declare -a source_cmd=()
  while argv_has_next "$@"
  do
    source_cmd+=( "$1" )
    shift
  done
  argv_is_seq "$@" || return
  shift
  test 0 -lt ${#source_cmd[*]} || {
    stderr_ "$stdp Expected executable, filepath(s), or symbol(s)" || return
  }
  { { declare -F "${source_cmd[0]}" || command -v "${source_cmd[0]}"
    } >/dev/null
  } || {
    read -t source_files <<< "$(build_expand_symbols "${source_cmd[@]}")"
    test 0 -lt ${#source_files[*]} || {
      stderr_ "$stdp Expected filepaths: '${source_cmd[*]@Q}" ||
        return
    }
    source_cmd=( "cat" )
    source_cmd+=$source_files
  }
  targets=$( "${source_cmd[@]}" | while read -r nameparts
    do
      for fmt in "$@"
      do
        #shellcheck disable=2086
        eval "echo $( expand_format "$fmt" $nameparts )"
      done
    done )
  test -n "$targets" || {
    stderr_ "$stdp Expected placeholder values: '${source_cmd[*]@Q}'" || return
  }

  ${list_sources:-false} && {
    echo "$targets"
    return
  }
  ${show_recipe:-false} && {
    echo "build-ifchange $targets"
  } || {
    #shellcheck disable=2086
    build-ifchange $targets
  }
}

build_target__from__expand_eval ()
{
  local self="build-target:from:expand-eval" stdp
  set -- $(eval "$@")
  test 0 -lt $# || {
    $LOG warn ":$self($BUILD_TARGET)" "Expanded to empty set"
    return
  }
  TARGET_PARENT=${BUILD_TARGET:?} TARGET_GROUP="${@@Q}" build_targets_ "${@:?}"
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
#shellcheck disable=2059
build_target__from__function () # ~ [<Function>] [<Args>]
{
  declare name=${BUILD_SPEC:-${BUILD_TARGET:?}} fun=${1:--}
  shift
  declare lk
  test $# -gt 0 && lk=":fun($#)" || lk=:fun

  test "${fun:-"-"}" != "-" || {
    fun=${BUILD_HPREF:-build__}$(build_target_name__function "$name")
  }

  test "${fun:-"-"}" != "*" ||
    fun="build_$(mkvid "$name" && printf -- "$vid")"

  test "${fun:-"-"}" != ":" ||
    fun="build_$(mkvid "$name" && printf -- "$vid")"

  # XXX: function argv?
  #test $# -eq 0 || {
  #  # XXX: function uses eval to expand vars
  #  set -- $(eval "echo $*")
  #  # FIXME: parse seq properly
  #  test -z "$1" -o "$1" = "--" || {
  #    build_targets_ "$1" &&
  #    source "$1" || return
  #  }
  #  shift
  #  test "${1:-}" != "--" || shift
  #}
  sh_fun "$fun" || {
    $LOG info "::from:function(${BUILD_TARGET:?})" \
      "Skipping missing routine" "$fun:${BUILD_SPEC:-}"
    return ${_E_continue:-196}
  }

  $LOG info "${lk}(${BUILD_TARGET//%/%%})" "Calling function" "$fun"
  $fun "$@"
}

# Compose: build file from given function(s)
# TODO: as compose-names but do static analysis to resolve dependencies
build_target__from__compose () # ~ <Composed...>
{
  false
}

build_target__from__compose_names () # ~ <Composed...>
{
  shift || return "${_E_GAE:-193}"
  : "${@:?"Expected one or more functions to typeset"}"
  declare fun tp rs r
  for fun in "$@"
  do
    build_target__from__compose__resolve "$fun" || return
  done
  build-stamp < "${BUILD_TARGET_TMP:?}"
  typeset build_target__from__compose | build-stamp
}

build_target__from__compose__resolve ()
{
  # There are myriads of ways to start looking for a function definition,
  # and also to generate a typeset.

  { tp="$(type -t "${1:?}")" && test "$tp" = "function"
  } || {
    for rs in ${COMPO_RESOLVE:-tagsfile composure}
    do
      build_target__from__compose__resolve_function__"${rs}" "$1"; r=$?
      test $r -eq 0 && break ||
        test "$r" -eq "${_E_continue:-196}" && continue
    done
    test $r -eq 0 || {
      test "$r" -eq "${_E_continue:-196}" &&
        $LOG error "" "Failed to resolve" "$BUILD_TARGET:$1:$COMPO_RESOLVE" ||
        $LOG error "" "Error during resolve" "$BUILD_TARGET:$1"
      return $r
    }
  }
  #build_target__from__compose__typeset__${BUILD_COMPO_TGEN:-sh}
  $LOG info "" "Typesetting..." "$1"
  type "$1" | tail -n +2 > "${BUILD_TARGET_TMP:?}" || return
}

# TODO: look in users C_INC/which composure.sh
build_target__from__compose__resolve_function__composure ()
{
  return "${_E_continue:-196}"
}

build_target__from__compose__resolve_function__tagsfile ()
{
  declare tsrc
  tsrc=$(grep -m 1 "^$1"$'\t' "${TAGS:?}" | awk '{print $2}') || {
    $LOG error "" "Unknown function" "$BUILD_TARGET:$1"
    return "${_E_continue:-196}"
  }
  BASE=source . "$tsrc" || {
    $LOG error "" "Failed to include" "$BUILD_TARGET:$1:$tsrc" 1 || return
  }
  build_targets_ "$tsrc"
}

# Pick word at index from each line. List references must be files or symbols,
# and a build-ifchange dependency is made for each. This does not check if a
# list file exists (because the build could create one), but instead only treats
#
build_target__from__lines_word () # ~ <Nr> <List-refs...>
{
  build-ifchange :if-fun:build_target__from__lines_word || return
  local nr=${1:?}
  shift
  build_file_arr LREFS FILES "$@" || return
  for file in "${FILES[@]}"
  do
    test -s "${file:?}" || {
      test -e "${file:?}" || {
        stderr_ "! $0[$$]: build-target:from:lines-word: No such file E$?" || return
      }
    }
    cut -f$nr -d' ' < "${file:?}"
  done >| "${BUILD_TARGET_TMP:?}"
  build-ifchange < "${BUILD_TARGET_TMP:?}"
}

# Generic target recipe using looked up parts. Without arguments, runs
# 'if <part> -- source-do <part>' rule. If a method is given, the part and all
# remaining parameters are passed to a rule with that name
# ('<method> <part> -- <...>'), and if a new
# sequence is given that is run after 'if <part>'.
#
build_target__from__part () # ~ [<Part-name>] [ <Method> | -- <Rule <...> ]
{
  declare pn=${1:--} part
  test -z "${TARGET_ALIAS:-}" || pn=$TARGET_ALIAS
  test "-" != "$pn" || pn=${BUILD_TARGET:?}

  case "${1:--}" in
    # Encode target as filename, replacing ext and dir separators
    ( "-" ) read -r pn <<< "$(build_target_name__filename "$pn")"
    #shellcheck disable=SC2211 # XXX: This is valid 'in' syntax.
    ( * ) ;; # Use part-name as-is
  esac
  $LOG debug ::from:part "Trying part lookup" "${pn//%/%%}"

  # Lookup actual path for part name from all parts locations
  #shellcheck disable=2086
  part=$(sh_exts=.do sh_path=${BUILD_PARTS:?} sh_lookup "$pn") || {
    return ${_E_continue:-196}
  }
  $LOG info ::from:part "Found recipe part" "${part//%/%%}"

  test $# -ge 2 && declare method=${2:?}
  test $# -gt 2 && {
    test "--" = "${3:-}" && {
      shift 3
      build_target_rule "$method" "$part" -- "$@" || return
    } || {
      $LOG error : "Surplus arguments" "$*"
      return 1
    }
  }

  test $# -eq 2 && {
    build_target_rule "$method" "$part" || return
  } || {
    build_target_rule if "$part" -- source-do "$part" || return
  }
}

#shellcheck disable=2059
build_target__from__shlib () # ~ <Target> [<Function>] [<Libs>] [<Args>]
{
  declare name=${1:?} func=${2:--}
  shift 2
  test "${func:-"-"}" != "*" ||
    func="build__$(mkvid "$BUILD_NAME_NS" && printf -- "$vid")"

  test "${func:-"-"}" != "-" ||
    func="build_$(mkvid "$name" && printf -- "$vid")"

  test $# -eq 0 || {
    #shellcheck disable=2046
    set -- $(eval "echo $*")
    test -z "$1" -o "$1" = "--" || {
      sh_fun lib_path || {
        declare scriptname=${log_key:?}
        declare sys_lib_log=$LOG
        source "${U_S:?}/src/sh/lib/sys.lib.sh" || return
        declare lib_lib_log=$LOG
        source "${U_S:?}/src/sh/lib/lib.lib.sh" || return
      }
      declare lp
      lp="$(lib_path "$1")" || return
      build_targets_ "${lp:?}" &&
      lib_require "$1" || return
    }
    shift
  }
  $func "$@"
}

# Take rule from symbolic target and run that for current target
build_target__from__symbol () # ~ <Symbol>
{
  build-ifchange :if-fun:build_target__from__symbol || return
  declare name="${1:?}"
  shift
  build_from_rule_for "${name}:\\*"
}

# Symlinks: create each dest, linking to srcs
build_target__from__symlinks () # ~ <Target-Name> <Source-Glob> <Target-Format>
{
  declare src match dest grep f
  grep="$(glob_spec_grep "${2:?}")" || return
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
#build_target_glob () # ~ <Name> <Target-Pattern> <Source-Globs...>
# XXX: this is not a simple glob but a map-path-pattern based on glob input
build_target__from__simpleglob () # ~ <Target-Spec> <Source-Spec>
{
  build-ifchange :if-scr-fun:${U_S:?}/src/sh/lib/build.lib.sh:build_target__from__simpleglob || return

  #shellcheck disable=2155
  declare src match glob=$(echo "${2:?}" | sed 's/%/*/')

  #shellcheck disable=2046
  build-ifchange $( for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$1" | sed 's/\*/'"$match"'/'
    done )
}

# Helper to chain build-target:from:* recipes.
# Takes intial argv sequence, stores as <Var>[] using build-arr-seq.
# Also returns non-zero if no items are found and records <Var>_LEN var
build_dep_seq () # ~ <Var-name> <Prerequisites> -- <...>
{
  declare vname=${1:?}
  shift
  build_arr_seq "$vname" "$@" || {
    # XXX: definition should exist at least.
    sh_null declare -p $vname || return
  }
  eval "declare depcnt=\${#${vname}[@]}"
  test 0 -lt "${depcnt:?}" || {
    $LOG error "" "No $vname items in sequence" "$*"
    return 1
  }
  eval "declare -g ${vname}_LEN=$depcnt"
}

# Helper to chain build-target:from:* recipes. Like build-dep-seq, but return
# non-zero on empty next sequence as well and call build-targets- with all items.
build_target_dep_seq () # ~ <Var-name> <Prerequisites> -- <...>
{
  declare vname=${1:?} lvname=${1}_LEN
  shift
  build_dep_seq $vname "$@" &&
  shift "${!lvname:?}" || return
  argv_is_seq "$@" || {
    $LOG error "" "No next sequence after if-$vname" "${!lvname:?}:$#:$*"
    return 1
  }
  eval "build_targets_ \"\${${vname}[@]}\""
}

# call: 'Alias' for expression
build_target__seq__call () # ~ <Command...> [ -- <Rule <...>> ]
{
  build_target__seq__expression "$@"
}

# This is not used anywhere currently, but it may be possible to execute several
# commands in sequence as part of a recipe. XXX: I'm just not sure wheter
# build-always or build-ifchange invocations (from multiple sub-commands) will
# not confuse Redo. But it can at least be used to do other things in isolated
# environments.
build_target__seq__do () # ~ <Redo-file <...>>
{
  build_dep_seq DO "$@" || return
  shift "${#DO[*]}"
  ! argv_is_seq "$@" || shift
  declare lk
  test ${#} -gt 0 && lk=":do(${#})" || lk=:do
  test $# -eq 0 ||
    $LOG warn "$lk" "Surpluss argv after Redo params" "${*//%/%%}"
  set -- "${BUILD_TARGET:?}" "${BUILD_TARGET_BASE:?}" "${BUILD_TARGET_TMP:?}" "$@"
  test 1 -eq "${#DO[*]}" && {
    $LOG warn "$lk" "Forking to recipe part" "$SHELL:${DO[0]//%/%%}"
    exec $SHELL "${DO[0]}" "$@"
  }
  declare src
  for src in "${DO[@]}"
  do
    $LOG warn "$lk" "Running recipe part" "$SHELL:${src//%/%%}"
    command "$SHELL" "$src" "$@" || return
  done
}

# expression: evalute given argv as command line (sequence part: not a
# pipeline and -- option is reserved).
build_target__seq__expression () # ~ <Command...> [ -- <Rule <...>> ]
{
  build_arr_seq EXPRESSION "$@" || return
  $LOG warn ":eval" "Executing from expression" "${EXPRESSION[*]}"
  "${EXPRESSION[@]:?}" || return
  $LOG info "::if-lines" "Expression finished" "${EXPRESSION[*]}"
  shift "${EXPRESSION_LEN:?}"
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

# Add first sequence as build-ifchange dependencies, and list in DEPS[].
# Then continue with rule in next sequence by entering/recursing into
# build-target-rule.
build_target__seq__if () # ~ <Dep-targets...> -- <Rule <...>>
{
  build_target_dep_seq DEPS "$@" || return
  shift ${DEPS_LEN:?} && shift || return
  build_target_rule "$@"
}

# Equivalent to 'if' but for already existing array var
build_target__seq__ifa () # ~ <Array-name> [ -- <Rule <...>> ]
{
  declare vname=${1:?}
  shift
  eval "build_targets_ \"\${${vname}[@]}\"" || return
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

# Like a normal 'if' except all of the prerequisite targets are treated as
# symlink filepaths, and their real paths will be stored in DEST[] (in addition
# to if's DEPS). Those are used as arguments for build-targets- instead.
build_target__seq__if_dest () # ~ <Symlinks...>  -- <Rule <...>>
{
  build_dep_seq DEPS "$@" || return
  read -ra DEST <<<"$(for dep in "${!DEPS[@]}"; do realpath -- "$dep"; done)"
  build_targets_ "${DEST[@]}" || return
  shift ${#DEPS[*]} && shift || return
  build_target_rule "$@"
}

# Pseudo-target: depend on certain function typeset. To invalidate without
# having prerequisites of its own, it uses build-always.
# See if-scr-fun to validate based on specified script source file.
build_target__seq__if_fun () # ~ <Fun <..>> [ -- <Rule <...>> ]
{
  build_arr_seq IF_FUN "$@" || return
  #shellcheck disable=2316 # Var is indeed called 'typeset'
  declare typeset
  typeset="$( for fun in "${IF_FUN[@]}"
    do
      typeset -f "$fun"
    done )" || return
  ${BUILD_TOOL:?}-stamp <<< "$typeset"
  ${BUILD_TOOL:?}-always
  $LOG info "::if-fun" "Function check done" "${IF_FUN[*]}"
  shift ${#IF_FUN[@]}
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

# Psuedo target checks file for line starting with key, and stamps line.
# This greps for one matching line. Key has all special characters escaped
# and is anchored left (Prefix is '^' by default) or right (set Suffix or Prefix
# to any regex).
build_target__seq__if_line_key () # ~ <File> <Key> [<Prefix>] [<Suffix>] \
  # [ -- <Rule <...>> ]
{
  declare file=${1:?} key=${2:?} l='^' r='\>'
  shift 2
  build_targets_ "$file" || return
  test $# -eq 0 || {
    argv_is_seq "$@" || { l=${1:-}; shift; }
    argv_is_seq "$@" || { r=${1:?}; shift; }
  }
  declare line keyre
  read -r keyre <<< "$(
      sed -E 's/([^[:alnum:],:_-])/\\\1/g' <<< "${key//\?/:}"
    )"
  fnmatch "*[0-9][a-z]" "$keyre" || r=
  line=$(grep -Em1 "$l$keyre$r" "$file") || {
    $LOG error ::if-line-key "No line with key" "$file:$key"
    return 1
  }
  build-stamp <<< "$line"
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

# Pseudo-target: depend on file targets, but validate on content lines
# (excluding blank lines and comments)
build_target__seq__if_lines () # ~ <File <...>> [ -- <Rule <...>> ]
{
  declare -ga IF_LINES=()
  while argv_has_next "$@"
  do
    IF_LINES+=( "$1" )
    shift
  done
  ${BUILD_TOOL:?}-ifchange "${IF_LINES[@]:?}" || return
  declare lines
  lines="$(grep -Ev '^\s*\(#.*|\s*)$' "${IF_LINES[@]:?}")" || return
  ${BUILD_TOOL:?}-stamp <<< "$lines"
  $LOG info "::if-lines" "File lines check done" "${IF_LINES[*]}"
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

# build-target:* helper for rule part 'if-scr-fun': depend on script file and
# function typeset.
#
# This allows to assemble recipes that stamp certain function definitions.
# It does compine two sequence handlers into one, see if-scr and if-fun.
# Ie. these are equiv::
#
#   if-scr-fun:<script>:<fun>       # Target of single-step recipe
#   if-scr:<script>::if-fun:<fun>   # Two step recipe sequence encoded as target
#
#   if-scr-fun <script> <fun>       # Or written in build-rule syntax
#   if-scr <script> -- if-fun <fun> # Equiv.
#
# This does not source anything, for that use alternative rule (seq)::
#
#   if-src-fun:<script>:<fun:<fun...>>
#   if-source <script <...>> -- if-fun <fun <...>> # Equiv.
#
build_target__seq__if_scr_fun () # ~ <Script> <Fun <...>> [ -- <Rule <...>> ]
{
  declare script=${1:?}
  build-ifchange :if-lines:"$script" || return
  shift
  build_arr_seq IF_FUN "$@" || return
  #shellcheck disable=2316 # Var is indeed called 'typeset'
  declare typeset
  typeset="$( for fun in "${IF_FUN[@]}"
    do
      typeset -f "$fun"
    done )" || return
  ${BUILD_TOOL:?}-stamp <<< "$typeset"
  $LOG info ::if-scr-fun "Script function check done" "$script:${IF_FUN[*]}"
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

build_target__seq__ifdone ()
{
  declare -ga IFDONE=()
  while argv_has_next "$@"
  do
    IFDONE+=( "$1" )
    shift
  done
  build-ifdone "${IFDONE[@]}" || return
  ${BUILD_TOOL:?}-stamp <<< "${IFDONE[@]}"
  $LOG info ::ifdone "Ifdone-check done" "${IFDONE[*]}"
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

# build-target:* helper for rule part 'if-source': source based on if/DEPS[]
# This will setup DEPS but source (load and evalute the script at each filepath
# from DEPS[]) as well. To source without making and ifchange dependency see
# 'source' directive.
#
# (so cannot currently use symbolic targets, XXX: add some symbol decl?)
build_target__seq__if_source () # ~ <Source-scripts...> [ -- <...> ]
{
  declare lk=":if-source($#)" src
  build_target_dep_seq DEPS "$@" || return
  for src in "${DEPS[@]}"
  do source "$src" || {
      $LOG error "$lk" "During source" "E$?:$src" $? || return
    }
  done
  shift ${#DEPS[*]}
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}
# Derive: build_target__seq__source

# Stamp all functions after building and sourcing the script.
# This calls sequence::
#
#   if-source <Script> -- if-fun <...>
#
build_target__seq__if_src_fun () # ~ <Script> <Fun <...>> [ -- <Rule <...>> ]
{
  declare script=${1:?}
  shift
  build_target_rule if-source "$script" -- if-fun "$@"
}

# Build SRC array from sequence and source files without making ifchange
# dependency. See 'if-source'.
build_target__seq__source () # ~ <Source-scripts...> [ -- <...> ]
{
  declare lk=":source($#)"
  build_dep_seq SRC "$@" || return
  declare src
  for src in "${SRC[@]}"
  do source "$src" || {
      $LOG error "$lk" "During source" "E$?:$src" $? || return
    }
  done
  shift ${#SRC[*]}
  ! argv_is_seq "$@" && return
  shift
  build_target_rule "$@"
}

# build-target:* helper for rule part: source-do directive
#
# sets proper arguments (ie. script parameters) sequence before sourcing
# scripts, so that they can be written as sort of in-between format for
# recipes. These run with the already loaded build-env profile so that may be
# more convenient to write or develop recipe scripts, but these would need a
# wrapper to function as standalone redo files.
#
# source-do is implemented separately from 'source' rule directive and
# accumulates the psuedo-Redo scripts in DO[]
build_target__seq__source_do () # ~ <Redo-file <...>> [-- <...>]
{
  build_dep_seq DO "$@" || return
  shift "${#DO[*]}"
  declare -a args=()
  ! argv_is_seq "$@" || {
    shift
    args=( "$@" )
  }
  declare lk
  test ${#args[@]} -gt 0 && lk=":src-do(${#args[@]})" || lk=:src-do
  set -- "${BUILD_TARGET:?}" "${BUILD_TARGET_BASE:?}" "${BUILD_TARGET_TMP:?}"
  declare src
  for src in "${DO[@]}"
  do
    $LOG notice "${lk}[${BUILD_TARGET//%/%%}]" "Sourcing recipe part" "${src//%/%%}"
    fnmatch "*/*" "$src" ||
      $LOG warn "${lk}[${BUILD_TARGET//%/%%}]" \
      "Sourcing from PATH, use relative path or set BUILD_SOURCE_PATH=1 (see ... XXX)" "$src"
    source "$src" || return
  done
  test 0 -lt "${#args[@]}" || return 0
  build_target_rule "${args[@]}"
}
# Derive: build_target__seq__source


# XXX: would need to expand all rules.
build_target_exists () # ~ <Target-name>
{
  false
}


build_target_recipe__alias () # <Name> <Targets...>
{
  ${list_sources:-false} && {
    shift
    echo "$*" | tr ' ' '\n'
    return
  }
  declare target=${1:?}
  echo "declare target=${1@Q}"
  shift
  echo shift
  #shellcheck disable=SC2145
  echo "TARGET_PARENT=\"${target}\" TARGET_GROUP=\"${@@Q}\" build_targets_ ${@@Q}"
}

build_target_recipe__dir_index () # <Name> <Dirs...>
{
  ${list_sources:-false} && {
    shift
    echo "$*" | tr ' ' '\n'
    return
  }
  declare target=${1:?}
  echo "declare target=${1@Q}"
  shift
  echo shift
  #shellcheck disable=SC2145
  echo "TARGET_PARENT=\"${target}\" TARGET_GROUP=\"${@@Q}\" TARGET_ALIAS=os-dir-index build-ifchange ${@@Q}"
}

build_target_recipe__expand () # <Name> <Targets...>
{
  ${list_sources:-false} && {
    shift
    eval "echo $*" | tr ' ' '\n'
    return
  }
  declare target=${1:?}
  echo "declare target=${1@Q}"
  shift
  echo shift
  echo "set -- \$(eval \"echo $*\")"
  #shellcheck disable=SC2145
  echo "TARGET_PARENT=\"${target}\" TARGET_GROUP=\"${@@Q}\" build-ifchange ${@@Q}"
}

build_target_recipe__expand_all ()
{
  show_recipe=true build_target__from__expand_all "$@"
}

build_target_rule ()
{
  $LOG debug ":target-rule" "Trying rule" "${*//%/%%}"

  declare type=${1:?}
  shift

  ! ${show_recipe:-false} || stderr_ "FIXME"

  #  sh_fun build_target_recipe__${type_//-/_} && {
  #    build_target_recipe__${type_//-/_} "$@"
  #    return
  #  }
  #  echo "set -- ${*@Q}"
  #  sh_fun_body build_target__from__${type//-/_} | sed 's/^    //'
  #  return
  #} || {
  sh_fun build_target__seq__${type//-/_} && {
    build_target__seq__${type//-/_} "$@" || return
  } || {
    sh_fun build_target__from__${type//-/_} || return ${_E_continue:-196}

    build_target__from__${type//-/_} "$@" || return
  }
}

# List target types current env profile can handle building for
build_target_types ()
{
  # Get all target rule handlers, remove name prefix, ignore sub-handlers
  # and print as slug Id
  sh_fun_for_pref "build_target__from__" | cut -c 18- | grep -v '__' | tr '_' '-'
}

# Helper for build handlers that use the rules table. Normally the Build Rules
# variable points to where rules should be read.
#
# This add a build-ifchange call for a recipe,
# but only if Build Rules Build = 1
build_rules ()
{
  test "${BUILD_TARGET:?}" != "${BUILD_RULES-}" -o -s "${BUILD_RULES-}" || {
    # Try to prevent redo self.id != src.id assertion failure
    $LOG alert ":build-rules:${BUILD_TARGET//%/%%}" \
      "Cannot build rules table from empty table" "${BUILD_RULES-null}" 1
    return
  }

  # XXX:
  return 0

  test "${BUILD_TARGET:?}" = "${BUILD_RULES-}" -o \
    \( "${BUILD_RULES_BUILD:-0}" = "0" -o \
      "${BUILD_TARGET:?}" = "${BUILD_RULES_BUILD-}" \
    \) || {

    test "${BUILD_RULES_BUILD:-0}" = "1" && {
      ${list_sources:-false} && {
        echo "${BUILD_RULES:?}"
        return
      }
      ${show_recipe:-false} && {
        echo "${BUILD_TOOL:?}-ifchange \"${BUILD_RULES:?}\""
      } || {
        ${BUILD_TOOL:?}-ifchange "${BUILD_RULES:?}" || return
      }
    } || {
      test "${BUILD_RULES_BUILD:-0}" = "0" || {
        ${list_sources:-false} && {
          echo "${BUILD_RULES_BUILD:?}"
          return
        }
        ${show_recipe:-false} && {
          echo "${BUILD_TOOL:?}-ifchange \"${BUILD_RULES_BUILD:?}\""
        } || {
          ${BUILD_TOOL:?}-ifchange "${BUILD_RULES_BUILD:?}" || return
        }
      }
    }
  }

  # TODO: add virtual targets for lines from build-rules files
  # build_rule_fetch "${1:?}" | build-stamp
}


# Generic handler to dispatch build for different types of rules, recipes.
build_target ()
{
  build_resolver build_target__with__ ${BUILD_TARGET_METHODS:-}
}


# Unexport and unset special target env
build_target__parent__reset_group ()
{
  sh_unset TARGET_PARENT TARGET_GROUP TARGET_KEY_SPECS
}


# Build-resolver that looks for target in env
build_target__with__env () # ~ [<Build-target>]
{
  declare tn vid var
  tn=${1:-${BUILD_TARGET:?}}
  tn=${tn/.\/}
  mkvid "$tn" &&
  var=build_${vid}_targets &&

  # Must be set or return and signal lookup to continue with ext alternative
  test "${!var-unset}" != unset || return ${_E_continue:-196}

  ! ${list_sources:-false} || {
    echo "${!var:?}"
        # XXX: | tr ' ' '\n'
    return
  }

  ${show_recipe:-false} && {
    test -z "${!var:-}" &&
      echo "stderr_ \"! \$0: Empty recipe for '${BUILD_TARGET:?}'\"" ||
      echo "${BUILD_TOOL:?}-ifchange ${!var:?}"
  } || {
    test -z "${!var:-}" &&
      stderr_ "! $0: Empty recipe for '${BUILD_TARGET:?}'" ||
      ${BUILD_TOOL:?}-ifchange ${!var:?}
  }
}

# Build-resolver that looks for target in file tree
# XXX: was same as the 'defer' rule. Need to mull on where script boundary is
# a bit, but ofcourse will depend on env and exports working OK first...
build_target__with__parts () # ~ [<Build-target>]
{
  declare pn=${BUILD_SPEC:?}
  pn=${pn/.\/}
  test -n "$pn" || return ${_E_next:-196}
  pn="$(echo "$pn" | tr '/.' '_')"
  test -n "$pn" || return ${_E_next:-196}
  build_target__from__part "$pn" source-do
  # 'part <pn> source-do' is equiv to build-target-rule 'source-do <part>',
  # however 'part' without any further parameters equals adding an ifchange
  # dependency: 'if <part> -- source-do <part>'
}

# Build-resolver that looks for target in rules-table
build_target__with__rules () # ~ [<Build-target>]
{
  test $# -gt 0 || set -- "${BUILD_TARGET:?}"

  $LOG "debug" ":target::rules" "Starting build rule for target" "${1//%/%%}"
  build_rules || return

  # Run build based on matching rule in BUILD_RULES table
  build_rule_exists "${1:?}" || {
    $LOG "debug" ":target::rules" "No such rule" "${1//%/%%}"
    return ${_E_continue:-196}
  }
  # XXX: cannot do this as long as targets (symbols in rules) have special
  # characters, as ':' needs to be escaped somehow.
  #${BUILD_TOOL:?}-ifchange \
  #  ":if-line-key:${BUILD_RULES:?}:${BUILD_TARGET//:/?}" || return

  $LOG info ":target::rules" "Found build rule for target" "${1//%/%%}"
  build_from_rules "$1" || return
}


# Helper for recipes to allow to run for aliased builds
build_unalias ()
{
  sh_unset TARGET_ALIAS
}


# Step one to resolve a target is getting a lookup sequence, by examining the
# pattern(s) of the target name. See `Target name patterns` for definitions.
# Also a build frontend.
build_which () # ~ [<Target>]
{
  # Experimental setup to group build-rule prerequisites.

  # Whenever a target recipe build from a rule in the Build Rules calls
  # build-ifchange for one of its sub-targets it can set Target Parent to its
  # own target name, and also add a key to the environment of the sub-target,
  # identifying relation the sub-target has to the parent target.

  # This export is cleared while looking up further sub-targets that are not
  # in the Target Group set by the Target Parent. Target recipes may use the
  # the target-parent-group env, but generic recipes do not need to know they
  # are part of a group at all.

  test -z "${TARGET_PARENT:-}" || {
    # Clear parent env if current target is not in parent's target group.
    fnmatch "* '${BUILD_TARGET:?}' *" " ${TARGET_GROUP:-} " || {
      build_target__parent__reset_group
    }
  }

  # Insert lookup name(s) based on parent env if set
  test -z "${TARGET_PARENT:-}" || {

    # Allows a rule to match every prerequisites of another, or specific
    # keys produced by the target-handler that are useful to acces in the
    # sub-target's recipe.
    set -o noglob
    declare key
    for key in ${TARGET_KEY_SPECS:-':\*'}
    do echo "$TARGET_PARENT$key"
    done
    set +o noglob
  }

  # Another way to hard-link a requested target to an env part name, without
  # having anything in place for this. E.g. build-ifdirchange can use this to
  # map all directory targets to a specific recipe part.
  # To make this more simple than Target Parent handling the recipe has to
  # clear the variable before using other build-* frontends so it is a bit
  # special.
  # However, depending on the handler method we still need to record this
  # mapping or Redo will not find the recipe on its own.
  # So whenever a handler encounters the TARGET_ALIAS it should check.
  # XXX: this is only done yet by 'parts' method (ie. the build-component:defer
  # rule handler)
  test -z "${TARGET_ALIAS:-}" || {
    echo "$TARGET_ALIAS"
  }


  # Regular handling of the target name, which method is determined by the
  # first character. Normally targets are split up into path, filename, and
  # extension elements. The special method does something similar for ':'-based
  # name patterns.
  # , and for other characters some additional keys are generated
  # as well, which helps to aid in matching the target to definitions
  # compiled into the env profile.
  declare target=${1:-${BUILD_TARGET:?}} method
  test "${target:0:1}" != '\' || {
    # FIXME: log isnt printing escape in strings
    $LOG warn :build-which "Initial character in target is escape" \
        "${target//%/%%}"
  }

  build_target_lookup "$target"
}

# XXX: Recursively print every possible matching path or name for target.
#
# # @prefix-special: :
# # @prefix-amp-ns: :symbols :
# # @prefix-star-ns: :sets :
# # @prefix-pct-ns: :patterns :
#
# The search does not end
# unless the initial character of the references name is a known
# prefix
# If the character is not special, the reference is a file path which should be
# resolved as either '/' or './' ie. get the '/' or '.' reference prefix.
#
build_target_lookup ()
{
  declare target=${1:?} methods method
  [[ "${target:0:1}" =~ ^${BUILD_SPECIAL_RE:?}$ ]] && {
    test "${BUILD_TARGET_DECO[${target:0:1}]-isset}" != isset || {
      $LOG error ":build-which" \
        "Missing handler for special character prefix" \
        "${target//%/%%}"
      return
    }
    methods=${BUILD_TARGET_DECO[${target:0:1}]}
  } || methods=filepath
  for method in $methods
  do
    ! ${BUILD_LOOKUP_DEBUG:-false} ||
      $LOG debug :build-which "Using '$method' handler for lookup" "${target//%/%%}"
    build_which__"${method//-/_}" "$target"
  done
}

build_which__file_name ()
{
  declare n=$(basename "${1:?}") b e _e h= dh def='%' # default
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
      ! $dh || echo ".$b.$e"
      echo "$b.$e"
      _e=${e#*.}
      test "$e" != "$_e" || break
      e=$_e
    done
    ! $dh || echo ".$b"
    echo "$b"
  }
}

build_which__file_path ()
{
  declare p=${1:?}
  while ! [[ "$p" =~ ^[/\.]$ ]]
  do
    echo "./$p"
    p=$(dirname "$p")
  done
}

# Given a target with or without directory path, yield every lookup name.
# This mirrors redo-whichdo, but using Redo as frontend the default.do lookup
# has already finished. Now we can look at env or other systems for the recipe,
# using the same lookup path. But also different formats, see build-which.
build_which__filepath ()
{
  declare p n
  fnmatch "*/*" "${1:?}" && {
    fnmatch "*/" "$1" && p="${1}" || n=$(basename "$1")
    true "${p:=$(dirname "$1")}"
  } || n=$1

  declare path name
  declare -a paths names
  test -z "${n:-}" && names=("") ||
    mapfile -t names <<< "$(build_which__file_name "${n:?}")"
  test -z "${p:-}" ||
    mapfile -t paths <<< "$(build_which__file_path "${p:?}" | sed 's/$/\//')"
  ! ${BUILD_LOOKUP_DEBUG:-false} || {
    test -n "${n:-}" &&
      stderr_ "Lookup file names for '$n': ${names[*]//$'\n'/ }" ||
      stderr_ "No file name for target '${1//%/%%}'"
    test -n "${p:-}" &&
      stderr_ "Lookup path names for '$p': ${paths[*]//$'\n'/ }" ||
      stderr_ "No path name for target '${1//%/%%}'"
  }

  declare first=true
  for path in "${paths[@]}" "./"
  do
    for name in "${names[@]}"
    do echo "$path$name"
    done
    # Don't use the actual basename except at exact given pathname
    ! $first || {
      names=$(echo "$names" | tail -n +2)
      first=false
    }
  done
}

# Replace initial character with other sequences to generate additional Id's
# or patterns to represent target.
# , and then apply
# build-which:special on the result.
build_which__prefix_alias ()
{
  echo "$1"
  declare alias
  for alias in ${BUILD_DECO_NAMES[${1:0:1}]}
  do
    echo "$alias ${1:1}"
  done
  pref=${BUILD_TARGET_ALIAS[${1:0:1}]}
  build_which__special "${pref}${1:1}"
}

# This is identical to handling directory paths, except '/' is the ':' char.
# The algorithm here is much simpler because there are no directory vs.
# filename elements (yet).
build_which__special ()
{
  declare p=${1:?} d=${1//[^:]} c
  d=${#d}
  while test -n "$p"
  do
    echo "$p"
    # Assemble lookup pattern
    p=${p%:*}
    c=${p//[^:]}
    c=${#c}
    echo "$p$(while test $(( d - 1 )) -ge $c; do printf '%s' ":%"; d=$(( d - 1 )); done)"
    test $d -eq $c || echo "$p:"
  done
}


## Env parts

. "${U_S:?}/tools/sh/parts/build-r0-0.sh"


## Build-info action/frontend handlers
#
. "${U_S:?}/tools/build/parts/build-info.sh"


## Misc. build parts

# XXX: some old, mostly copies to-be compiled into final build.lib or prereqs
# elsewhere

. "${US_BIN:=$HOME/bin}/argv.lib.sh"

. "${U_S:?}/tools/sh/parts/fnmatch.sh"
. "${U_S:?}/tools/sh/parts/str-id.sh"
. "${U_S:?}/tools/sh/parts/sh-mode.sh"


attributes_sh ()
{
  grep -Ev '^\s*(#.*|\s*)$' "$@" |
  awk '{ st = index($0,":") ;
      key = substr($0,0,st-1) ;
      gsub(/[^A-Za-z0-9]/,"_",key) ;
      print toupper(key) "=\"" substr($0,st+2) "\"" }'
}


expand_format () # ~ <Format> <Name-Parts>
{
  declare format="$1"
  shift
  for part in "$@"
  do
    #shellcheck disable=2001,2154
    case "$format" in
      *'%*'* ) echo "$format" | sed 's#%\*#'"$part"'#g' ;;
      *'%_'* ) mkvid "$part"; echo "$format" | sed 's/%_/'"$vid"'/g' ;;
      *'%-'* ) mksid "$part"; echo "$format" | sed 's/%-/'"$sid"'/g' ;;
      * ) return 98 ;;
    esac
  done
}


env_defined ()
{
  test "unset" != "${ENV_DEF[${1:?}]-unset}"
}

env_declared ()
{
  env_defined "${1:?}" && test "1" -eq "${ENV_DEF[${1:?}]}"
}

env_included ()
{
  test "unset" != "${ENV_PART[${1:?}]-unset}"
}

env_require ()
{
  set -- $( while test $# -gt 0
      do
        env_declared "${1:?}" || echo "$1"
        shift
      done )
  test $# -eq 0 && return

  ${env_boot:-false} && {
    $LOG debug :env-require "Pending env" "$*"
    ENV_PENDING="$@"
    return ${_E_pending:-198}
  }
  $LOG debug :env-require "Requiring env" "$*"
  declare pen

  for pen in "$@"
  do
    $LOG info ":env-require" "Looking for pending env part" "$pen"
    ENV_PART[$pen]=$(sh_path=${ENV_PATH:?} any=true sh_lookup $pen ) || {
        $LOG error :env-require "Unable to locate '$pen'" "E$?:${ENV_PATH:-}"
        return 1
      }
  done
  sh_source $(for pen in "$@"; do echo "${ENV_PART[$pen]}"; done) || {
    $LOG error :env-require "Unexpected error sourcing '$*'" E$?
    return 1
  }
  for pen in "$@"
  do
    sh_fun env__define__"${pen//-/_}" && continue
    # XXX: parts declare
    eval "env__define__${pen//-/_} () { :; }"
    #type "env__define__${pen//-/_}" >&2
  done
}


find_executables ()
{
  find . -executable -type f | cut -c3-
}


# Return first globbed part, given glob pattern and expanded path.
# Returned part is everything matched from first to last wildcard glob,
# so this works on globstar and to a degree with multiple wildcards.
glob_spec_var () # ~ <Pattern> <Path>
{
  test $# -eq 2 || return "${_E_GAE:-193}"
  set -- "${@:?}" "$(glob_spec_grep "${1:?}")"
  #shellcheck disable=2001
  echo "${2:?}" | sed 's/'"${3:?}"'/\1/g'
}

glob_spec_grep ()
{
  # Escape all special regex characters, then turn glob in there into
  # a match group. Multiple globs turn into one group as well, including string
  # parts in between.
  match_grep "${1:?}" | sed 's/\*\(.*\*\)\?/\(\.\*\\)/'
}


list_executables () # _ [Newer-Than]
{
  list_src_files find_executables "${2-}" ""
}

list_lib_sh_files () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" "" ".lib.sh"
}

list_scripts () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" '^\#\!'
}

# List any /bin/*sh or non-empty .sh/.bash file, from everything checked into SCM
list_sh_files () # [Generator] [Newer-Than]
{
  #shellcheck disable=2086
  list_src_files "${1-}" "${2-}" "$sh_shebang_re" $sh_file_exts
}

list_src_files () # Generator Newer-Than Magic-Regex [Extensions-or-Globs...]
{
  declare generator="${1:-"vc_tracked"}" nt=${2:-} mrx=${3:-}
  shift 3
  { test "$generator" = - || "$generator"; } | while read -r path ; do

# Cant do anything with dirs or empty files
    test ! -d "$path" -a -s "$path" || continue

# Allow for faster updates by checking only changed files
    test -z "$nt" || {
        test "$path" -nt "$nt" || continue
    }

# Scan name extension or glob match first
    test $# -eq 0 || {
        declare m
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
      head -n1 "$path" | grep -qm 1 "$mrx" || continue
    }
    echo "$path"
  done
}


# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test.
match_grep () # String
{
  echo "${1:?}" | sed -E 's/([^A-Za-z0-9{}(),?!@+_])/\\\1/g'
}
# Copy


# Parameters from *nix line comments (# prefix) are keys prefixed by '@',
# separated from value by ': '. Values may be empty, and are otherwise taken
# literally from source. Keys may have some special characters, but will be
# V-Id encoded for indexing and access.
params_sh ()
{
  grep -Po '^#  *@\K[A-Za-z_-][A-Za-z0-9:\./\\_-]*:.*' "$@" |
  awk '{ st = index($0,":") ;
      key = substr($0,0,st-1) ;
      gsub(/[^A-Za-z0-9_]/,"_",key) ;
      print "build_" key "_targets=\"" substr($0,st+2) "\"" }'
}


# Read only data, trimming whitespace but leaving '\' as-is.
# See read-escaped and read-literal for other modes/impl.
read_data () # (s) ~ <Read-argv...> # Read into variables, ignoring escapes and collapsing whitespacek
{
  read -r "$@"
}
# Copy

# Read character data separated by spaces, allowing '\' to escape special chars.
# See also read-literal and read-content.
read_escaped ()
{
  #shellcheck disable=2162 # Escaping can be useful to ignore line-ends, and read continuations as one line
  read "$@"
}
# Copy


# XXX: functions and variables have different namespaces
sh_clear ()
{
  true "${@:?}"
  typeset vardecl exectype
  while test $# -gt 0
  do
    vardecl=$(typeset -p "${1:?}") && {
      sh_unset "$1" || return

    } || {
      sh_type_clear "$1" || return
    }
    shift
  done
}

sh_fun ()
{
  test "$(type -t "${1:?}")" = "function"
}
# Copy

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
  typeset -f "${1:?}"
  #type "${1:?}" | tail -n +2
}

sh_lookup () # ~ <Paths...> # Lookup paths at PATH.
# Regular source or command do not look up paths, only declare (base) names.
{
  declare n e bd found foundany sh_path=${sh_path:-} sh_path_var=${sh_path_var:-PATH}

  test -n "$sh_path" || {
    sh_path=${!sh_path_var:?}
  }

  for n in "${@:?}"
  do
    found=false
    for bd in $(echo "$sh_path" | tr ':' '\n')
    do
      for e in ${sh_exts:-""}
      do
        test -e "$bd/$n$e" || continue
        echo "$bd/$n$e"
        found=true
        true "${foundany:=true}"
        ${any:-false} && continue
        break 2
      done
    done
    ${found} && {
      ${any:-${every:-false}} && continue
      ${first:-true} && return || continue
    } || {
      ${any:-false} && continue || return
    }
  done
  ${none:-false} || {
    ${any:-false} && {
      ${foundany:-false} || return
    } || {
      $found
    }
  }
}
# Copy

sh_null ()
{
  "$@" >/dev/null
}

sh_source ()
{
  while test $# -gt 0
  do
    source "${1:?}" || return
    shift
  done
}

sh_type_clear () # [exectype] ~ <Sym>
{
  true "${exectype:=$(type -t "${1:?}")}"
  case "$exectype" in
  ( "function" ) unset -f "$1" ;;
  ( "alias" ) unalias "$1" ;;
  ( * ) $LOG error ":sh-clear" "Cannot unset type" "$exectype:$1" 1 ;;
  esac
}

# Remove variable, from exports as well
sh_unset () # ~ <Var-name>
{
  # TODO: clear other var types
  unset "$@" && declare +x "$@"
}

sh_unset_ifset () # ~ <Sym <...>>
{
  true "${@:?}"
  typeset vardecl
  while test $# -gt 0
  do
    vardecl=$(declare -p "${1:?}" 2>/dev/null ) && {
      sh_unset "$1" || return
    }
    shift
  done
}

test_same_dir () # ~ <Dir-path-1> <Dir-path-2>
{
  test "$(realpath "${1:?}")" = "$(realpath "${2:?}")"
}


env__define__ifdone ()
{
  declare -ga target_arr ood_arr
  mapfile -t target_arr <<< $(build-targets) || return
  mapfile -t ood_arr <<< $(build-ood) || return
}

is_target ()
{
  declare target
  for target in "${target_arr[@]}"
  do
    if [ "$target" = "${1:?}" ] ; then
      return
    fi
  done
  return 1
}

is_ood ()
{
	declare target
	for target in "${ood_arr[@]}"
	do
	  if [ "$target" = "${1:?}" ] ; then
			return
	  fi
	done
	return 1
}

build_sources ()
{
  declare tag
  while test $# -gt 0
  do
    tag=${1:?}
    read -r fun line script <<< $(declare -F env__define__"${tag//-/_}")
    test -n "${line:-}" || {
      $LOG error ":build-declare" "No extdebug info for" "$tag"
      # return 1
    } || {
      ENV_PART[$tag]=$script
      #build-ifrule if scr-fun "$script" "$fun"

      #build-ifrule if "$script" -- eval "source \"$script\" && build-stamp <<< \"\$(declare -f \"$fun\")\""

    }
    shift
  done
}


## Wrappers for Redo commands and additional build frontend handlers


build_rule_target ()
{
  ${BUILD_NS_:?}$1
}

build-ifrule ()
{
  build-ifchange "$(build_rule_target "$@")"
}


# Return non-zero when target(s) are OOD

build-ifdone ()
{
  while test $# -gt 0
  do
    is_target "${1:?}" ||  {
      ${quiet:-false} ||
        $LOG error ":build-ifdone[${BUILD_TARGET//%/%%}]" "No such target" "$1"
      return 1
    }
    # Target is up-to-date unless it appears in OOD listing
    ! is_ood "${1:?}" || {
      ${quiet:-false} ||
        $LOG warn ":build-ifdone[${BUILD_TARGET//%/%%}]" "Target is out of date" "$1"
      return 1
    }
    shift
  done
}


# These strip targets from output that are marked as purely virtual by specific
# character #prefix, and they hide up-path targets behind one '../...' line to
# keep things readable.

build-ood ()
{
  test $# -eq 0 || return "${_E_GAE:-$?}"
  command ${BUILD_TOOL:?}-ood | build_list_strip_phony
}

#shellcheck disable=2120
build-sources ()
{
  test $# -eq 0 || return "${_E_GAE:-$?}"
  command ${BUILD_TOOL:?}-sources | build_list_strip_phony
}

#shellcheck disable=2120
build-targets ()
{
  test $# -eq 0 || return "${_E_GAE:-$?}"
  command ${BUILD_TOOL:?}-targets | build_list_strip_phony
}

build_list_strip_phony ()
{
  grep -v '^'"${BUILD_VIRTUAL_RE:?}" |
    sed 's/^\.\..*$/..\/.../g' |
    awk '!a[$0]++' || true
}


_unredo ()
{
  (
    unset REDO_NO_OOB \
      REDO_BASE \
      REDO_PWD \
      REDO_STARTDIR \
      REDO_TARGET \
      REDO_UNLOCKED \
      REDO_RUNID \
      REDO_CHEATFDS \
      REDO_CYCLES \
      REDO_DEPTH \
      REDO_UNLOCKED \
      REDO
    declare -x REDO_NO_OOB \
      REDO_BASE \
      REDO_PWD \
      REDO_STARTDIR \
      REDO_TARGET \
      REDO_UNLOCKED \
      REDO_RUNID \
      REDO_CHEATFDS \
      REDO_CYCLES \
      REDO_DEPTH \
      REDO_UNLOCKED \
      REDO

    build-ifchange "${@:?}"
  )
}


# Additional build frontends

# List build and recipe lines using show-source build-resolver mode.
#
# While build-which shows any potential path, this shows the script lines that
# a build for a target would have triggered. XXX: this can be expanded or
# raw. To show other internals see build-symbol.
build-show ()
{
  test $# -eq 1 || return "${_E_GAE:-$?}"
  BUILD_TARGET=${1:?}
  BUILD_TARGET_BASE=
  BUILD_TARGET_TMP=
  BUILD_BASE=${CWD:-$PWD}
  # XXX:
  BUILD_STARTDIR=${BUILD_BASE:?}
  build_for_target
}

# Lookup target by using the list-sources build-resolver handler mode.
#
# Helper to resolve different values for virtual targets, in addition to
# build-show and build-which. While build-which lists a entire lookup sequence
# with for all potental targets, this prints the one actual spec that was
# triggered.
#
# This is not so useful by itself, but we can also list any prerequisites and
# parts (sub-targets), as well as the Id for the actual handler that is
# responsible for the recipe.
#
# Based on that we could say the target name is symbolic for one or all of its
# parts.
# For certain targets, there is only one actual source that it refers to so we
# can use the target name as a symbol for that, instead of the full path.
# But build.lib has no concept of 'symbolic targets' built in. All of the
# basic rule types can either represent one or a sequence of targets, even
# defer which resolved to only one part can accept further arguments.
# currently what is a prerequisite or a part has not been completely figured
# out.
# XXX: see build-symbolic-target
build-symbol ()
{
  true "${@:?}"
  while test $# -gt 0
  do
    ${quiet:-true} || {
      echo "# Target symbol: $1"
    }
    list_sources=true
    {
      ${quiet:-true} && {
        build-show "$1" > /dev/null || return
      } || {
        build-show "$1" || return
      }
    } #| awk '!a[$0]++'
    ${quiet:-true} || {
      echo "$BUILD_HANDLER"
    }
    echo "$BUILD_SPEC"
    shift
  done
}

# For the +U-s build, '&' by convention indicates a symbolic ref to a file.
# So we can use build- symbol to get the actual file using the following line:
#
# $ build-symbol \&build-rules | tail -n -3 | head -n 1
#
build_symbolic_target ()
{
  declare target
  target=$(quiet=false build-symbol "$@" | tail -n -3 | head -n 1) || return
  # XXX: test build_target "$target"
  build_targets_ "$target"
  echo "$target"
}

build-sym ()
{
  test $# -eq 1 || return "${_E_GAE:-$?}"
  build_symbolic_target "$@"
}

build-symbolic-target ()
{
  test $# -eq 1 || return "${_E_GAE:-$?}"
  build_symbolic_target "$@"
}


# Rebuild if any directory index changes.
# XXX: this stamps file list but only name, not all attributes, times
build-ifdirchange ()
{
  true "${@:?}"
  while test $# -gt 0
  do
    TARGET_ALIAS=os-dir-index redo-ifchange "$1" || return
    shift
  done
}
# XXX: tools generate
build_env__boot__ood=BUILD_TOOL

build-ifglobchange ()
{
  true "${@:?}"
  while test $# -gt 0
  do
    TARGET_ALIAS=os-path-glob redo-ifchange "$1" || return
    shift
  done
}


# Helper for frontend to run command handler, calls first function from
# build{-,_}<action> after running build-boot.
# During the routine the following
# global variables are set:
# - BUILD_BOOT argument(s) to build-boot. Default: 'build-action', set empty to let build-boot use BUILD_ENV from build-env.
# - BUILD_ACTION to the first argument if set and not empty
# - ENV_STATIC all current keys from ENV_DEF
# - ENV_BOOT all keys from ENV_DEF after bootstrap
# - BUILD_DEPS the difference
# XXX: clean that up
build_ () # ~ <Build-action> <Argv <...>>
{
  declare -a ENV_STATIC=( "${!ENV_DEF[@]}" )
  declare BUILD_ACTION=${1:-${BUILD_ACTION:?}} build_action_handler r
  test $# -eq 0 || shift

  # build-* handlers override exists else defer execution to build_<action>
  build_action_handler=build-"$BUILD_ACTION"
  sh_fun "$build_action_handler" && {
    "${build_action_handler}" "$@"
    return
  }

  build_action_handler=build_$(build_target_name__function "${BUILD_ACTION:?}")

  declare ret
  build_boot ${BUILD_BOOT-env-path log-key build-action} || { ret=$?
      test $ret -eq ${_E_break:-197} && exit
      $LOG error ":[${BUILD_TARGET//%/%%}]" "Failed bootstrapping" \
        "E$ret:action=${BUILD_ACTION:?}"
      return $ret
    }
  declare -a ENV_BOOT=( "${!ENV_DEF[@]}" )
  $LOG info "" "@@@ Bootstrap for '${BUILD_ACTION:?}' done" "${ENV_BOOT[*]}"

  sh_fun "$build_action_handler" || { ret=$?
    $LOG error "" "No such entrypoint" "$build_action_handler" $ret
    exit $ret
  }
  $LOG debug "" "Ready for script '$BUILD_ACTION'" "$*"

  # Execute build-action

  "${build_action_handler}" "$@" || ret=$?

  $LOG debug "" "Finished script '$BUILD_ACTION'" "E${ret:-0}:$*"

  # XXX: When finished, add all env parts used during bootstrap to dependencies
  #test -z "${BUILD_ID-}" &&
  #  $LOG warn "" "No build ID" ||
  #    test ${BUILD_ACTION:?} != env-build ||
  #      test ${ret:-0} -ne 0 || {
  #        build_set_dependencies || ret=$?
  #        test 0 -eq ${#BUILD_DEPS[*]} ||
  #          $LOG warn ":[${BUILD_TARGET//%/%%}]" "Added dependencies" "E${ret:-0}:${BUILD_DEPS[*]}"
  #      }

  test ${ret:-0} -eq ${_E_break:-197} && exit
  return ${ret:-0}
}


test -n "${__lib_load-}" || {

  # Safe script's entry point name as BUILD_SCRIPT, or re-use SCRIPTNAME
  BUILD_SCRIPT=${SCRIPTNAME:-$(basename -- "$0" )}
  case "$BUILD_SCRIPT" in

    ( "build-" )
        build_ "$@"
      ;;

    ( "build-"* )
        BUILD_ACTION=${BUILD_SCRIPT:6} build_ "" "$@"
      ;;

    ( "build" )
        build_ run "$@"
      ;;

    ( "-"* )
      ;;

    ( * )
      ;;
  esac
}

# Id: Users-Scripts/0.0.2-dev  build.lib.sh  [2018-2022; 2018-11-18]
