#!/usr/bin/env bash

build_lib_load () # sh:no-stat: OIl has trouble parsing heredoc
{
  lib_require argv date match $package_build_tool || return

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
}

build_lib_init ()
{
  # List of targets for build tool
  test -n "${components_txt-}" || {
    true "${COMPONENTS_TXT:="$(PWD=$CWD out_fmt=one cwd_lookup_path components.txt .components.txt)"}"

    components_txt=$COMPONENTS_TXT
  }

  # Toggle or alternate target for build tool to build components-txt
  #test -n "${components_txt_build-}" ||
  #  components_txt_build=${COMPONENTS_TXT_BUILD:-"1"}

  true "${PROJECT_CACHE:="$CWD/.meta/cache"}"
  true "${COMPONENT_TARGETS:="$PROJECT_CACHE/component-targets.list"}"

  # Targets for CI jobs
  test -n "${build_txt-}" || build_txt="${BUILD_TXT:-"build.txt"}"

  test -n "${dependencies_txt-}" || dependencies_txt="${DEPENDENCIES_TXT:-"dependencies.txt"}"
}

build ()
{
  test -n "${package_build_tool-}" || return 1
  $package_build_tool "$@"
}

# Alias target: defer to other targets
build_component_alias () # <Name> <Targets...>
{
  shift
  #shellcheck disable=SC2046
  set -- $(eval "echo $*")
  # XXX: not sure if this can something with spaces/other special characters
  # properly. May be test such later...
  #eval "set -- $(echo $* | lines_printf '"%s"')"
  build-ifchange "$@"
}

# Defer to script: build a (single) target using a source script that can build multiple targets
build_component_defer () # ~ <Target-Name> <Part-Name>
{
  local part
  part=$(sh_lookup "$2" $build_parts_bases )
  source "$part"
}

build_component_exists () # Target
{
  test -n "${1-}" || return 98
  read_nix_style_file "$components_txt" | {
    while read name type args
    do
      test "$name" = "$1" && return
      continue
    done
    return 1
  }
}

# Almost like alias, except this expands strings containing shell expressions.
# These can be brace-expansions, variables or even subcommands.
build_component_expand () # ~ <Target-Name> <Target-Expressions...>
{
  shift
  build-ifchange $(eval "echo $*")
}

#
build_component_expand_all () # ~ <Target-Name> <Source-Command...> -- <Target-Formats...>
{
  local source_cmd=
  shift

  while argv_has_next "$@"
  do source_cmd="$source_cmd $1";
    shift
  done
  argv_is_seq "$@" || return
  shift

  build-ifchange $( $source_cmd | while read nameparts
    do
      for fmt in "$@"
      do
        eval "echo $( expand_format "$fmt" $nameparts )"
      done
    done )
}

# Function target: invoke function with build-args
build_component_function () # ~ <Target-Name> [<Function-Name>] <Libs...>
{
  local libs name=$1 func="$2"
  shift 2
  test "${func:-"-"}" != "-" ||
    func="build_$(mkvid "$name" && printf -- "$vid")"

  test $# -eq 0 || { lib_require "$@" || return; }
  $func "$@"
}

# Symlinks: create each dest, linking to srcs
build_component_symlinks () # ~ <Target-Name> <Source-Glob> <Target-Format>
{
  local src match dest grep="$(glob_spec_grep "$2")" f
  test ${quiet:-0} -eq 1 || f=-v

  shopt -s nullglob
  for src in $2
  do
    dest=$(eval "echo \"$(
        expand_format "$3" "$(echo "$src" | sed 's/'"$grep"'/\1/g' )" || return
      )\"")

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

# Simpleglob: defer to target paths obtained by expanding source-spec
#build_component_glob () # ~ <Name> <Target-Pattern> <Source-Globs...>
build_component_simpleglob () # ~ <Target-Name> <Target-Spec> <Source-Spec>
{
  local src match glob=$(echo "$3" | sed 's/%/*/')
  build-ifchange $( for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$2" | sed 's/\*/'"$match"'/'
    done )
}

# Call the build-component-* handler (based on rule's type), by retrieving the
# first target/type/arguments rule from the compoentns-txt file, by matching an
# rule name (and type if given).
build_components () # ~ <Name> [<Type>]
{
  $LOG "note" "" "Building components" "$*"

  local name="$1" name_p type="${2:-"[^ ]*"}" comptab; shift 2
  fnmatch "*/*" "$name" && name_p="$(match_grep "$name")" || name_p="$name"
  comptab=$(grep '^'"$name_p"' '"$type"'\($\| \)' "$components_txt") &&
    test -n "$comptab" || {
      error "No such component '$type:$name" ; return 1
    }

  read_data name type args <<<"$comptab"
  # Rules have to expand globs by themselves.
  set -o noglob; set -- $name $args; set +o noglob
  $LOG "info" "" "Building as '$type' component" "$*"
  build_component_${type//-/_} "$@"
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

build_run () # ~ <Target>
{
  grep -q "^$1 " "$components_txt" && {
    build_components "$1"
    return $?
  }

  test -e "$COMPONENT_TARGETS.do" || {
    { cat <<EOM
#!/usr/bin/env bash

cd \$REDO_BASE
ENV_NAME=redo \
  . ./tools/redo/env.sh &&
  build-ifchange "\$components_txt" &&
  build_fetch_rules
EOM
    } > "$COMPONENT_TARGETS.do"
  }
  redo-ifchange "$(realpath --relative-to=$PWD "$COMPONENT_TARGETS")"

  local name
  name=$( grep -F " $1 " "$COMPONENT_TARGETS" | cut -d' ' -f1 ) && {

    case "$(grep "^$name " "$components_txt" | cut -d' ' -f2)" in
      ( simpleglob )
          build-ifchange "$1"
          return $?
        ;;
    esac
  }

  build-ifchange "$1"
}

build_fetch_alias_rules () # ~ <Group-Name> <Prerequisites...>
{
  local group="$1"
  shift
  while test $# -gt 0
  do
    echo "$group $1"
    shift
  done
}

build_fetch_expand_rules () # ~ <Group-Name> <Brace-Pattern...>
{
  local group="$1" a
  shift
  for a in $(eval "echo $*")
  do
    echo "$group $a"
  done
}

build_fetch_expand_all_rules () # ~ <Target> <Cmd...> -- <Tpl-Pattern...>
{
  local group=$1 source_cmd=
  shift

  while argv_has_next "$@"
  do source_cmd="$source_cmd $1";
    shift
  done
  argv_is_seq "$@" || return
  shift

  for a in $( $source_cmd | while read nameparts
    do
      for fmt in "$@"
      do
        eval "echo $( expand_format "$fmt" $nameparts )"
      done
    done )
  do
    echo "$group $a"
  done
}

build_fetch_function_rules () # ~ <Group-Name> <Func-Name> <Libs...>
{
  local group="$1"
  shift
  echo "$group - type:$*"
}

build_fetch_simpleglob_rules () # ~ <Group-Name> <Target-Spec> <Source-Spec>
{
  local src match glob=$(echo "$3" | sed 's/%/*/')
  for src in $glob
    do
      match="$(glob_spec_var "$glob" "$src")"
      echo "$1 $(echo "$2" | sed 's/\*/'"$match"'/') $(echo "$glob" | sed 's/\*/'"$match"'/')"
    done
}

# Produce a list of <Group> <Target> <Sources> from c.txt
build_fetch_rules ()
{
  read_nix_style_file "$components_txt" | {
    while read name type args
    do
      set -o noglob; set -- $name $args; set +o noglob
      build_fetch_${type//-/_}_rules "$@"
    done
  }
}

build_fetch_symlinks_rules () # ~ <Group-Name> <Target-Spec> <Source-Spec>
{
  local group=$1 src match dest grep="$(glob_spec_grep "$2")" f
  test ${quiet:-0} -eq 1 || f=-v

  shopt -s nullglob
  for src in $2
  do
    dest=$(eval "echo \"$(
        expand_format "$3" "$(echo "$src" | sed 's/'"$grep"'/\1/g' )" || return
      )\"")
    echo "$group $dest"
  done
  shopt -u nullglob
}

# TODO: virtual target to build components-txt table, and to generate rules for
# every record.
build_table_for_targets () # ~ <>
{
  false
}

# Virtual target that shows various status bits about build system
build_info ()
{
  echo "${!build_component_*}" | words_to_lines | cut -c 12- >&2
}

# Return first globbed part, given glob pattern and expanded path.
# Returned part is everything matched from first to last wildcard glob,
# so this works on globstar and to a degree with multiple wildcards.
glob_spec_var () # ~ <Pattern> <Path>
{
  set -- "$@" "$(glob_spec_grep "$1")"
  echo "$2" | sed 's/'"$3"'/\1/g'
}

glob_spec_grep ()
{
  # Escape all special regex characters, then turn glob in there into
  # a match group. Multiple globs turn into one group as well, including string
  # parts in between.
  match_grep "$1" | sed 's/\*\(.*\*\)\?/\(\.\*\\)/'
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
        for m in "$@"
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

expand_format () # ~ <Format> <Name-Parts>
{
  local format="$1"
  shift
  for part in "$@"
  do
    case "$format" in
      *'%*'* ) echo "$format" | sed 's#%\*#'"$part"'#g' ;;
      *'%_'* ) mkvid "$part"; echo "$format" | sed 's/%_/'"$vid"'/g' ;;
      *'%-'* ) mksid "$part"; echo "$format" | sed 's/%-/'"$sid"'/g' ;;
      * ) return 98 ;;
    esac
  done
}


test -n "${__lib_load-}" || {

  case "$(basename -- "$0" .lib.sh )" in

    ( "build" )
        . "${U_S}/tools/redo/env.sh" || exit $?

        test $# -gt 0 || set -- $build_all_targets
        while test $# -gt 0
        do
          build_run "$1" || {
            $LOG error "$1" "" "E:$?"
            exit 1
          }
          shift
        done
      ;;

    ( * ) ;;
  esac
}
#
