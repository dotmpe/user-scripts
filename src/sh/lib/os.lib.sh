#!/bin/sh

## OS - system toolkit/programs, files, paths.


os_lib__load ()
{
  lib_require str &&
  : "${OS_HOST:="$(hostname -f)"}" &&
  : "${OS_HOSTNAME:="$(hostname -s)"}" &&
  : "${OS_NAME:="$(uname -o)"}" &&
  : "${OS_UNAME:="$(uname -s)"}"
}

os_lib__init ()
{
  [[ "${os_lib_init-}" = "0" ]] || {

    os_filestat_getschema || return

    [[ "$LOG" && ( -x "$LOG" || "$(type -t "$LOG")" = "function" ) ]] \
      && os_lib_log="$LOG" || os_lib_log="$INIT_LOG"
    [[ "$os_lib_log" ]] || return 108
    ! sys_debug -dev -debug -init ||
      $os_lib_log notice "" "Initialized os.lib" "$(sys_debug_tag)"
  }
}


# Ensure path is absolute, and clean up '/'.
absdir () # ~ <Path> [<Basedir>]
{
  # NOTE: somehow my Linux pwd makes a symbolic path to root into //bin,
  # using tr to collapse all sequences to one
  #( cd "$1" && pwd -P | tr -s '/' '/' )
  [[ "${1:0:1}" = "/" ]] && echo "$1" || {
    : "${2:-$PWD}/$1"
    echo "${_//\/\//\/}"
  }
}

# A simple, useful wrapper for awk prints entire line, one column or other
# AWK print value if AWK expression evaluates true.
awk_line_select () # (s) ~ <Awk-If-Expr> [<Out>]
{
  : "${1:?awk-line-select: An expression is required}"
  awk '{ if ( '"$_"' ) { print '"${2:-"\$0"}"' } }'
}

# Cumulative dirname, return the root directory of the path
# XXX: make basedirs, cons w cwd-lookup-path
basedir ()
{
  # Recursively. FIXME: a string op. may be faster
  while fnmatch "*/*" "$1"
  do
    set -- "$(dirname "$1")"
    [[ "$1" != "/" ]] || break
  done
  echo "$1"
}

# [exts=] basenames [ .EXTS ] PATH...
# Get basename(s) for all given exts of each path. The first argument is handled
# dynamically. Unless exts env is provided, if first argument is not an existing
# and starts with a period '.' it is used as the value for exts.
basenames () # [exts=] ~ [ .EXTS ] PATH...
{
  [[ "${exts-}" ]] || {
    fnmatch ".*" "$1" || return
    exts="$1"; shift
  }
  while [[ $# -gt 0 ]]
  do
    name="$1"
    shift
    for ext in $exts
    do
      name="$(basename -- "$name" "$ext")"
    done
    echo "$name"
  done
}

# Count occurence of character each line
count_char () # ~ <Char>
{
  local ch="${1:?}"; shift
  # strip -1 "error" for empty line
  awk -F"$ch" '{print NF-1}' | sed 's/^-1$//'
}

# Count every character
count_chars () # ~ [<File> | -]...
{
  [[ "${1:-"-"}" = "-" ]] && {
    wc -w | awk '{print $1}'
    return
  } || {
    while [[ $# -gt 0 ]]
    do
      wc -c "$1" | awk '{print $1}'
      shift
    done
  }
}

# Count tab-separated columns on first line. One line for each file.
count_cols ()
{
  [[ $# -gt 0 ]] && {
    while [[ $# -gt 0 ]]
    do
      { printf '\t'; head -n 1 "$1"; } | count_char '\t'
      shift
    done
  } || {
    { printf '\t'; head -n 1; } | count_char '\t'
  }
}

# Count lines with wc (no EOF termination correction)
count_lines ()
{
  [[ "${1-"-"}" = "-" ]] && {
    wc -l | awk '{print $1}'
    return
  } || {
    while [[ $# -gt 0 ]]
    do
      wc -l "$1" | awk '{print $1}'
      shift
    done
  }
}

# Count words
count_words () # [FILE | -]...
{
  [[ "${1:-"-"}" = "-" ]] && {
    wc -w | awk '{print $1}'
    return
  } || {
    while [[ $# -gt 0 ]]
    do
      wc -w "$1" | awk '{print $1}'
      shift
    done
  }
}

dirname_ ()
{
  while [[ "$1" -gt 0 ]]
    do
      set -- $(( $1 - 1 ))
      set -- "$1" "$(dirname "$2")"
    done
  echo "$2"
}

# Perform action for first path existing as directory
dir_exists () # ~ <Action> <Paths...>
{
  os_do_exists "test -d" "$@"
}

disk_usage () # ~ <Path> [<Du-flags=s>]
{
  if_ok "$(du ${2:+-}${2--s} "${1:?}")" &&
  echo "${_%%[$'\t ']*}"
}

# Perform action for first path from inputs that passes test.
os_do_exists () # ~ <Test> <Action=echo> <Paths...>
{
  local test_ test=${1:?} act=${2:-echo}
  shift 2
  [[ "${test:0:1}" = '!' ]] && test_='test ! -'${test:1} ||
    [[ "${#test}" = '1' ]] &&
      test_='test -'${test} || test_=$test
  while [[ $# -gt 0 ]]
  do
    $test_ "${1:?}" && break
    shift; continue
  done
  [[ $# -gt 0 ]] || return
  $act "$1"
}

dotname () # ~ Path [Ext-to-Strip]
{
  echo "$(dirname -- "$1")/.$(basename -- "$1" "${2-}")"
}

# Number lines from read-nix-style-file by src, filter comments after.
enum_nix_style_file ()
{
  cat_f=-n read_nix_style_file "$@" '^[0-9]*:\s*(#.*|\s*)$' || return
}

# make numbered copy, see number-file
file_backup () # ~ <Name> [<.Ext>]
{
  [[ -s "${1:?}" ]] || return
  action="cp -v" file_number "${@:?}"
}

# XXX: Determine
file_format_reader () # ~ <File-path>
{
  TODO "Determine file format for reader"
}

# Modelines are regulary used to provide editor and file format settings.
# XXX: would want to select modepart for specific editor if specified as well
file_modeline () # :file{version,id,mode} ~ <File>
{
  declare fml_lvar=${fml_lvar:-false} vpk=file_ml_
  #"$fml_lvar" && vpk=local:file_ml_ || vpk=file_ml_

  fileversion="" fileid="" filemode=""

  file_ml_src=${1:--}
  if_ok "$(file_id_modeline_grep "$@")" && {
    : "$(<<< "$_" normalize_ws)"
    line_number_raw "$_" $vpk ":" &&
    file_ml_raw=$(str_trim1 "${file_ml_raw}") || return
    # XXX: only uses last part of line, how about specified editors?
    declare rest rest_
    filemode=${file_ml_raw##* }; rest_=${file_ml_raw% *}
    [[ "${#rest_}" -lt "${#file_ml_raw}" ]] || return 0
    rest=$rest_; fileid=${rest##* }; rest_=${rest% *}
    [[ "${#rest}" -gt "${#rest_}" ]] || return 0
    rest=$rest_; fileversion=${rest##* }; rest_=${rest% *}
    [[ "${#rest}" -ge "${#rest_}" ]] || {
      : "rest=$rest_ file:$file_ml_src"
      : "$_${fileid:+:id=$fileid}"
      : "$_${fileversion:+:ver=$fileversion}"
      : "$_${filemode:+:mode=$filemode}"
      : "$_:'$file_ml_raw'"
      $LOG warn "" "Too many fields in Id (ignored)" "$_"
    }
  } || {
    if_ok "$(file_pp_modeline_grep "$@")" && {
      : "$(<<< "$_" normalize_ws)"
      line_number_raw "$_" $vpk ":" &&
      file_ml_raw=$(str_trim1 "${file_ml_raw}") || return
      filemode=${file_ml_raw##* }
      # XXX: only uses last part of line, how about specified editors?
    } || {
        set --
        for fml_editor in ${fml_editors:-ex vim}
        do
          : "${file_ml_src:?}"
          if_ok "$(file_editor_mode_grep "$_")" || continue
          : "$(<<< "$_" normalize_ws)"
          set -- "$_"
          break
        done
        [[ $# -gt 0 ]] &&
        line_number_raw "$1" $vpk ":" &&
        file_ml_raw=:$(str_trim1 "${file_ml_raw}") || return
        filemode=${file_ml_raw%% *}
      # ||
        # $LOG error "" "No modefile for input" "${1--}" ${_E_nsk}
    }
  }
}

file_editor_mode_grep ()
{
  grep -niPo -m1 "^#.* ${fml_editor:-ex}:\K.*" "$@"
}

file_id_modeline_grep ()
{
  grep -niPo -m1 "^#  *${fml_idk:-id}:? *\K.*" "$@"
}

file_pp_modeline_grep ()
{
  grep -niPo -m1 "^#${fml_mlpd:-modeline}  *\K.*" "$@"
}

file_modification_age ()
{
  fmtdate_relative "$(filemtime "$1")" "" ""
}

# Add number to filename, provide extension to split basename before adding suffix
file_number () # [action=mv] ~ <Name> [<.Ext>]
{
  local dir base dest cnt=1
  dir=$(dirname -- "${1:?}")
  #shellcheck disable=2086
  base=$(basename -- "$1" ${2-})

  while true
  do
    dest=$dir/$base-$cnt${2-}
    [[ -e "$dest" ]] || break
    cnt=$(( cnt + 1 ))
  done

  local action="${action:-echo}"
  $action "$1" "$dest"
}

# determine fr-spec,
# this may refer to a function or some sort of symbol
file_reader () # (<?,fr-ctx:,:fr-{p,b,spec}) ~ [<File> <...>]
{
  local fr_ctx=${fr_ctx:-modeline} fr_argc fr_init

  ${fr_ctx:?}_file_path "$@" || return
  [[ -z "${fr_argc-}" ]] || shift $_

  stderr echo file_reader "$@" fr_p=$fr_p
  ${fr_ctx:?}_file_reader "${fr_p:?}" || fr_init=$?
  [[ -z "${fr_init-}" ]] ||
    $LOG alert :file-reader "Unable to set file-reader context" \
      "${fr_ctx:-}:E${fr_init:-?}:$*" ${fr_init:-$?}
  [[ "${fr_spec-}" ]] || return ${_E_NF:-124}
}

# rename to numbered file, see number-file
file_rotate () # ~ <Name> [<.Ext>]
{
  [[ -s "${1:?}" ]] || return
  action="mv -v" file_number "${@:?}"
}

# FIXME: file-deref=0?
file_stat_flags()
{
  [[ "${file_deref:-0}" -eq 0 ]] || flags=${flags:--}L
}

file_tool_flags()
{
  trueish "${file_names-}" && flags= || flags=b
  falseish "${file_deref-}" || flags=${flags}L
}

file_update_age ()
{
  fmtdate_relative "$(filectime "$1")" "" ""
}

# Use `stat` to get inode change time (in epoch seconds)
filectime() # File
{
  while [[ $# -gt 0 ]]
  do
    case "${OS_UNAME,,}" in
      darwin )
          stat -L -f '%c' "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          stat -L -c '%Z' "$1" || return 1
        ;;
      * ) $os_lib_log error "os" "filectime: $OS_UNAME?" "" 1 ;;
    esac; shift
  done
}

# Description of file contents, format
fileformat ()
{
  local flags= ; file_tool_flags
  file -"${flags}" "$1"
}

# Check wether name has extension, return 0 or 1
fileisext() # Name Exts..
{
  local f="$1" ext="" ; ext=$(filenamext "$1") || return ; shift
  [[ "$*" ]] || return
  [[ "$ext" ]] || return
  for mext
  do [[ ".$ext" = "$mext" ]] && return 0
  done
  return 1
}

# Use `stat` to get modification time (in epoch seconds)
filemtime() # File
{
  local flags=
  file_stat_flags
  while [[ $# -gt 0 ]]
  do
    case "${OS_UNAME,,}" in
      darwin )
          "${file_names:-false}" && pat='%N %m' || pat='%m'
          stat -f "$pat" $flags "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          "${file_names:-false}" && pat='%N %Y' || pat='%Y'
          stat -c "$pat" $flags "$1" || return 1
        ;;
      * ) $os_lib_log error "os" "filemtime: $OS_UNAME?" "" 1 ;;
    esac; shift
  done
}

# Use `file` to get mediatype aka. MIME-type
filemtype () # File..
{
  local flags= ; file_tool_flags
  case "${OS_UNAME,,}" in
    darwin )
        file -"${flags}"I "$1" || return 1
      ;;
    linux )
        file -"${flags}"i "$1" || return 1
      ;;
    * ) error "filemtype: $OS_UNAME?" 1 ;;
  esac
}

filename_baseid () # ~ <Path-Name>
{
  basename="$(filestripext "$1")"
  id=$(str_sid "$basename")
}

# for each argument echo filename-extension suffix (last non-dot name element)
filenamext () # ~ <Name..>
{
  local n
  for n in "${@:?}"
  do
    basename -- "$n"
  done | grep '\.' | sed 's/^.*\.\([^\.]*\)$/\1/' || true
}

# Use `stat` to get size in bytes
filesize () # File
{
  local flags=
  file_stat_flags
  while [[ $# -gt 0 ]]
  do
    case "${OS_UNAME,,}" in
      darwin )
          stat -L -f '%z' "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          stat -L -c '%s' "$1" || return 1
        ;;
      * ) $os_lib_log error "os" "filesize: $OS_UNAME?" "" 1 ;;
    esac; shift
  done
}

bytesize_orders=(
  "B bytes"       # 1 = 8b
  "KiB Kilobytes"  # 10^3
  "MiB Megabytes"  # 10^6
  "GiB Gigabytes"  # 10^9
  "TiB Terabytes"  # 10^12
  #"PiB Petabytes"  # 10^15
  #"EB Exabyte"    # 10^18
  #ZB Zettabyte  # 10^21
  #YB Yottabyte  # 10^24
  #RB Ronnabyte  # 10^27
  #QB Quettabyte # 10^30
)

# human-readable-bytesize
readable_bytesize () # ~ <Size>
{
  local bo_idx=0 bo=1 bs=${1:?}
  while true
  do
    bs="$(echo "scale=3; $bs / 1000" | ${c_bc:-bc})" || return
    bo=$(( bo + 3 ))
    bo_idx=$(( bo_idx + 1 ))
    awk -v a="$bs" -v b="$(( 10 ** $bo ))" 'BEGIN{ if (a<=b) exit 1 }' || break
  done
  echo "$bs${bytesize_orders[$bo_idx]// *}"
}

# Format int grouping digits in sets of three
readable_number () # ~ <Num> [<group-separator>]
{
  local num=${1:?} sep=${2:-,} n out
  while [[ 3 -lt "${#num}" ]]
  do
    n=${num%???}
    out=${num:${#n}}${out+$sep$out}
    num=$n
  done
  echo "$num${out+,$out}"
}

os_filestat_fieldsformat () # ~ <FIELDS...>
{
  local _fieldspec
  : "${@:?}"
  for _fieldspec
  do
    fnmatch "$_fieldspec" "[a-zA-Z]" && {
      echo "%$_fieldspec"
    } || {
      echo "${os_filestat_schema["os:stat:format:$_fieldspec.alias"]:?Field $_fieldspec}"
    }
  done
}

os_filestat_getschema () # ~
{
  : "${os_filestat_schemafp:=${STATUSDIR_ROOT:?os_filestat_schemafp location required}cache/os-lib-filestat.schema.sh}"
  [[ -s "${os_filestat_schemafp:?}" ]] && {
    . "${os_filestat_schemafp:?}" || return
  } ||
    os_filestat_init || return
}

# XXX: single frontend for os-filestat should probably be object based.
# the utils below are designed to retrieve several stat fields in a single
# stat invocation

#os_filestat () # ~ <PATH> <DEST> <FIELDS...>
#{
#  local _path=${1:?Expected PATH argument} _os_fstat_destname=${2-}
#  local -n _os_fstat_data=${2:?Expected DEST array table}
#  #_fmt=$(os_filestat_fieldsformat "${@:3}") &&
#  TODO $FUNCNAME
#}

# XXX: write field schemes for file, directory and other path types to Bash
# readable file
os_filestat_init ()
{
  declare -gA os_filestat_schema=(

  ["os:stat:format:%a.short"]="access rights in octal (note '#' and '0' printf flags)"
  ["os:stat:format:%A.short"]="access rights in human readable form"
  ["os:stat:format:%b.short"]="number of blocks allocated (see %B)"
  ["os:stat:format:%B.short"]="the size in bytes of each block reported by %b"
  ["os:stat:format:%C.short"]="SELinux security context string"
  ["os:stat:format:%d.short"]="device number in decimal"
  ["os:stat:format:%D.short"]="device number in hex"
  ["os:stat:format:%f.short"]="raw mode in hex"
  ["os:stat:format:%F.short"]="file type"
  ["os:stat:format:%g.short"]="group ID of owner"
  ["os:stat:format:%G.short"]="group name of owner"
  ["os:stat:format:%h.short"]="number of hard links"
  ["os:stat:format:%i.short"]="inode number"
  ["os:stat:format:%m.short"]="mount point"
  ["os:stat:format:%n.short"]="file name"
  ["os:stat:format:%N.short"]="quoted file name with dereference if symbolic link"
  ["os:stat:format:%o.short"]="optimal I/O transfer size hint"
  ["os:stat:format:%s.short"]="total size, in bytes"
  ["os:stat:format:%t.short"]="major device type in hex, for character/block device special files"
  ["os:stat:format:%T.short"]="minor device type in hex, for character/block device special files"
  ["os:stat:format:%u.short"]="user ID of owner"
  ["os:stat:format:%U.short"]="user name of owner"
  ["os:stat:format:%w.short"]="time of file birth, human-readable; - if unknown"
  ["os:stat:format:%W.short"]="time of file birth, seconds since Epoch; 0 if unknown"
  ["os:stat:format:%x.short"]="time of last access, human-readable"
  ["os:stat:format:%X.short"]="time of last access, seconds since Epoch"
  ["os:stat:format:%y.short"]="time of last data modification, human-readable"
  ["os:stat:format:%Y.short"]="time of last data modification, seconds since Epoch"
  ["os:stat:format:%z.short"]="time of last status change, human-readable"
  ["os:stat:format:%Z.short"]="time of last status change, seconds since Epoch"

  ["os:stat:format:access-rights-oct.alias"]="%a"
  ["os:stat:format:access-rights.alias"]="%A"
  ["os:stat:format:allocated-blocks.alias"]="%b"
  ["os:stat:format:block-size.alias"]="%B"
  ["os:stat:format:security-context.alias"]="%C"
  ["os:stat:format:device-number.alias"]="%d"
  ["os:stat:format:device-number-hex.alias"]="%D"
  ["os:stat:format:raw-mode-hex.alias"]="%f"
  ["os:stat:format:file-type.alias"]="%F"
  ["os:stat:format:owner-gid.alias"]="%g"
  ["os:stat:format:owner-group-name.alias"]="%G"
  ["os:stat:format:hard-link-count.alias"]="%h"
  ["os:stat:format:inode-number.alias"]="%i"
  ["os:stat:format:mount-point.alias"]="%m"
  ["os:stat:format:file-name.alias"]="%n"
  # XXX: called this sym(bolic)-ref(erence) since its one or two quoted strings
  # "'<linkpath>' -> '<trgtpath>' when type is 'symbolic link'
  ["os:stat:format:quoted-symref.alias"]="%N"
  ["os:stat:format:optimal-xfer-size.alias"]="%o"
  ["os:stat:format:byte-size.alias"]="%s"
  ["os:stat:format:major-devtype-hex.alias"]="%t"
  ["os:stat:format:minor-devtype-hex.alias"]="%T"
  ["os:stat:format:owner-uid.alias"]="%u"
  ["os:stat:format:owner-name.alias"]="%U"
  ["os:stat:format:birth-time.alias"]="%w"
  ["os:stat:format:birth-timestamp.alias"]="%W"
  ["os:stat:format:access-time.alias"]="%x"
  ["os:stat:format:access-timestamp.alias"]="%X"
  ["os:stat:format:modification-time.alias"]="%y"
  ["os:stat:format:modification-timestamp.alias"]="%Y"
  ["os:stat:format:status-time.alias"]="%z"
  ["os:stat:format:status-timestamp.alias"]="%Z"
	["os:stat:format:terse.alias"]="%n %s %b %f %u %g %D %i %h %t %T %X %Y %Z %W %o %C"

  ["os:stat:format:inode.alias"]="%i"
  ["os:stat:format:ctime-dt.alias"]="%z"
  ["os:stat:format:ctime.alias"]="%Z"
  ["os:stat:format:atime-dt.alias"]="%x"
  ["os:stat:format:atime.alias"]="%X"
  ["os:stat:format:mtime-dt.alias"]="%y"
  ["os:stat:format:mtime.alias"]="%Y"
  )
  #os_fsstat_schema=(
	#)

  {
    echo "declare -gA os_filestat_schema"
    arr_dump os_filestat_schema
  } > "${os_filestat_schemafp:?}"
}

os_filestat_list () # ~ <PATH> <DEST> <FIELDS...>
{
  local _path=${1:?} _fieldspec _fmt
  local -n _dest=${2:?}

  _fmt="$(os_filestat_fieldsformat "${@:3}")" &&
  if_ok "$(stat -c "$_" "${_path}")" &&
  <<< "$_" mapfile -t ${2:?}
}

os_filestat_makeformat () # <DEST> <FIELDS...>
{
	local _field
	local -n _fmt=${1:?}
	shift &&
	for _field
	do
	  test -n "${os_filestat_schema["os:stat:format:%$field.short"]-}" &&
    fmt=${fmt-}${fmt+ }$_ || {
	    test -n "${os_filestat_schema["os:stat:format:$field.alias"]-}" &&
      fmt=${fmt-}${fmt+ } $_ ||
        $LOG alert : "Unknown format specifier" "$field" 3 || return
    }
	done
}

# Read stat output line by line. Each field's format must expand to exactly one
# line, but may contain spaces. XXX: Not sure if this is useful but it allows
# to retireve composite string values. Note that while this may seem useful for
# filenames, those are usually very unrestricted and can have newlines. Better
# to use bash facilities for quoting, or use %N/quoted-deref instead of
# %n/filename.
os_filestat_read () # ~ <PATH> <NAMESPECS...>
{
  local _path=${1:?} _fieldspec _var
  local -a _fields _vars
  shift 1 &&
  for _fieldspec in "${@:?}"
  do
    _fields+=( ${_fieldspec%%:*} )
    : "${_fieldspec##*:}"
    _vars+=( ${_//[^A-Za-z0-9_]/_} )
  done &&
  if_ok "$(os_filestat_values "${_path}" - "${_fields[@]}")" &&
  for _var in "${_vars[@]}"
  do
    read -r "${_var}"
  done <<< "$_"
}

# Use a single readline invocation to read all stat output to variables.
# Values cannot include spaces. Newlines in the pattern are substituted for
# spaces. This suits many values that stat returns, but it cannot read
# composite formatting sequences. XXX: Also unfortenately file-type can have
# spaces.
os_filestat_readline () # ~ <PATH> <NAMESPECS...>
{
  local _path=${1:?} _fieldspec
  local -a _fields _vars
  shift 1 &&
  for _fieldspec in "${@:?}"
  do
    _fields+=( ${_fieldspec%%:*} )
    : "${_fieldspec##*:}"
    _vars+=( ${_//[^A-Za-z0-9_]/_} )
  done &&
  if_ok "$(os_filestat_values "${_path}" - "${_fields[@]}")" &&
  : "${_//$'\n'/ }" &&
  <<< "$_" read -r "${_vars[@]}"
}

# FIXME: this is not as useful while stat field values cannot be used with
# KEYFMT. Only field key or name. Should add callback function for key building.
# ${os_table_keycb} str_format_one str_format_shell str_format_pfields
os_filestat_table () # ~ <PATH> <DEST> <KEYFMT> <FIELDS...>
{
  local _path=${1:?} _keyfmt=${3:-%s} _{fieldspec,key,value}
  local -n _dest=${2:?}
  if_ok "$(os_filestat_values "${_path}" - "${@:4}")" &&
  for _fieldspec in "${@:4}"
  do
    read -r _value &&
    printf -v _key -- "${_keyfmt}" "$_fieldspec" &&
    _dest[${_key}]=${_value} || return
  done <<< "${_}"
}

os_filestat_values () # ~ <PATH> <DEST=-> <FIELDS...>
{
  local _path=${1:?} _dest _fmt
  { [[ ${2:--} == - ]] && _dest=/dev/stdout || _dest=${2}; } &&
  _fmt="$(os_filestat_fieldsformat "${@:3}")" &&
  stat -c "$_fmt" "$_path" >> "${_dest:?}"
}


# Return basename for one file, using filenamext to extract extension.
# See basenames for multiple args, and pathname to preserve (relative) directory
# elements for name.
filestripext () # ~ <Name>
{
  ext="$(filenamext "$1")" || return
  [[ "$ext" ]] && set -- "$1" ".$ext"
  basename -- "$@"
}

filter () # (Std:0:) ~ <Test-handler>
{
  local value
  while read -r value
  do
    "${@:?}" "$value" || {
      sys_astat -eq ${_E_next:?} && continue
      return
    }
    echo "$value"
  done
}

filter_args () # ~ <Test-cmd> <Args...> # Print args for which test pass
{
  local value test=${1:?}
  for value in "${@:2}"
  do
    $test "$value" || {
      continue
      # TODO: make test functions discern between error and test failure/pass
      #test ${_E_next:?} -eq $? && continue
      #return $_
    }
    echo "$value"
  done
}

# Strip comments lines, including pre-proc directives and empty lines.
filter_content_lines () # (s) ~ [<Marker-Regex>] # Remove marked or empty lines from stream
{
  grep -v '^\s*\('"${1:-"#"}"'.*\|\s*\)$'
}

filter_empty_lines () # (s) ~ # Remove empty lines from stream
{
  grep -v '^\s*$'
}

# Strip line comments, including line-continuations and comments at the end of
# lines and indented comments.
# See line-comment-conts-collapse to transform them.
filter_line_comments () # (s) ~ [<Marker-bre>]
{
  # Remove non-contination line-end comments first.
  # Then substitute contineous blocks and lines together with their newline
  # (ie. remove lines completely). And one more to remove comment on last
  # line in file.
  sed ' :a; N; $!ba;
      s/ * '"${1:-"#"}"'[^\n]*[^\\]\n/\n/g
      s/[\t ]*'"${1:-"#"}"'[^\\\n]*\(\\\n[^\\\n]*\)*\n//g
      s/\n[\t ]*'"${1:-"#"}"'.*$//
    '
}

# Each line is passed as last argument to given command, only those giving zero
# status are echo'ed.
filter_lines () # ~ <Cmd...> # Remove lines for which command returns non-zero
{
  local line
  while read -r line
  do "$@" "$line" || continue
    echo "$line"
  done
}

# XXX: rename to for-lines or something
# Go over arguments and echo. If no arguments given, or on argument '-' the
# standard input is cat instead or in-place respectively. Strips empty lines.
# (Does not open filenames and read from files). Multiple '-' arguments are
# an error, as the input is not buffered and rewounded. This simple setup
# allows to use arguments as stdin, insert arguments-as-lines before or after
# stdin, and the pipeline consumer is free to proceed.
#
# If this routine is given no data is hangs indefinitely. It does not have
# indicators for data availble at stdin.
foreach_item () # [(s)] ~ ['-' | <Arg...>]
{
  : source "os.lib.sh"
  {
    [[ 0 -lt $# ]] && {
      while [[ 0 -lt $# ]]
      do
        [[ "$1" = "-" ]] && {
          # XXX: echo foreach_stdin=1
          cat -
          # XXX: echo foreach_stdin=0
        } || {
          printf -- '%s\n' "$1"
        }
        shift
      done
    } || cat -
  } | grep -v '^$'
}

foreach2 ()
{
  while read -r line
  do "$@" "$line" || return
  done
}

# Extend rows by mapping each value line using act, add result tab-separated
# to line. See foreach-do for other details.
foreach_addcol () # ~ [ - | <Arg...> ]
{
  [[ "${p-}" ]] || local p= # Prefix string
  [[ "${s-}" ]] || local s= # Suffix string
  [[ "${act-unset}" != unset ]] || local act="echo"
  foreach_item "$@" | while read -r _S
    do S="$p$_S$s" && printf -- '%s\t%s\n' "$S" "$($act "$S")" ; done
}
# Var: F:foreach-addcol.bash

# Read `foreach-item` lines and act, default is echo ie. same result as
# `foreach-item`
# but with p(refix) and s(uffix) wrapped around each item produced. The
# unwrapped loop-var is _S.
foreach_do () # ~ [ - | <Arg...> ]
{
  [[ "${p-}" ]] || local p= # Prefix string
  [[ "${s-}" ]] || local s= # Suffix string
  [[ "${act-}" ]] || local act="echo"
  foreach_item "$@" | while read -r _S ; do S="$p$_S$s" && $act "$S" || return ; done
}

foreach_eval ()
{
  local p="${p-}" # Prefix string
  local s="${s-}" # Suffix string
  local act=${act:-"echo"}
  foreach_item "$@" | while read -r _S ; do S="$p$_S$s" && eval "$act \"$S\"" ; done
}

# See -addcol and -do.
foreach_inscol ()
{
  [[ "${p-}" ]] || local p= # Prefix string
  [[ "${s-}" ]] || local s= # Suffix string
  [[ "${act-}" ]] || local act="echo"
  foreach_item "$@" | while read -r _S
    do S="$p$_S$s" && printf -- '%s\t%s\n' "$($act "$S")" "$S" ; done
}

get_uuid ()
{
  [[ -e /proc/sys/kernel/random/uuid ]] && {
    cat /proc/sys/kernel/random/uuid
    return 0
  }
  command -v uuidgen >/dev/null 2>&1 && {
    uuidgen
    return 0
  }
  $os_lib_log error "os" "FIXME uuid required" "" 1
  return 1
}

# Change cwd to parent dir with existing local path element (dir/file/..) $1, leave go_to_before var in env.
go_to_dir_with () # ~ <Local-Name>
{
  [[ "${1-}" ]] || error "go-to-dir: Missing filename arg" 1

  # Find dir with metafile
  go_to_before=.
  while true
  do
    [[ -e "$1" ]] && break
    go_to_before=$(basename -- "$PWD")/$go_to_before
    [[ "$PWD" = "/" ]] && break
    cd ..
  done

  [[ -e "$1" ]] || return 1
}

# An (almost) no-op that does pass previous status back, usable as an
# alternative to putting arguments after 'true' (or ':'), ie to do string
# expressions or subshells and store at last argument ('$_'). If such value
# comes from an subshell, true will always mask status by 0. Alternatively 'test
# -{n,z}' would be usable e.g. for commands that do not return any non-zero
# status on failures, but otherwise that would mask any subshell state just the
# same.
if_ok () # (?) ~ <...> # No-op, except pass (return) previous status
{
  return
}

ignore_sigpipe () # (?) ~ <...> # Status OK if SIG:PIPE
{
  [[ $? -eq 141 ]] # For linux/bash: 128+signal where signal=SIGPIPE=13
}

# Little wrapper to use lines-while to read line-continuations to lines
lines () #
{
  read_f="" lines_count_while_eval echo "\$line"
}

# Wrap wc but correct files with or w.o. trailing posix line-end
line_count () # FILE
{
  [[ -s "${1-}" ]] || return 42
  [[ "$(filesize "$1")" -gt 0 ]] || return 43
  # XXX: posix valid files... ?
  #shellcheck disable=2005,2046
  #lc="$(echo $(od -An -tc -j "$(( $(filesize "$1") - 1 ))" "$1"))"
  #case "$lc" in "\n" ) ;;
  #  "\r" ) error "POSIX line-end required" 1 ;;
  #  * ) printf '\n' >>"$1" ;;
  #esac
  if_ok "$(wc -l "$1")" &&
  echo "${_%% *}"
}

line_number_raw () # ~ <Line-str> <Var-pk> <Num-sep> # Extract line number prefix
{
  local lnr__str=${1--} lnr__vpk=${2:-line_} lnr__nsep=${3:- }
  local -n lnr__ln=${vpk}ln lnr__raw=${vpk}raw
  lnr__ln="${lnr__str%%$lnr__nsep*}" lnr__raw="${lnr__str#*$lnr__nsep}"
}

# Offset content from input/file to line-based window.
lines_slice() # [First-Line] [Last-Line] [-|File-Path]
{
  [[ "${3-}" ]] || error "File-Path expected" 1
  [[ "$3" = "-" ]] && set -- "$1" "$2"
  [[ "$1" ]] && {
    [[ "$2" ]] && { # Start - End: tail + head
      tail -n "+$1" "$3" | head -n $(( $2 - $1 + 1 ))
      return $?
    } || { # Start - ... : tail
      tail -n "+$1" "$3"
      return $?
    }

  } || {
    [[ "$2" ]] && { # ... - End : head
      head -n "$2" "$3"
      return $?
    } || { # Otherwise cat
      cat "$3"
    }
  }
}

lines_vars () # ~ <Varnames...> # Read lines on stdin, one for each var
{
  local __varname
  for __varname
  do
    read -r $__varname || return
  done
}

# See read-while, but echo every line after command has tested it.
lines_while () # ~ <Cmd <argv...>>
{
  echo=true read_while "$@"
}

# Read $line as long as CMD evaluates, and increment $line_number.
# CMD can be silent or verbose in anyway, but when it fails the read-loop
# is broken.
lines_count_while_eval () # CMD
{
  [[ $# -gt 0 ]] || return ${_E_MA:?}

  line_number=0
  while ${read:-read_with_flags} line
  do
    eval "$*" || break
    line_number=$(( line_number + 1 ))
  done
  [[ $line_number -gt 0 ]] || return
}

# TODO: introduce fr_file vs fr_reader context and rename to
# file_reader_path
modeline_file_path ()
{
  [[ $# -gt 0 ]] && {
    [[ ! -e "$1" ]] || {
      fr_p=${1:?} fr_b=false fr_argc=1
    } ||
      fr_p=
  }
  [[ "${fr_p-}" ]] || {
    [[ -t 0 ]] || {
      # buffer stdin at ramfs file location
      fr_p="${RAM_TMPDIR:?}/$(uuidgen).$$.stdin" &&
      cat > "$fr_p" ||
        $LOG alert :file-reader "Failed to read input into file" "E$?:$fr_p" $? ||
          return
      fr_b=true
    }
  }
  [[ "${fr_p-}" ]] || return ${_E_GAE:-193}
  [[ -e "${fr_p-}" ]] || return ${_E_NF:-124}
  [[ -s "${fr_p-}" ]] || return ${_E_E:-193}
}

modeline_file_reader ()
{
  ! file_modeline "${1:?Filename expected}" || {
    #str_globmatch "$filemode" "*[ ]reader:*" "reader:*" && {
    str_wordmatch "reader:*" $filemode && {
      : "${filemode#* reader:}"
      : "${_#reader:}"
      : "${_%% *}"
      fr_spec="$_"
    }
  }
}

normalize_relative()
{
  OIFS=$IFS
  IFS='/'
  local NORMALIZED=

  for I in $1
  do
    # Resolve relative path punctuation.
    if [ "$I" = "." ] || [ -z "$I" ]
      then continue

    elif [ "$I" = ".." ]
      then
        NORMALIZED=$(echo "$NORMALIZED"|sed 's/\/[^/]*$//g')
        continue
      else
        NORMALIZED="${NORMALIZED}/${I}"
        #test -n "$NORMALIZED" \
        #  && NORMALIZED="${NORMALIZED}/${I}" \
        #  || NORMALIZED="${I}"
    fi
  done
  IFS=$OIFS
  [[ "$NORMALIZED" ]] \
    && {
      case "$1" in
        /* ) ;;
        * )
            NORMALIZED="$(expr_substr "$NORMALIZED" 2 ${#NORMALIZED} )"
          ;;
      esac
    } || NORMALIZED=.
  trueish "${strip_trail-}" && echo "$NORMALIZED" || case "$1" in
    */ ) echo "$NORMALIZED/"
      ;;
    * ) echo "$NORMALIZED"
      ;;
  esac
}

# XXX: Because '!' does not work with "$@"
not ()
{
  ! "$@"
}

os_file_mode ()
{
  stat -L -c "%a" "${@:?}"
}

os_private () # ~ <File> [<Var>] # True if current user only has at least read rights
{
  test -f "${1:?}" && {
    test -z "${2-}" && local mode || local -n mode=${2:?}
    test -O "$1" &&
    sys_out mode stat -L -c "%a" "$1" &&
    case "$mode" in ( [4-7]00 ) true;; ( * ) false; esac
  }
}

os_privategroup () # ~ <File> [<Var>] # True if current user/group only, have at least read rights
{
  test -f "${1:?}" && {
    test -z "${2-}" && local mode || local -n mode=${2:?}
    test -O "$1" &&
    sys_out mode stat -L -c "%a" "$1" &&
    case "$mode" in ( [4,6][0,4,6]0 ) true;; ( * ) false; esac
  }
}

os_pids () # ~ <Cmd-name>
{
  ps -C "${1:?}" -o pid:1=
}

# Remove last element from path.
# Like normal dirname command but native (and cleans out ./)
# XXX: the normal dirname command says that the directory for . and .. is .
# (and / for // or ///). Otherwise, aside of '..' the algorithm is fairly
# straightforward: remove one trailing '/*' match, or return '.' if none.
os_dirname () # ~ <Path>
{
  local path=${1:?"$(sys_exc os:dirname:path)"} abs=false root
  case "$path" in
  ( ?*/ )    path="${path%\/}"
  esac
  case "$path" in
  ( /* )     abs=true path=${path:1} ;;
  ( ./ )     path=. ;;
  ( ./* )    path=${path:2}
  esac
  "$abs" && root=/ || root=.
  case "$path" in
  ( ?*/?* )  path="${path%\/*}" ;;
  ( * )      path="$root" ;;
  esac
  echo "$path"
}

os_basename () # ~ <Path> <Ext ...> # Remove path and given extensions from name (in order)
{
  local path=${1:?"$(sys_exc os:basename:path)"} ext
  shift
  case "$path" in
  ( ?*/ )    path="${path%\/}"
  esac
  case "$path" in
  ( */* )  path="${path##*\/}" ;;
  esac
  for ext
  do
    path=${path%$ext}
  done
  echo "$path"
}

os_pathname () # ~ <Path> <Ext ...> # Remove given extensions from path (in order)
{
  local path=${1:?"$(sys_exc os:pathname:path)"} ext
  shift
  for ext
  do
    path=${path%$ext}
  done
  echo "$path"
}

# TODO: deprecate, see os-pathname
# Combined dirname/basename to remove .ext(s) but return path
pathname () # ~ <Path> <Ext ...>
{
  local name="${1:?}" dirname
  dirname=$(dirname -- "$1") || return
  #fnmatch "./*" "$1" && dirname="$(echo "$dirname" | cut -c3-)"
  shift 1
  for ext
  do
    name="$(basename -- "$name" "$ext")"
  done
  #shellcheck disable=2059
  [[ "$dirname" && "$dirname" != "." ]] && {
    printf -- "$dirname/$name\\n"
  } || {
    printf -- "$name\\n"
  }
}

# basepath: see pathname as alt. to basename for ext stripping

# Simple iterator over pathname
pathnames () # exts=... [ - | PATHS ]
{
  [[ "${exts-}" ]] || exit 40
  #shellcheck disable=2086
  [[ "${1--}" != "-" ]] && {
    for path
    do
      pathname "$path" $exts
    done
  } || {
    { cat - | while read -r path
      do pathname "$path" $exts
      done
    }
  }
}

# Run read-blocks until one full block has been echoed.
read_block ()
{
  first=true read_blocks "$@"
}

# Read all lines. Echo every one, after a particular pattern and value is found,
# and until the pattern is matched again. Check that line for value again and
# repeat, keep reading until EOF.
read_blocks () # ~ <Match> <Value-glob>
{
  local found=false first echo
  first=${first:-false}
  while true
  do
    $found && echo=true || echo=false
    read_while not grep -q "$1" || return
    ! $found || ! $first || break
    #shellcheck disable=2154
    fnmatch "$1$2" "$line" && found=true || found=false
    ${quiet:-false} && continue
    $found \
      && $LOG info ":read-blocks" "Reading block after matching header" "$line" \
      || $LOG debug ":read-blocks" "Found block header but no match" "$line"
  done
}

# Prefix/suffix lines with fixed value string
read_concat () # ~ [<Prefix-str>] [<Suffix-str>] # Concat value to lines
{
  local _S
  while ${read:-read -r} _S
  do echo "${1:-}${_S}${2:-}"; done
}

# Read only data, trimming whitespace but leaving '\' as-is.
# See read-escaped and read-literal for other modes/impl.
read_data () # (s) ~ <Read-argv...> # Read into variables, ignoring escapes and collapsing whitespacek
{
  read -r "$@"
}

# Read character data separated by spaces, allowing '\' to escape special chars.
# See also read-literal and read-content.
read_escaped ()
{
  #shellcheck disable=2162 # Escaping can be useful to ignore line-ends, and read continuations as one line
  read "$@"
}

read_escaped_literal () # (s) ~ <Read-argv...> # Read obeying escapes and without collapsing whitespace.
{
  #shellcheck disable=2162
  IFS= read "$@"
}

read_head_blocks () # ~ <Head> <Values>
{
  local echo
  while true
  do
    echo=false read_while not grep -q "^$1" || break
    section=$( echo "$line" | sed "s#^$1##" | awk '{ print $1 }' )
    read -r _ || break
    [[ $# -gt 2 ]] && {
      fnmatch "* $section *" " $* " && echo=true || echo=false
    } || {
      echo=true
    }
    { read_while grep -qE "^[0-9]+ "
    } | sed "s#^#$section #" || break
  done

  #read_while not grep -q "^$1" | sed "s#^#$section #"
}

# Test for file or return before read
read_if_exists ()
{
  [[ "${1-}" ]] || return 1
  read_nix_style_file "$@" 2>/dev/null || return 1
}

# [0|1] [line_number=] read-lines-while FILE WHILE [START] [END]
#
# Read FILE lines and set line_number while WHILE evaluates true. No output,
# WHILE should evaluate silently, see lines-while. This routine sets up a
# (subshell) pipeline from lines-slice START END to lines-while, and captures
# only the status and var line-number from the subshel.
#
read_lines_while() # File-Path While-Eval [First-Line] [Last-Line]
{
  [[ "${1-}" ]] || error "Argument expected (1)" 1
  [[ -f "$1" ]] || error "Not a filename argument: '$1'" 1
  [[ "${2-}" && $# -le 4 ]] || return
  local stat=''

  read_lines_while_inner() # sh:no-stat
  {
    local r=0
    lines_slice "${3-}" "${4-}" "$1" | {
        lines_count_while_eval "$2" || r=$? ; echo "$r $line_number"; }
  }
  stat="$(read_lines_while_inner "$@")"
  [[ "$stat" ]] || return
  line_number=$(echo "$stat" | cut -f2 -d' ')
  return "$(echo "$stat" | cut -f1 -d' ')"
}

# Read data without collapsing spaces or obeying '\' escapes, but as-is.
read_literal () # (s) ~ <Read-argv...> # Read as-is, with escapes and whitespace intact
{
  IFS= read -r "$@"
}

# Read file filtering octothorp comments, like this one, and empty lines
# XXX: this one support leading whitespace but others in ~/bin/*.sh do not
read_nix_style_file () # [cat_f=] ~ File [Grep-Filter]
{
  [[ $# -le 2 && "${1:-"-"}" = - || -e "${1-}" ]] || return 98
  [[ "${1-}" ]] || set -- "-" "${2-}"
  [[ "${2-}" ]] || set -- "$1" '^\s*(#.*|\s*)$'
  [[ -z "${cat_f-}" ]] && {
    grep -Ev "$2" "$1" || return $?
  } || {
    #shellcheck disable=2086
    cat $cat_f "$1" | grep -Ev "$2"
  }
}
# Sh-Copy: HT:tools/u-s/parts/sh-read.inc.sh

# Continue reading, passing each line at stdin to Cmd until it returns non-zero
# Returns read error (1 for EOF or others) or 0 on first non-zero command exec.
read_while () # ~ <Cmd <argv...>>
{
  while true
  do
    ${read:-read -r} line || return
    echo "$line" | "$@" || return 0
    ! ${echo:-false} || echo "$line"
  done
}

read_with_flags ()
{
  #shellcheck disable=2162
  read "${read_f--r}"
}

realpaths ()
{
  act=realpath p="" s="" foreach_do "$@"
}

# Sort into lookup table (with Awk) to remove duplicate lines.
# Removes duplicate lines (unlike uniq -u) without sorting.
remove_dupes () # ~ <Awk-argv...>
{
  awk '!a[$0]++' "$@"
}

# Same as remove-dupes but strip comments/preproc-lines
remove_dupes_nix () # ~ <Awk-argv...>
{
  awk '( substr($1,1,1) != "#" && !a[$0]++ )' "$@"
}

remove_dupes_nix_data_bycol () # ~ <Colnr> <Awk-argv>
{
  awk -F "${AWK_FS:-${IFS:-$' \t\n'}}" \
    '( substr($1,1,1) != "#" || !a[$'"${1:-1}"']++ )' \
    "${@:2}"
}

remove_dupes_nix_data_bycol_rev () # ~ <Colnr> <Awk-argv>
{
  tac | remove_dupes_nix_data_bycol "$@" | tac
}

# Same as remove-dupes but leave comments/preproc-lines alone.
remove_dupes_nix_data () # ~ <Awk-argv...>
{
  awk '( substr($1,1,1) == "#" || !a[$0]++ )' "$@"
}

# Sort paths by mtime. Uses foreach-addcol to add mtime column, sort on and then
# remove again. Listing most-recent modified file name/path first.
sort_mtimes ()
{
  act=filemtime foreach_addcol "$@" | sort -r -k 2 | cut -f 1
}

os_argc () # ~ <Expected> <Actual> ...
{
  : source "os.lib.sh"
  [[ $2 -eq $1 ]] || {
    [[ $2 -eq 0 ]] && return ${_E_MA:?} || return ${_E_GAE:?}
  }
}

os_expandpath () # ~ <Arr> <Expr>
{
  local outname=${1:-os_paths} offset &&
  sys_exparr "$outname" "${2}" &&
  local -n __os_expp_arr=${outname} &&
  local -i i &&
  for i in "${!__os_expp_arr[@]}"
  do
    [[ -e ${__os_expp_arr[i]} ]] && continue
    unset "${outname}[$i]"
  done
}

# Go over basedirs given in array, and run find for each. Effectively listing
# paths on stdout.
# XXX: might want to tab-separate basedirs from subpaths on output, but in
# practice that is done easily enough in-line (and this array as temporary
# in-memory data).
os_find_bdarr () # ~ <Arr-name> <Find-args>
{
  local basedir
  local -n __os_fbdarr=${1:?}
  for basedir in "${__os_fbdarr[@]}"
  do
    : "${basedir%%\/}"
    find "${_}/" "${@:2}" || {
      local _stat=$?
      {
        ! "${VERBOSE:-false}" || ! "${DEBUG:-false}"
      } && return $_stat || {
        : "E$_stat:find:${*:2}"
        $LOG warn  "$lk" "Error reading results reading into '$1'" "$_" $_stat
      }
    }
  done
}

# Turn find search query into (array) list of pathnames. Verbosely if requested.
os_find_sarr () # ~ <Arr> <Find-expr>
{
  ! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
    local lk="${lk:-":Bash[$$]:os-find-sarr"}"
  if_ok "$(find "${@:2}")" &&
  test -n "$_" &&
  mapfile -t "${1:?Array name expected}" <<< "$_" && {
    ! "${VERBOSE:-false}" || ! "${DEBUG:-false}" || {
      local -n _arr=${1}
      $LOG debug "$lk" "Read ${#_arr[*]} results by find into array '$1'" "find:${*:2}"
    }
  } || { local _stat=$?
    {
      ! "${VERBOSE:-false}" || ! "${DEBUG:-false}"
    } && return $_stat || {
      : "E$_stat:find:${*:2}"
      $LOG warn  "$lk" "Error reading results reading into '$1'" "$_" $_stat
    }
  }
}

# XXX: see argv.lib test_ funs as well
# for (user log) verbose functions, see assert.lib

os_isblock () # ~ <Name>
{
  : source "os.lib.sh"
  : "${1:?test-isblock: Path name expected}"
  [[ -b "$_" ]]
}

os_ischar () # ~ <Name>
{
  : source "os.lib.sh"
  : "${1:?test-ischar: Path name expected}"
  [[ -c "$_" ]]
}

os_isdir () # ~ <Name>
{
  : source "os.lib.sh"
  : "${1:?test-isdir: Path name expected}"
  [[ -d "$_" ]]
}

os_isfile () # ~ <Name>
{
  : source "os.lib.sh"
  : "${1:?test-isfile: Path name expected}"
  [[ -f "$_" ]]
}

os_isnonempty () # ~ <Name>
{
  : source "os.lib.sh"
  : "${1:?test-isnonempty: Path name expected}"
  [[ -s "$_" ]]
}

# test -e (XXX: same as test -a?)
os_ispath () # ~ <Name>
{
  : source "os.lib.sh"
  : "${1:?test-ispath: Path name expected}"
  [[ -e "$_" ]]
}

os_dirs_exist () # ~ <Names...>
{
  : source "os.lib.sh"
  local _dir
  for _dir
  do [[ -d $_dir ]] || return
  done
}

os_lookup_add () # ~ <Var> <Prepend> <Append>
{
  : source "os.lib.sh"
  [ -e "${2}" -o -e "${3-}" ] || {
    >&2 echo "os_path_add: No such file or directory '$*'"
    return 1
  }
  local -n __path=${1?}
  [ -n "${2-}" ] && {
    case "$__path" in
      $2:* | *:$2 | *:$2:* ) ;;
      * ) __path=$2${__path:+:}$__path ;;
    esac
  } || {
    [ -n "${3:?}" ] && {
      case "$__path" in
        $3:* | *:$3 | *:$3:* ) ;;
        * ) __path=$__path${__path:+:}}$3 ;;
      esac
    }
  }
}

# TODO: cleanup add-env-path
os_path_add () # ~ <Prepend-Value> <Append-Value>
{
  : source "os.lib.sh"
  [ $# -ge 1 ] && [ -n "$1" ] || [ -n "${2-}" ] || return 64
  [ -e "$1" ] || [ -e "${2-}" ] || {
    >&2 echo "os_path_add: No such file or directory '$*'"
    return ${_E_no_path:-120}
  }
  [ -n "${1:-}" ] && {
    case "$PATH" in
      $1:* | *:$1 | *:$1:* ) ;;
      * ) eval PATH=$1:$PATH ;;
    esac
  } || {
    [ -n "${2:?}" ] && {
      case "$PATH" in
        $2:* | *:$2 | *:$2:* ) ;;
        * ) eval PATH=$PATH:$2 ;;
      esac
    }
  }
}

os_lookuppaths () # ~ <Path-var> <Result-var> <Paths...>
{
  : source "os.lib.sh"
  : description "Read PATH-type variable into Bash array"
  : "${1:?"os-lookuppaths: Expected variable reference"}"
  : "${2:?"os-lookuppaths: Expected variable reference"}"

  local -n __out=${2:?}
  sys_is_arr "$1" && local -n __arr=$1 || {
    local -n __ref=$1 __arr=${1}_arr
    : "${__ref-}"
    <<< "${_//:/$'\n'}" mapfile -t ${1}_arr || return
  }
  shift 2
  : "${*:?"os-lookuppaths: Expected paths"}"
  local path __path __r
  for path
  do
    for __path in "${__arr[@]}"
    do
      if ${os_lookuppaths_expand:-false}
      then
        for __r in $(eval "echo \"$__path/\"$path")
        do
          [[ -e "$__r" ]] || continue
          __out+=( "$__r" )
        done
      else
        [[ -e "$__path/$path" ]] || continue
        __out+=( "$__path/$path" )
      fi
    done
  done
}

os_pathvar () # ~ <Path-var> [<Arr-var>]
{
  : source "os.lib.sh"
  : description "XXX: copy PATH-type value to Bash array"
  : "${1:?"os-pathvar: Expected variable reference"}"
  local __os_path_out=${2:-${1}_arr}
  sys_is_arr "$1" && {
    declare -gn ${__os_path_out}=${1}
  } || {
    local -n __ref=$1 __arr=${__os_path_out}
    : "${__ref-}"
    <<< "${_//:/$'\n'}" mapfile -t ${__os_path_out}
  }
}

# alias foreach-pathseq?
os_pathcb () # ~ <Path-var> <Cmd...>
{
  : source "os.lib.sh"
  : "${1:?"os-pathcb: Expected variable reference"}"
  : "${2:?"os-pathcb: Expected command"}"
  sys_is_arr "$1" && local -n __arr=$1 || {
    local -n __ref=$1 __arr=${1}_arr
    : "${__ref-}"
    <<< "${_//:/$'\n'}" mapfile -t ${1}_arr
  }
  local __path
  for __path in "${__arr[@]}"
  do
    "${@:2}" "${__path:?}" || return
  done
}

os_sourceif () # ~ <Name> # Source if non-empty
{
  : source "os.lib.sh"
  [[ -s "${1:?}" ]] || return 0
  . "${1:?}"
}

unique_args () # ~ <Args...>
{
  declare -A tab
  declare arg
  for arg
  do [[ "${tab[$arg]+set}" ]] || {
      tab[$arg]=
      echo "$arg"
    }
  done
}

# Ziplists on lines from files. XXX: Each file should be same length.
zipfiles ()
{
  rows="$(count_lines "$1")" &&
  { for file ; do
      cat "$file"
      #truncate_lines "$file" "$rows"
    done
  } | ziplists "$rows"
}

# Turn lists into columns, using shell vars.
ziplists () # [SEP=\t] Rows
{
  local col=0 row=0
  [[ "$SEP" ]] || SEP='\t'
  while true
  do
    col=$(( col + 1 )) ;
    for row in $(seq 1 "$1") ; do
      read -r "row${row}_col${col}" || break 2
    done
  done
  col=$(( col - 1 ))

  for r in $(seq 1 "$1")
  do
    for c in $(seq 1 "$col")
    do
      eval "printf \"%s\" \"\$row${r}_col${c}\""
      #shellcheck disable=2059
      [[ "$c" -lt "$col" ]] && printf "$SEP" || printf '\n'
    done
  done
}

#
