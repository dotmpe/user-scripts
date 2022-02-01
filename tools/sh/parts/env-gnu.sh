#!/usr/bin/env bash

# In case I ever need to deal with Darwin again but dont want to

# Set GNU 'aliases' to try to build on Darwin/BSD

case "$uname" in

  Darwin )
      export gsed=${gsed:-"gsed"}
      export ggrep=${ggrep:-"ggrep"}
      export gawk=${gawk:-"gawk"}
      export gdate=${gdate:-"gdate"}
      export gstat=${gstat:-"gstat"}
      export guniq=${guniq:-"guniq"}
      export gsort=${gsort:-"gsort"}
      export gcut=${gcut:-"gcut"}
      export greadlink=${greadlink:-"greadlink"}
      export grealpath=${grealpath:-"grealpath"}
    ;;

  #Linux ) # Default:
  * ) test "$uname" = "Linux" ||
        $LOG "warn" ":gnu" "Unknown OS" "$uname"

      export gsed=${gsed:-"sed"}
      export ggrep=${ggrep:-"grep"}
      export gawk=${gawk:-"awk"}
      export gdate=${gdate:-"date"}
      export gstat=${gstat:-"stat"}
      export guniq=${guniq:-"uniq"}
      export gsort=${gsort:-"sort"}
      export gcut=${gcut:-"cut"}
      export greadlink=${greadlink:-"readlink"}
      export grealpath=${grealpath:-"realpath"}
    ;;
esac

#
