
# Created: 2018-10-17


sh_mode strict dev build

# TODO: should only test files no longer marked as 'dev', see attributes-local

lint-tags ()
{
  test -z "$*" && {
    # TODO: forbid only one tag... setup degrees of tags allowed per release

    git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' "$@" && return 1 || true
  } || {

    git grep '\(XXX\|FIXME\|TODO\):' "$@" && return 1 || true
  }
}

test "${BUILD_SPEC:?}" = :lint:tags: && {

  declare script errors
  script="${BUILD_TARGET:${#BUILD_SPEC}}"
  errors=${PROJECT_CACHE:?}/lint-tags-${script//\//-}.errors
  build-ifchange "$script" || return
  # Do not need to fail here and keep rebuilding this target because of the exit
  # state. Instead check for error lines in other target and fail appropiately
  lint-tags "$script" >| "$errors" || {
    ! ${sei_fail:-false} || return
    $LOG warn ":lint-tags.do" "Embedded tags lint (continuing)" "$script"
  }
  test -s "$errors" || rm "$errors"
  return
}

test "unset" = "${IF_DEPS[@]-unset}" && {
  srcls_sym="&source-list"
  build-ifchange "$srcls_sym" || return
  $LOG warn ":lint-tags.do" "Could not use If-Deps to get list symbol, using '$srcls_sym'"
} ||
  srcls_sym=${IF_DEPS[0]}

source_list=$(build-sym "$srcls_sym")

test -s "$source_list" || return 0

redo-ifchange $({
    while read -r x
    do
      test -f "$x" -a ! -h "$x" || continue
      echo ":lint:tags:$x"
    done
  } < "$source_list")

declare errors=${PROJECT_CACHE:?}/lint-tags.errors
shopt -s nullglob
set -- "${PROJECT_CACHE:?}"/lint-tags-*.errors
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
  stderr_ "Lint (tags): $cnt"

#
