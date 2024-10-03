
us_preproc__INIT ()
{
  us_preproc_src+=( "$1" )
  cat <<EOM
std_quiet declare -p us_preproc_src || declare -ga us_preproc_src
EOM
}

us_preproc__RUN ()
{
  $LOG debug :preproc:BUILD-RUN "Writing target meta cache" "${meta:?}"
  "${us_build_autorun:-true}" && {
    set -- "${us_preproc_src[@]}"
  }
  for f in "$@"
  do
    echo "us_preproc_src+=( \"$f\" )"
  done | tee "$meta"
}

us_preproc__DEFINE ()
{
  local var=${1:?} val=${2:?} # lk=${lk:+:us-preproc}:define
  eval declare -g "us_preproc_vardefs[$var]=$val"
  #us_preproc_vars+=( "$var" )
  : "${var//:/__}"
  : "${var//[^A-Za-z0-9_]/_}"
  declare -g "$_=${us_preproc_vardefs[$var]}"
}

us_preproc__INCLUDE ()
{
  local lk=${lk:+:us-preproc}:include
  false
}

us_preproc__MODELINE ()
{
  echo "# ex:ft=bash:"
}

us_preproc__RESOLVE ()
{
  local type=${1:?} rest=${*:2} lk=${lk:+:us-preproc}:resolve

  : "${type^^}"
  sh_fun us_preproc__RESOLVE_${_//[^A-Z0-9_]/_} ||
    $LOG alert : "No such sub-directive" "$dir" 2 || return
  $LOG debug :preproc "Resolve" "$_"
  "$_" $rest
}

us_preproc__RESOLVE_FUN ()
{
  local name=${1:?} ctx=${2:-} fun=${1//[^A-Za-z0-9_]/_}

  sh_fun "$fun" && ! "${us_preproc_forceload:-false}" ||
  test -z "$ctx" || {
    us_build_context "$ctx" &&
    uc_script_load "$name" &&
    if_ok "$(command -v "$name.${scr_ext:-sh}")" || return
    us_preproc_src+=( "$_" )
  }
  sh_fun "$fun" ||
    $LOG error "$lk:fun" "No such function" "$name" 2

  declare -f "$fun"
  # TODO: convert back to symbolic ref
  echo "# Copy: ${ctx_dir:-U-S}:$name"
}

us_preproc__RESOLVE_IF_FUN ()
{
  local fun=${1//[^A-Za-z0-9_]/_}
  echo "sh_fun $fun ||"
  us_preproc__RESOLVE_FUN "$@" | sed 's/^/  /'
}

us_preproc__RESOLVE_SCR ()
{
  local name=${1:?} ctx=${2:-} partid=${1//[^A-Za-z0-9_]/_}
  test -z "$ctx" ||
    us_build_context "$ctx" || return

  # FIXME: before caching all intermediate targets, need env specs build up first
  if_ok "$(command -v "$name.${scr_ext:-.sh}.build")" && {
    us_build "$_" || {
      $LOG error : "Resolving preprocessed script failed" "E$?:$_" $? || return
    }
    us_preproc_src+=( "$_" )
  } || {
    ! if_ok "$(command -v "$name.${scr_ext:-sh}")" || {
      cat "$_" || {
        $LOG error : "Reading script failed" "E$?:$_" $? || return
      }
      us_preproc_src+=( "$_" )
      # TODO: convert back to symbolic ref
      echo "# Copy: ${ctx_dir:-U-S}:$name"
    }
  }
}

us_preproc__RESOLVE_SCR_IF_FUN ()
{
  local fun=${1//[^A-Za-z0-9_]/_}
  echo "sh_fun $fun || {"
  us_preproc__RESOLVE_SCR "$@"
  echo "}"
}

