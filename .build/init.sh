#!/usr/bin/env bash

test -e .git/hooks/pre-commit || {
  ln -s ../../.build/pre-commit.sh .git/hooks/pre-commit
}
git submodule update --init
