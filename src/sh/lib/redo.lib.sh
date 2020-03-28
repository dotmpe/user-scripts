#!/bin/sh

redo_lib_load()
{
  test -n "${redo_db-}" || {
    test -e ".redo/db.sqlite3" && redo_db=.redo/db.sqlite3
  }
  test ! -e "${redo_db-}" || {
    test -w ".redo/db.sqlite3" || {
      cp redo_db=.redo/db.sqlite3 .cllct/redo-db.sqlite3
      redo_db=.cllct/redo-db.sqlite3
    }
  }
}

# List dependencies for target with bit inidicating wether they where generated by redo.
redo_deps() # Target-Path
{
  test -n "$1" && {
    local id=$(echo "SELECT rowid FROM Files WHERE name='$1';" | sqlite3 "$redo_db")
    test -n "$id" || error "No such target '$1'" 1
    echo '
SELECT
  Files.name, Files.is_generated
FROM Files JOIN Deps on Files.rowid = Deps.source WHERE target='"$id"';
' | sqlite3 "$redo_db" | tr '|' ' '
    return $?

  } || {

    echo '
SELECT
  Files.name
FROM Files JOIN Deps on Files.rowid = Deps.source WHERE Files.is_generated=1;
' | sqlite3 "$redo_db" | tr '|' ' '
    return $?
  }
}
