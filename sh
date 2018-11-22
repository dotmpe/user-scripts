#!/bin/sh

set -e

exec ./tools/sh/init-here.sh /src/sh "$(cat <<EOM

  lib_load sys build logger

  cmd_exists foobar


  #lib_load logger package build-test
  
  #spwd=. ppwd=$PWD vc_tracked
  #exit \$?

  #package_init
  #build_test_init
  
  #package_components
EOM
)"
