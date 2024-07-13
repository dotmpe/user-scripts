#!/usr/bin/env bash

### Initial script to cache shell output

shell_cache_lib__load()
{
  true "${shell_cache_id:=}"
  declare -g -A shell_cached
  declare -g -A shell_cache_time
}

# Run command once, return cached value for every subsequent invocation.
shell_cached () # Cmd Args...
{
  local vid
  str_vid vid "$*"
  test "${shell_cached["$vid"]+isset}" || shell_cached["$vid"]="$("$@")"
  echo "${shell_cached["$vid"]}"
  shell_cache_id="$vid"
}

# Like cache but track time of last execution as well and re-run on invocation
# if certain time has passed.
shell_max_age () # Seconds Cmd Args...
{
  test $# -gt 1 || return 98
  local refresh_time=$(( $(date_epochsec) - $1 ))
  shift 1
  local vid
  str_vid vid "$*"
  test "${shell_cached["$vid"]+isset}" -a \
      "${shell_cache_time["$vid"]:-0}" -gt $refresh_time || {
    shell_cached["$vid"]="$("$@")"
    shell_cache_time["$vid"]=$(date_epochsec)
  }
  echo "${shell_cached["$vid"]}"
  shell_cache_id="$vid"
}

shell_invalidate () # Id [Cmd Args...]
{
  test $# -ge 1 || return 177
  local vid="${1-}"
  [[ $vid ]] || { shift; str_vid vid "$*"; } || return
  test -z "${shell_cache_time["$vid"]+isset}" || unset "shell_cached_time[$vid]"
  unset "shell_cached[$vid]"
}

# Id: U-s
