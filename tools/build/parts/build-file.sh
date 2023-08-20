## Build (and execute) file from (preproc) template

: "${0%%.sh}"
case "$0" in
  ( build-* )
      base=build:
      run=false
      : "${_#build-}"
    ;;
  ( run-* )
      base=run:
      run=true
      : "${_#run-}"
    ;;
  * ) stderr echo "! $0: Expected {build,run}-* frontend"; exit 1
esac
script=$_
export UC_LOG_BASE=$base$script

sh_mode dev

. ./tools/sh/parts/sh-fun.sh &&
lib_require us-build log &&
lib_init us-build

: "${_E_GAE:=193}" # Generic Argument Error

: "${_E_ok:=195}" # Explicit OK (finished, continue)
: "${_E_next:=196}" # Try next alternative (unfinished or partial)

"${run}" && {
  us_main "$script.sh" "$@"
  exit $?
} ||
  us_build_v "$script.sh"
