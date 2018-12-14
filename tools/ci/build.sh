#!/bin/sh
# See .travis.yml

# Initial tests, no tooling at all yet. Just smoketesting CI init.

announce 'Check project baseline'
bats test/baseline/project.bats

# OK, fire it up
announce 'Running user-script init.sh helpers'
./tools/sh/init-here.sh "" "" "" "echo foo"
. ./tools/sh/init.sh

# Again
./tools/sh/init-here.sh "" "" "" "echo foo"

# More
mkdir -vp $HOME/build/user-tools/my-new-project
cd $HOME/build/user-tools/my-new-project

git init
. $U_S/tools/sh/init-from.sh
find ./ -not -path '*.git*'
git status
