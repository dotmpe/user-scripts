
### us-build: a simple file-preprocessor to assemble scripts


us_build_lib__load ()
{
  : "${USER_TOOLS_CACHE:=$HOME/.local/var/user-tools}"
  : "${US_BUILD_CACHE_PREF:=us-preproc--}"

  # XXX: Set default ref to context and (set) name for built-in directives
  : "${us_build_proc_default:=u-s:tools/u-s/preproc/base}"

  # List every built-in directive
  : "${us_build_proc_dirs:=INCLUDE DEFINE MODELINE RESOLVE}"

  : "${us_build_init_dirs:=IMPORT INIT}"
  : "${us_build_init_default:=IMPORT}"
  : "${us_build_run_dirs:=MODELINE RUN}"
  : "${us_build_run_default:=MODELINE}"

  # Filter unhandled preproc statements from output
  #: "${us_preproc_filterdirs:=false}"
  # Auto-append all included files to generated target's us-build-files list.
  #: "${us_build_autorun:=true}"

  : "${us_build_trgt_ext:=.sh}"
  # For DEFINE, define now so seeding is possible before lib-init
  declare -gA us_preproc_vardefs
}

us_build_lib__init ()
{
  test -z "${us_build_lib_init:-}" || return $_
  lib_require str || return
  declare -ga us_preproc_src=()
  #declare -a us_preproc_vars
  us_build_init
}

us_build_init () # ~
{
  : "${us_build_proc_default%/*}"
  : "${_//[/]/:}"
  us_preproc_vardefs["$_"]=${us_build_proc_default%/*} us_preproc_initbase=$_
  us_preproc_initimport="${us_build_proc_default##*/}"

  test -n "${us_preproc_vardefs[":"]:-}" || us_preproc_vardefs[":"]=$PWD

  test "${us_preproc_vardefs[":"]}" = "${us_preproc_initbase}" && {
    us_preproc_context=${us_preproc_vardefs[":"]}
    #us_build_context "${us_preproc_context:?}"
    us_preproc_src+=( "$us_preproc_initimport.sh" )
  } || {
    us_build_context "${us_preproc_initbase}" ||
      return
    us_preproc_src+=( "$ctx_dir/$us_preproc_initimport.sh" )
  }

  us_debuglog "Importing main suite" "$us_preproc_initbase:$us_preproc_initimport"
  . "$us_preproc_initimport.sh"
  # uc_script_load $us_preproc_initimport.sh
}

# Ensure target has .sh suffix, and reset cached, tpl and meta for target value.
# All values will be all global and absolute paths.
us_build__target_set () # ~ <Target> <...>
{
  local ext=$us_build_trgt_ext
  targetref=${1:?}
  target=$(us_build_value "$targetref") || return
  str_globmatch "$target" "/*" || target="$PWD/$target"
  : "${target%$ext}"
  cached="${USER_TOOLS_CACHE:?}/${US_BUILD_CACHE_PREF:?}${_//\//--}$ext"
  meta="${cached%$ext}.meta.sh"
  target="${target%$ext}$ext"
  tpl=$target.build
  us_preproc_src+=( "$tpl" )
  us_debug &&
    $LOG debug ":us-build[$targetref]" "Env established" "$tpl:meta:$meta" ||
    $LOG info ":us-build[$targetref]" "Env established" "$tpl"
}

us_build__target_unset () # (target{,ref}) ~
{
  # FIXME: move to run directives?
  if_ok "$(declare -p us_preproc_src)" &&
  echo "$_" >| "$meta" ||
  us_ifnodev rm "$meta"
  $LOG info ":us-build[$targetref]" "Finished from ${#us_preproc_src[@]} sources" "meta:$meta"
}

# Return if target is up-to-date, or assemble new one in Cache-Dir
us_build () # ~ <Target> # Assemble if missing or out-of-date
{
  local cached meta tpl ood cmdpref
  : "${base:?}"
  : "${_,,}"
  : "${_//[^a-z0-9]}"
  local base=$_-build
  ${base//-/_}__target_set "${1:?}" || return
  test 2 -ge $# || return ${_E_GAE:?}

  local lk=${lk:-${base}}[$targetref]

  # Source meta for cached build, test if target is UTD. Otherwise
  # always try to set regenerate.
  test -e "$target" -a -e "$meta" && {

    us_debuglog "Sourcing cached meta..." "$meta"
    . "$meta" &&
    us_debuglog_info "Testing cached meta" \
        "$meta:(${#us_preproc_src[@]}):${us_preproc_src[*]// /:}"

    { test 0 -lt "${#us_preproc_src[@]}" || {
        us_debuglog "No sources defined for template" "$tpl"
        ood=true
        false
      }
    } && { test "$target" -nt "$tpl" || {
        us_debuglog "Target OOD for template" "$tpl"
        ood=true
        false
      }
    } &&
    for file in "${us_preproc_src[@]}"
    do test "$target" -nt "$file" && {
      us_debuglog "Target UTD for source" "$file"
    } || {
      us_debuglog_info "Target OOD for source" "$file"
      ood=true; break; }
    done

    ! ${ood:-false} && {
      us_debuglog "Target and cache all up-to-date" "$targetref:$meta"
      return
    }
  } || {
    us_debuglog_info "Target (or cache) missing" "$targetref:$meta"
  }

  us_debuglog "(Re)generating script..." "$targetref"

  # Run preproc, body transform and run directives to generate file
  "${NOACT:-false}" && {
    us_notice "*** NOACT ***: Process template" "$tpl"
    return
  } || {
    { us_build_preproc "$tpl" &&
      us_debuglog "Preprocessing done" "$targetref" &&
      us_build_proc "$tpl" &&
      us_debuglog "Main processing done" "$targetref" &&
      us_build_run "$tpl"
    } >| "$target" || {
      rm "$target"
      return 3
    }
  }

  ${base//-/_}__target_unset || return
}

us_build__runline () # ~ <Rest>...
{
  str_wordmatch "$dir" $procdirs && {
    sh_fun us_preproc__${dir//[^A-Z0-9_]/_} ||
      $LOG alert : "No such directive" "$dir" 2 || return
    "$_" $* || return
  } || "${us_preproc_filterdirs:-false}" &&
    return ${_E_next:?} || return ${_E_ok:?}
}

# XXX: Expand context reference
us_build_value () # ~ <...
{
  ! str_globmatch "$1" "*:*" || {
    # Expand '*:' prefix using either vardefs table or env variable
    : "${1%%:*}"
    : "${_,,}"
    sh_adef us_preproc_vardefs "$_" &&
      set -- "${us_preproc_vardefs[$_]}/${1:$(( 1 + ${#_} ))}" || {
        : "${_^^}"
        : "${_//[^A-Z0-9_]/_}"
        set -- "${!_}/${1:$(( 1 + ${#_} ))}"
      }
  }
  # XXX: also allow var refs in definitions... but BWC mode, should be using vardefs
  if_ok "$(eval "echo \"${1:?}\"")" &&
  echo "$_"
}

us_build_context () # ~ <...
{
  local lk=${lk:-us:build}:context
  if_ok "$(us_build_value "$1")" &&
  test -d "$_" ||
    $LOG error "$lk" "Unknown context type" "E$?:$1:$_" 3 || return
  ctx_dir=$_
  PATH=$PATH:$ctx_dir
}

us_build_dir () # ~ <Line-prefix> [...]
{
  test -n "${1:-}" &&
  str_globmatch "${1^^}" "#[A-Z_-]*" && {
    : "${1:1}"
    #: "${_//[^A-Z0-9_]/_}"
    dir=${_^^}
  }
}

# Collect meta directives and generate script prologue with them
# Like the opposite 'run' this collects lines into an array, and then runs
# their each their handlers.
us_build_preproc () # ~ <File> [<Add-init-dirs>] [...]
{
  local l dir procdirs="${us_build_init_dirs:?}"
  test $# -gt 1 && {
    : "${*:2}"
    : "${_:?}"
    : "${_^^}"
    procdirs="$procdirs ${_//[^A-Z0-9_]/_}"
  }

  declare -ga us_build_preproc=()
  read -r -a us_build_preproc <<< "$(
    while read -r prefix rest
    do
      us_build_dir "$prefix" || continue
      echo "${prefix:-}${rest:+ }${rest:-}"
    done <<< "$(grep " ${procdirs// /\|} " "$1")")"
  $LOG debug :run:preproc "Found prologue directives" \
    "(${#us_build_preproc[*]})${us_build_preproc[*]:+ }${us_build_preproc[*]}"

  test 0 -lt "${#us_build_preproc[*]}" || us_build_preproc+=( "#build-preproc" )

  $LOG info :run:preproc "Generating initial script (prologue)" \
    "(${#us_build_preproc[*]})${us_build_preproc[*]:+ }${us_build_preproc[*]}"
  for l in "${us_build_preproc[@]}"
  do
    : "${l%% *}"
    : "${_#\#}"
    dir=${_^^}
    us_build__runline "$1" || {
      test ${_E_next:?} -eq $? && continue
      test ${_E_ok:?} -eq $_ ||
        $LOG error :run:preproc "Failed at" "E$_:$_" $? || return
    }
  done
}

# Output source with directives processed.
us_build_proc () # ~ <File> [<Additional-directives>...] [...]
{
  local prefix rest dir procdirs="${us_build_proc_dirs:?}"
  test $# -gt 1 && {
    : "${*:2}"
    : "${_:?}"
    : "${_^^}"
    procdirs="$procdirs ${_//[^A-Z0-9_]/_}"
  }
  echo "# % Generated on $(date --iso=min) from ${targetref:?}"
  echo "# % Do not edit; auto-generated from ${#us_preproc_src[@]} sources "
  $LOG info :run:proc "Generating script body" "$targetref"
  while read -r prefix rest
  do
    us_build_dir "$prefix" && {
      us_build__runline "$rest" || {
        test ${_E_next:?} -eq $? && continue
        test ${_E_ok:?} -eq $_ || return
      }
      # Only proc selected directives, output others verbatim
    } || {
      test -z "$prefix" ||
      str_globmatch "$prefix" "##*" ||
        echo "${prefix:-}${rest:+ }${rest:-}"
    }
  done < "$1"
}

# Collect run directives and generate script epilogue with them.
# See also the opposite 'preproc'.
us_build_run () # ~ <File> [<Additional-directives>...] [...]
{
  local l dir procdirs="${us_build_run_dirs:?}"
  test $# -gt 1 && {
    : "${*:2}"
    : "${_:?}"
    : "${_^^}"
    procdirs="$procdirs ${_//[^A-Z0-9_]/_}"
  }

  declare -ga us_build_run
  read -r -a us_build_run <<< "$(
    while read -r prefix rest
    do
      us_build_dir "$prefix" || continue
      echo "${prefix:-}${rest:+ }${rest:-}"
    done <<< "$(grep " ${procdirs// /\|} " "$1")")"
  $LOG debug :run:main "Found run directives" \
    "(${#us_build_run[*]})${us_build_run[*]:+ }${us_build_run[*]}"

  test 0 -lt "${#us_build_run[*]}" || us_build_run+=( "#build-run" )

  $LOG info :run:main "Generating main run script (epilogue)" \
    "(${#us_build_run[*]})${us_build_run[*]:+ }${us_build_run[*]}"
  for l in "${us_build_run[@]}"
  do
    : "${l%% *}"
    : "${_#\#}"
    dir=${_^^}
    us_build__runline "$1" || {
      test ${_E_next:?} -eq $? && continue
      test ${_E_ok:?} -eq $_ ||
        $LOG error :run:main "Failed at" "E$_:$_" $? || return
    }
  done
}

us_build_v () # ~ <Target ...> # Verbose build of target
{
  $LOG info :run "Check script target" "$1"
  us_build "$@" ||
    $LOG alert :run "Script build failed" "E$?:$1" $? || return
}

# Check for dev mode, build and fork to target script. The flow is identical
# to us-run, except the current process exits and is replaced by a new instance
# running the target.
us_exec () # ~ <Target-script>
{
  us_fork=true us_run "$@"
}

# Build and fork to script when executable bit is set, otherwise source and
# exit. See us-run and us-exec,
# TODO: however also handle dev, debug and noact modes here
us_main () # (base) ~ <Target-script>
{
  : "${base:=u-s}"
  test -n "${us_preproc_vardefs[$base]:-}" || {
    : "${base^^}"
    us_preproc_vardefs["$base"]=${!_:?}
  }
  us_main_env debug noact
  us_main_devenv

  local target=$(us_build_value "${1:?}") || return
  local t="${target%$us_build_trgt_ext}"
  local lk=${lk:-${base}-main[$$]}:run

  test -x "$t$us_build_trgt_ext" && : "${us_fork:=true}"
  # Execute (fork) or load script into current session, possibly return for exit
  us_run "$@"
  exit $?
}

us_main_env ()
{
  for opt in "$@"
  do
    # FIXME: sh_mode_ok "$opt" || return
    #str_globmatch "E:$opt" $SHMODE
    : "${opt^^}"
    test -n "${!_:-}" || {
      # XXX: refer to shmode or ctx here? Maybe some CTX precursor...
      str_globmatch "${opt,,}" $SHMODE && {
        declare -g ${opt^^}=true
      } ||
        declare -g ${opt^^}=false
    }
  done
  # XXX: go over {UC,US}_DEBUG, DIAG, NOACT as well somehow?
}

# XXX: during development, add other script files to us_preproc_src
us_main_devenv ()
{
    # XXX: CTX etc.
  case " ${SHMODE:?} " in
    ( *" build "* )
        export -f us_debug{,log}
        us_preproc_src+=( "$0" )
        us_preproc_src+=( "$U_S/src/sh/lib/us-build.lib.sh" )
      ;;
    ( *" strict "* )
        us_preproc_src+=( "$0" )
        #stderr us-main:strict echo 0=$0
      ;;
    ( *" dev "* )
        export -f us_debug{,log}
        us_preproc_src+=( "$0" )
        : "$(echo $ENV_LIB | tr ' ' '\n')"
        mapfile -O "${#us_preproc_src[@]}" -t us_preproc_src <<< "$_"
      ;;
  esac
}

# Check for dev mode, build and source target script. The flow is identical to
# us-exec, except the script re-uses the running shell instance and can
# possibly return from us-run after execution.
us_run () # ~ <Target> [<Args...>]
{
  local target targetref=${1:?}
  shift
  us_build_v "$targetref" || return

  ! "${us_fork:-false}" && {
    "${NOACT:-false}" &&  {
      llk=:source
      us_notice "*** NOACT ***: Source target" "$target"
      return
    }
    . "$target"
    return
  }
  test -x "$target" &&
    set -- "$target" "$@" ||
    set -- bash -a "$base" "$target" "$@"
  "${NOACT:-false}" &&  {
    llk=:exec
    us_notice "*** NOACT ***: Exec target" "$target"
    return
  }
  exec "$@"
}

sh_fun us_debug ||
  us_debug ()
  {
    "${US_DEBUG:-${DEBUG:-false}}"
  }

sh_fun us_dev ||
  us_dev ()
  {
    "${US_DEV:-${DEV:-false}}"
  }

us_ifdev ()
{
  ! us_dev && return
  "$@"
}

us_ifnodev ()
{
  us_dev && return
  "$@"
}

# FIXME: autodefine
us_debuglog () # ~ <Message> <Context>
{
  ! us_debug ||
  $LOG debug "$lk" "$@"
}

# FIXME: autodefine
us_debuglog_info () # ~ <Message> <Context>
{
  ! us_debug ||
  $LOG info "$lk" "$@"
}

us_main_log () # ~ <Level-ref> <Message> <Context>
{
  "${QUIET:-false}" ||
  $LOG "$1" "$lk" "${@:2}"
}

us_notice ()
{
  "${QUIET:-false}" ||
  $LOG notice "$lk${llk:-:notice}" "$@"
}

# Id: U-S:us-build.lib
