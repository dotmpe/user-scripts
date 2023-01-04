true "${UCONF:="$HOME/.conf"}"
true "${U_S:="$HOME/project/user-scripts"}"
true "${US_BIN:="$HOME/bin"}"

# XXX: move to uconf
declare -g -A BUILD_NS_DIR=(
    [compo]=${C_INC:?}
    [uconf]=${UCONF:?}
    [bin]=${US_BIN:?}
    [us]=${U_S:?}
    [uc]=${U_C:?}
    [htd]=${HTDIR:?}
  )

# Special prefix characters for target references, in addition to '/' and '.'
BUILD_SPECIAL_RE='[\+\@\:\%\&\*]'

# Special targets that should not generate file content
BUILD_VIRTUAL_RE='[\?\+-]'

# Special targets that are symbols for file paths
BUILD_FSYM_RE='[\%\&]'
#BUILD_AREF_RE='[\%\&]'

# Special targets that are symbols for file content
#BUILD_CREF_RE='[\%\&]'

BUILD_NS=:
BUILD_NS_=${BUILD_NS:0:1}

declare -g -A BUILD_DECO_NAMES=(
  ["&"]=amp\ and
  ["@"]=at\ ctx
  #[\\]=bwd
  [:]=col
  ["\$"]=cur
  [.]=dot\ per\ p
  ["="]=eq
  ["^"]=esc\ req
  [/]=fwd\ slash
  ["#"]=hash
  [-]=min\ dash
  [+]=plus\ inc\ in
  [%]=pct\ part
  ["?"]=qm\ qs\ q
  ["*"]=star\ group
  ["~"]=tilde
)
declare -g -A BUILD_TARGET_DECO=(
  [:]=special
  [/]=filepath
  [.]=filepath
  [-]=prefix-alias [+]=prefix-alias
  ["?"]=prefix-alias
  ["@"]=prefix-alias ["&"]=prefix-alias [%]=prefix-alias ["*"]=prefix-alias
)
declare -g -A BUILD_TARGET_ALIAS=(
  ["&"]=${BUILD_NS_:?}file:
  ["*"]=${BUILD_NS_:?}group:
  ["%"]=${BUILD_NS_:?}pattern:
  ["@"]=${BUILD_NS_:?}context:
  ["^"]=${BUILD_NS_:?}target:
  ["?"]=${BUILD_NS_:?}target:
  ["??"]=${BUILD_NS_:?}recipe:
)

# XXX: Example value, should mvoe some stuff to personal user-conf
true "${BUILD_BASES:=${C_INC:?} ${UCONF:?} ${US_BIN:?} ${U_S:?} ${U_C:?} ${HTDIR:?}}"

true "${BUILD_TOOL:="redo"}"

true "${PROJECT_CACHE:=".meta/cache"}"

true "${build_main_targets:="all help build test"}"
true "${build_all_targets:="build test"}"
