#!/bin/sh

env_d_boot() # Setup camp.
{
  env_d_mk="$(cat <<EOM

  XXX_VAR           =
  ENV_ETC_LOCAL    ?= .local/etc/
  ENV_ETC          ?= $HOME/.local/etc/

  # test -n "$UCONF_ENVD" -a -e "$UCONF_ENVD"
  UCONF_ENVD       ?=@ $UCONF/etc/env.d

  # Similar, but add :<value> or <ins>:
  ENVPATH         =+@ $ENV_ETC/env.d
  ENVPATH         @=+ $HOME/.env.d
  ENVPATH         @+= /etc/env.d

  LENVPATH        @=+ .env.d
  LENVPATH        @=+ env.d/
  LENVPATH        @+= $ENV_ETC_LOCAL/env.d
EOM
)"

make_lookup_path='$(wildcard
  $(foreach EXT,kv mk sh jp, *.$(EXT)))

  $(foreach EXT,kv mk sh jp, *.$(EXT)))

    $(addprefix $(CWD), .env.d env.d $ENV_ETC_LOCAL/env.d)

  )'

  ENVPATH="$ENV_ETC/env.d/*. $HOME/.env.d /etc/env.d"


  test -e "$UCONF/etc/env.d"
}

env_d_append()
{
  env_d_mk="$env_d_mk.$(cat)"
}

env_d_lwalk()
{
  local cwd=$PWD
  until test "$cwd" = "/" -o "$cwd" = "$HOME"
  do
    for lenvpath in $LENVPATH
    do
      test -e "$cwd/$lenvpath" || continue
      echo "$cwd/$lenvpath"
    done
    cwd=$(dirname "$cwd")
  done
}

env_d_src() # Lock the tent.
{
  for env_d_mk_l in $(env_d_lwalk) $ENVPATH
  do
    true
  done
}

env_d_complete() # Lock the tent.
{
  #for env_d_mk_src in $(env_d_src)
  for env_d_mk_src in $(echo "$make_lookup_path" | make_op )
  do
    $env_d_match "$env_d_mk_src" && {
      echo matched $env_d_match_env $env_d_mk_src >&2
      env_d_append < "$env_d_mk_src"
    }
  done

  echo "end: $env_d_mk" >&2

  unset env_d_mk_src
}
