#!/bin/sh

# Define {stack_var}_{shift,unshit,push,pop}() and var ${stack-var}_lvl
sh_new_stack() # Stack-Var
{
  test $# -eq 1 || return
  local stack_id="$1"
  eval "$(cat <<EOM

  # Remove and echo the front of ${stack_id}
  ${stack_id}_shift() #
  {
    test \$# -eq 0 || return
    test \$${stack_id}_lvl -eq 0 && return 1

    test \$${stack_id}_lvl -eq 1 && {
      ${stack_id}="\$${stack_id}_d"
      ${stack_id}_d=
      ${stack_id}_lvl=0
    } || {

      ${stack_id}="\$( printf -- "\$${stack_id}_d" | cut -d"${TAB_C}" -f1 )"
      ${stack_id}_d="\$( printf -- "\$${stack_id}_d" | cut -d"${TAB_C}" -f2- )"

      ${stack_id}_lvl=\$(( \$${stack_id}_lvl - 1 ))
    }
  }

  # Add to the front of ${stack_id}
  ${stack_id}_unshift() # varspec
  {
    test \$# -eq 1 || return
    test -z "\$${stack_id}_d" && ${stack_id}_d="\$1" || ${stack_id}_d="\$1${TAB_C}\$${stack_id}_d"
    ${stack_id}_lvl=\$(( \$${stack_id}_lvl + 1 ))
  }

  # Remove and echo the end of ${stack_id}
  ${stack_id}_pop() #
  {
    test \$# -eq 0 || return
    test \$${stack_id}_lvl -eq 0 && return 1

    test \$${stack_id}_lvl -eq 1 && {
      ${stack_id}="\$${stack_id}_d"
      ${stack_id}_d=
      ${stack_id}_lvl=0
    } || {

      ${stack_id}="\$( printf -- "\$${stack_id}_d" | cut -d"${TAB_C}" -f\$${stack_id}_lvl )"
      ${stack_id}_lvl=\$(( \$${stack_id}_lvl - 1 ))
      ${stack_id}_d="\$( printf -- "\$${stack_id}_d" | cut -d"${TAB_C}" -f1-\$${stack_id}_lvl )"
    }
  }

  # Add to the end of ${stack_id}
  ${stack_id}_push() # varspec
  {
    test \$# -eq 1 || return
    test -z "\$${stack_id}_d" && ${stack_id}_d="\$1" || ${stack_id}_d="\$${stack_id}_d${TAB_C}\$1"
    ${stack_id}_lvl=\$(( \$${stack_id}_lvl + 1 ))
  }

EOM
)"
}

# See FIXME's

# Remove and echo the front of varspec-c
#sh_varspec_shift() #
#{
#  test $# -eq 0 || return
#  test $ilv -eq 0 && return 1
#
#  test $ilv -eq 1 && {
#    echo "$varspec_c"
#    varspec_c=
#    ilv=0
#  } || {
#
#    printf -- "$varspec_c" | cut -d"$TAB_C" -f1
#  # FIXME: fix awk so it doesn't mange whitespce, then try again. See pop/push.
#    #varspec_c=$( printf -- "$varspec_c" | awk '{$1=""; print $0}' )
#    varspec_c="$( printf -- "$varspec_c" | cut -d"$TAB_C" -f2- )"
#
#    ilv=$(( $ilv - 1 ))
#  }
#}
#
## Add to the front of varspec-c
#sh_varspec_unshift() # varspec
#{
#  test $# -eq 1 || return
#  test -z "$varspec_c" && varspec_c="$1" || varspec_c="$1${TAB_C}$varspec_c"
#  ilv=$(( $ilv + 1 ))
#}
#
## Remove and echo the end of varspec-c
#sh_varspec_pop() #
#{
#  test $# -eq 0 || return
#  test $ilv -eq 0 && return 1
#
#  test $ilv -eq 1 && {
#    echo "$varspec_c"
#    varspec_c=
#    ilv=0
#  } || {
#
#    printf -- "$varspec_c" | cut -d"$TAB_C" -f$ilv
#    ilv=$(( $ilv - 1 ))
#    varspec_c="$( printf -- "$varspec_c" | cut -d"$TAB_C" -f1-$ilv )"
#
#    # FIXME awk tabs; see stack-shift
#    #printf -- "$varspec_c" | awk '{print $NF}'
#    #varspec_c="$( printf -- "$varspec_c" | awk '{$NF=""; print $0}' )"
#  }
#}
#
## Add to the end of varspec-c
#sh_varspec_push() # varspec
#{
#  test $# -eq 1 || return
#  test -z "$varspec_c" && varspec_c="$1" || varspec_c="$varspec_c${TAB_C}$1"
#  ilv=$(( $ilv + 1 ))
#}
