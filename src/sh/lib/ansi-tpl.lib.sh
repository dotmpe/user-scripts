#!/bin/sh

### Colored and styled prompt, terminal escape codes

ansi_tpl_lib_load ()
{
  # Ask terminal about possible colors if we can
  test "${TERM:-dumb}" = "dumb" &&
    true "${ncolors:=0}" || true ${ncolors:=$(tput colors)}

  # Load term-part to set this to more sensible default
  true "${COLORIZE:=$(test $ncolors -gt 0 && printf 1 || printf 0)}"

  test -n "${CS-}" || CS=dark

  test $COLORIZE -eq 1 || ansi_tpl_env_def
}

ansi_tpl_env_def ()
{
  # XXX: not in dash
  declare -g \
    _f0= BLACK=   _b0= BG_BLACK= \
    _f1= RED=     _b1= BG_RED= \
    _f2= GREEN=   _b2= BG_GREEN= \
    _f3= YELLOW=  _b3= BG_YELLOW= \
    _f4= BLUE=    _b4= BG_BLUE= \
    _f5= CYAN=    _b5= BG_CYAN= \
    _f6= MAGENTA= _b6= BG_MAGENTA= \
    _f7= WHITE=   _b7= BG_WHITE= \
    BOLD= REVERSE= NORMAL=

  ${INIT_LOG:?} debug ":ansi:tpl" "Defaulted markup to none" "TERM:$TERM ncolors:$ncolors" 7
}

ansi_tpl_lib_init ()
{
  test ${COLORIZE:-1} -eq 1 || {
    # Declare empty if required (if not found yet)
    declare -p _f0 >/dev/null 2>&1 || ansi_tpl_env_def
    return
  }

  local tset
  case "$TERM" in xterm | screen ) ;; ( * ) false ;; esac && tset=set ||
  case "$TERM" in xterm-256color | screen-256color ) ;; ( * ) false ;; esac &&
  case ${ncolors:-0} in
    (   8 ) tset=set ;;
    ( 256 ) tset=seta ;;
    (   * ) bash_env_exists _f0 || ansi_tpl_env_def; return ;;
  esac || {
    # If no color support found, simply set vars and return zero-status.
    # Maybe want to fail trying to init ANSI.lib later...
    #bash_env_exists _f0 || ansi_tpl_env_def; return;
    declare -p _f0 >/dev/null 2>&1 || ansi_tpl_env_def; return;
  }

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
}

ansi_tpl_aliases ()
{
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
}

ansi_tpl_less ()
{
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

# Id: Us:
# Derive: U-c:ansi-uc.lib.sh
