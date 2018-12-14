#!/bin/sh

# Setup exactly like user-script, from HTTP published files.

test -n "$U_S" && {

    test -e tools/sh/init.sh || {
      mkdir -vp tools/sh/boot src/sh/lib &&
      cp $U_S/tools/sh/init.sh $U_S/tools/sh/init-here.sh tools/sh/
    }

} || {

    test -n "$U_S_GIT_WEB" ||
      export U_S_GIT_WEB=https://rawgit.com/user-tools/user-scripts
    test -n "$U_S_VERSION" || export U_S_VERSION=master


    test -e tools/sh/init.sh || {
      mkdir -vp tools/sh/boot src/sh/lib &&
      cd tools/sh &&

      curl -sSfO ${U_S_GIT_WEB}/${U_S_VERSION}/tools/sh/init-from.sh &&
      curl -sSfO ${U_S_GIT_WEB}/${U_S_VERSION}/tools/sh/boot/null.sh &&

      cd ../../src/sh/lib &&

      curl -sSfO ${U_S_GIT_WEB}/${U_S_VERSION}/src/sh/lib/sys.sh &&
      curl -sSfO ${U_S_GIT_WEB}/${U_S_VERSION}/src/sh/lib/os.sh &&
      curl -sSfO ${U_S_GIT_WEB}/${U_S_VERSION}/src/sh/lib/str.sh

      cd ../../..
    }
}
