#!/bin/sh

###

##

#
syslog_lib_load () { true; }
syslog_lib_init () { true; }


# These mappings are take from LOGGER(1). See also
# <https://www.paessler.com/it-explained/syslog>

# Return level number as string for use with line-type or logger level, channel
# Basicly these correspond to KERN_<Level-Name> in the Linux kernel.
syslog_level_name() # Level-Num
{
  case "$1" in
      1 ) echo emerg ;;
      2 ) echo crit ;;
      3 ) echo err ;;
      4 ) echo warn ;;
      5 ) echo notice ;;
      6 ) echo info ;;
      7 ) echo debug ;;

      * ) return 1 ;;
  esac
}

syslog_level_num() # Level-Name
{
  case "$1" in
      emerg )           echo 1 ;;
      crit  )           echo 2 ;;
      err   | error )   echo 3 ;;
      warn  | warning ) echo 4 ;;
      notice )          echo 5 ;;
      info  )           echo 6 ;;
      debug )           echo 7 ;;

      * ) return 1 ;;
  esac
}

# These are take from LOGGER(1) as well, but the mapping is less clear and does not seem to be complete in the manual.
syslog_facility_name()
{
  case "$1" in

      0 ) echo kern ;;
      1 ) echo user ;;
      2 ) echo mail ;;
      3 ) echo daemon ;;
      4 ) echo auth ;;
      5 ) echo syslog ;;
      6 ) echo lpr ;;
      9 ) echo cron ;;
      10 ) echo authpriv ;;
      11 ) echo ftp ;;
			# TODO: fill out completely, if ever needed...

      * ) return 1 ;;
  esac
}

syslog_facility_num()
{
  case "$1" in

      kern ) echo 0 ;;
      user ) echo 1 ;;
      mail ) echo 2 ;;
      daemon ) echo 3 ;;
      auth | security ) echo 4 ;;
      syslog ) echo 5 ;;
      lpr ) echo 6 ;;
      news ) echo 7 ;;
      uucp ) echo 8 ;;
      cron ) echo 9 ;;
      authpriv ) echo 10 ;; # XXX: or the other way around with 4
      ftp ) echo 11 ;;
      #ntp ) echo 12 ;; # 12-15 is not in LOGGER(1) or used on rsyslog?

      local0 ) echo 16 ;;
      local1 ) echo 17 ;;
      local2 ) echo 18 ;;
      local3 ) echo 19 ;;
      local4 ) echo 20 ;;
      local5 ) echo 21 ;;
      local6 ) echo 22 ;;
      local7 ) echo 23 ;;

      * ) return 1 ;;
  esac
}

#
