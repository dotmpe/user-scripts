
# Created: 2022


sh_mode strict dev build

mkdir -vp "${PROJECT_CACHE:?}" >&2

test "${BUILD_SPEC:?}" = :lint:shellcheck: && {

  declare script errors
  script="${BUILD_TARGET:${#BUILD_SPEC}}"
  errors=${PROJECT_CACHE:?}/lint-shellcheck-${script//\//-}.errors
  build-ifchange "$script" || return
  shellcheck -s sh -x "$script" >| "$errors"
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
  test ! -s "$errors" || cat "$errors"
  rm "$errors"
}

#
