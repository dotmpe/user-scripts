#!/usr/bin/env bash


## us:fail stop (interactive) or return (batch-mode) non-zero
#
# Run Command-Line and fail with non-zero status by exit or return, if
# command returned non-zero
# Allow some programs to recover (but not continue as is) based on (user or
# system) context.
#

us_fail () # ~ STATUS [...] -- COMMAND-LINE...
{
  test $# -ge 2 || return 64
  local status=$1
  shift 1

  # Reserve all arguments up until next '--'
  argv_is_seq "$1" && shift || {
    argv_more "$@" && shift $more_argc || return 64
  }

  "$@"

  test $? -eq 0 || {
    { std_batch_mode && us_error $status
    } && {
      exit $status
    }
    return $status
  }
}

## us:error make script handle error (non-zero return) codes and states or abort
#
# some or all codes may allow execution to continue, it is really hard to tell
# in a generic way. XXX: see us_uc_env_def
#
# FIXME: this should really be compiled / (re-)evaluated based on context
us_error () # ~ LEVEL
{
  test $# -gt 0 || return

  # XXX: maybe do a mask on the value first, then decide how to further test.
  # iso. a giant case/esac, of which we obviously can't have one definite
  # version.

  case "$1" in

    # Conventional use in Linux

    1 )   $UC_E_GE ;; # Generic errror
    2 )   $UC_E_SH ;; # Misuse of Shell built-in
    126 ) $UC_E_CE ;; # Cannot execute
    127 ) $UC_E_CN ;; # Command not found
    128 ) $UC_E_IAE ;; # Invalid argument to exit

    # This is a mixed POSIX/ANSI/BSD signal list

    129 ) $UC_E_HUP     ;; # Signal 1. HUP        "Hang Up"
    130 ) $UC_E_INT     ;; #        2. INT        Interrupt or break
    131 ) $UC_E_QUIT    ;; #        3. QUIT       Dump core
    132 ) $UC_E_ILL     ;; #        4. ILL        "Illegal instruction"
    133 ) $UC_E_TRAP    ;; #        5. TRAP       Trace trap
    134 ) $UC_E_ABRT &&    #        6. ABRT
          $UC_E_IOT     ;; #           IOT        I/O trap, synonym for ABRT
    135 ) $UC_E_BUS     ;; #        7. BUS        (memory errors not possible on Linux)
    136 ) $UC_E_FPE     ;; #        8. FPE        Floating Point Exception
    137 ) $UC_E_KILL    ;; #        9. KILL       Terminate process (cannot be handled)
    138 ) $UC_E_USR1    ;; #       10. USR1       Custom user handling 1 / 2
    139 ) $UC_E_SEGV    ;; #       11. SEGV       Segmentation violation "Seg fault"
    140 ) $UC_E_USER2   ;; #       12. USER2      Custom user handling 2 / 2
    141 ) $UC_E_PIPE    ;; #       13. PIPE       "Open pipe"
    142 ) $UC_E_ALRM    ;; #       14. ALRM
    143 ) $UC_E_TERM    ;; #       15. TERM       Request termination
    144 ) $UC_E_STKFLT  ;; #       16. STKFLT
    145 ) $UC_E_CHLD    ;; #       17. CHLD
    146 ) $UC_E_CONT    ;; #       18. CONT
    147 ) $UC_E_STOP    ;; #       19. STOP       Stop project for later resurrection (cannot be handled)
    148 ) $UC_E_TSTP    ;; #       20. TSTP       Temporary stop
    151 ) $UC_E_TTIN    ;; #       21. TTIN       Attempt to read tty from background
    152 ) $UC_E_TTOU    ;; #       22. TTOU       Attempt to write tty from background
    153 ) $UC_E_URG     ;; #       23. URG        Urgent/OOB data
    154 ) $UC_E_XCPU    ;; #       24. XCPU       Exceeds CPU duration
    155 ) $UC_E_XFSZ    ;; #       25. XFSZ       Exceeds allowed file-size
    156 ) $UC_E_VTALRM  ;; #       26. VTALRM     Virtual alarm clock
    157 ) $UC_E_PROF    ;; #       27. PROF       Profiling alarm clock
    158 ) $UC_E_WINCH   ;; #       28. WINCH      Window Change
    159 ) $UC_E_IO &&      #       29. IO         Output is now possible
          $UC_E_POLL    ;; #           POLL
    160 ) $UC_E_PWR &&     #       30. PWR        Power failure
          $UC_E_LOST    ;; #           LOST
    161 ) ;;               #       31. UNUSED

    255 ) $UC_E_OOR ;; # Exit Status Out of Range

  esac
}

#
