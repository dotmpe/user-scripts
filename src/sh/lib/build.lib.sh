#!/bin/sh

build_lib_load () # sh:no-stat: OIl has trouble parsing heredoc
{
  lib_require date match $package_build_tool || return

  local var=${package_build_tool}_commands cmd
  test -n "${!var-}" || {
    $LOG error "" "No build tool commands" "$package_build_tool" 1
    return
  }
  for name in ${!var-}
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

  # List of targets for build tool
  test -n "${components_txt-}" ||
    components_txt=${COMPONENTS_TXT:-"components.txt"}

  # Toggle or alternate target for build tool to build components-txt
  test -n "${components_txt_build-}" ||
    components_txt_build=${COMPONENTS_TXT_BUILD:-"1"}

  # Targets for CI jobs
  test -n "${build_txt-}" || build_txt="${BUILD_TXT:-"build.txt"}"

  test -n "${dependencies_txt-}" || dependencies_txt="${DEPENDENCIES_TXT:-"dependencies.txt"}"
}

build_component_exists () # Target
{
  test -n "${1-}" || return 98
  read_nix_style_file "$components_txt" | {
    while read name type target_spec source_specs
    do
      test "$name" = "$1" && return
      # XXX: why was this here? #fnmatch "$target_spec" "$1" && return
      continue
    done
    return 1
  }
}

build_fetch_component () # Path
{
  read_nix_style_file "$components_txt" |
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
  $LOG "note" "" "Building as component" "$*"
  build_components "$1" "" "$@"
}

build_components () # Target-Name Type Build-Args...
{
  local name="$1" name_p type="${2:-"[^ ]*"}" ; shift 2
  fnmatch "*/*" "$name" && name_p="$(match_grep "$name")" || name_p="$name"
  grep '^'"$name_p"' '"$type"'\($\| \)' "$components_txt" | {
    read name type rest
    test -n "$name" || error "No such component '$type:$name" 1
    set -o noglob; set -- $name $rest -- "$@"; set +o noglob
    $LOG "info" "" "Building as '$type' component" "$*"
    build_component_$type "$@"
  }
}

# Simpleglob: defer to target paths obtained by expanding source-spec
build_component_simpleglob () # NAME TARGET_SPEC SOURCE_SPECS
{
  local src match glob=$(echo "$3" | sed 's/%/*/')
  build-ifchange $( for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$2" | sed 's/\*/'"$match"'/'
    done )
}

# Return first globbed part, given glob pattern and expanded path.
# Returned part is everything matched from first to last wildcard glob,
# so this works on globstar and to a degree with multiple wildcards.
glob_spec_var () # Pattern Path
{
  set -- "$@" "$(glob_spec_grep "$1")"
  echo "$2" | sed 's/'"$3"'/\1/g'
}

glob_spec_grep ()
{
  match_grep "$1" | sed 's/\*\(.*\*\)\?/\(\.\*\\)/'
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
  local aliases= ; shift
  while test $# -gt 0 -a "${1-}" != "--"
  do aliases="${aliases:-}${aliases+" "}$1"; shift
  done; shift

  build-always && build-ifchange $aliases
}

# Symlinks: create each dest, linking to srcs
build_component_symlinks () # NAME SRC-GLOB DEST-FMT -- Build-Arg
{
  local src match dest grep="$(glob_spec_grep "$2")" f
  test ${quiet:-0} -eq 1 || f=-v
  shopt -s nullglob
  for src in $2
  do
    match="$(echo "$src" | sed 's/'"$grep"'/\1/g' )"
    case "$3" in
      *'%*'* ) dest=$(echo "$3" | sed 's#%*#'"$match"'#') ;;
      *'%_'* ) mkvid "$match"; dest=$(echo "$3" | sed 's/%_/'"$vid"'/') ;;
      *'%-'* ) mksid "$match"; dest=$(echo "$3" | sed 's/%-/'"$sid"'/') ;;
      * ) return 98 ;;
    esac
    dest="$(eval echo $dest)"
    test ! -e "$dest" -o -h "$dest" || {
      $LOG "" "File exists and is not a symlink" "$dest"; return 1
    }
    test -h "$dest" && {
      test "$src" = "$(readlink "$dest")" || rm ${f-} "$dest" >&2
    }
    test -h "$dest" || {
      test -d "$(dirname "$dest")" || mkdir ${f-} "$(dirname "$dest")" >&2
      ln ${f:-"-"}s "$src" "$dest" >&2
    }
  done
  shopt -u nullglob
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

build_copy_changed ()
{
  { test -e "$2" && diff -bqr "$1" "$2" >/dev/null
  } || {
    cp "$1" "$2"
    echo "Updated <$2>" >&2
  }
}

#
