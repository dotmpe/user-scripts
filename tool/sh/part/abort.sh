#!/bin/sh


# Abort run with usage printed to stderr
abort() # Command-Line...
{
  usage >&2
  test -z "${1:-}" || {
    echo "Failure in '$1': $(usage "$1")" >&2
  }
  exit 2
}

# Id: U-S:                                     ex:filetype=bash:colorcolumn=80:
