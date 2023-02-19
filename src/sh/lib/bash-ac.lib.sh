#!/bin/sh

## Bash Auto-completion

bash_ac_lib_load()
{
  # enable programmable completion features (you don't need to enable
  # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
  # sources /etc/bash.bashrc).
  if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
  fi

  if [ -x "$(command -v grunt)" ]
  then
  # Tab completion for Gruntfiles
    eval "$(grunt --completion=bash)"
  fi

  if [ "$(uname -s)" = "Darwin" ]
  then

    if [ -f $(brew --prefix)/etc/bash_completion ]; then
      #source $(brew --prefix)/share/bash-completion/bash_completion

      # Define functions, and source files from BASH_COMPLETION_DIR
      # Latter contains 195 files on my OSC-ML/Bash 4 env.
      source $(brew --prefix)/etc/bash_completion

    fi

    # Bash completion has been installed to:
    #BASH_COMPLETION_DIR=/usr/local/etc/bash_completion.d
    # There is also another dir with a few but same files:
    # $(brew --prefix)/share/bash-completion/completions

  fi
}
