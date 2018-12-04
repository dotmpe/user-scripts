#!/bin/sh

docker_sh_lib_load()
{
  test -n "$dckr_pref" || dckr_pref=
  test -n "$docker_sh_c" || docker_sh_c=
  test -n "$docker_sh_c_port" || docker_sh_c_port=22
  test -n "$docker_name" || docker_name=
  test -n "$docker_image" || docker_image=
  test -n "$docker_shell" || docker_shell=bash
  test -n "$docker_cmd" || docker_cmd=bash
}

docker_sh_names()
{
  ${dckr_pref}docker inspect --format='{{.Name}}' $(${dckr_pref}docker ps -aq --no-trunc)
}

# Default to env container
docker_sh_c() # CMD [Container] [ARGS...]
{
  local c="$2" act="$1"
  test $# -gt 1 && shift 2 || shift 1
  test -n "$c" || c=$docker_sh_c
  test -n "$c" || c=$docker_name
  docker_sh_c_$act "$c" "$@"
}

docker_sh_c_exists() # [Container]
{
  docker_sh_c_status "$@" >/dev/null
}

docker_sh_c_run() # [Container]
{
  docker_sh_c_exists "$1" && {
    docker_sh_c_start "$@"
  } || {
    docker_sh_c_create "$@"
  }
}

docker_sh_c_create() # [Container] [Docker-Image]
{
  test -n "$1" || set -- "$docker_name" "$2" "$3"
  test -n "$2" || set -- "$1" "$docker_image" "$3"
  test -n "$3" || set -- "$1" "$2" "$docker_cmd"

  ${dckr_pref}docker run -di --name "$1" "$2" "$3" || return
  # TODO: one-time-init, maybe use init/service scripts inside container here
  func_exists docker_sh_c_init && docker_init=docker_sh_c_init
  test -z "$docker_init" || {
    note "Docker init: $docker_init"
    $docker_init "$1"
  }
}

docker_sh_c_recreate() # [Container] [Docker-Image]
{
  docker_sh_c_delete "$1" && docker_sh_c_create "$1" "$2"
}

docker_sh_c_start() # [Container]
{
  ${dckr_pref}docker start -i "$1"
}

docker_sh_c_delete() # [Container]
{
  ${dckr_pref}docker rm -f "$1"
}

docker_sh_c_id() # [Container]
{
  docker_sh_c_inspect '{{.Id}}' "$@"
}

docker_sh_c_is_running() # [Container]
{
  trueish "$( docker_sh_c_inspect '{{.State.Running}}' "$@" )"
}

docker_sh_c_status() # [Container]
{
  docker_sh_c_inspect '{{.State.Status}}' "$@"
}

docker_sh_c_ip() # [Container]
{
  test -n "$1" || error "dckr-ip: container required" 1
  ${dckr_pref}docker inspect --format '{{ .NetworkSettings.IPAddress }}' $1 ||
    error "docker IP inspect on $1 failed" 1
}

docker_sh_c_port() # [Container]
{
  test -n "$1" || error "dckr-ip: container required" 1
  test -n "$2" || set -- "$1" $docker_sh_c_port
  ${dckr_pref}docker inspect --format '{{ (index (index .NetworkSettings.Ports "'$2'/tcp") 0).HostPort }}' "$1" || error "docker port $2 inspect on $1 failed" 1
}

docker_sh_c_inspect() # Expr [Container]
{
  ${dckr_pref}docker inspect --format "$1" "$2"
}

docker_sh_c_image_name() # [Container]
{
  docker_sh_c_inspect '{{.Config.Image}}' "$@"
}

docker_sh_c_update() # Container [Image]
{
  test -n "$1" || set -- "$docker_sh_c" "$2"
  test -n "$1" || set -- "$docker_name" "$2"
  test -n "$2" || set -- "$1" "$docker_image"
  test -n "$2" || {
    docker_sh_c exists "$1" || return
    test -n "$2" || set -- "$1" "$( docker_sh_c_image_name "$1" )"
  }

  ${dckr_pref}docker pull "$2"
  docker_sh_c is_running "$1" || return 0
  docker_sh_c_recreate "$@" || return
}

docker_sh_c_require()
{
  docker_sh_c is_running "$@" || {

    docker_sh_c_exists "$@" && {
      docker_sh_c_start "$@" || return
      docker_sh_c is_running "$@" || return
    } || {

      docker_sh_c_create "$@" || return
    }

    docker_sh_c is_running "$@"
  }
}

docker_sh_c_require_updated()
{
  docker_sh_c_exists "$1" && {

    docker_sh_c is_running "$@" || {
      docker_sh_c_start "$@" || return
    }
    docker_sh_c_update "$@" || return

  } || {

    echo not runing, updating
    docker_sh_c_update "$@" || return
    docker_sh_c_create "$@" || return
  }

  docker_sh_c is_running "$1"
}
