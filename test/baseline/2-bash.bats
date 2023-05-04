#!/usr/bin/env bats

load ../init
base="baseline-2:bash"

setup()
{
  init && load assert
}


@test "$base: std globbing" {

  tmpd && test -d "$tmpd"
  cd $tmpd

  assert_equal "$(echo foo.*)" "foo.*"
  touch foo.bar
  assert_equal "$(echo foo.*)" "foo.bar"
  rm foo.bar

  shopt -u nullglob
  shopt -u globstar
  shopt -u failglob
  shopt -u extglob

  assert_equal "$(echo {foo,bar}-{el,baz})" "foo-el foo-baz bar-el bar-baz"

  cd "$BATS_CWD"
  rm -rf "$tmpd"

}


@test "$base: Shell variable name indirection" {

  FOO=foo
  BAR=FOO

  assert_equal "${!BAR}" "foo"

}


@test "$base: Shell variable name expansion" {

  foo_1=a
  foo_bar=b

  assert_equal "$( echo ${!foo*} )" "foo_1 foo_bar"

}


@test "$base: Shell substring removal" {

  PARAMETER="PATTERN foo"
  assert_equal "${PARAMETER#PATTERN}" " foo"
  assert_equal "${PARAMETER##P* }" "foo"

  PARAMETER="foo PATTERN"
  assert_equal "${PARAMETER%PATTERN}" "foo "
  assert_equal "${PARAMETER%% P*}" "foo"

}


@test "$base: Shell substring replace" {

  STRING=foobarbar
  PATTERN=bar
  SUBSTITUTE=baz
  assert_equal "${STRING/$PATTERN/$SUBSTITUTE}" "foobazbar"
  assert_equal "${STRING//$PATTERN/$SUBSTITUTE}" "foobazbaz"

  # Anchoring
  MYSTRING=xxxxxxxxxx
  assert_equal "${MYSTRING/#x/y}" "yxxxxxxxxx"
  assert_equal "${MYSTRING/%x/y}" "xxxxxxxxxy"

}


@test "$base: aliases are recognized (Bash)" {

  . ./tools/sh/init.sh
  load ../helper/stdtest
  lib_load shell
  shell_lib__init

  _r() {
    shopt -s expand_aliases
    alias foo='bar'
    type foo
  }
  run _r
  { test_ok_nonempty 1 && test_lines 'foo is aliased to `bar'"'"
  } || stdfail "alias foo=bar"

  assert test $IS_BASH -eq 1

}
