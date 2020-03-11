#!/bin/sh


# Deal with checksumming, and file manifests with checksums


ck_lib_load()
{
  empty_md5=d41d8cd98f00b204e9800998ecf8427e
  empty_sha1=da39a3ee5e6b4b0d3255bfef95601890afd80709
  empty_sha2=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  empty_git=e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
}

# Helpers to validate checksum for file, or show how to get/echo checksum
# abbrev=7 (default) allow abbreviated checksums even only 1 char, set minimum
ck_git() # File [Check]
{
  test -n "${abbrev-}" || abbrev=7
  cksum="$(git hash-object "$1")" || return
  test -n "${2-}" && {
    test ${#2} -eq ${#cksum} || { # length should be 40
      test $abbrev -gt 0 || return
      # Partial match but at least N chars
      test ${#2} -ge $abbrev && fnmatch "$2*" "$cksum"
      return $?
    }
    test "$2" = "$cksum" || return
  } || echo "$cksum"
}

# See ck-git for description.
ck_md5()
{
  test -n "${abbrev-}" || abbrev=7
  cksum="$(md5sum "$1" | cut -f1 -d' ')" || return
  test -n "${2-}" && {
    test ${#2} -eq ${#cksum} || {
      test $abbrev -gt 0 || return
      # Partial match but at least N chars
      test ${#2} -ge $abbrev && fnmatch "$2*" "$cksum"
      return $?
    }
    test "$2" = "$cksum" || return
  } || echo "$cksum"
}

# See ck-git for description.
# TODO: rewrite prefix; ck_sha() { ck_sha1 "$@"; }
ck_sha1()
{
  test -n "${abbrev-}" || abbrev=7
  cksum="$(sha1sum "$1" | cut -f1 -d' ')" || return
  test -n "${2-}" && {
    test ${#2} -eq ${#cksum} || {
      test $abbrev -gt 0 || return
      # Partial match but at least N chars
      test ${#2} -ge $abbrev && fnmatch "$2*" "$cksum"
      return $?
    }
    test "$2" = "$cksum" || return
  } || echo "$cksum"
}

# See ck-git for description.
ck_sha2()
{
  test -n "${abbrev-}" || abbrev=7
  cksum="$(sha256sum "$1" | cut -f1 -d' ')" || return
  test -n "${2-}" && {
    test ${#2} -eq ${#cksum} || {
      test $abbrev -gt 0 || return
      # Partial match but at least N chars
      test ${#2} -ge $abbrev && fnmatch "$2*" "$cksum"
      return $?
    }
    test "$2" = "$cksum" || return
  } || echo "$cksum"
}
ck_sha2_a()
{
  test -n "${abbrev-}" || abbrev=7
  cksum="$(shasum -a 256 "$1" | cut -f1 -d' ')" || return
  test -n "$2" && {
    test ${#2} -eq ${#cksum} || {
      test $abbrev -gt 0 || return
      # Partial match but at least N chars
      test ${#2} -ge $abbrev && fnmatch "$2*" "$cksum"
      return $?
    }
    test "$2" = "$cksum" || return
  } || echo "$cksum"
}
