#!/bin/sh

oil_lib_load()
{
  OIL_CONTAINER=u-s-oil-treebox
  OIL_IMAGE=bvberkum/treebox:dev
  OIL_PATH=/src/github.com/bvberkum/oil
  lib_load docker-sh
}

oil_docker_init()
{
  docker_name=$OIL_CONTAINER
  docker_image=$OIL_IMAGE
  docker_sh_c_init()
  {
    ${dckr_pref}docker exec --user root $OIL_CONTAINER \
      sh -c 'echo treebox:treeobx | chpasswd' &&
    oil bash -c 'git checkout 2a94f6ff && git clean -dfx && make configure && build/dev.sh minimal'
  }
  oil()
  {
    ${dckr_pref}docker exec -i -w "$OIL_PATH" "$OIL_CONTAINER" "$@"
  }
  oshc()
  {
    note "OSHC: '$*'"
    oil "./bin/oshc" "$@"
  }

  # FIXME: dont restart if we have newest image
  set -- 0

  # Dont pull new images
  test "$1" = "0" && {
    docker_sh_c require
    return $?
  }

  # Run/restart container with newest version
  docker_sh_c require_updated
}

oil_docker_reset()
{
  docker_sh_c_delete "$OIL_CONTAINER"
}
