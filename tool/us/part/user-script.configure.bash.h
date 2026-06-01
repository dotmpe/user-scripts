# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#
#ifndef USER_SCRIPT_CONFIGURE_BASH_H
#define USER_SCRIPT_CONFIGURE_BASH_H
# FIXME: cannot quite get _file quoting working exactly right; better testing
# for names with ws required.
##define US_KEY_IMPORT(_file) . <(line_prefix "export " < <(read_nix _file)) || failerr "E$? importing "_file
##define US_ENV_SOURCE(_file) [[ ! -s _file ]] || . _file || failerr "E$? loading "_file
#ifdef US_CONFIGURE
#ifndef US_ENV_SEED
#error US_ENV_SEED setting required
#endif
userscripts::core::pass_status () { return; }
#:declare-ifndef -f if_ok userscripts::core::pass_status
#:declare-ifndef -f failerr userscripts::core::echo_stderr_with_status
#:declare-ifndef -f line_prefix User-Script.String.line-prefix User-Script.String.line-surround
#:declare-ifndef -f read_nix User-Script.OS.file-data
# : "${ENV_BASH:=./env.bash}"
# : "${BUILD_ENV_BASH:=./.local-env.bash}"
if [[ -s US_ENV_SEED ]]
then US_KEY_IMPORT(US_ENV_SEED) || failerr "Abnormal status $? while sourcing user script env seed (user-script.configure.bash)"
fi
append_path /var/local/statusdir
# TODO: build global config and use that for all configurations (for pp inc)
[[ ! ${METADIR:+set} || ! -d "${METADIR-}/config" ]] ||
  append_path "$METADIR/config"
#  append_path "$METADIR/config" US_PP_INC
#
# NOTE: to see actual local configure and load, see EWD after METADIR is
# configured, and other relevant parts.
#
US_BASEDIR_COMMANDS="init sync update"
US_BASEDIR_FIELDS="type uuid cfg"
# ENV_PEND='BASEDIR US_CONFIG'
# ENV_DEF[US_CONFIG]=
# '${user_basedir_cfg[$uc_dirnum]}'
if wordmatch @dev ${CTX_HOST-}
then
  usp_opts+=' --reload'
fi
# 
#declare -gA US_ENV_TARGETS=(
#  [@env]="@env @"
#  [@build]=@build
#  [@project]="@config @env @build @clean"
#  [@build]=@build
#)
# build_env_targets=@env
# build_all_targets=@test
# : "${CONF_TARGET:=@config}"
# : "${ENV_TARGET:=@env}"
#else

#endif
#endif
# Id: user-script.configure.bash                 vim:set ft=bash sw=2 sts=2 et:
