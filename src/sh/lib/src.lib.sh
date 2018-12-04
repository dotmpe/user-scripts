#!/bin/sh


src_lib_load()
{
  test -n "$sentinel_comment" || sentinel_comment="#"
}


# Insert into file using `ed`. Accepts literal content as argument.
# file-insert-at 1:file-name[:line-number] 2:content
# file-insert-at 1:file-name 2:line-number 3:content
file_insert_at_spc=" ( FILE:LINE | ( FILE LINE ) ) INSERT "
file_insert_at()
{
  test -x "$(which ed)" || error "'ed' required" 1

  test -n "$*" || error "arguments required" 1

  local file_name= line_number=
  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -e "$file_name" || error "no file $file_name" 1
  test -n "$1" || error "content expected" 1
  echo "$1" | grep -q '^\.$' && {
    error "Illegal ed-command in input stream"
    return 1
  }

  # use ed-script to insert second file into first at line
  # Note: this loses trailing blank lines
  # XXX: should not have ed period command. Cannot sync this function, file-insert-at
  stderr info "Inserting at $file_name:$line_number"
  echo "${line_number}a
$1
.
w" | ed -s $file_name
}


# Replace one entire line using Sed.
file_replace_at() # ( FILE:LINE | ( FILE LINE ) ) INSERT
{
  test -n "$*" || error "arguments required" 1
  test -z "$4" || error "too many arguments" 1

  local file_name= line_number=

  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -e "$file_name" || error "no file $file_name" 1
  test -n "$line_number" || error "no line_number" 1
  test -n "$1" || error "nothing to insert" 1

  note "Removing line $file_name:$line_number"
  echo "${line_number}d
.
w" | ed $file_name >/dev/null

  file_insert_at $file_name:$(( $line_number - 1 )) "$1"
}


# Quietly get the first grep match' into where-line and parse out line number
file_where_grep() # 1:where-grep 2:file-path
{
  test -n "$1" || {
    error "where-grep arg required"
    return 1
  }
  test -e "$2" -o "$2" = "-" || {
    error "file-where-grep: file-path or input arg required '$2'"
    return 1
  }
  where_line="$(grep -n "$@" | head -n 1)"
  line_number=$(echo "$where_line" | sed 's/^\([0-9]*\):\(.*\)$/\1/')
}


# XXX: no escape for insert string
file_replace_at_sed()
{
  test -n "$*" || error "arguments required" 1

  local file_name= line_number=

  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -e "$file_name" || error "no file $file_name" 1
  test -n "$line_number" || error "no line_number" 1
  test -n "$1" || error "nothing to insert" 1

  sed $line_number's/.*/'$1'/' $file_name
}

get_lines()
{
  test -n "$*" || error "arguments required" 1

  local file_name= line_number=

  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -n "$1" || set -- 1

  tail -n +$line_number $file_name | head -n $1
}

# Return span of lines from Src, starting output at Start-Line and ending
# Span-Lines later, or at before End-Line.
#
#   Span-Lines = End-Line - Start-Line.
#
# If no end is given, then Src must a file and the end is set to the file
# length. Start is set to 0 if empty.
# TODO: cleanup and manage start-line, end-line, span-lines env code.
#
source_lines() # Src Start-Line End-Line [Span-Lines]
{
  test -f "$1" || return
  test -n "$2" && start_line=$2 || start_line=0
  test -n "$Span_Lines" || Span_Lines=$4
  test -n "$Span_Lines" || {
    end_line=$3
    test -n "$end_line" || end_line=$(count_lines "$1")
    Span_Lines=$(( $end_line - $start_line ))
  }
  tail -n +$start_line $1 | head -n $Span_Lines
}


source_line() # Src Start-Line
{
  source_lines "$1" "$2" "$(( $2 + 1 ))"
}


# Given a shell script line with a source command to a relative or absolute
# path (w/o shell vars or subshells), replace that line with the actual contents
# of the sourced file.
expand_source_line() # Src-File Line
{
  test -f "$1" || error "expand_source_line file '$1'" 1
  test -n "$2" || error "expand_source_line line" 1
  local srcfile="$(source_lines "$1" "$2" "" 1 | awk '{print $2}')"
  test -f "$srcfile" || error "src-file $*: '$srcfile'" 1
  expand_line "$@" "$srcfile" || return
  trueish "$keep_source" || rm $srcfile
  info "Replaced line with resolved src of '$srcfile'"
}


# See expandline, uses and removes 'srcfile' if requested
expand_srcline()
{
  test -f "$srcfile" || error "src-file $*: '$srcfile'" 1
  expand_line "$@" "$srcfile"
  trueish "$keep_source" || rm $srcfile
  info "Replaced line with resolved src of '$srcfile'"
}

