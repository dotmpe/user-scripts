# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_EWD_BASH_H
#define USER_SCRIPT_EWD_BASH_H
#ifdef US_CONFIGURE
for dir in ${METADIR_DEFAULT:-meta .meta}
do [[ -d "$dir" ]] &&
  dir=$(realpath --relative-to . "$dir") &&
  EWD=$PWD METADIR=$dir && break
done
unset dir
#endif
US_ENV_SOURCE($EWD/$METADIR/config/us.bash)
#ifdef US_CONFIGURE
us_part $usp_opts us-os-extra uc-cache us-config us-metadir uc-basedir us-lib 
config_assert US_ENV_SEED <<EOM
EWD=$EWD
METADIR=$METADIR
\US_CONFIG_BUILD=US_CONFIG_BUILD
\US_LOCAL_ENV_BUILD=US_LOCAL_ENV_BUILD
\US_BUILD_ENV_BUILD=US_BUILD_ENV_BUILD
\US_ENV_LOCAL=US_ENV_LOCAL
\US_ENV_BUILD=US_ENV_BUILD
\US_ENV_BUILD_LIFE=US_ENV_BUILD_LIFE
EOM
#if [[ ! ${uc_diruuid:+set} ]]
#then
  # TODO: Re-stablish cache from local config
  #PATH+=":$U_S/src/bash/lib"
  #PATH+=":$U_S/src/sh/lib"
  #lib_require envd
  # XXX: lib_init envd

  #config_load
  [[ ${uc_dirnum:+set} ]] || uc_dirnum=${#uc_basedir_id[*]}
  [[ ${uc_diruuid:+set} ]] || uc_diruuid=$(uuidgen)
  [[ ${uc_dirlabel:+set} ]] ||
    failerr "Label required for basedir $uc_dirnum: ${!uc_dirlabel} EWD=$EWD"

  config_assertlocal <<EOM
declare -ga uc_basedir_key user_basedir_uuid
declare -gA uc_basedir_{path,}id
uc_basedir_id["$uc_dirlabel"]=$uc_dirnum
uc_basedir_key[$uc_dirnum]=$uc_dirlabel
user_basedir_uuid[$uc_dirnum]=$uc_diruuid
EOM
  # XXX: should may be want unique uuid per work tree, not per basedir
  #cache_updatemap "$US_BASEDIR_CACHE" "${!uc_diruuid}" "$uc_diruuid" &&
  #>&2 echo "New UUID ${uc_diruuid} for EWD=${EWD@Q}" ||
  #  failerr "Failed created UUID for ${EWD@Q}"
#fi
assert_env 2 EWD metadir_ok
#endif
#endif
#
# Id: user-script.ewd.bash     vim:set ft=bash sw=2 sts=2 et:
