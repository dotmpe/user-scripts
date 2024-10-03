#!/bin/sh


test -n "$U_S_GIT_WEB" ||
  export U_S_GIT_WEB=https://rawgit.com/user-tools/user-scripts
test -n "$U_S_VERSION" || export U_S_VERSION=master

curl -sSf ${U_S_GIT_WEB}/${U_S_VERSION}/tools/sh/init-from.sh | sh -
