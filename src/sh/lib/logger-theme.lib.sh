#!/bin/sh

logger_theme_lib_load()
{
  case $TERM in

    *256color )
        LOG_TERM=256
        ncolors=$(tput colors)
      ;;

    xterm* | ansi | linux )
        LOG_TERM=16
        ncolors=$(tput -T xterm colors)
      ;;

    screen )
        LOG_TERM=16
        ncolors=$(tput colors)
      ;;

    dumb | '' )
        LOG_TERM=bw
      ;;

    * )
        LOG_TERM=bw
        # XXX: echo "[std.sh] Other term: '$TERM'" >&2
      ;;

  esac

  if test -n "$ncolors" && test $ncolors -ge 8; then

    normal="$(tput sgr0)"
    norm=$normal
    bold="$(tput bold)"
    bld=$bold
    underline="$(tput smul)"
    standout="$(tput smso)"

    if test $ncolors -ge 256; then
      blackb="\033[0;90m"
      #grey="\e[0;37m"
      purple="\033[38;5;135m"
      blue="\033[38;5;27m"
      red="\033[38;5;196m"
      darkyellow="\033[38;5;208m"
      yellow="\033[38;5;220m"
      #normal="\033[0m"

      test "$CS" = 'dark' && {
        default="\033[38;5;254m"
        bdefault="\033[38;5;231m"
        grey="\033[38;5;244m"
        darkgrey="\033[38;5;238m"
        drgrey="\033[38;5;232m"
      }
      test "$CS" = 'light' && {
        default="\033[38;5;240m"
        bdefault="\033[38;5;232m"
        grey="\033[38;5;245m"
        darkgrey="\033[38;5;250m"
        drgrey="\033[38;5;255m"
      }

      grn="$(tput setaf 2)"

    else


      black="$(tput setaf 0)"
      #blackb="$(tput setab 0)"
      red="$(tput setaf 1)"
      grn="$(tput setaf 2)"
      yellow="$(tput setaf 3)"
      blue="$(tput setaf 4)"
      purple="$(tput setaf 5)" # magenta
      cyan="$(tput setaf 6)"
      default="$(tput setaf 7)"
      grey="${default}"
      darkgrey=
      drgrey=
      bdefault="${bold}${default}"
    fi
  fi
}
