CWD=${REDO_STARTDIR:?}
BUILD_TOOL=redo
BUILD_ID=$REDO_RUNID
BUILD_STARTDIR=$CWD
BUILD_BASE=${REDO_BASE:?}
BUILD_PWD="${CWD:${#BUILD_BASE}}"
test -z "$BUILD_PWD" || BUILD_PWD=${BUILD_PWD:1}
BUILD_SCRIPT=${BUILD_PWD}${BUILD_PWD:+/}default.do
test -z "$BUILD_PWD" && BUILD_PATH=$CWD || BUILD_PATH=$CWD:$BUILD_BASE
BUILD_PATH=$BUILD_PATH:${U_S:?}
