#!/bin/sh

build_lib_load ()
{
  lib_assert $package_build_tool
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

build_tests()
{
  local test_fmt=$1 report_fmt=$2; shift 2

  for x in "$@"
    do
      echo "$(dirname $x)/$(basename -- "$x" .$test_fmt).$report_fmt"
    done
}

build_test()
{
  true
}

build()
{
  test -n "${package_build_tool-}" || return 1
  $package_build_tool "$@"
}

# XXX: Map to namespace to avoid overlap with builtin names
req_subcmd() # Alt-Prefix [Arg]
{
  test $# -gt 0 -a $# -lt 3 || return
  local dflt= altpref="$1" subcmd="$2"

  prefid="$(printf -- "$altpref" | tr -sc 'A-Za-z0-9_' '_')"

  type "$subcmd" 2>/dev/null >&2 && {
    eval ${prefid}subcmd=$subcmd
    return
  }
  test -n "$altpref" || return

  subcmd="$altpref$subcmd"
  type "$subcmd" 2>/dev/null >&2 && {
    eval ${prefid}subcmd=$subcmd
    return
  }

  $LOG error "ci:env" "No subcmd for '$2'"
  return 1
}

main_() # [Base] [Cmd-Args...]
{
  local main_ret= base="$1" ; shift 1
  test -n "$base" || base="$(basename "$0" .sh)"

  test $# -gt 0 || set -- default
  req_subcmd "$base-" "$1" || usage-fail "$base: $*"

  shift 1
  eval \$${prefid}subcmd "$@" || main_ret=$?
  unset ${prefid}subcmd prefid

  return $main_ret
}

main_test_() # Test-Cat [Cmd-Args...]
{
  export _ENV package_build_tool

  local main_test_ret= testcat="$1" ; shift 1
  test -n "$testcat" || testcat=$(basename "$0" .sh)

  test $# -gt 0 || set -- all
  req_subcmd "$testcat-" "$1" ||
	$LOG error "" "test: $testcat: $*" "" 1

  shift 1
  eval \$${prefid}subcmd \"\$@\" || main_test_ret=$?
  unset ${prefid}subcmd prefid

  test -z "$main_test_ret" && print_green "" "OK" || {
    print_red "" "Not OK"
    return $main_test_ret
  }
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

list_scripts () # [Generator] [Newer-Than]
{
  list_src_files "${1-}" "${2-}" '^\#\!'
}

find_executables ()
{
  find . -executable -type f | cut -c3-
}

#
