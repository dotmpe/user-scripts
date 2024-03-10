
math_lib__init ()
{
  # Allow to map commands used in this lib, default is to always lookup exec
  # (ie. supress functions/aliases).
  c_sleep="command sleep"
  c_bc="command bc"
  # Supresses alias, but not function
  #: "${c_sleep:=\sleep}"
  #: "${c_bc:=\bc}"
  # NOTE: mapping is rarely needed, but I have a case to override the sleep
  # command, to be able to signal to the user/system when a script process is
  # not actually doing anything. And it needs to exclude this call from that.
}

calc_float () # ~ <Expr> [<fpp=3>]
{
  local f
  f="$(echo "scale=${2:-3}; $1" | bc)" || return

  [[ "${f:0:2}" != "-." ]] && {
    [[ "${f:0:1}" != "." ]] && : "$f" || : "0$f"
  } || : "-0${f:1}"
  echo "$_"
}

# Calculate average value of several numeric samples from command output. By
# default the number must be an integer, and a floating point part is simply
# stripped before summing and averaging. Set sample_float=true to calculate
# using floating point values. And sample_fpp=<precision> to round it. This
# uses `bc` for calculation.
command_avg () # ~ <Var-name> <Sample-count> <Sample-delay> <Cmd-argv...>
{
  #true "${c_sleep:?}" "${c_bc:?}" # XXX: this or expand defaults like below...
  local name=${1:?} samples=0 count=${2:-3} sleep=${3:-0.25}
  shift 3
  for i in $(seq 1 $count)
  do
    ${c_sleep:-sleep} $sleep &&
    test -n "$("$@")" || return
    ${sample_float:-false} "$_" && {
      test -n "$(echo "$samples + $_" | ${c_bc:-bc} -l)" || return
    } || {
      # Sum integer part only
      test -n "$(( samples + ${_/.*} ))" || return
    }
    samples=$_
  done
  ${sample_float:-false} && {
    test -z "${sample_fpp:-}" && {
      test -n "$(echo "$samples / $count" | ${c_bc:-bc} -l)" || return
    } ||
      test -n "$(echo "scale=${sample_fpp}; $samples / $count" | ${c_bc:-bc})" || return
  } ||
    test -n "$(( $samples / $count ))" || return
  declare -g ${name}=$_
}

