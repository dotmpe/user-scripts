#!/bin/sh

## OS - system toolkit/programs, files, paths.


os_lib__load ()
{
  : "${uname:="$(uname -s)"}"
}

os_lib__init ()
{
  test "${os_lib_init-}" = "0" || {
    test -n "$LOG" -a \( -x "$LOG" -o "$(type -t "$LOG")" = "function" \) \
      && os_lib_log="$LOG" || os_lib_log="$INIT_LOG"
    test -n "$os_lib_log" || return 108
    $os_lib_log debug "" "Initialized os.lib" "$0"
  }
}


absdir ()
{
  # NOTE: somehow my Linux pwd makes a symbolic path to root into //bin,
  # using tr to collapse all sequences to one
  ( cd "$1" && pwd -P | tr -s '/' '/' )
}

# A simple, useful wrapper for awk prints entire line, one column or other
# AWK print value if AWK expression evaluates true.
awk_line_select () # (s) ~ <Awk-If-Expr> [<Out>]
{
  awk '{ if ( '"${1:?"An expression is required"}"' ) { print '"${2:-"\$0"}"' } }'
}

# Cumulative dirname, return the root directory of the path
# XXX: make basedirs, cons w cwd-lookup-path
basedir ()
{
  # Recursively. FIXME: a string op. may be faster
  while fnmatch "*/*" "$1"
  do
    set -- "$(dirname "$1")"
    test "$1" != "/" || break
  done
  echo "$1"
}

# [exts=] basenames [ .EXTS ] PATH...
# Get basename(s) for all given exts of each path. The first argument is handled
# dynamically. Unless exts env is provided, if first argument is not an existing
# and starts with a period '.' it is used as the value for exts.
basenames () # [exts=] ~ [ .EXTS ] PATH...
{
  test -n "${exts-}" || {
    fnmatch ".*" "$1" || return
    exts="$1"; shift
  }
  while test $# -gt 0
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
  test "${1:-"-"}" = "-" && {
    wc -w | awk '{print $1}'
    return
  } || {
    while test $# -gt 0
    do
      wc -c "$1" | awk '{print $1}'
      shift
    done
  }
}

# Count tab-separated columns on first line. One line for each file.
count_cols ()
{
  test $# -gt 0 && {
    while test $# -gt 0
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
  test "${1-"-"}" = "-" && {
    wc -l | awk '{print $1}'
    return
  } || {
    while test $# -gt 0
    do
      wc -l "$1" | awk '{print $1}'
      shift
    done
  }
}

# Count words
count_words () # [FILE | -]...
{
  test "${1:-"-"}" = "-" && {
    wc -w | awk '{print $1}'
    return
  } || {
    while test $# -gt 0
    do
      wc -w "$1" | awk '{print $1}'
      shift
    done
  }
}

dirname_ ()
{
  while test "$1" -gt 0
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

# Perform action for first path from inputs that passes test.
os_do_exists () # ~ <Test> <Action=echo> <Paths...>
{
  local test_ test=${1:?} act=${2:-echo}
  shift 2
  test "${test:0:1}" = '!' && test_='test ! -'${test:1} ||
    test "${#test}" = '1' &&
      test_='test -'${test} || test_=$test
  while test $# -gt 0
  do
    $test_ "${1:?}" && break
    shift; continue
  done
  test $# -gt 0 || return
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
  test -s "${1:?}" || return
  action="cp -v" file_number "${@:?}"
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
    test -e "$dest" || break
    cnt=$(( cnt + 1 ))
  done

  local action="${action:-echo}"
  $action "$1" "$dest"
}

# rename to numbered file, see number-file
file_rotate () # ~ <Name> [<.Ext>]
{
  test -s "${1:?}" || return
  action="mv -v" file_number "${@:?}"
}

# FIXME: file-deref=0?
file_stat_flags()
{
  test -n "$flags" || flags=-
  test "${file_deref:-0}" -eq 0 || flags=${flags}L
  test "$flags" != "-" || flags=
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
  while test $# -gt 0
  do
    case "${uname,,}" in
      darwin )
          stat -L -f '%c' "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          stat -L -c '%Z' "$1" || return 1
        ;;
      * ) $os_lib_log error "os" "filectime: $uname?" "" 1 ;;
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
  test -n "$*" || return
  test -n "$ext" || return
  for mext in "$@"
  do test ".$ext" = "$mext" && return 0
  done
  return 1
}

# Use `stat` to get modification time (in epoch seconds)
filemtime() # File
{
  local flags=- ; file_stat_flags
  while test $# -gt 0
  do
    case "${uname,,}" in
      darwin )
          "${file_names:-false}" && pat='%N %m' || pat='%m'
          stat -f "$pat" $flags "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          "${file_names:-false}" && pat='%N %Y' || pat='%Y'
          stat -c "$pat" $flags "$1" || return 1
        ;;
      * ) $os_lib_log error "os" "filemtime: $uname?" "" 1 ;;
    esac; shift
  done
}

# Use `file` to get mediatype aka. MIME-type
filemtype () # File..
{
  local flags= ; file_tool_flags
  case "${uname,,}" in
    darwin )
        file -"${flags}"I "$1" || return 1
      ;;
    linux )
        file -"${flags}"i "$1" || return 1
      ;;
    * ) error "filemtype: $uname?" 1 ;;
  esac
}

filename_baseid () # ~ <Path-Name>
{
  basename="$(filestripext "$1")"
  mkid "$basename" '' '_'
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
  local flags=- ; file_stat_flags
  while test $# -gt 0
  do
    case "${uname,,}" in
      darwin )
          stat -L -f '%z' "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          stat -L -c '%s' "$1" || return 1
        ;;
      * ) $os_lib_log error "os" "filesize: $uname?" "" 1 ;;
    esac; shift
  done
}

# Return basename for one file, using filenamext to extract extension.
# See basenames for multiple args, and pathname to preserve (relative) directory
# elements for name.
filestripext () # ~ <Name>
{
  ext="$(filenamext "$1")"
  test -n "$ext" && set -- "$1" ".$ext"
  basename -- "$@"
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

# Go over arguments and echo. If no arguments given, or on argument '-' the
# standard input is cat instead or in-place respectively. Strips empty lines.
# (Does not open filenames and read from files). Multiple '-' arguments are
# an error, as the input is not buffered and rewounded. This simple setup
# allows to use arguments as stdin, insert arguments-as-lines before or after
# stdin, and the pipeline consumer is free to proceed.
#
# If this routine is given no data is hangs indefinitely. It does not have
# indicators for data availble at stdin.
foreach () # [(s)] ~ ['-' | <Arg...>]
{
  {
    test -n "$*" && {
      while test $# -gt 0
      do
        test "$1" = "-" && {
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

# Extend rows by mapping each value line using act, add result tab-separated
# to line. See foreach-do for other details.
foreach_addcol () # ~ [ - | <Arg...> ]
{
  test -n "${p-}" || local p= # Prefix string
  test -n "${s-}" || local s= # Suffix string
  test "${act-unset}" != unset || local act="echo"
  foreach "$@" | while read -r _S
    do S="$p$_S$s" && printf -- '%s\t%s\n' "$S" "$($act "$S")" ; done
}
# Var: F:foreach-addcol.bash

# Read `foreach` lines and act, default is echo ie. same result as `foreach`
# but with p(refix) and s(uffix) wrapped around each item produced. The
# unwrapped loop-var is _S.
foreach_do () # ~ [ - | <Arg...> ]
{
  test -n "${p-}" || local p= # Prefix string
  test -n "${s-}" || local s= # Suffix string
  test -n "${act-}" || local act="echo"
  foreach "$@" | while read -r _S ; do S="$p$_S$s" && $act "$S" ; done
}

foreach_eval ()
{
  test -n "${p-}" || local p= # Prefix string
  test -n "${s-}" || local s= # Suffix string
  test -n "${act-}" || local act="echo"
  foreach "$@" | while read -r _S ; do S="$p$_S$s" && eval "$act \"$S\"" ; done
}

# See -addcol and -do.
foreach_inscol ()
{
  test -n "${p-}" || local p= # Prefix string
  test -n "${s-}" || local s= # Suffix string
  test -n "${act-}" || local act="echo"
  foreach "$@" | while read -r _S
    do S="$p$_S$s" && printf -- '%s\t%s\n' "$($act "$S")" "$S" ; done
}

get_uuid ()
{
  test -e /proc/sys/kernel/random/uuid && {
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
  test -n "$1" || error "go-to-dir: Missing filename arg" 1

  # Find dir with metafile
  go_to_before=.
  while true
  do
    test -e "$1" && break
    go_to_before=$(basename -- "$(pwd)")/$go_to_before
    test "$(pwd)" = "/" && break
    cd ..
  done

  test -e "$1" || return 1
}

# An (almost) no-op that does pass previous status back, usable as an
# alternative to 'true' (or ':') for use to store a value as last argument ('$_').
# If such value comes from an invocation, its status will always be masked with
# 0 by 'true'. Alternatively 'test -{n,z}' would be usable e.g. for commands
# that do not return any non-zero status on failures, but otherwise it would
# override any status just the same (besides adding an extra assumption about
# the value).
if_ok () # (?) ~ <...> # No-op, but return previous status
{
  return
}

ignore_sigpipe () # (?) ~ <...> # Status OK if SIG:PIPE
{
  local r=$?
  test $r -eq 141 # For linux/bash: 128+signal where signal=SIGPIPE=13
}

# Little wrapper to use lines-while to read line-continuations to lines
lines () #
{
  read_f="" lines_count_while_eval echo "\$line"
}

# Wrap wc but correct files with or w.o. trailing posix line-end
line_count () # FILE
{
  test -s "${1-}" || return 42
  test "$(filesize "$1")" -gt 0 || return 43
  #shellcheck disable=2005,2046
  lc="$(echo $(od -An -tc -j "$(( $(filesize "$1") - 1 ))" "$1"))"
  case "$lc" in "\n" ) ;;
    "\r" ) error "POSIX line-end required" 1 ;;
    * ) printf '\n' >>"$1" ;;
  esac
  declare lc
  lc=$(wc -l "$1" | awk '{print $1}')
  echo "$lc"
}

# Offset content from input/file to line-based window.
lines_slice() # [First-Line] [Last-Line] [-|File-Path]
{
  test -n "${3-}" || error "File-Path expected" 1
  test "$3" = "-" && set -- "$1" "$2"
  test -n "$1" && {
    test -n "$2" && { # Start - End: tail + head
      tail -n "+$1" "$3" | head -n $(( $2 - $1 + 1 ))
      return $?
    } || { # Start - ... : tail
      tail -n "+$1" "$3"
      return $?
    }

  } || {
    test -n "$2" && { # ... - End : head
      head -n "$2" "$3"
      return $?
    } || { # Otherwise cat
      cat "$3"
    }
  }
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
  test $# -gt 0 || return

  line_number=0
  while ${read:-read_with_flags} line
  do
    eval "$*" || break
    line_number=$(( line_number + 1 ))
  done
  test $line_number -gt 0 || return
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
  test -n "$NORMALIZED" \
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

os_pids () # ~ <Cmd-name>
{
  ps -C "${1:?}" -o pid:1=
}

# Combined dirname/basename to remove .ext(s) but return path
pathname() # PATH EXT...
{
  local name="$1" dirname
  dirname=$(dirname -- "$1") || return
  fnmatch "./*" "$1" && dirname="$(echo "$dirname" | cut -c3-)"
  shift 1
  for ext in "$@"
  do
    name="$(basename -- "$name" "$ext")"
  done
  #shellcheck disable=2059
  test -n "$dirname" -a "$dirname" != "." && {
    printf -- "$dirname/$name\\n"
  } || {
    printf -- "$name\\n"
  }
}

# basepath: see pathname as alt. to basename for ext stripping

# Simple iterator over pathname
pathnames () # exts=... [ - | PATHS ]
{
  test -n "${exts-}" || exit 40
  #shellcheck disable=2086
  test "${1--}" != "-" && {
    for path in "$@"
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
    test $# -gt 2 && {
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
  test -n "${1-}" || return 1
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
  test -n "${1-}" || error "Argument expected (1)" 1
  test -f "$1" || error "Not a filename argument: '$1'" 1
  test -n "${2-}" -a $# -le 4 || return
  local stat=''

  read_lines_while_inner() # sh:no-stat
  {
    local r=0
    lines_slice "${3-}" "${4-}" "$1" | {
        lines_count_while_eval "$2" || r=$? ; echo "$r $line_number"; }
  }
  stat="$(read_lines_while_inner "$@")"
  test -n "$stat" || return
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
  test $# -le 2 -a "${1:-"-"}" = - -o -e "${1-}" || return 98
  test -n "${1-}" || set -- "-" "${2-}"
  test -n "${2-}" || set -- "$1" '^\s*(#.*|\s*)$'
  test -z "${cat_f-}" && {
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

# Ziplists on lines from files. XXX: Each file should be same length.
zipfiles ()
{
  rows="$(count_lines "$1")"
  { for file in "$@" ; do
      cat "$file"
      #truncate_lines "$file" "$rows"
    done
  } | ziplists "$rows"
}

# Turn lists into columns, using shell vars.
ziplists () # [SEP=\t] Rows
{
  local col=0 row=0
  test -n "$SEP" || SEP='\t'
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
      test "$c" -lt "$col" && printf "$SEP" || printf '\n'
    done
  done
}

#
