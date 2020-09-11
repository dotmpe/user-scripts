#!/bin/sh

## Docker shell tools


docker_sh_lib_load()
{
  test -n "${dckr_pref-}" || dckr_pref= # Allow for sudo or custom wrapper exec
}

docker_sh_names()
{
  ${dckr_pref}docker inspect --format='{{.Name}}' $(${dckr_pref}docker ps -aq --no-trunc)
}

# Default to env container
docker_sh_c() # CMD [Container] [ARGS...]
{
  local c="${2:-${docker_sh_c:-${docker_name-}}}" act="$1"
  test -n "$c" || error "dckr-sh: container required" 1
  test $# -gt 1 && shift 2 || shift 1
  docker_sh_c_$act "$c" "$@"
}

docker_sh_c_exists() # [Container]
{
  docker_sh_c_status "$@" >/dev/null
}

docker_sh_c_status() # [Container]
{
  docker_sh_c_inspect '{{.State.Status}}' "$@"
}

docker_sh_c_ip() # [Container]
{
  test $# -le 1 || return 98
  local c="${1:-${docker_sh_c:-${docker_name-}}}"
  test -n "$c" || error "dckr-ip: container required" 1
  ${dckr_pref}docker inspect --format '{{ .NetworkSettings.IPAddress }}' $1 ||
    error "docker IP inspect on $1 failed" 1
}

docker_sh_c_port() # [Container] [Port=22]
{
  test $# -le 1 || return 98
  local c="${1:-${docker_sh_c:-${docker_name-}}}" port=${2:-22}
  test -n "$c" || error "dckr-port: container required" 1
  ${dckr_pref}docker inspect --format '{{ (index (index .NetworkSettings.Ports "'$port'/tcp") 0).HostPort }}' "$c" || error "docker port $port inspect on $c failed" 1
}

docker_sh_c_inspect() # Format [Container]
{
  test $# -le 2 || return 98
  local c="${2:-${docker_sh_c:-${docker_name-}}}"
  test -n "$c" || error "dckr-inspect: container required" 1
  ${dckr_pref}docker inspect --format "$1" "$c"
}

docker_sh_c_image_name() # [Container]
{
  docker_sh_c_inspect '{{.Config.Image}}' "$@"
}

# Make data from an image available on a volume, so it can be inspected by other
# containers.
#
# The data is in a directory, and given a (volumne) name to ease removal/later
# reference.
docker_setup_volume_from_imagepath() # Name Data-Ref Src-Img
{
  ${dckr_pref-}docker create --name $1 -v $2 $3 >/dev/null
}

#
