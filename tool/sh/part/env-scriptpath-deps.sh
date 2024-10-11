#!/bin/sh

## Add script-packages (from dependencies.txt) to SCRIPTPATH

test -n "${INIT_LOG-}" || return 109


test -z "${SCRIPTPATH-}" ||
  $INIT_LOG notice ":env-scriptpath-deps" "Current SCRIPTPATH" "$SCRIPTPATH"


export scriptname=env-scriptpath-deps

# Assert every parts we need is sourced
for func_dep in fnmatch trueish remove_dupes unique_paths script_package_include
do test "$(type -t $func_dep 2>/dev/null)" = function && continue
  . $U_S/tool/sh/parts/${func_dep//_/-}.sh
done

# Make effort to autodetect name of shell and use as load.<ext>, if none given
test -n "${SH_EXT-}" || {
  test -n "${REAL_SHELL-}" ||
    REAL_SHELL=$(ps --pid $$ --format cmd --no-headers | cut -d' ' -f1)
  fnmatch "-*" "$REAL_SHELL" &&
    SH_EXT="${REAL_SHELL:1}" || SH_EXT="$(basename -- "$REAL_SHELL")"

  # XXX: always add sh, but no sh is tested anywhere yet
  test "$SH_EXT" = "sh" || SH_EXT="$SH_EXT sh"
}

# (Only) in dev-mode auto-detect one checkouts dir
trueish "${ENV_DEV-}" && {
  test -n "${PROJECT_DIR-}" || {
    for pd in $HOME/project /srv/project-local $HOME/build/dotmpe
    do test -d "$pd" || continue
      PROJECT_DIR="$pd"
      break
    done
    unset pd
  }
}

# Normally use every Vnd-Path as a (Go-like) vendor sub-dir
test -n "${VND_PATHS-}" || {
  test -n "${VND_GH_SRC-}" || VND_GH_SRC=/src/vendor/github.com
  test -n "${VND_BB_SRC-}" || VND_BB_SRC=/src/vendor/bitbucket.org

  test -n "${VND_SRC_PREFIX-}" || VND_SRC_PREFIX=$VND_GH_SRC

  VND_PATHS="$(unique_paths ~/build $VND_GH_SRC $VND_BB_SRC $VND_SRC_PREFIX ~/.basher/cellar/packages)"
}


# Use dependencies that include sources from dependencies.txt files, ie the git
# and basher ones.

test -n "${PROJECT_DEPS:-}" || PROJECT_DEPS=$CWD/dependencies.txt

trueish "${ENV_DEV-}" && {
  test ! -e $CWD/dependencies.local.txt || {
    PROJECT_DEPS=$CWD/dependencies.local.txt
  }
} || {

  $INIT_LOG notice "" "No Dev-Mode detected" "$PROJECT_DEPS"
}

# Look for deps at each VND_PATHS, source load.*sh file to let it setup SCRIPTPATH
for supportlib in $(grep -h '^\(git\|dir\|basher\) ' $PROJECT_DEPS | cut -d' ' -f2);
do
  trueish "${ENV_DEV-}" && {

    # In dev-mode, expand user-paths using eval
    fnmatch "[/~]*" "$supportlib" && {
      supportlib="$(eval "echo $supportlib")"
      test -d "$supportlib" && {
        script_package_include "$supportlib" && continue
        $INIT_LOG error "" "Error including script-package at" "$supportlib"
        continue
      }
    }

    # Override VND_PATHS in Dev-Mode with basenames from ~/project that match
    # dependency basename
    test -d "$PROJECT_DIR/$(basename "$supportlib")" && {
      script_package_include "$PROJECT_DIR/$(basename "$supportlib")" && continue
      $INIT_LOG error "" "Error including script-package at" "$PROJECT_DIR/$(basename "$supportlib")" 31 || return
      continue
    }
  }

  # Go over known locations and include user-script packages matching dependency
  for vnd_base in $VND_PATHS
  do
    test -d "$vnd_base/$supportlib" || continue
    test "$vnd_base/$supportlib/*" != "$(echo "$vnd_base/$supportlib/"*)" ||
      continue

    script_package_include "$vnd_base/$supportlib" && break
    $INIT_LOG error "" "Error including script-package at" "$vnd_base/$supportlib" 32 || return
    break
  done

  true
done

{ script_package=0 ; for sh_ext in $SH_EXT; do
    test -f "$CWD/load.$sh_ext" && script_package=1 || continue
  done
  test $script_package -eq 1
} && {

  script_package_include $CWD ||
    $INIT_LOG error "" "Error including script-package at" "$CWD" 30 || return
}

test -z "${SCRIPTPATH:-}" &&
    $INIT_LOG error "" "No SCRIPTPATH found" ||
    $INIT_LOG notice "" "New SCRIPTPATH from $PROJECT_DEPS" "$SCRIPTPATH"
unset supportlib vnd_base
export SCRIPTPATH
