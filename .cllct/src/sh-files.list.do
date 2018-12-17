redo-ifchange "scm-status"

(
  scriptname="do:$REDO_PWD:$1"
  cd "$REDO_BASE" &&

  . ./tools/sh/init.sh && lib_load build-htd && list_sh_files >"$REDO_PWD/$3"
  test -s "$REDO_PWD/$3" || {
    error "No shell script files found!" 1
  }
)

echo "Listed $(wc -l "$3"|awk '{print $1}') sh files"  >&2
redo-stamp <$3
