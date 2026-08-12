#ifndef USER_SCRIPT_TEST_INIT_SH_H
#define USER_SCRIPT_TEST_INIT_SH_H
#if LANG == bash
#define _assert_fs_nzf(x) [[ -f x && -s x ]]
#define _assert_fs_nt(a,b) [[ a -nt b ]]

assert_fs_nzf ()
{
  _assert_fs_nzf("$1")
}

assert_fs_nt()
{
  _assert_fs_nt("$1","$2")
}

assert_fresh ()
{
  _assert_fs_nzf("$1") &&
  _assert_fs_nt("$1","$2")
}

#else
#error unsupported shell LANG
#endif
#endif
# Id: user-script.test-init.sh.h                 vim:set ft=bash sw=2 sts=2 et:
