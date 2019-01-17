#!/usr/bin/env bash

sh-hd-offsets() # Tab Cols...
{
  about 'Header offsets'

  local tab="$1"; shift

  $ggrep -m 1 -E '^#\ [^\!\/\.,]+$' "$tab" | {

    read header
    for col in $@
    do
      span=$( echo "$header" |
          $gsed -E 's/^(#.*\ \<'$col'\>( *|$)).*$/\1/g' )
      echo col=$col
      fnmatch "# $col *" "$header" &&
        echo offset=1 || {
        prefix=$( echo "$header" |
            $gsed -E 's/^(#.*)\ \<'$col'\>( .*|$)/\1/g' )
        echo offset=$(( 2 + ${#prefix} ))
      }
      echo end=${#span}
    done
  }
}
# Id: U-S:
