# Actual build target
XREDO_TARGET="${REDO_PWD:+$REDO_PWD/}${REDO_TARGET:?}"
# XRedo/Base: Actual initial (path, name or id) spec for target
#XREDO_BASE=${XREDO_TARGET%%[+:\/]*}
XREDO_BASE=${XREDO_TARGET%%:*}
XREDO_NODE=${XREDO_TARGET%:*}

: "${EWD:=$REDO_STARTDIR}"
: "${METADIR:=$EWD/.meta}"
: "${LCACHE:=$METADIR/cache}"

# Virtual ref for build root
: "${XREDO_GLOBAL:=@}"
: "${XREDO_BUILD:=${XREDO_GLOBAL}build:/}"
: "${XREDO_DATA:=$METADIR/build}"
: "${XREDO_CACHE:=$METADIR/build/cache}"

# Aliases
: "${A:=$XREDO_GLOBAL}"
: "${At_Build:=$XREDO_BUILD}"
: "${B:=$XREDO_DATA}"
: "${C:=$XREDO_CACHE}"

# Id: user-script.build.xredo                    vim:set ft=bash sw=2 sts=2 et:
