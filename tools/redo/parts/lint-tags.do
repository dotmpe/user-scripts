
# Created: 2018-10-17

# This recipe has two modes: one to call a 'tags' lint check for a set of
# files, and one to execute the actual check. It needs a list of files, a
# target prefix to reserve for either mode, and a place to put check failures.

# XXX: currently using defer-with type rule to pass symbolic source list
# with DEP. Something more declarative would be nice to do all that.
# Ie. build__declare lint-tags lint-tags-%, but also need to replace namespace,
# get location for build cache...


sh_mode strict build

#shellcheck disable=2120
lint-tags ()
{
  # XXX: no-commit
  #git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' "$@" && return 1 || true
  git grep '\(XXX\|FIXME\|TODO\):' -- "$@" && return 1 || true
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
    $LOG warn ":lint-tags.do" "Embedded tags lint (continuing)" "${script//%/%%}"
  }
  test -s "$errors" || rm "$errors"
  return
}

test "unset" = "${DEPS[@]-unset}" && {
  true "${LINT_TAGS_SRC_SPEC:="&lint-tags:file-list"}"
  $LOG warn ":lint-tags.do" \
    "Could not use Deps to get list symbol, using '$LINT_TAGS_SRC_SPEC'"
  build-ifchange "${LINT_TAGS_SRC_SPEC:?}" || return
} ||
  LINT_TAGS_SRC_SPEC=${DEPS[0]}

# FIXME build-sym #source_list=$(build-sym "${LINT_TAGS_SRC_SPEC:?}")
build_fsym_arr DEPS SOURCES
source_list=${SOURCES[0]}
test -s "$source_list" || {
  $LOG error :lint-tags "No such file" "$source_list"
  return 1
}
test -s "$source_list" || {
  $LOG warn :lint-tags "Lint check finished bc there is nothing to check"
  return
}

stderr_ "source: $source_list $(wc -l "$source_list")"

declare -a tags
mapfile -t tags <<< "$({
    while read -r x
    do
      test -f "$x" -a ! -h "$x" || continue
      echo ":lint:tags:$x"
    done
  } < "$source_list")"
redo-ifchange "${tags[@]}" ||
    $LOG warn :lint-tags "Lint check aborted" "E$?" $? || return

declare errors=${PROJECT_CACHE:?}/lint-tags.errors
shopt -s nullglob
set -- "${PROJECT_CACHE:?}"/lint-tags-*.errors
test $# -eq 0 && {
  test ! -e "$errors" || rm "$errors"
} || {
  cat "$@" >| "$errors"
  test ! -s "$errors" && rm "$errors" || cat "$errors" >| "$BUILD_TARGET_TMP"
}

declare cnt
test -s "$BUILD_TARGET_TMP" && {
  cnt=$(wc -l < "$BUILD_TARGET_TMP") || return
} || {
  test ! -s "$BUILD_TARGET" ||
    cnt=$(wc -l < "$BUILD_TARGET") || return
}

test "${cnt:-0}" -eq 0 || {
  stderr_ "Lint (tags): $cnt"
  $LOG warn :lint-tags "Files containing 'tags' lint" "$cnt" $?
}

# ID: lint-tags
