
### Checksumming

# Helper function to generate ASCII (hex encoded) checksums using some common
# hash or checksum algorithms.

# XXX: several cksum implementations/results exist, see other more experimental
# libs for those.

# XXX: and file manifests with checksums (see ck-htd.lib etc.)

# TODO: string indexing instead of globmatch comparison could bit faster?


ck_lib__load()
{
  sha256sum_cmd=( "sha256sum" )
  #sha256sum_cmd=( "shasum" "-a" "256" )

  empty_md5=d41d8cd98f00b204e9800998ecf8427e
  empty_git=e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
  empty_sha1=da39a3ee5e6b4b0d3255bfef95601890afd80709
  empty_sha224=d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f
  empty_sha2=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  empty_sha384=38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b
  empty_sha512=cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e
  empty_b2=786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce
}

# See ck-git for description.
ck_b2 () # File [Check]
{
  typeset cksum_cmd=( "b2sum" ) ; ck_sum "$@"
}

# Helpers to validate checksum for file
# abbrev=7 (default) allow abbreviated checksums even only 1 char, set minimum
ck_git() # File [Check]
{
  typeset cksum_cmd=( "git" "hash-object" ) ; ck_sum "$@"
}

# See ck-git for description.
ck_md5 () # File [Check]
{
  typeset cksum_cmd=( "md5sum" ) ; ck_sum "$@"
}

# See ck-git for description.
ck_sha1 () # File [Check]
{
  typeset cksum_cmd=( "sha1sum" ) ; ck_sum "$@"
}

# See ck-git for description.
ck_sha2 () # File [Check]
{
  typeset cksum_cmd=( "${sha256sum_cmd[@]}" ) ; ck_sum "$@"
}

# See ck-git for description.
ck_sha224 () # File [Check]
{
  typeset cksum_cmd=( "sha224sum" ) ; ck_sum "$@"
}

# See ck-git for description.
ck_sha384 () # File [Check]
{
  typeset cksum_cmd=( "sha384sum" ) ; ck_sum "$@"
}

# See ck-git for description.
ck_sha512 () # File [Check]
{
  typeset cksum_cmd=( "sha512sum" ) ; ck_sum "$@"
}

# Generate or validate checksum for input (file or stdin).
ck_sum () # ~ [<File>] [<Checksum>]
{
  test -n "${abbrev-}" || local abbrev=7
  # XXX: not every command may need output cleanup (or have options to output
  # which does not need cleanup), but cleaning is harmless.
  if_ok "$("${cksum_cmd[@]:?}" "${1:--}")" || return
  : "${_/  *}"
  cksum="$_"
  test -n "$cksum" || return
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

# Id: U-S:
