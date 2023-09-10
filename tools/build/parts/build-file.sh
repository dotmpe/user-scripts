## Build (and execute) file from (preproc) template

: "${0%%.sh}"
: "${_##*/}"
stderr echo running $_
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
  * ) stderr echo "! $0: Expected {build,run}-* frontend"; exit 1
esac
export UC_LOG_BASE=$base$script

stderr echo running script=$script

sh_mode dev

. ./tools/sh/parts/sh-fun.sh &&
lib_require us-build log &&
lib_init us-build

base=u-s

: "${_E_GAE:=193}" # Generic Argument Error

: "${_E_ok:=195}" # Explicit OK (finished, continue)
: "${_E_next:=196}" # Try next alternative (unfinished or partial)

"${run}" && {
  us_main "$script.sh" "$@"
  exit $?
} ||
  us_build_v "$script.sh"
