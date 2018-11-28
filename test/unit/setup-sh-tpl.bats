#!/h usr/bin/env bats

base=unit/setup-sh-tpl.lib
load ../init

setup()
{
  init &&
  load assert &&
  lib_load setup-sh-tpl
}


@test "$base: setup-sh-tpl-basevar PATHNAME" {

  run setup_sh_tpl_basevar ".../.../setup-sh-tpl-1.sh"
  test_ok_nonempty "setup_sh_tpl_1_" || stdfail

}

@test "$base: setup-sh-tpl-name-index FILENAME [VAR-PREFIX]" {

  verbosity=3
  . ./test/var/build-lib/setup-sh-tpl-1.sh

  run setup_sh_tpl_name_index "File Name" setup_sh_tpl_
  test_ok_nonempty 1 || stdfail A.

  run setup_sh_tpl_name_index "No Such Name" setup_sh_tpl_
  test_nok_empty || stdfail B.

}
