#!/bin/sh


date_lib_load()
{
  export TODAY=+%y%m%d0000

  # Age in seconds
  export _5MIN=300
  export _1HOUR=3600
  export _3HOUR=10800
  export _6HOUR=64800

  export _1DAY=86400
  export _1WEEK=604800

  # Note: what are the proper lengths for month and year? It does not matter that
  # much if below is only used for fmtdate-relative.
  export _1MONTH=$(( 4 * $_1WEEK ))
  export _1YEAR=$(( 365 * $_1DAY ))

  test -n "$uname" || uname="$(uname -s)"
  date_lib_init_bin
}


date_lib_init_bin()
{
  case "$uname" in
    Darwin ) gdate="gdate" ;;
    Linux ) gdate="date" ;;
  esac
  export gdate
}


# newer-than FILE SECONDS, filemtime must be greater-than Now - SECONDS
newer_than() # FILE SECONDS
{
  test -n "$1" || error "newer-than expected path" 1
  test -e "$1" || error "newer-than expected existing path" 1
  test -n "$2" || error "newer-than expected delta seconds argument" 1
  test -z "$3" || error "newer-than surplus arguments" 1
  test $(( $(date +%s) - $2 )) -lt $(filemtime "$1")
}

# older-than FILE SECONDS, filemtime must be less-than Now - SECONDS
older_than()
{
  test -n "$1" || error "older-than expected path" 1
  test -e "$1" || error "older-than expected existing path" 1
  test -n "$2" || error "older-than expected delta seconds argument" 1
  test -z "$3" || error "older-than surplus arguments" 1
  test $(( $(date +%s) - $2 )) -gt $(filemtime "$1")
}

# given timestamp, display a friendly human readable time-delta:
# X sec/min/hr/days/weeks/months/years ago
fmtdate_relative() # [ Previous-Timestamp | ""] [Delta] [suffix=" ago"]
{
    # Calculate delta based on now
  test -n "$2" || set -- "$1" "$(( $(date +%s) - $1 ))" "$3"
    # Set default suffix
  test -n "$3" -o -z "$datefmt_suffix" || set -- "$1" "$2" "$datefmt_suffix"
  test -n "$3" || set -- "$1" "$2" " ago"

  if test $2 -gt $_1YEAR
  then

    if test $2 -lt $(( $_1YEAR + $_1YEAR ))
    then
      printf -- "one year$3"
    else
      printf -- "$(( $2 / $_1YEAR )) years$3"
    fi
  else

    if test $2 -gt $_1MONTH
    then

      if test $2 -lt $(( $_1MONTH + $_1MONTH ))
      then
        printf -- "a month$3"
      else
        printf -- "$(( $2 / $_1MONTH )) months$3"
      fi
    else

      if test $2 -gt $_1WEEK
      then

        if test $2 -lt $(( $_1WEEK + $_1WEEK ))
        then
          printf -- "a week$3"
        else
          printf -- "$(( $2 / $_1WEEK )) weeks$3"
        fi
      else

        if test $2 -gt $_1DAY
        then

          if test $2 -lt $(( $_1DAY + $_1DAY ))
          then
            printf -- "a day$3"
          else
            printf -- "$(( $2 / $_1DAY )) days$3"
          fi
        else

          if test $2 -gt $_1HOUR
          then

            if test $2 -lt $(( $_1HOUR + $_1HOUR ))
            then
              printf -- "an hour$3"
            else
              printf -- "$(( $2 / $_1HOUR )) hours$3"
            fi
          else

            if test $2 -gt $_1MIN
            then

              if test $2 -lt $(( $_1MIN + $_1MIN ))
              then
                printf -- "a minute$3"
              else
                printf -- "$(( $2 / $_1MIN )) minutes$3"
              fi
            else

              printf -- "$2 seconds$3"

            fi
          fi
        fi
      fi
    fi
  fi
}

# Get stat datetime format, given file or datetime-string. Prepend @ for timestamps.
timestamp2touch() # [ FILE | DTSTR ]
{
  test -n "$1" || set -- "@$(date +%s)"
  test -e "$1" && {
    $gdate -r "$1" +"%y%m%d%H%M.%S"
  } || {
    $gdate -d "$1" +"%y%m%d%H%M.%S"
  }
}

# Copy mtime from file or set to DATESTR or @TIMESTAMP
touch_ts() # ( DATESTR | TIMESTAMP | FILE ) FILE
{
  test -n "$2" || set -- "$1" "$1"
  touch -t "$(timestamp2touch "$1")" "$2"
}
