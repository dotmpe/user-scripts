#!/bin/sh

# XXX: exploiting make to do dep mngmnt for env parts
# see also user-env.lib

mkenv_d_lib__load ()
{
  lib_require make
}

mkenv_d_boot() # Setup camp.
{
  mkenv_d_mk="$(cat <<EOM

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

mkenv_d_append()
{
  mkenv_d_mk="$mkenv_d_mk.$(cat)"
}

mkenv_d_lwalk()
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

mkenv_d_src() # Lock the tent.
{
  for mkenv_d_mk_l in $(mkenv_d_lwalk) $ENVPATH
  do
    true
  done
}

mkenv_d_complete() # Lock the tent.
{
  #for mkenv_d_mk_src in $(mkenv_d_src)
  for mkenv_d_mk_src in $(echo "$make_lookup_path" | make_op )
  do
    $mkenv_d_match "$mkenv_d_mk_src" && {
      echo matched $mkenv_d_match_env $mkenv_d_mk_src >&2
      mkenv_d_append < "$mkenv_d_mk_src"
    }
  done

  echo "end: $mkenv_d_mk" >&2

  unset mkenv_d_mk_src
}
