### Env.d

# Locate and track loaded parts. Parts are declared by ENVD_TYPE.

envd_lib__load ()
{
  lib_require str args sys-cmd &&
  declare -g ENVD_BASES &&
  sys_cmd_apop 2 sys_default ENVD_BASES env{,d} us build host user
}

envd_lib__init ()
{
  declare -g ENVD_{PATH,SLICE} &&
  declare -ga ENVD_{D,PATHA,SLICEA} &&
  declare -gA \
    ENVD_{DECL,DEF,DEP,FUN,HOOK,PART,TYPE,VAR} \
    LIB_{PRE,DEP} &&
  # Expose type array so (user) scripts can check for presence of env mngmnt
  declare -n \
    ENV_TYPE=ENVD_TYPE &&
  # TODO:
  #  str.lib/str-word os.lib/filter-args sys.lib/source-all sys.lib/var-assert
  envd_dtype envd.lib lib - - - \
    --vars \
      ENVD_{DEF,DEP,FUN,HOOK,PART,TYPE,VAR} \
      LIB_{PRE,DEP} \
    --funs \
      envd_restart envd_boot envd_require filter_args envd_declared \
      envd_define envd_load &&

  # Continue from existing envd (ie. from cache); initialize to use as current
  envd_loadenv || return

  ! sys_debug -dev -debug -init ||
    $LOG notice "" "Initialized envd.lib" "$(sys_debug_tag)"
}

# TODO: set TYPE
envd__update__us_def ()
{
  declare -ga US_DEF
  local base
  for base in ${ENVD_BASES:?}
  do
    # List all functions with prefix
    if_ok "$(compgen -A function ${base:?}__define__)" &&
    <<< "$_" mapfile -O ${#US_DEF[*]} -t US_DEF || continue
  done
}

# Build US_UPD[ part-id => bases ] from defined handlers (including this one)
envd__update__envd_var_update ()
{
  local base wid sid
  declare -a funs
  for base in ${ENVD_BASES:?}
  do
    blo=$(( ${#base} + 10 ))
    sys_arr funs compgen -A function ${base:?}__update__ || continue
    for fun in "${funs[@]}"
    do
      wid=${fun:$blo}
      sid=${wid//_/-}
      declare -n ref=envd_var_update["$sid"]
      [[ "set" = ${ref+set} ]] && {
        str_wordmatch "$base" $ref || ref=${ref-}${ref+ }$base
      } || ref=$base
    done
  done
}

# XXX:
envd_runner () # ~ <bases> <handle> <keys...>
{
  local base call
  call=$(str_join __ $(str_words "${@:2}"))
  for base in ${1:?}
  do
    $LOG info :envd-runner "Calling" "${base:?}__${call:?}"
    "${base:?}__${call:?}" ||
      $LOG error :envd-runner "Calling" "E$?:${base:?}.$(str_join . "${@:2}")" $? || return
  done
}

# Once envd itself is fully initialized, it can help with bootstrapping scripts
# based on the current system and user shell setup

# Helper to wrap envd-define, to keep running load/define resolve cycles until
# all parts are XXX: completely declared?
# For now this means ENVD_DEF status should become 0
envd_boot () # ~ <Initial-parts...>
{
  declare lk=${lk-}:env-boot
  declare tag ret
  while [[ $# -gt 0 ]]
  do
    ! "${DEBUG:-false}" || {
      : "($#) $*"
      $LOG debug "$lk" "Booting env..." "${_//%/%%}"
    }
    tag=${1:?}
    unset "ENVD_DEP[$tag]"
    envd_boot=true envd_define "$tag" ||
    { ret=$?
      [[ $ret -eq "${_E_break:-197}" ]] && return $ret
      [[ $ret -eq "${_E_retry:-198}" ]] ||
        $LOG error "$lk" "Error defn/decl" "E$ret:tag=$tag" $ret || return
      : "${ENVD_PENDING:?Pending expected for \"$tag\" E$ret = E:retry}"
      #shellcheck disable=2086
      set -- $ENVD_PENDING "$@"
      unset ENVD_PENDING
      continue
    }
    shift
  done
}

envd_cache_file ()
{
  declare -n file=${1:?}
  file=.meta/cache/envd-${2:?}.sh
}

envd_cache_load ()
{
  declare cache
  envd_cache_file cache "$1" &&
  . "$cache" &&
  envd_restart
}

envd_commit () # ~ <fk>
{
  declare cache
  envd_cache_file cache "$1" &&
  envd_dump >| "$cache"
}

# Declare current context, when used from within 'define' hooks.
# lib and dep may be CSV (or space separated strings).
# Declares is a list of long-options followed by arguments
# Outside Envd-Tag context initial argument may be option, with -n for new
# declaration (cannot exist) of tag followed by type, or -r to re-run declares
envd_declare () # ~ <Type-ref> <Preload-lib> <Post-reinit-lib> <Envd-dep> <declares ...>
{
  local lk=${lk-}:envd-declare
  # Given static Envd.Tag env, load default
  test -n "${ENVD_TAG-}" && {
    local type=${1-}
    [[ $type = "-" ]] && type=
    # FIXME: should really shift argv until --
    [[ "${2:--}" = "-" ]] || LIB_PRE["${ENVD_TAG:?}"]=${2//,/ }
    [[ "${3:--}" = "-" ]] || LIB_DEP["${ENVD_TAG:?}"]=${3//,/ }
    [[ "${4:--}" = "-" ]] || envd_require ${4//,/ } || return
  } || {
    [[ ${1:0:1} = "-" ]] || return
    local ENVD_TAG=${2:?}
    declare -n type=ENVD_TYPE["${ENVD_TAG:?}"]
    [[ ${#1} -gt 1 ]] && {
      [[ $1 = "-n" ]] && {
        [[ "unset" = "${type-unset}" ]] || return
        type=${3:?}
        shift 2
      } || {
        [[ $1 = "-d" ]] || return
        false
      }
    } || shift 1
    [[ "unset" != "${type-unset}" ]] || return
  }
  test $# -le 4 || {
    # XXX: reset values; declare now by running envd-declare:<type> for each
    # type (Envd.Tag) in <declare...>
    declare o=5
    while test $o -lt $#
    do
      declare cmd args=()
      test "${!o:0:2}" = "--" ||
        $LOG error "$lk" "Unknown option" "${!o}" $? || return
      : "${!o:2}"
      cmd=envd_declare__${_//-/_}
      o=$(( o + 1 ))
      args_hseq_arrv args "${@:$o}"
      "$cmd" "${args[@]}" || return
      o=$(( o + ${#args[@]} ))
    done
  }
}

envd_declare__funs () # ~ <Funs...>
{
  envd_declare__tagc fun "$@"
}

envd_declare__sources () # ~ <Paths...>
{
  envd_declare__tagc src "$@"
}

envd_declare__tagc () # ~ <Key> <Init-values...>
{
  : "${1:?}"
  local __us_envd_tagc=${_^^}
  sys_default "ENVD_${__us_envd_tagc}[${ENVD_TAG:?}]" "" &&
  str_append "ENVD_${__us_envd_tagc}[${ENVD_TAG:?}]" "${*:2}"
}

envd_declare__vars () # ~ <Names...>
{
  envd_declare__tagc var "$@"
}

envd_declared ()
{
  [[ "${ENVD_TYPE["${1:?}"]:+ne}" ]]
}

# Make every env part define everything about itself and its context
envd_define ()
{
  declare lk=${lk-}:env-declare
  declare ENVD_{REF,T{AG,WORD}}
  for ENVD_REF
  do
    # Filter refs from normal tags
    [[ "$ENVD_REF" =~ ^[a-z0-9][a-z0-9-]+[a-z0-9]$ ]] || {

      # Reference is not a single tag but path
      [[ "$ENVD_REF" =~ \/ ]] && {
        envd_define__pathref "$ENVD_REF" || return
        continue
      }

      # Reference is not a tag or path but has type extension(s)
      [[ "$ENVD_REF" =~ \. ]] && {
        envd_define__as__"${ENVD_REF##*.}" "${ENVD_REF%.*}" || return
        continue
      }

      $LOG alert "$lk" "Unrecognized env part reference" "$ENVD_REF"
      return ${_E_script:-2}
    }

    # Process ref as normal tag
    ENVD_TAG=$ENVD_REF
    envd_defined "$ENVD_TAG" || {

      ENVD_TWORD="${ENVD_TAG//[^A-Za-z0-9_]/_}"
      declare -n \
        envd_def=ENVD_DEF["$ENVD_TAG"] \
        envd_part=ENVD_PART["$ENVD_TAG"] \
        envd_decl=ENVD_DECL["$ENVD_TAG"]

      #! envd_declared "$ENVD_TAG" || {

      #  envd_handle define "$ENVD_TAG" || return
      #  continue
      #}

      # Handle definition for unknown part name

      envd_loaded "$ENVD_TAG" || {
        envd_load "$ENVD_TAG" ||
          $LOG error :envd-load "Failed" "E$?:$ENVD_TAG" $? || return
      }

      #sh_fun "$ENVD_TWORD" && {
      #  envd_declare envd.fun
      #  envd_def=$?
      #} || {
      env__define__"$ENVD_TWORD"
      envd_def=$?
      #}
      ! "${DEBUG:-false}" ||
        [[ $envd_def -eq 0 ]] &&
          $LOG debug "$lk" "Declared" "$ENVD_TAG" ||
          $LOG debug "$lk" "Condition" "E$envd_def:$ENVD_TAG"
      [[ $envd_def -eq 0 ]] || return $envd_def
    }
  done
}

envd_define__as__fun ()
{
  false
}

envd_define__as__group ()
{
  false
}

envd_define__as__part ()
{
  false
}

envd_define__as__var ()
{
  false
}

envd_define__pathref ()
{
  envd_defined "${1##*/}" && return
  #envd_define_from_path "${1#/*}" || return
  stderr echo ENVD_TAG=${1##*/} envd_require "${1%/*}"
  ENVD_TAG=${1##*/} envd_require "${1%/*}"
}

envd_defined ()
{
  [[ "${ENVD_DEF["${1:?}"]:+set}" && 0 -eq "${ENVD_DEF["${1:?}"]}" ]]
}

# Embed envd-declare in explicit ENVD_TAG env
envd_dtype () # ~ <Dynamic-type-ref> <envd-declare-argv...>
{
  ENVD_TAG=${1:?} envd_declare "${@:2}"
}

envd_dump ()
{
  declare -p ${ENVD_VAR[*]}
  #declare fun
  #for fun in "${!ENVD_DEF[@]}"
  #do
  #  declare -f env__define__$(str_word $fun)
  #done
  declare -f ${ENVD_FUN[*]}
}

envd_export ()
{
  declare -x ${ENVD_VAR[*]}
  #declare fun
  #for fun in "${!ENVD_DEF[@]}"
  #do
  #  declare -xf env__define__$(str_word $fun)
  #done
  declare -xf ${ENVD_FUN[*]}
}

# Load parts and track in ENVD_PART
envd_load ()
{
  $LOG debug :env-load "Looking for part filess" "$*"
  declare ENVD_NAME ENVD_SRC ENVD_oldPATH=$PATH
  [[ -z "${ENVD_PATH+set}" ]] || export PATH=$ENVD_PATH:$ENVD_oldPATH
  #[[ "${ENVD_PATH+set}" ]] && export PATH=$ENVD_PATH:$ENVD_oldPATH
  for ENVD_NAME
  do
    $LOG info ":env-require" "Looking for pending env part" "$ENVD_NAME"
    envd_lookup ENVD_SRC "$ENVD_NAME" &&
    ENVD_PART["$ENVD_NAME"]=$ENVD_SRC &&
    sys_default ENVD_TYPE["$ENVD_NAME"] "" ||
        $LOG error :env-require "Unable to locate '$ENVD_NAME'" \
            "E$?:${ENVD_PATH:-}" $? || return
  done
  source_all $(for ENVD_NAME; do echo "${ENVD_PART[$ENVD_NAME]}"; done) || {
    $LOG error :env-require "Unexpected error sourcing '$*'" E$?
    return 1
  }
  [[ -z "${ENVD_PATH+set}" ]] || export PATH=$ENVD_oldPATH
}

envd_load_if ()
{
  set -- $(filter_args "not envd_declared" "$@") &&
  [[ $# -eq 0 ]] || envd_load "$@"
}

envd_loaded ()
{
  # envd_declared || envd_defined || envd_partial
  [[ "unset" != "${ENVD_TYPE["${1:?}"]-unset}" || \
    "unset" != "${ENVD_DEF["${1:?}"]-unset}" || \
    "unset" != "${ENVD_PART["${1:?}"]-unset}" ]]
}

# Recover envd session from environment.
envd_loadenv () # ~
{
  #: "${ENVD_PART[@]?"$(sys_exc envd:loadenv "Lib not initialized")"}"
  ENVD_PART["us-def"]="env.arr.envd"
  ENVD_PART["envd-var-update"]="var.assoc.envd"

  # var.envd
  # group.envd
  # fun.envd
  # define.envd
  # declare.envd

  #ENVD_VAR_UPDATE["us-def"]
  # Look at existing declarations; definition functions, updatable variables
  envd_var_update us-def envd &&
  envd_var_update envd-var-update envd || return

  #stderr declare -p US_DEF envd_var_update

  #declare pn pw pf fn
  #for pn in "${US_DEF[@]}_"
  #do
  #  pw="${pn:13}"
  #  pw="${pw//_/-}"
  #  stderr echo "pw:$pw pn:$pn"
  #  [[ "set" = "${ENVD_TYPE["$pw"]+set}" ]] && continue
  #  read -r _ _ pf <<< "$(declare -F "$pn")"
  #  ENVD_PART["$pw"]=$pf
  #  ENVD_TYPE["$pw"]=define
  #done
  if_ok "$(compgen -A function)" &&
  for fn in $_
  do
    pn=${fn//__/\/}
    pn=${pn//_/-}
    rpn=${pn##*/}
    pt=${pn%/*}
    pt=$(str_join . $(args_rev ${pt//\// }))

    if [[ $pt = "$rpn" ]]
    then
      pt=fun.envd
    fi
    sys_assert ENVD_PART["$rpn"] $pt
  done
}

envd_lookup () # ~ <Var> <Name>
{
  declare -n path=${1:?}
  path=$(command -v "${2:?}.sh")
  #ENVD_PART[$ENVD_PART]=$(sh_path=${ENVD_PATH:?} any=true sh_lookup $ENVD_PART ) || {
}

envd_restart ()
{
  lib_load "${LIB_PRE[@]}" &&
  set -- "${!ENVD_DEF[@]}" &&
  ENVD_DEF=() &&
  envd_boot "$@" &&
  lib_load "${LIB_DEP[@]}" &&
  declare lib{,v,w} &&
  for lib in "${LIB_DEP[@]}"
  do
    libw=${lib//[^A-Za-z0-9_]/_}
    libv=${libw}_lib_init
    [[ "unset" = "${!libv-unset}" ]] && continue
    unset $libv
  done &&
  lib_init "${LIB_DEP[@]}"
}

envd_require () # ~ <Names...>
{
  #test -n "${ENVD_TAG-}" || return ${_E_script:?}
  #declare -n env_dep=ENVD_DEP["${ENVD_TAG:?}"]
  #env_dep=${env_dep-}${env_dep:+ }$*

  $LOG debug :env-require "Checking for" "$*"
  set -- $(filter_args "not envd_declared" "$@") &&
  [[ $# -eq 0 ]] && return
  ! "${envd_boot:-false}" || {
    $LOG debug :env-require "Pending" "$*"
    ENVD_PENDING="$*"
    return ${_E_retry:-198}
  }
  $LOG debug :env-require "Declaring" "$*"
  envd_define "$@"
}

# Give value for (variable) name
# see uc-var: variables can be marked dirty, or transparantly initialized
envd_var () # ~ <Name> ...
{
  : ${1:?"$(sys_exc envd:var:@_1 "Name of var expected")"}
  declare -n type=ENVD_TYPE["$1"]
  envd_var_init "$@" &&
  echo "${!1}"
}

envd_var_dirty () # ~ <Name> ...
{
  [[ "set" = "${ENVD_D["${1:?}"]+set}" ]]
}

envd_var_init () # ~ <Name> ...
{
  : ${1:?"$(sys_exc envd:var-init:@_1 "Name of var expected")"}
  declare -n var=$(str_word "$1")
  # XXX: need to know about type here...
  [[ "set" = ${var+set} ]] &&
  ! envd_var_dirty "$1" ||
    envd_var_update "$1"
}

envd_var_update () # ~ <Name> [<Bases..>]
{
  local id
  id=${1:?"$(sys_exc envd:var-update:id@_1 "Name for type expected")"}
  declare -n type=ENVD_PART["$id"]
  [[ "set" = ${type+set} ]] &&
  wid=$(str_word "$id") &&
    # XXX:
  : ${type%.envd} &&
  typename=${_%.*} vartype=${_#*.} &&
  case "$vartype" in
    ( arr ) declare -ga $wid ;;
    ( assoc ) declare -gA $wid ;;
    ( int ) declare -gi $wid ;;
    ( str ) declare -g $wid ;;
  esac &&
  case "$typename" in
    ( env )
        : "${*:2}"
        : "${_:-${envd_var_update["$id"]:?}}"
        envd_runner "$_" update "$id"
        #export
      ;;

    ( var )
        : "${*:2}"
        : "${_:-${envd_var_update["$id"]:?}}"
        envd_runner "$_" update "$id"
      ;;

    * ) $LOG error :envd:var-update "Cannot update part" "$id:$type" 2
  esac
}

#
