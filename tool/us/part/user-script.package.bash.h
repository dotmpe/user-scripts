# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_PACKAGE_BASH
#define USER_SCRIPT_PACKAGE_BASH
#ifdef US_CONFIGURE

# [[ -e $METADIR/package/main.json ]] || {
#   if [[ -h $METADIR/package/main.json ]]; then
#     _WARN "Found broken main config symlink, attempting to recover"
#   fi

  us_part $usp_opts us-os-extra us-config py-venv uc-cache

  pyvenv.load+user &&
  export PYTHONPATH=$HOME/.local/pylib &&
  . <(pyvenv_script "${PYVENV_NAME:=script-mpe}") ||
    failerr "E$? getting python virtual env" || exit

  us_part $usp_opts --alias us-package
  
  package_setlocal "$EWD" ||
    ERR "Failed local package setup (E$?)" || exit
  . <(echo "${us_package_hooks['init@local']}")

  . <(line_prefix package_ < $PACK_SH)

  package_writescripts

  config_assertlocal <<EOM
package_id=$package_id
PACK_SH=$PACK_SH
$(for script in $PACK_SCRIPTS/*.sh
do
  chmod +x "$script"
  : "${script##*/}"
  : "${_%.sh}"
  echo declare -xf "$_"
  echo "$_ () { $script \"\$@\"; }"
done)
EOM
# }
#else
. <(line_prefix package_ < $PACK_SH)
# XXX: redo @update.package 
#endif
# Id: user-script.package.bash                   vim:set ft=bash sw=2 sts=2 et:
