
# Calculate average value of several numeric samples from command.
command_avg () # ~ <Var-name> <Sample-count> <Sample-delay> <Cmd-argv...>
{
  local name=${1:?} samples=0 count=${2:-3} sleep=${3:-0.25}
  shift 3
  for i in $(seq 1 $count)
  do
    command sleep $sleep
    : "$("$@")"
    ${sample_float:-false} $_ && {
      test -z "${sample_fpp:-}" &&
        : "$(echo "$samples + $_" | bc -l)" ||
        : "$(echo "scale=${sample_fpp}; $samples + $_" | bc)"
    } || {
      # Sum integer part only
      : "$(( samples + ${_/.*} ))"
    }
    samples=$_
  done
  ${sample_float:-false} &&
    : "$(echo "$samples / $count" | bc -l)" ||
    : "$(( $samples / $count ))"
  declare -g ${name}=$_
}

