#!/usr/bin/env bash
#
# This is a few old build recipe related routines.
#
# Copyright B. van Berkum 2023-2026 <berend@dotmpe.com>
#
# Private data repository. No distribution.

_generate_script_header ()
{
  echo "#!/usr/bin/env bash"
  us-pp --pwd --output --lang=bash - <<< "#&'strict'"
}

generate_self_build_recipe ()
{
  cat <<EOM
>&2 echo "\$\$ redo: Using $1.build"
VERBOSE=0 QUIET=1 ./$1.build &&
redo-ifchange ./$1.build ${@:2} &&
redo-stamp < ./$1
EOM
}

generate_self_build_recipe_static ()
{
  _generate_script_header
  cat <<EOM
redo-ifdone $REDO_TARGET
#if ! redo-ifdone $REDO_TARGET
#then
#  redo $REDO_TARGET &&
#  >&2 echo exec redo \$REDO_TARGET &&
#  exec redo \$REDO_TARGET
#fi
>&2 echo "\$\$ redo: Using ${REDO_TARGET%.do}.build"
VERBOSE=0 QUIET=1 ./${REDO_TARGET%.do}.build &&
redo-ifchange ./${REDO_TARGET%.do}.build &&
redo-stamp < ./${REDO_TARGET%.do}
EOM
}

generate_us_build_recipe ()
{
  cat <<'EOM'
if test ! -e $REDO_TARGET.build
then
  failerr "No build recipe for $REDO_TARGET" || exit
fi
>&2 echo "$$ redo: Using $REDO_TARGET.build"
redo-ifdone $REDO_TARGET.do
#if ! redo-ifdone $REDO_TARGET.do
#then
#  redo $REDO_TARGET.do
#  exec redo $REDO_TARGET
#fi
VERBOSE=0 QUIET=1 us-build --pwd "$REDO_TARGET.build" "$3" &&
redo-stamp < "$3" &&
redo-ifchange "$REDO_TARGET.build"
EOM
}

# case "$REDO_TARGET" in
#   ( default.do )
#       _generate_script_header
#       generate_us_build_recipe
#     ;;
#   ( all.do )
#       _generate_script_header
#       cat <<'EOM'
# VERBOSE=0 QUIET=1 ./env.bash.build &&
# . ./env.bash &&
#
# redo-ifdone @env &&
# redo-ifchange ${build_all_targets:?}
# EOM
#     ;;
#   ( *.bash.do )
#       > "$3" \
#       generate_self_build_recipe_static ${REDO_TARGET%.bash.do}.build &&
#       redo-stamp < "$3"
#     ;;
#
#   * ) >&2 echo "Unknown target $REDO_TARGET"
#       exit 1
#     ;;
# esac

# Id: default         vim:set ft=bash sw=2 sts=2 et:
