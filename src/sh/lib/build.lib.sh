#!/bin/sh

build_lib_load () # sh:no-stat: OIl has trouble parsing heredoc
{
  lib_require match $package_build_tool
  local var=${package_build_tool}_commands cmd
  for name in ${!var}
  do
    cmd="build${name:${#package_build_tool}}"
    eval "$(cat <<EOM
$cmd ()
{
  $name "\$@"
}
EOM
    )"
  done

  test -n "${sh_file_exts-}" || sh_file_exts=".sh .bash"
  # Not sure what shells to restrict to, so setting it very liberal
  test -n "${sh_shebang_re-}" || sh_shebang_re='^\#\!\/bin\/.*sh\>'
}

build_component_exists () # Target
{
  test -n "${1-}" || return 98
  read_nix_style_file .meta/stat/index/components.list | {
    while read name type target_spec source_specs
    do
      test "$name" = "$1" && return
      fnmatch "$target_spec" "$1" && return
      continue
    done
    return 1
  }
}

build_fetch_component () # Path
{
  read_nix_style_file .meta/stat/index/components.list |
    while read target_name type target_spec source_specs
  do
    case "$type" in

      alias | function ) ;;

      simpleglob )
          fnmatch "$target_spec" "$1" && {
            echo "$type $target_spec $source_specs"
            return
          }
        ;;

      * ) $LOG error "" "Unknown target type '$type'" "$target_name $1" 1 ;;
    esac
  done
  return 1
}

build_component () # Target Basename Temp
{
  build_components "$1" "" "$@"
}

build_components () # Target-Name Type Build-Args...
{
  local name="$1" name_p type="${2:-"[^ ]*"}" ; shift 2
  fnmatch "*/*" "$name" && name_p="$(match_grep "$name")" || name_p="$name"
  grep '^'"$name_p"' '"$type"'\($\| \)' .meta/stat/index/components.list | {
    read name type rest
    set -o noglob; set -- $name $rest -- "$@"; set +o noglob
    build_component_$type "$@"
  }
}

# Simpleglob: defer to target paths obtained by expanding source-spec
build_component_simpleglob () # NAME TARGET_SPEC SOURCE_SPECS
{
  local src name glob=$(echo "$3" | sed 's/%/*/')
  for src in $glob
  do
    name="$(glob_spec_var "$glob" "$src")"
    build-ifchange $(echo "$2" | sed 's/\*/'"$name"'/')
  done
}

# Return first globbed part, given glob pattern and expanded path
glob_spec_var () # Pattern Path
{
  set -- "$@" $(match_grep "$1" | sed 's/\*/\(\.\*\\)/')
  echo "$2" | sed 's/'"$3"'/\1/g'
}

# Function target: invoke function with build-args
build_component_function () # Name [Function] Libs... -- Build-Arg
{
  local libs name=$1 func="$2"
  shift 2
  test "${func:-"-"}" != "-" ||
    func="build_$(mkvid "$name" && printf -- "$vid")"
  while test $# -gt 0 -a "${1-}" != "--"
  do libs="${libs:-}${libs+" "}$1"; shift
  done; shift

  test -z "${libs-}" || { lib_require $libs || return; }
  $func "$@"
}

# Alias target: defer to other targets
build_component_alias () # Name Targets... -- Build-Arg
{
  local aliases ; shift
  while test $# -gt 0 -a "${1-}" != "--"
  do aliases="${aliases:-}${aliases+" "}$1"; shift
  done; shift

  build-always && build-ifchange $aliases
}

build ()
{
  test -n "${package_build_tool-}" || return 1
  $package_build_tool "$@"
}

list_src_files () # Generator Newer-Than Magic-Regex [Extensions-or-Globs...]
{
  local generator="${1:-"vc_tracked"}" nt=${2:-} mrx=${3:-}
  shift 3
  { test $generator = - || $generator; } | while read -r path ; do

# Cant do anything with dirs or empty files
    test ! -d "$path" -a -s "$path" || continue

# Allow for faster updates by checking only changed files
    test -z "$nt" || {
        test "$path" -nt $nt || continue
    }

# Scan name extension or glob match first
    test $# -eq 0 || {
        local m
        for m in $@
        do
            test ${m:0:1} != . || m="*$m"
            fnmatch "$m" "$path" || continue
            echo "$path"
            continue 2
        done
        continue
    }

# Or grep for sha-bang pattern
    test -z "$mrx" || {
      head -n1 "$path" | grep -qm 1 $mrx || continue
    }
    echo "$path"
  done
}

# List any /bin/*sh or non-empty .sh/.bash file, from everything checked into SCM
list_sh_files () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" "$sh_shebang_re" $sh_file_exts
}

list_lib_sh_files () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" "" ".lib.sh"
}

list_executables () # _ [Newer-Than]
{
  list_src_files find_executables "${2-}" ""
}

find_executables ()
{
  find . -executable -type f | cut -c3-
}

list_scripts () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" '^\#\!'
}

build_chatty () # Level
{
  test ${quiet:-$(test $verbosity -lt ${1:-3} && printf 1 || printf 0)} -eq 0
}

#
