git ls '*.sh' | {
  while read -r x
  do
    shellcheck -s sh -x "$x" || {
      fail=$?
      echo "Failed at $x E$fail" >&2
    }
  done
  return ${fail:-0}
}
