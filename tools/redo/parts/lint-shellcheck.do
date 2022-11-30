
# Created: 2022-08-30


sh_mode strict build

test -x "$(command -v shellcheck)" ||
  $LOG error :lint-shellcheck "No Shellcheck installation found" "" 1 || return

test "${BUILD_SPEC:?}" = :lint:shellcheck: && {

  declare script errors
  script="${BUILD_TARGET:${#BUILD_SPEC}}"
  errors=${PROJECT_CACHE:?}/lint-shellcheck-${script//\//-}.errors
  build-ifchange "$script" ~/.shellcheckrc ${BUILD_BASE:?}/.shellcheckrc || return
  # Do not need to fail here and keep rebuilding this target because of the exit
  # state. Instead check for error lines in other target and fail appropiately
  shellcheck -s sh -x "$script" >| "$errors" || {
    ! ${sc_fail:-false} || return
    $LOG warn ":lint-shellcheck.do" "Shellcheck lint (continuing)" "$script"
  }
  test -s "$errors" || rm "$errors"
  return
}

test "unset" = "${DEPS[@]-unset}" && {
  true "${LINT_SC_SRC_SPEC:="&lint-shellcheck:file-list"}"
  $LOG warn ":lint-shellcheck.do" "Could not use If-Deps to get list symbol, using '$LINT_SC_SRC_SPEC'"
  build-ifchange "${LINT_SC_SRC_SPEC:?}" || return
} ||
  LINT_SC_SRC_SPEC=${DEPS[0]}

#sh_list=$(build-sym "${LINT_SC_SRC_SPEC:?}")
sh_list=${PROJECT_CACHE:?}/source-sh.list
test -s "$sh_list" || {
  $LOG warn :lint-shellcheck "Lint check finished bc there is nothing to check"
  return
}

declare -a shck
mapfile -t shck <<< "$({
    while read -r x
    do
      test -f "$x" -a ! -h "$x" || continue
      echo ":lint:shellcheck:$x"
    done
  } < "$sh_list")"
redo-ifchange "${shck[@]}" ||
  $LOG error :lint-shellcheck "Lint check aborted" "E$?" $? || return

declare errors=${PROJECT_CACHE:?}/lint-shellcheck.errors
shopt -s nullglob
set -- "${PROJECT_CACHE:?}"/lint-shellcheck-*.errors
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

test "${cnt:-0}" -eq 0 || {
  stderr_ "Lint (shellcheck): $cnt"
  $LOG warn :lint-shellcheck "Files containing 'shellcheck' lint" "$cnt" $?
}

# Derive: lint-tags
