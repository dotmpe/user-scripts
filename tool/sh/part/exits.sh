#!/bin/sh

# Values copied from /usr/include/sysexits.h

EXIT_OK=0
EXIT_USAGE=64  # command line usage error
EXIT_DATAERR=65  # data format error
EXIT_NOINPUT=66  # cannot open input
EXIT_NOUSER=67  # addressee unknown
EXIT_NOHOST=68  # host name unknown
EXIT_UNAVAILABLE=69  # service unavailable
EXIT_SOFTWARE=70  # internal software error
EXIT_OSERR=71  # system error (e.g., can't fork)
EXIT_OSFILE=72  # critical OS file missing
EXIT_CANTCREAT=73  # can't create (user) output file
EXIT_IOERR=74  # input/output error
EXIT_TEMPFAIL=75  # temp failure; user is invited to retry
EXIT_PROTOCOL=76  # remote error in protocol
EXIT_NOPERM=77  # permission denied
EXIT_CONFIG=78  # configuration error
