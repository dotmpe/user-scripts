
# Created: 2022


sh_mode strict dev build

mkdir -vp "${PROJECT_CACHE:?}" >&2

test "${BUILD_SPEC:?}" = :lint:shellcheck: && {

  declare script errors
  script="${BUILD_TARGET:${#BUILD_SPEC}}"
  errors=${PROJECT_CACHE:?}/lint-shellcheck-${script//\//-}.errors
  build-ifchange "$script" ~/.shellcheckrc .shellcheckrc || return
  # Do not need to fail here and keep rebuilding this target because of the exit
  # state. Instead check for error lines in other target and fail appropiately
  shellcheck -s sh -x "$script" >| "$errors" || {
    ! ${sc_fail:-false} || return
    $LOG warn ":lint-shellcheck.do" "Shellcheck lint (continuing)" "$script"
  }
  test -s "$errors" || rm "$errors"
  return
}

test "unset" = "${IF_DEPS[@]-unset}" && {
  shls_sym="&sh-list"
  build-ifchange "$shls_sym" || return
  $LOG warn ":lint-shellcheck.do" "Could not use If-Deps to get list symbol, using '$shls_sym'"
} ||
  shls_sym=${IF_DEPS[0]}

sh_list=$(build-sym "$shls_sym")

test -s "$sh_list" || return 0

#shellcheck disable=2046
build-ifchange $( {
    while read -r x
    do
      test -f "$x" -a ! -h "$x" || continue
      echo ":lint:shellcheck:$x"
    done
  } < "$sh_list")

declare errors=${PROJECT_CACHE:?}/lint-shellcheck.errors
shopt -s nullglob
set -- "${PROJECT_CACHE:?}"/lint-shellcheck-*.errors
test $# -eq 0 && {
  test ! -e "$errors" || rm "$errors"
} || {
  cat "$@" >| "$errors"
  rm "$@"
  test ! -s "$errors" || cat "$errors" >| "$BUILD_TARGET_TMP"
  rm "$errors"
}

build-always

declare cnt
test -s "$BUILD_TARGET_TMP" && {
  cnt=$(wc -l < "$BUILD_TARGET_TMP") || return
} || {
  test ! -s "$BUILD_TARGET" ||
    cnt=$(wc -l < "$BUILD_TARGET") || return
}

test $cnt -eq 0 ||
  stderr_ "Lint (shellcheck): $cnt"

#
