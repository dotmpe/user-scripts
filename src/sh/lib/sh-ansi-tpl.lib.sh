#!/bin/sh

### Colored and styled prompt, terminal escape codes

sh_ansi_tpl_lib_load ()
{
  test -n "${ncolors-}" || ncolors=$(tput colors)

  # Load term-part to set this to more sensible default
  test -n "${COLORIZE-}" || COLORIZE=0

  test -n "${CS-}" || CS=dark

  test $COLORIZE -eq 1 || ansi_uc_env_def
}

sh_ansi_tpl_env_def ()
{
  declare \
    _f0= BLACK= _b0= BG_BLACK= \
    _f0= RED= _b0= BG_RED= \
    _f0= GREEN= _b0= BG_GREEN= \
    _f0= YELLOW= _b0= BG_YELLOW= \
    _f0= BLUE= _b0= BG_BLUE= \
    _f0= CYAN= _b0= BG_CYAN= \
    _f0= MAGENTA= _b0= BG_MAGENTA= \
    _f0= WHITE= _b0= BG_WHITE= \
    BOLD= REVERSE= NORMAL=
}

sh_ansi_tpl_lib_init ()
{
  local tset
  case ${ncolors:-0} in
    (   8 ) tset=set ;;
    ( 256 ) tset=seta ;;
    (   * ) bash_env_exists _f0 || ansi_uc_env_def; return ;;
  esac

  : ${_f0:=${BLACK:=$(tput ${tset}f 0)}}
  : ${_f1:=${RED:=$(tput ${tset}f 1)}}
  : ${_f2:=${GREEN:=$(tput ${tset}f 2)}}
  : ${_f3:=${YELLOW:=$(tput ${tset}f 3)}}
  : ${_f4:=${BLUE:=$(tput ${tset}f 4)}}
  : ${_f5:=${CYAN:=$(tput ${tset}f 5)}}
  : ${_f6:=${MAGENTA:=$(tput ${tset}f 6)}}
  : ${_f7:=${WHITE:=$(tput ${tset}f 7)}}

  : ${_b0:=${BG_BLACK:=$(tput ${tset}b 0)}}
  : ${_b1:=${BG_RED:=$(tput ${tset}b 1)}}
  : ${_b2:=${BG_GREEN:=$(tput ${tset}b 2)}}
  : ${_b3:=${BG_YELLOW:=$(tput ${tset}b 3)}}
  : ${_b4:=${BG_BLUE:=$(tput ${tset}b 4)}}
  : ${_b5:=${BG_CYAN:=$(tput ${tset}b 5)}}
  : ${_b6:=${BG_MAGENTA:=$(tput ${tset}b 6)}}
  : ${_b7:=${BG_WHITE:=$(tput ${tset}b 7)}}

  : ${REVERSE:=$(tput rev)}
  : ${BOLD:=$(tput bold)}
  : ${NORMAL:=$(tput sgr0)}
  if [ "$CS" = "dark" ]
  then
    NORMAL="\[\033[0;37m\]"
    SEP="\[\033[1;38m\]"
  else
    NORMAL="\[\033[0;38m\]"
    SEP="\[\033[1;30m\]"
  fi
  PSEP="$BWHITE:$NORMAL"
  ISEP="$SEP \d$NORMAL"
  TSEP="${SEP}T$NORMAL"
  AOSEP="$SEP<$NORMAL"
  APSEP="$SEP>$NORMAL"
  PAT="$SEP@$NORMAL"

  if test "$COLORIZE" = "1"
  then

    alias tree='tree -C'
    case "$uname" in
      darwin ) alias ls='ls -G'
        ;;
      linux ) alias ls='ls --color=auto'
          #alias dir='dir --color=auto'
          #alias vdir='vdir --color=auto'
        ;;
    esac
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
  fi

  ##LESS man page colors
  # Purple section titles and alinea leader IDs
  export LESS_TERMCAP_md=$'\E[01;35m'
  # Green keywords
  export LESS_TERMCAP_us=$'\E[01;32m'
  # Black on Yellow statusbar
  export LESS_TERMCAP_so=$'\E[00;43;30m'
  # Normal text
  export LESS_TERMCAP_me=$'\E[0m'
  export LESS_TERMCAP_ue=$'\E[0m'
  export LESS_TERMCAP_se=$'\E[0m'
  # Red?
  export LESS_TERMCAP_mb=$'\E[01;31m'
}
