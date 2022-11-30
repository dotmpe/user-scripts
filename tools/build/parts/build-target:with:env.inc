env:declare:build-target:with:env ()
{
  env-require build-session || return
  build:add-handler build-target:with:env
}

build-target:with:env ()
{
  declare vid var
  mkvid "${1:-${BUILD_TARGET:?}}" &&
  var=build_${vid}_targets &&

  # Must be set or return and signal lookup to continue with ext alternative
  test "${!var-unset}" != unset || return ${_E_continue:-196}

  ! ${list_sources:-false} || {
    echo "${!var:?}"
        # XXX: | tr ' ' '\n'
    return
  }

  ${show_recipe:-false} && {
    test -z "${!var:-}" &&
      echo "stderr_ \"! \$0: Empty recipe for '${BUILD_TARGET:?}'\"" ||
      echo "${BUILD_TOOL:?}-ifchange ${!var:?}"
  } || {
    test -z "${!var:-}" &&
      stderr_ "! $0: Empty recipe for '${BUILD_TARGET:?}'" ||
      ${BUILD_TOOL:?}-ifchange ${!var:?}
  }
}
