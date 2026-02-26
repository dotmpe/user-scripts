## Build (and execute) file from (preproc) template

: "${0%%.sh}"
: "${_##*/}"
>&2 echo running $_
case "$_" in
  ( build-* )
      script="${_#build-}"
      base=build:
      run=false
    ;;
  ( run-* )
      script="${_#run-}"
      base=run:
      run=true
    ;;
  * ) >&2 echo "! $0: Expected {build,run}-* frontend"; exit 1
esac
export UC_LOG_BASE=$base$script

>&2 echo running script=$script

sh_mode dev
pass () { return; }
:pass () { return; }
uc_env_2625 +if-init
uc_env_2625 -r uconf-shell-core-dsl
#uconf-shell-log

#. ./tool/sh/part/sh-fun.sh &&
lib_require script-mpe us-build log shell-uc &&
>&2 echo libs loaded &&
lib_init shell-uc us-build &&
>&2 echo libs initialized &&
true

base=u-s

: "${_E_GAE:=193}" # Generic Argument Error

: "${_E_ok:=195}" # Explicit OK (finished, continue)
: "${_E_next:=196}" # Try next alternative (unfinished or partial)

"${run}" && {
  us_main "$script.sh" "$@"
  exit $?
} ||
  us_build_v "$script.sh"
