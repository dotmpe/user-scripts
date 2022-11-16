
# Created: 2018-10-17


sh_mode strict dev build

#shellcheck disable=2120
lint-tags ()
{
  # XXX: no-commit
  #git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' "$@" && return 1 || true
  git grep '\(XXX\|FIXME\|TODO\):' "$@" && return 1 || true
}

test "${BUILD_SPEC:?}" = :lint:tags: && {

  declare script errors
  script="${BUILD_TARGET:${#BUILD_SPEC}}"
  errors=${PROJECT_CACHE:?}/lint-tags-${script//\//-}.errors
  build-ifchange "$script" || return
  # Do not need to fail here and keep rebuilding this target because of the exit
  # state. Instead check for error lines in other target and fail appropiately
  lint-tags < "$script" >| "$errors" || {
    ! ${sei_fail:-false} || return
    $LOG warn ":lint-tags.do" "Embedded tags lint (continuing)" "$script"
  }
  test -s "$errors" || rm "$errors"
  return
}


# TODO: should only test files no longer marked as 'dev', see attributes-local

test "unset" = "${IF_DEPS[@]-unset}" && {
  true "${LINT_TAGS_SRC_SPEC:="&lint-tags:src"}"
  build-ifchange "${LINT_TAGS_SRC_SPEC:?}" || return
  $LOG warn ":lint-tags.do" "Could not use If-Deps to get list symbol, using '$LINT_TAGS_SRC_SPEC'"
} ||
  LINT_TAGS_SRC_SPEC=${IF_DEPS[0]}

source_list=$(build-sym "${LINT_TAGS_SRC_SPEC:?}")

test -s "$source_list" || return 0

#shellcheck disable=2046
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
  test ! -s "$errors" && rm "$errors" || cat "$errors" >| "$BUILD_TARGET_TMP"
}

build-always

declare cnt
test -s "$BUILD_TARGET_TMP" && {
  cnt=$(wc -l < "$BUILD_TARGET_TMP") || return
} || {
  test ! -s "$BUILD_TARGET" ||
    cnt=$(wc -l < "$BUILD_TARGET") || return
}

test "${cnt:-0}" -eq 0 ||
  stderr_ "Lint (tags): $cnt"

#
