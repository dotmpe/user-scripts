#!/bin/sh


# OS: files, paths

os_lib_load()
{
  test -n "$uname" || uname="$(uname -s)"
  test -n "$os" || os="$(uname -s | tr '[:upper:]' '[:lower:]')"

  test -n "$gsed" || case "$uname" in
      Linux ) gsed=sed ;; * ) gsed=gsed ;;
  esac
  test -n "$ggrep" || case "$uname" in
      Linux ) ggrep=grep ;; * ) ggrep=ggrep ;;
  esac
}


absdir()
{
  # NOTE: somehow my Linux pwd makes a symbolic path to root into //bin,
  # using tr to collapse all sequences to one
  ( cd "$1" && pwd -P | tr -s '/' '/' )
}

dirname_()
{
  while test $1 -gt 0
    do
      set -- $(( $1 - 1 ))
      set -- "$1" "$(dirname "$2")"
    done
  echo "$2"
}

# Combined dirname/basename to remove .ext(s) but return path
pathname() # PATH EXT...
{
  local name="$1" dirname="$(dirname "$1")"
  fnmatch "./*" "$1" && dirname="$(echo "$dirname" | cut -c3-)"
  shift 1
  for ext in $@
  do
    name="$(basename "$name" "$ext")"
  done
  test -n "$dirname" -a "$dirname" != "." && {
    printf -- "$dirname/$name\\n"
  } || {
    printf -- "$name\\n"
  }
}
# basepath: see pathname as alt. to basename for ext stripping

# Simple iterator over pathname
pathnames() # exts=... [ - | PATHS ]
{
  test -n "$exts" || exit 40
  test -n "$*" -a "$1" != "-" && {
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

realpaths()
{
  act=realpath p= s= foreach_do "$@"
}

# Cumulative dirname, return the root directory of the path
basedir()
{
  # Recursively. FIXME: a string op. may be faster
  while fnmatch "*/*" "$1"
  do
    set -- "$(dirname "$1")"
    test "$1" != "/" || break
  done
  echo "$1"
}

dotname() # Path [Ext-to-Strip]
{
  echo $(dirname "$1")/.$(basename "$1" "$2")
}

short()
{
  test -n "$1" || set -- "$(pwd)"
  # XXX maybe replace python script. Only replaces home
  $scriptpath/short-pwd.py -1 "$1"
}


# Use `stat` to get size in bytes
filesize() # File
{
  while test $# -gt 0
  do
    case "$uname" in
      Darwin )
          stat -L -f '%z' "$1" || return 1
        ;;
      Linux | CYGWIN_NT-6.1 )
          stat -L -c '%s' "$1" || return 1
        ;;
      * ) error "filesize: $1?" 1 ;;
    esac; shift
  done
}

# Use `stat` to get modification time (in epoch seconds)
filemtime() # File
{
  while test $# -gt 0
  do
    case "$uname" in
      Darwin )
          stat -L -f '%m' "$1" || return 1
        ;;
      Linux | CYGWIN_NT-6.1 )
          stat -L -c '%Y' "$1" || return 1
        ;;
      * ) error "filemtime: $1?" 1 ;;
    esac; shift
  done
}


normalize_relative()
{
  OIFS=$IFS
  IFS='/'
  local NORMALIZED

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
  trueish "$strip_trail" && echo "$NORMALIZED" || case "$1" in
    */ ) echo "$NORMALIZED/"
      ;;
    * ) echo "$NORMALIZED"
      ;;
  esac
}


# Read file filtering octothorp comments, like this one, and empty lines
# XXX: this one support leading whitespace but others in ~/bin/*.sh do not
read_nix_style_file() # [cat_f=] ~ File [Grep-Filter]
{
  test -n "$1" || return 1
  test -z "$2" || error "read-nix-style-file: surplus arguments '$2'" 1
  cat $cat_f "$1" | grep -Ev '^\s*(#.*|\s*)$' || return 1
}

read_nix_style_files()
{
  while test -n "$1"
  do
    read_nix_style_file $1
    shift
  done
}


count_lines()
{
  test -z "$1" -o "$1" = "-" && {
    wc -l | awk '{print $1}'
  } || {
    while test -n "$1"
    do
      wc -l $1 | awk '{print $1}'
      shift
    done
  }
}

get_uuid()
{
  test -e /proc/sys/kernel/random/uuid && {
    cat /proc/sys/kernel/random/uuid
    return 0
  }
  test -x $(which uuidgen) && {
    uuidgen
    return 0
  }
  error "FIXME uuid required" 1
  return 1
}
