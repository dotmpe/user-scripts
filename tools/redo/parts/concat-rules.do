# XXX: dont need anything fancy currently. But would want to try write generic
# concat recipe.

sh_mode dev strict build

test -d "$(dirname "$3")" || mkdir -p "$(dirname "$3")"

set -- "$@" "${BUILD_RULES:?}"
#build-ifchange "$4"
#build_install_parts \
#      concat-rules .list "&build-rules"

{
  echo "# Generated on $(date --iso=min) from $4"
  echo "# at $3"
  echo
  cat "$4"
} >| "$3"

${BUILD_TOOL:?}-stamp <"$3"
#build-stamp <"$3"

  #and copied to .meta/stat/index/components.list"
# Copy the file so it can be managed (by another system) as standalone
# metadata
#build_copy_changed "$3" .meta/stat/index/components.list
