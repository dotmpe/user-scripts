
### Build-r0.0 env parts


env__build__attributes ()
{
  build_targets_ "$attributes" || return
  attributes_sh "$attributes" >| "${BUILD_TARGET_TMP:?}" || return
  build-stamp < "${BUILD_TARGET_TMP:?}"
}

# Generate a copy of the build profile for caching.
env__build__build_env_cache ()
{
  env_require build-envs || return

  # Finally run some steps to generate the profile
  #set -- ${BUILD_ENV_STATIC:-${BUILD_BOOT-env-path log-key build-action}}
  set --
  $LOG warn ":build-env-cache($BUILD_TARGET)" "Building..." "$*"
  quiet=true build_env "$@" >| "${BUILD_TARGET_TMP:?}" || return
  build-stamp < "${BUILD_TARGET_TMP:?}"
}

env__build__package ()
{
  build_add_cache ./.meta/package/envs/main.sh
}

env__build__rule_params ()
{
  build_rules || return
  build_targets_ "${BUILD_RULES:?}" || return
  params_sh "${BUILD_RULES:?}" >| "${BUILD_TARGET_TMP:?}" || return
  build-stamp < "${BUILD_TARGET_TMP:?}"
}


env__define__argv ()
{
  #source "${U_S:?}/src/sh/lib/argv.lib.sh"
  source "${U_C:?}/script/argv-uc.lib.sh"
}

env__define__attributes ()
{
  test -n "${attributes:-}" || {
    test -e ".meta/attributes" && attributes=.meta/attributes
    test -e ".attributes" && attributes=.attributes
  }
  test -e "${attributes:-}" ||
    $LOG error ::attributes "None found" "" 1 || return

  attributes_sh="${PROJECT_CACHE:?}/attributes.sh"
  # On build
  test "${BUILD_TARGET:?}" = "$attributes_sh" && {
    env__build__attributes || return
    return ${_E_break:-197}
  }
  # On load: can handle env dependency in two ways:
  # 1. build-ifchange to update and then source, making cache file pre-requisite
  #    for whatever is current target.
  # 2. build-ifdone to abort on OOD cache.
  #    To allow the target to build, one or more special targets need to be
  #    specified on which an exception can be made here.

  #echo "attributes: ${build_at_build_env_targets:-@build-env}" >&2
  # XXX: still need to export from profile and load through parent
  { test "$BUILD_TARGET" = "${build_at_build_env_targets:-@build-env}"
  #{ build_target_group build-env || {
  #    test -n "${build_at_env_targets:-}" && build_env_target
  #  }
  } && {
    $LOG info ::attributes "Building and loading attributes" "$BUILD_TARGET"
    build_targets_ "${attributes_sh:?}" || return
  } || {
    ${BUILD_UNRECURSE:-false} && {
      $LOG info ::attributes "Starting isolated build for attributes" "$BUILD_TARGET"
      _unredo "${attributes_sh:?}" || return
    } || {
      $LOG info ::attributes "Checking to load attributes" "$BUILD_TARGET"
      env_require ifdone || return
      build-ifdone "${attributes_sh:?}" || return ${_E_OOB:-199}
    }
  }
  source "$attributes_sh" ||
    $LOG error "" "Sourcing attributes cache" "E$?:$attributes_sh" $? || return

  test "${BUILD_ACTION:-}" != "env-build" && return
  build_add_cache "$attributes_sh" &&
  build_add_source "$attributes" &&
  build_add_setting "attributes attributes_sh"
}

env__define__attributes_cache ()
{
  . "$attributes_sh"
}

env__define__build ()
{
  env_require build-env build-core build-lib build-init || return
  build_define_commands || return
  build_add_setting "BUILD_SPECIAL_RE BUILD_VIRTUAL_RE BUILD_TARGET_DECO" &&
  build_add_handler "$( for cmd in $(build_actions)
    do
      echo build${cmd:${#BUILD_TOOL}}
    done )"
}

env__define__build_action ()
{
  case "${BUILD_ACTION:?}" in
    ( bg )         set -- \
        from-local build-parts build-rules \
        fifo-server ;;
    ( env )        set -- from-dist ;;
    ( info ) ;;
    ( ood ) ;;
    ( run ) ;;
    ( sources ) ;;
    ( targets ) ;;
    ( target )     set -- from-local build-parts build-rules ;;
    ( env-build )  set -- from-local build-parts build-rules ;;
    ( which ) ;;
    ( show ) ;;
    ( symbol|sym|symbolic-target ) ;;
    ( ifdirchange ) ;;
    ( ifglobchange ) ;;
    ( * ) $LOG error "" "No such build action" "$BUILD_ACTION" ; return 1 ;;
  esac
  test $# -eq 0 && return
  #  build_env_sources ||
  env_require "$@" || return
  $LOG debug "" "Build action '$BUILD_ACTION' booted" "$*"
}

env__define__build_core ()
{
  build_add_handler \
"$(sh_fun_for_pref "build_install_")"\
" $(sh_fun_for_pref "build_which")"\
" $(sh_fun_for_pref "build_target")"\
" $(sh_fun_for_pref "build_for_target")"\
" build_env_sh build_env_vars build_sh"\
" build_boot build_lib_load build_env_sources"\
" build_source"\
" build_resolver"\
" sh_lookup"\
" build_rules build_from_rules read_data sh_fun_body sh_fun_type"\
" build_env_rule"\
" build_rule_exists build_rule_fetch"\
" fnmatch mkvid match_grep sh_fun"\
" build_ sh_unset sh_unset_ifset"\
" build_alias_part build_unalias"\
" expand_format"\
" glob_spec_var"\
" glob_spec_grep"
}

# Handle local sh/yaml build-env
env__define__build_env ()
{
  false # TODO: need a BUILD_ENV setting
}

# Default env part for builds to bootstrap from a generated profile file.
# This includes a built-in target handler, but the local project can provide a
# recipe for the local frontend (ie. a redo file) to override.
#
# The intention of the cache file is so that any build script (ie. a build.lib
# frontend or recipe script) can use it to quickly bootstrap with one source
# invocation.
#
# Usually, the current build would want to add a some dependency on this
# cache file (using build-ifchange) and then source the fresh file after that.
# That would however taint every target in the system with a direct
# dependency and invalidate every time the cache file is touched. Just like
# with the default recipe file, individual build targets would want much more
# precise target trigger and validation.
#
# That does not leave this env part much options. Strictly taken, it should
# abort the current build target when the cache is out of date.
#
env__define__build_env_cache ()
{
  env_require build-function-targets || return

  # Built-in recipe for cache file with accumalated profile.
  # Project could include $BUILD_ENV_CACHE.do file to override built-in recipe
  true "${BUILD_ENV_CACHE:="${PROJECT_CACHE:=".meta/cache"}/${BUILD_TOOL:?}-env.sh"}"
  test "${BUILD_TARGET:?}" = "$BUILD_ENV_CACHE" && {
    build_targets_ :if-scr-fun:${U_S:?}/tools/sh/parts/build-r0-0.sh:env__build__build_env_cache || return
    #build_targets_ :env:BUILD_ENV_STATIC,BUILD_BOOT

    # Include any libs that might override env:build:build-env-cache
    env_require build-libs || return
    # Run build routine
    env__build__build_env_cache || return
    return ${_E_stop:-197}
  }

  #echo "build-env: ${build_at_build_env_targets:-@build-env}" >&2
  # Build during particular build phases only. Outside the proper lifecycle,
  # either run out-of-steam with OOD error or
  # trigger a sub-build in such a way that it does not leave a
  # direct dependency.
  # Configurtion needs some checks to validate. But build is already slow.
  { test "$BUILD_TARGET" = "${build_at_build_env_targets:-@build-env}"
  #{ build_main_target || {
  #    test -n "${build_at_env_targets:-}" && build_env_target
  #  }
  } && {
    $LOG info ::build-env-cache "Building and loading build-env cache" "$BUILD_TARGET"
    build_targets_ "$BUILD_ENV_CACHE" || return ${_E_OOB:-199}
  } || {
    ${BUILD_UNRECURSE:-false} && {
      $LOG info ::build-env-cache "Starting isolated build" "$BUILD_TARGET"
      _unredo "${BUILD_ENV_CACHE:?}" || return
    } || {
      $LOG info ::build-env-cache "Checking to load build-env cache" "$BUILD_TARGET"
      env_require ifdone || return
      build-ifdone "$BUILD_ENV_CACHE" || return
    }
  }
  source "$BUILD_ENV_CACHE" ||
    $LOG error "" "Sourcing build-env cache" "E$?:$BUILD_ENV_CACHE" $?

  #test "${BUILD_ACTION:-}" != "env-build" && return
  #build_add_setting "BUILD_ENV_CACHE"
}

env__define__build_envs ()
{
  build_add_setting "ENV_BUILD_ENV"
  test -n "${ENV_BUILD_ENV:-}" && return
  test -n "${sh_exts:-}" -a -n "${build_envs_defnames:-}" ||
    build_lib_load || return

  # To aid during bootstrap phase, find and source any helper profile
  ENV_BUILD_ENV=$(sh_path=. any=true none=true first=true \
      sh_lookup ${build_envs_defnames:?}) || return

  test -z "${ENV_BUILD_ENV:-}" || {
    sh_source $ENV_BUILD_ENV || $LOG error :build-envs \
      "Sourcing build-envs returned error" "E$?:$ENV_BUILD_ENV" $? || return
    ENV_BUILD_ENV="${ENV_BUILD_ENV//$'\n'/:}"
    $LOG debug :build-envs "Loaded helper profile(s)" "$ENV_BUILD_ENV"
  }
}

# Building from functions for certain targets as part of bootstrap, is made
# possible by this.
#
env__define__build_function_targets ()
{
  test "${BUILD_TARGET:0:1}" != "${BUILD_NS_:?}" && return

  env_require ${BUILD_FUNCTIONS_ENV-build-envs build-libs build-init} || return
  env_require argv || return

  # XXX:
  declare rule r
  rule=${BUILD_TARGET:1}
  rule=${rule//::/ -- }
  rule=${rule//:/ }
  # XXX:
  rule=${rule//\?/:}
  $LOG info ::build-function-targets "Trying rule at boot time..." "${rule//%/%%}"
  build_target_rule ${rule} && {
    return ${_E_break:-197}
  } || { r=$?
    test $r -eq ${_E_continue:-196} && return
    $LOG error "::build-function-targets" "Failed to build from rule" "E$r:$rule" $r
  }
}

env__define__build_init ()
{
  test -z "${BUILD_ID:-}" && {
    env_require build-session || return
  } || {
    env_require build-${BUILD_TOOL:?} || return
  }
  build_lib_load && # XXX: can use build_lib_init here at some point?
  build_define_commands || return
}

env__define__build_lib ()
{
  source "${U_S:?}/src/sh/lib/${BUILD_TOOL:?}.lib.sh" &&
    ${BUILD_TOOL:?}_lib_load
}

env__define__build_lib_local ()
{
  source "$CWD/build-lib.sh" &&
    build__lib_load &&
    unset -f build__lib_load
}

env__define__build_libs ()
{
  build_add_setting "ENV_BUILD_LIBS"
  test -n "${ENV_BUILD_LIBS:-}" && return
  test -n "${sh_exts:-}" -a -n "${build_libs_defnames:-}" ||
    build_lib_load || return

  # Inject any local env scripts
  ENV_BUILD_LIBS=$(sh_path=${BUILD_PATH:?} none=true any=true first=false \
      sh_lookup ${build_libs_defnames:?}) || return

  test -z "${ENV_BUILD_LIBS:-}" || {
    sh_source $ENV_BUILD_LIBS || $LOG error :build-libs \
      "Sourcing build-libs returned error" "E$r:$ENV_BUILD_LIBS" $? || return
    ENV_BUILD_LIBS="${ENV_BUILD_LIBS//$'\n'/:}"
    $LOG debug :build-libs "Loaded helpers (libraries)" "$ENV_BUILD_LIBS"
  }
}

env__define__build_parts ()
{
  build_add_setting "BUILD_PARTS"
  test -n "${BUILD_PARTS:-}" && return

  { BUILD_PARTS=$(sh_exts="" sh_path=${BUILD_BASES:?} any=true first=false \
        sh_lookup tools/${BUILD_TOOL:?}/parts
    ) && test -n "$BUILD_PARTS" && BUILD_PARTS=${BUILD_PARTS//$'\n'/:}
  } &&
    $LOG debug ::build-parts "Setting parts-path" "$BUILD_PARTS" ||
    $LOG error ::build-parts "Setting parts-path" "E$?:$BUILD_PARTS" $?
}

env__define__build_rules ()
{
  build_add_setting "BUILD_RULES"
  test -n "${BUILD_RULES:-}" && return
  BUILD_RULES="$(sh_exts="" sh_path=. any=true sh_lookup \
      ${build_rules_defnames:?})" || return

  #test "$BUILD_TARGET" = "${build_at_build_env_targets:-@build-env}" || {
  #  build-ifchange "$BUILD_RULES"
  #}
}

env__define__build_session ()
{
  test "${BUILD_TOOL:?}" != null || {
    $LOG warn "" "Build tool null"
  }

  true "${CWD:=$PWD}"
  true "${BUILD_BASE:=$CWD}"
  true "${BUILD_STARTDIR:=$PWD}"
  BUILD_PWD="${BUILD_STARTDIR:${#BUILD_BASE}}"
  test -z "$BUILD_PWD" || BUILD_PWD=${BUILD_PWD:1}

  test -n "${BUILD_PATH:-}" || {
    test -z "$BUILD_PWD" && BUILD_PATH=$CWD || BUILD_PATH=$PWD:$BUILD_BASE
  }
  true "${BUILD_ID:=}"
  true "${BUILD_SCRIPT:=$0}"
}

#  test "unset" != "${build_source[*]-unset}" || env__define__build_source

# @env:def:build-source
env__define__build_source ()
{
  # Mapping real path to local source-path for scriptfile
  declare -gA build_source
  #declare -ga build_source_
}

env__define__env_path ()
{
  test -n "${ENV_PATH:-}" || {
    ENV_PATH=tools/sh/parts
    sh_exts=.sh
    env_require from-dist || return
  }

  test "${ENV_PATH:-}" != "tools/sh/parts" || {
    { ENV_PATH=$( for pp in tools/{sh,ci,main}/parts
      do
        sh_exts= sh_path=${BUILD_BASES:?} any=true first=false \
          sh_lookup "$pp" || return
      done
      ) && test -n "$ENV_PATH" && ENV_PATH=${ENV_PATH//$'\n'/:}
    } &&
      $LOG debug ::env-path "Setting env-path" "$ENV_PATH" ||
      $LOG error ::env-path "Setting env-path" "E$?:$ENV_PATH" $? || return
  }

  build_add_setting "ENV_PATH"
}

env__define__fifo_server ()
{
  source "${US_BIN:?}/bg.lib.sh"
}

env__define__from_dist ()
{
  source "${U_S:?}/tools/sh/build-env-defaults.sh"

  build_add_setting "BUILD_DECO_NAMES BUILD_TARGET_DECO BUILD_TARGET_ALIAS"
    build_add_setting "BUILD_NS_DIR BUILD_SPECIAL_RE BUILD_VIRTUAL_RE BUILD_NS BUILD_NS_"
  build_add_setting PROJECT_CACHE

  #BUILD_PATH
  build_add_setting "CWD BUILD_RULES BUILD_RULES_BUILD"
  build_add_setting "BUILD_BASES BUILD_NS BUILD_NS_DIR BUILD_TOOL"
  build_add_setting "build_main_targets build_all_targets"
}

env__define__from_package ()
{
  true "${BUILD_TOOL:=${package_build_tool:?}}"
  true "${BUILD_RULES:=${package_build_rules_tab:?}}"

  #true "${init_sh_libs:="os sys str match log shell script ${BUILD_TOOL:?} build"}"

  true "${build_main_targets:="${package_tools_redo_targets_main-"all help build test"}"}"
  true "${build_all_targets:="${package_tools_redo_targets_all-"build test"}"}"
  # dep package
  # vars BUILD_TOOL BUILD_MAIN_TARGETS BUILD_ALL_TARGETS
}

env__define__from_local ()
{
  env_require build-envs build-libs build-init from-dist || return
  env_require ${BUILD_ENV:-} || return
  build_add_setting "BUILD_ENV"
  #env_autoconfig attributes build-rules build-params
}

env__define__log_key ()
{
  test -z "${log_key:-}" && {
    declare -x log_key=BUILD[$$]
  } || {
    fnmatch "*\[$$\]*" "${log_key:-}" && {
      # How can PID be already in log prefix?
      $LOG error "" "Nested build_${BUILD_ACTION:?} call?" "${BUILD_TARGET:-}"
    } || {

      case "${log_key:-}" in ( *":%%.do"* )
        # if '%.do[<pid>]' pattern is already present, only add own PID,
        # and abbreviate prev
        log_key=$( sed -E '
          s/:%%.do\[((([0-9\/-]+\/)?[0-9]{3})[0-9]*)\]/:%%.do[\2-\/'$$']/
        ' <<< "${log_key:?}" )
        # And at some point concat PID's to fixed with
        #log_key=$( sed -E '
        #    s/([0-9\/]+)(\/[0-9]+)/\3/
        #' <<< "${log_key:?}" )
      ;; ( * )
        log_key="${log_key:-}${log_key:+:}${BUILD_SCRIPT//default/%%}[$$]"
      ;; esac
      #test "$BUILD_ACTION" = target && {
      #  test $# -eq 0 && log_key="${log_key}:" || log_key="${log_key}($#)"
      #} || log_key="${log_key}:$BUILD_ACTION"
      declare -x log_key
    }
  }
}

env__define__null ()
{
  true
}

env__define__package_sh ()
{
  true "${PACKAGE:=$( sh_path=. any=true
    sh_lookup {.,}package.{sh,yml,yaml} )}"

  test -e "$PACKAGE" || {
    $LOG error ":env::package.sh" "No package found"
    return 1
  }

  build_add_setting "PACKAGE"

  fnmatch "*.sh" "$PACKAGE" && {
    build_add_cache "$PACKAGE" &&
    source "$PACKAGE"
    return
  }

  # XXX:
  { test -e ./.meta/package/envs/main.sh -a \
    ./.meta/package/envs/main.sh -nt "$PACKAGE"
  } || {
    htd package update && htd package write-scripts
  }
}

# Add 'params' (currently only generated from Build-Rules) to build-env. This
# builds, sources and declares a cache file with extracted build settings.
#
# Like any other target, but here in particular as part of 'build-env' or any
# other bootstrap, a target build should only ever be triggered during the
# appropiate (super) target(s). Because any way you look at it,
# with the current Redo toolkit, doing so adds a dependency for the current
# target (state) on the to-be build target (state).
#
# With a progressive build sequence (ie. 'build test') that may seem valid.
# As part of 'test', a recipe can invoke 'build' and aside from a slight shift
# in dependency nesting and sequence at the upper level nothing substantially
# is different. This is very user 'friendly' and seamless, but it is not
# entirely logical and yet afaics Redo cannot deal with this in any way.
#
# Cf. example 'build' and 'configuration. A logical constraint could be that
# the latter has to be done completely before any of the former can happen.
# Only except that in the vanilla toolkit there is no way to tell Redo
# explicitly that an earlier state is known to have turned dirty again, and/or
# that this is expected and to be allowed, and most importantly to please go
# and up-date it before returning.
#
# NB. the build sequence itself ie. the redo{,-ifchange} parameters already
# sort of express a (possible) implicit relation.
# I don't think Redo exploits that anywhere. But what if we could tell it to?
#
# Redo's imperative nature encourages to write recipes that discover
# dependencies on the go. This is great, but it somewhat obfuscates that a
# build has phases like in a life cycle. It forces the user to sort that
# out, put targets in the correct 'phase', but at no point does it
# offer any help to deal with previously succesful targets going OOD during
# subsequent recipes. The user has to make that call, making Redo (or this
# particular build) instead of fully recursive rather somewhat repetitve...
#
# In another scenario a recursive initialization and configuration can happen
# in the same way, such as an upgrade of the code for example, during which
# new targets are discovered but 'too late'. The user has to correct the system
# for this, and unfortunately that probably means a more complex target setup
# and one I think that still cannot solve this one fundamental problem
# completely.
#
# Summarizing:
# Redo may complete a succesful run, but only upon re-invocation and provided
# nothing like the above happens again will the build finally be complete.
# Luckily, we can test for that situation using redo-ood. So a solution to
# this can be scripted, it is just that I don't see a way currently for a
# recipe to auto-correct this short of building this redo-ood check into it
# and probably specifying some maximum retry count.
#
# Usually that could be 'all', or any of the already established 'main' targets
# set, but it may be required to specify one or more designated build-env
# configuration targets. Furthermore, that setting would have to be already
# in the environment (exported?), because params could hold that configuration
# except it will not be loaded until it is no longer OOD and could not be
# loaded before the target dependency check anyway.
#
#
# So aside from allowing
# When loaded as part then building the
#
# only allowed during
# refuse to build it
#
env__define__rule_params ()
{
  # Built-in recipe for cache file with params extracted from annotations
  params_sh="${PROJECT_CACHE:?}/params.sh"
  test "${BUILD_TARGET:?}" = "$params_sh" && {
    env__build__rule_params || return
    return ${_E_stop:-197}
  }

  # Build as sub-dependency of @build-env only
  #echo "params: ${build_at_build_env_targets:-@build-env}" >&2
  { test "$BUILD_TARGET" = "${build_at_build_env_targets:-@build-env}"
  #{ build_main_target || {
  #    test -n "${build_at_env_targets:-}" && build_env_target
  #  }
  } && {
    $LOG info ::rule-params "Building and loading params" "$BUILD_TARGET"
    build_targets_ "$params_sh" || return
  } || {
    ${BUILD_UNRECURSE:-false} && {
      $LOG info ::rule-params "Starting isolated build for params" "$BUILD_TARGET"
      _unredo "${params_sh:?}" || return
    } || {
      $LOG info ::rule-params "Checking to load params" "$BUILD_TARGET"
      env_require ifdone || return
      build-ifdone "$params_sh" || return ${_E_OOB:-199}
    }
  }
  source "$params_sh" ||
    $LOG error "" "Sourcing params cache" "E$?:$params_sh" $? || return

  test "${BUILD_ACTION:-}" != "env-build" && return
  build_add_cache "$params_sh" &&
  build_add_source "${BUILD_RULES:?}" &&
  build_add_setting "BUILD_RULES params_sh"
}

env__define__stderr_ ()
{
  # TODO: move to build-env:build and handle as build target
  source "${C_INC:?}/tools/sh/parts/stderr-user.sh" &&
  #eval "$(compo- c-export stderr_ stderr_nolevel)" &&
  build_add_handler "stderr_ stderr_nolevel"
}

env__define__us_build ()
{
  sh_include_path_langs="redo main ci bash sh" &&
  . "${U_S:?}/tools/sh/parts/include.sh" &&
  sh_include lib-load &&
  package_build_tool=redo &&
  lib_load match redo build
}

env__define__us_libs ()
{
  sh_include_path_langs="redo main ci bash sh" &&
  . "${U_S:?}/tools/sh/parts/include.sh" &&
  sh_include lib-load
}

#
