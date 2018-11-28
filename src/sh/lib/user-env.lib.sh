#!/bin/sh

user_env_lib_load()
{
  # Dir to record env-keys snapshots:SD-Shell-Dir
  test -n "$SD_SHELL_DIR" || SD_SHELL_DIR="$HOME/.statusdir/shell"

  # Set defaults for required vars
  #test -n "$ENV_NAME" || ENV_NAME=development

  user_env_init
  test -n "$lib_loaded" || lib_loaded=
}

user_env_init()
{
  env_d_mk=''
  test -n "$env_d_match_env" || env_d_match_env=user_env_match
  env_d_hooks=''
}

# Decide wether mk or sh-profile format at PATH is to be loaded into env and
# echo unless not.
#
# Include every name, unless it contains ':' then we will look at ENV_D
# ENV_COMP ENV_NAME... ????? and include if base of <base>:<lname>.<ext>
# is in ~. This can contain p=v or some:name:space but just that and periods.
# No slashes or quotes, braces, # or anything else weird non-id. Comp-Id.
user_env_match()
{
  env_d_match_env=$ENV_NAME
  fnmatch "*:*" "$1" && {
    test -n "$ENV_NAME" || return
    return
  } || {
    true
    return
  }
}

user_value_or_eval_default()
{
  true
}

user_env_or_default()
{
  true
}

user_env_finish()
{
  true
}

user_env_dump()
{
  true
}
