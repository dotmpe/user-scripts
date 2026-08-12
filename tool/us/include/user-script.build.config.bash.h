#
# Copyright 2018-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#
#ifndef USER_SCRIPT_BUILD_CONFIG_BASH_H
#define USER_SCRIPT_BUILD_CONFIG_BASH_H
#ifdef US_CONFIGURE
>&2 mkdir -vp tool/redo/recipe tool/us/part

assert_symlink \\
  "tool/redo/recipe/&default.us-build.do" \\
  "$U_S"/tool/redo/default.do

assert_symlink default.do "tool/redo/recipe/&default.us-build.do"

# NOTE: regenerating .do.do requires deleting the targets, as redo marks them as
# user source files after generating new copies.
for target in US_BUILD_LIFE
do
  : TODO: assert_symlink @target.do.do "tool/redo/recipe/&default.us-build.do"
done
# TODO: finish {local,build}-env.bash.build sources
# assert_symlink @build.env.do.do "tool/redo/recipe/&default.us-build.do"
# assert_symlink @clean.env.do.do "tool/redo/recipe/&default.us-build.do"
# assert_symlink @config.do.do "tool/redo/recipe/&default.us-build.do"
# assert_symlink @env.do.do "tool/redo/recipe/&default.us-build.do"

#:include user-script.build.env.local.bash.h

if [[ ${REDO_RUNID-} ]]
then
  :
else
  # redo @config &&
  >&2 echo "Initial configuration done, you can now use \`redo @config @env\` to confirm"
  # redo @{config,diag,env,test}
fi

#else
#error No build script
#endif
#endif
#
# Id: user-script         vim:set ft=bash sw=2 sts=2 et:
