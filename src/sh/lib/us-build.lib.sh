nit.
### us-build: a simple file-preprocessor for assembling scripts


us_build_lib__load ()
{
  : "${USER_TOOLS_CACHE:=$HOME/.local/var/user-tools}"

  : "${US_BUILD_CACHE_PREF:=us-preproc--}"

  # XXX: Set default ref to context and (set) name for built-in directives
  : "${us_build_proc_default:=u-s:tools/us/preproc/base}"

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

  : "${us_build_target_ext=.sh}"

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

# Take us-build-proc-default and determine init{base,import} from that.
# Ie. with 'u-s:tool/us/preproc/base'
# context init
#   base 'u-s'
#   part 'base:*'
#   import 'tool/us/preproc/base.sh'
# tool/bash/exec and base

us_build_init () # ~
{
  : "${us_build_proc_default%/*}"
  : "${_//[/]/:}"
  us_preproc_vardefs["$_"]=${us_build_proc_default%/*} us_preproc_initbase=$_
  us_preproc_initimport="${us_build_proc_default##*/}"

  [[ ${us_preproc_vardefs[":"]-} ]] || {
    us_preproc_vardefs[":"]=.build:
    us_preproc_vardefs[".build"]=${PPBASE:-${PWD}}
  }

  #[[ ${us_preproc_vardefs[":"]} = "${us_preproc_initbase}" ]] && {
  #  us_preproc_context=${us_preproc_vardefs[":"]}
    #us_build_context "${us_preproc_context:?}"

    us_preproc_src+=( "$us_preproc_initimport.sh" )
  } || {
    stderr echo Need context "${us_preproc_initbase}"
    us_build_context "${us_preproc_initbase}" ||
      return
    us_preproc_src+=( "$ctx_dir/$us_preproc_initimport.sh" )
  }

  us_debuglog "Importing main suite" "$us_preproc_initbase:$us_preproc_initimport"
  . "$us_preproc_initimport.sh" || return
  # uc_script_load $us_preproc_initimport.sh

  stderr echo us-build init PID $$
  stderr declare -p \
    PWD BASH_COMMAND BASH_ARGV \
    us_preproc_vardefs \
    us_build_proc_default us_preproc_init{base,import} us_preproc_context us_preproc_src
}

# Ensure template has .sh suffix, and reset cached, tpl and meta for template value.
# All values will be all global and absolute paths.
us_build__template_set () # ~ <Target> <...>
{
  local ext=$us_build_target_ext
  templateref=${1:?}
  template=$(us_build_value "$templateref") || return
  str_globmatch "$template" "/*" || {
    stderr echo "Expected global template (build-base=$bbase), proceeding with PWD/$template"
    template="$PWD/$template"
  }
  : "${template%$ext}"
  cached="${USER_TOOLS_CACHE:?}/${US_BUILD_CACHE_PREF:?}${_//\//--}$ext"
  meta="${cached%$ext}.meta.sh"
  template="${template%$ext}$ext"
  tpl=$template.build

  stderr echo Target set
  stderr declare -p template{,ref} PWD cached meta tpl
  us_preproc_src+=( "$tpl" )
  sys_debug &&
    $LOG debug ":us-build[$templateref]" "Env established" "$tpl:meta:$meta" ||
    $LOG info ":us-build[$templateref]" "Env established" "$tpl"
}

us_build__template_unset () # (template{,ref}) ~
{
  # FIXME: move to run directives?
  if_ok "$(declare -p us_preproc_src)" &&
  echo "$_" >| "$meta" ||
  us_ifnodev rm "$meta"
  $LOG info ":us-build[$templateref]" "Finished from ${#us_preproc_src[@]} sources" "meta:$meta"
}

# Return if template is up-to-date, or assemble new one in Cache-Dir
us_build () # ~ <Target> # Assemble if missing or out-of-date
{
  local cached meta tpl ood cmdpref

  : "${base:-us}"
  : "${_,,}"
  : "${_//[^a-z0-9]}"
  local bbase=$_-build
  ${bbase//-/_}__template_set "${1:?}" || return
  test 2 -ge $# || return ${_E_GAE:?}

  local lk=${lk:-${bbase}}[$templateref]
  $LOG info $lk "Looking at build state for template" "$1"

  # Source meta for cached build, test if template is UTD. Otherwise
  # always try to set regenerate.
  test -e "$template" -a -e "$meta" && {

    us_debuglog "Sourcing cached meta..." "$meta"
    . "$meta" &&
    us_debuglog_info "Testing cached meta" \
        "$meta:(${#us_preproc_src[@]}):${us_preproc_src[*]// /:}"

    { test 0 -lt "${#us_preproc_src[@]}" || {
        us_debuglog "No sources defined for template" "$tpl"
        ood=true
        false
      }
    } && { test "$template" -nt "$tpl" || {
        us_debuglog "Target OOD for template" "$tpl"
        ood=true
        false
      }
    } &&
    for file in "${us_preproc_src[@]}"
    do test "$template" -nt "$file" && {
      us_debuglog "Target UTD for source" "$file"
    } || {
      us_debuglog_info "Target OOD for source" "$file"
      ood=true; break; }
    done

    ! ${ood:-false} && {
      us_debuglog "Target and cache all up-to-date" "$templateref:$meta"
      return
    }
  } || {
    stderr echo "Target (or cache) missing" "$templateref:$meta"
    # FIXME
    #us_debuglog_info "Target (or cache) missing" "$templateref:$meta"
  }

  $LOG debug "$lk" "(Re)generating script..." "$templateref"

  # Run preproc, body transform and run directives to generate file
  "${NOACT:-false}" && {
    us_notice "*** NOACT ***: Process template" "$tpl"
    return
  } || {

    { us_build_preproc "$tpl" &&
      us_debuglog "Preprocessing done" "$templateref" &&
      us_build_proc "$tpl" &&
      us_debuglog "Main processing done" "$templateref" &&
      us_build_run "$tpl"
    } >| "$template" || {
      rm "$template"
      return 3
    }
  }

  ${bbase//-/_}__template_unset || return
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
    [[ ${1:0:1} = : ]] && {
      stderr echo Local namespace
      stderr declare -p PWD
      set -- "$PWD/${1:1}"
    } || {
      # Expand '*:' prefix using either vardefs table or env variable
      : "${1%%:*}"
      : "${_,,}"
      sh_adef us_preproc_vardefs "$_" &&
        set -- "${us_preproc_vardefs[$_]}/${1:$(( 1 + ${#_} ))}" || {
          : "${_^^}"
          : "${_//[^A-Z0-9_]/_}"
          set -- "${!_:?"Missing either '${1%%:*}' vardef or env"}/${1:$(( 1 + ${#_} ))}"
        }
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
    $LOG error "$lk" "Unknown context type" "E$?:$1,NODIR:$_" 3 || return
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
  echo "# % Generated on $(date --iso=min) from ${templateref:?}"
  echo "# % Do not edit; auto-generated from ${#us_preproc_src[@]} sources "
  $LOG info :run:proc "Generating script body" "$templateref"
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

us_build_v () # ~ <Target ...> # Verbose build of template
{
  $LOG info :run "Check script template" "$1"
  us_build "$@" ||
    $LOG alert :run "Script build failed" "E$?:$1" $? || return
}

# Check for dev mode, build and fork to template script. The flow is identical
# to us-run, except the current process exits and is replaced by a new instance
# running the template.
us_exec () # ~ <Target-script>
{
  us_fork=true us_run "$@"
}

# Build and run script. Fork to script when executable bit is set, otherwise
# source and exit. See us-run and us-exec,
# TODO: however also handle dev, debug and noact modes here
us_build_main () # (base) ~ <Target-script>
{
  : "${base:=us}"
  # XXX:
  #[[ ${us_preproc_vardefs[$base]-} ]] || {
  #  : "${base^^}"
  #  us_preproc_vardefs["$base"]=${!_:?"$(sys_exc us:main:base "" base)"}
  #}
  us_main_env debug noact
  us_main_devenv

  local template=$(us_build_value "${1:?}") || return
  local t="${template%$us_build_target_ext}"
  local lk=${lk:-${base}-main[$$]}:run

  test -x "$t$us_build_target_ext" && : "${us_fork:=true}"
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
  local template templateref=${1:?}
  shift
  us_build_v "$templateref" || return

  ! "${us_fork:-false}" && {
    "${NOACT:-false}" &&  {
      llk=:source
      us_notice "*** NOACT ***: Source template" "$template"
      return
    }
    us_notice "Sourcing script template" "$templateref"
    . "$template"
    us_notice "Returned from template" "E$?:$templateref" $?
    return
  }
  test -x "$template" &&
    set -- "$template" "$@" ||
    set -- bash -a "$base" "$template" "$@"
  us_notice "Forking to template" "$*"
  "${NOACT:-false}" && {
    llk=:exec
    us_notice "*** NOACT ***: Exec template" "$template"
    return
  }
  exec "$@"
}

us_ifdev ()
{
  ! sys_debug_mode dev && return
  "$@"
}

us_ifnodev ()
{
  sys_debug_mode dev && return
  "$@"
}

# FIXME: autodefine
# us-debuglog like us-debug only executes the given log command if DEBUG is on,
us_debuglog () # ~ <Message> [<Context>] [<Status>]
{
  us_debug $LOG debug "$lk" "$@"
}

# FIXME: autodefine
us_debuglog_info () # ~ <Message> [<Context>] [<Status>]
{
  us_debug $LOG info "$lk" "$@"
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
