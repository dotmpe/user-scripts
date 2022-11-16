
# Created: 2018-10-17


build-ifchange "&source-list"
source_list=$(build-sym "&source-list")

# TODO: should only test files no longer marked as 'dev', see attributes-local


lint-tags ()
{
  test -z "$*" && {
    # TODO: forbid only one tag... setup degrees of tags allowed per release

    git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' "$@" && return 1 || true
  } || {

    git grep '\(XXX\|FIXME\|TODO\):' "$@" && return 1 || true
  }
}

{

  declare x fail
  while read -r x
  do
    lint-tags "$x" || {
      fail=$?
      echo "$x"
      echo "Failed at $x E$fail" >&2
    }
  done
  return ${fail:-0}

} < "$source_list"

#
