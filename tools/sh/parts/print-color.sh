#!/bin/sh

case "${TERM:-"dumb"}" in

  dumb ) ;;
      c_normal=
      c_black=
      c_red=
      c_green=
      c_yellow=
      #c_blue=
      #c_purple=
      c_bold=
      c_default=

  * )
      c_normal="$(tput sgr0)"
      c_black="$(tput setaf 0)"
      c_red="$(tput setaf 1)"
      c_green="$(tput setaf 2)"
      c_yellow="$(tput setaf 3)"
      #c_blue="$(tput setaf 4)"
      #c_purple="$(tput setaf 5)" # magenta
      c_bold="$(tput bold)"
      c_default="$(tput setaf 7)"
    ;;

esac

print_red() # Key Msg
{
  test $# -eq 2 || return 98
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_red" "$c_default" "$1" "$c_red" "$c_default" "$2" "$c_normal"
}

print_yellow() # Key Msg
{
  test $# -eq 2 || return 98
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_yellow" "$c_default" "$1" "$c_yellow" "$c_default" "$2" "$c_normal"
}

print_green() # Key Msg
{
  test $# -eq 2 || return 98
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_green" "$c_default" "$1" "$c_green" "$c_default" "$2" "$c_normal"
}
