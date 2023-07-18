#!/bin/sh

# TODO /etc/localtime

date_lib__load()
{
  export TODAY=+%y%m%d0000

  # Age in seconds
  export _1MIN=60
  export _2MIN=120
  export _3MIN=180
  export _4MIN=240
  export _5MIN=300
  export _10MIN=600
  export _15MIN=900
  export _20MIN=1200
  export _30MIN=1800
  export _45MIN=2700

  export _1HOUR=3600
  export _3HOUR=10800
  export _6HOUR=64800

  export _1DAY=86400
  export _1WEEK=604800

  # Note: what are the proper lengths for month and year? It does not matter that
  # much if below is only used for fmtdate-relative.
  export _1MONTH=$(( 31 * $_1DAY ))
  export _1MONTH2=$(( 4 * $_1WEEK ))
  export _3MONTH=$(( 3 * 4 * $_1WEEK ))
  export _6MONTH=$(( 6 * 4 * $_1WEEK ))
  export _9MONTH=$(( 9 * 4 * $_1WEEK ))
  export _1YEAR=$(( 365 * $_1DAY ))

  datefmt_suffix=
}


date_lib__init()
{
  test "${date_lib_init-}" = "0" && return
  # XXX: test -z "${date_lib_init:-}" || return ${date_lib_init:-}

  test -n "${gdate-}" || case "$uname" in
    Darwin ) gdate="gdate" ;;
    Linux ) gdate="date" ;;
    * ) $LOG error "" uname "$uname" 1 ; return 1 ;;
  esac

  TZ_OFF_1=$($gdate -d '1 Jan' +%z)
  TZ_OFF_7=$($gdate -d '1 Jul' +%z)
  TZ_OFF_NOW=$($gdate +%z)

  test \( $TZ_OFF_NOW -gt $TZ_OFF_1 -a $TZ_OFF_NOW -gt $TZ_OFF_7 \) &&
    IS_DST=1 || IS_DST=0

  export gdate

  # FIXME:
  #local us_log=; req_init_log || return
  #$us_log info "" "Loaded date.lib" "$0"
  $LOG info "" "Loaded date.lib" "$0"
}


# newer-than FILE SECONDS, filemtime must be greater-than Now - SECONDS
newer_than() # FILE SECONDS
{
  test -n "${1-}" || error "newer-than expected path" 1
  test -e "$1" || error "newer-than expected existing path" 1
  test -n "${2-}" || error "newer-than expected delta seconds argument" 1
  test -z "${3-}" || error "newer-than surplus arguments" 1

  #fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(date_epochsec "$2") -lt $(filemtime "$1")
}

# older-than FILE SECONDS, filemtime must be less-than Now - SECONDS
older_than ()
{
  test -n "${1-}" || error "older-than expected path" 1
  test -e "$1" || error "older-than expected existing path" 1
  test -n "${2-}" || error "older-than expected delta seconds argument" 1
  test -z "${3-}" || error "older-than surplus arguments" 1
  #fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(date_epochsec "$2") -gt $(filemtime "$1")
}

date_ts()
{
  date +%s
}

# XXX: cleanup Time-Fmt arg
date_epochsec () # File | -Delta-Seconds | @Timestamp | Time-Fmt
{
  test $# -eq 1 || return 64
  test -e "$1" && {
      filemtime "$1"
      return $?
    } || {

      fnmatch "-*" "$1" && {
        echo "$(date_ts) $1" | bc
        return $?
      }

      fnmatch "@*" "$1" && {
        echo "$1" | cut -c2-
        return $?
      } || {
        date_fmt "$1" "%s"
        return $?
      }
    }
  return 1
}

date_fmt() # Date-Ref Str-Time-Fmt
{
  test $# -eq 2 || return 98
  test -z "$1" && {
    tags="today"
  } || {
    # NOTE patching for GNU date
    test -e "$1" && tags="@$(filemtime "$1")" ||
        tags=$( echo "$1" | bsd_date_tag ) # XXX: date-htd.lib
  }
  $gdate ${date_flags:-} -d "$tags" +"$2"
}

date_()
{
  test -n "${1-}" && {
    test -e "$1" && set -- -r "$1" "$2" || set -- -d "$1" "$2"
  }
  $gdate "$@"
}

# Compare date, timestamp or mtime and return oldest as epochsec (ie. lowest val)
date_oldest() # ( FILE | DTSTR | @TS ) ( FILE | DTSTR | @TS )
{
  set -- "$(date_epochsec "$1")" "$(date_epochsec "$2")"
  test $1 -gt $2 && echo $2
  test $1 -lt $2 && echo $1
}

# Compare date, timestamp or mtime and return newest as epochsec (ie. highest val)
date_newest() # ( FILE | DTSTR | @TS ) ( FILE | DTSTR | @TS )
{
  set -- "$(date_epochsec "$1")" "$(date_epochsec "$2")"
  test $1 -lt $2 && echo $2
  test $1 -gt $2 && echo $1
}

# given timestamp, display a friendly human readable time-delta:
# X sec/min/hr/days/weeks/months/years ago
fmtdate_relative() # [ Previous-Timestamp | ""] [Delta] [suffix=" ago"]
{
  test $# -le 3 || return
  test -n "${1-}" && {
    # Calculate delta based on now
    test -n "${2-}" || set -- "$1" "$(( $(date +%s) - $1 ))" "${3-}"
  } || {
    # FIXME:
    test -n "${2-}" || return
    test -n "$2" || set -- "$(( $(date +%s) - $2 ))" "$2" "${3-}"
  }
    # Set default suffix
  test -n "${3-}" -o -z "${datefmt_suffix-}" || set -- "$1" "$2" "$datefmt_suffix"
  test $# -eq 3 || set -- "$1" "$2" " ago"

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
  test -n "${1-}" || set -- "@$(date_ts)"
  test -e "$1" && {
    $gdate -r "$1" +"%y%m%d%H%M.%S"
    return
  } || {
    $gdate -d "$1" +"%y%m%d%H%M.%S"
  }
}

# Copy mtime from file or set to DATESTR or @TIMESTAMP
touch_ts () # ~ ( DATESTR | TIMESTAMP | FILE ) FILE
{
  test $# -eq 2 -a -n "${1-}" -a -n "${2-}" || return 64

  touch -t "$(timestamp2touch "$1")" "$2"
}

date_iso() # Ts [date|hours|minutes|seconds|ns]
{
  test -n "${2-}" || set -- "${1-}" date
  test -n "$1" && {
    $gdate -d @$1 --iso-8601=$2 || return $?
  } || {
    $gdate --iso-8601=$2 || return $?
  }
}

# Print fractional seconds since Unix epoch
epoch_microtime () # [Date-Ref=now]
{
  date_ "${1-"now"}" +"%s.%N"
}

date_microtime ()
{
  date_ "${1-"now"}" +"%Y-%m-%d %H:%M:%S.%N"
}

sec_nomicro ()
{
  fnmatch "*.*" "$1" && {
      echo "$1" | cut -d'.' -f1
  } || echo "$1"
}

#
