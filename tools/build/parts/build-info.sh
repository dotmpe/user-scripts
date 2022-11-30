# Show bit about current build system
build_info ()
{
  test $# -gt 0 -a -n "${1:-}" || set -- summary

  declare key
  for key in "$@"
  do
    ! ${summary:-false} || {
      sh_fun build_info__${key//-/_}_summary && {
        build_info__${key//-/_}_summary || return
      }
    }
    build_info__${key//-/_} || return
  done
}

build_info__build_runtime ()
{
  build_info__builder_line
  #echo "Build Tool: ${BUILD_TOOL:-(unset)}"
  echo "Build Action: ${BUILD_ACTION:-(unset)}"
}

build_info__build_sources ()
{
  echo "Build sources: "
  build-sources | sed 's/^/  - /' || true
}

build_info__build_status ()
{
  echo "Build status: "
  for name in $build_main_targets
  do
    ! fnmatch "-*" "$name" || continue
    echo "  - $name: | "
    { build-log $name 2>&1 || true
    } | sed 's/^/      /'
  done
}

build_info__build_targets ()
{
  echo "Build targets: "
  build-targets | sed 's/^/  - /' || true
}

build_info__builder ()
{
  build_info build-runtime builder-static builder-config
}

build_info__builder_config ()
{
  echo "Builder config: "
  echo "  Build Path: ${BUILD_PATH:-(unset)}"
  echo "  Build Bases: ${BUILD_BASES:-(unset)}"
  echo "  Env Path: ${ENV_PATH:-(unset)}"
}

build_info__builder_line ()
{
  echo "Builder: $(${BUILD_TOOL:?} --version) ($BUILD_TOOL)"
}

build_info__builder_static ()
{
  echo "Builder static env: "
  echo "  Env Build Env: ${ENV_BUILD_ENV:-(unset)}"
  echo "  Env Build Libs: ${ENV_BUILD_LIBS:-(unset)}"
}

build_info__components ()
{
  echo "Components: "
  build_info env rule-types build-targets build-sources |
    sed 's/^/    /' || true
}

build_info__env ()
{
  echo "Env: | "
  build_env_vars | build_sh | sed 's/^/    /' || true
}

build_info__package_line ()
{
  echo "Package: ${package_name-null}/${package_version-null}"
}

build_info__rule_types ()
{
  echo "Build rule types: "
  build_target_types | sed 's/^/  - /' || true
}

build_info__summary ()
{
  echo "Build summary: "
  summary=true build_info package-line builder-line components |
    sed 's/^/  - /' || true
}
