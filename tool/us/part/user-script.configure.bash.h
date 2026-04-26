# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_CONFIGURE_BASH_H
#define USER_SCRIPT_CONFIGURE_BASH_H
#define US_CONFIGURE

usp_opts="--alias --reload --hooks:declare,define,init,user+load"
PATH+=:/var/local/statusdir

US_BASEDIR_COMMANDS="init sync update"
US_BASEDIR_FIELDS="type uuid cfg"

#ENV_PEND='BASEDIR US_CONFIG'
#ENV_DEF[US_CONFIG]=
#'${user_basedir_cfg[$uc_dirnum]}'
#'$METADIR/config/us.bash'

#endif
# Id: user-script.configure.bash                 vim:set ft=bash sw=2 sts=2 et:
