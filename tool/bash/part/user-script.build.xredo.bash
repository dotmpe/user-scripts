# Actual build target
XREDO_TARGET="${REDO_PWD:+$REDO_PWD/}${REDO_TARGET:?}"
# XRedo/Base: Actual initial (path, name or id) spec for target
#XREDO_BASE=${XREDO_TARGET%%[+:\/]*}
XREDO_BASE=${XREDO_TARGET%%:*}
XREDO_NODE=${XREDO_TARGET%:*}
# Id: user-script.build.xredo                    vim:set ft=bash sw=2 sts=2 et:
