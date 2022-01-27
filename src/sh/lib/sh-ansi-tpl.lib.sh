#!/bin/sh

### Colored and styled prompt, terminal escape codes

sh_ansi_tpl_lib_load()
{
  test -n "${COLORIZE-}" || COLORIZE=1
  test -n "${CS-}" || CS=dark
  #force_color_prompt=yes

  if test "$COLORIZE" = "1"
  then
    CYAN="\[\033[1;36m\]"
    YELLOW="\[\033[1;33m\]"
    GREEN="\[\033[1;32m\]"
    BLUE="\[\033[1;34m\]"
    RED="\[\033[1;31m\]"
    BWHITE="\[\033[1;37m\]"
    if [ "$CS" = "dark" ]
    then
      NORMAL="\[\033[0;37m\]"
      SEP="\[\033[1;38m\]"
    else
      NORMAL="\[\033[0;38m\]"
      SEP="\[\033[1;30m\]"
    fi
  else
    CYAN=
    YELLOW=
    GREEN=
    BLUE=
    NORMAL=
    BWHITE=
    SEP=
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
