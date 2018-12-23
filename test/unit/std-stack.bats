 #!/usr/bin/env bats

base=std-stack
load ../init

setup()
{
  init && . "./tools/ci/parts/std-stack.sh"
}

@test "$base: sh-new-stack" {

  sh_new_stack stack_test_id

  local stack_test_id= stack_test_id_d= stack_test_id_lvl=0 verbosity=4

  load assert

  stack_test_id_push foo
  stack_test_id_push bar
  stack_test_id_push baz
  assert_equal "$stack_test_id_d" "foo${TAB_C}bar${TAB_C}baz"

  stack_test_id_pop
  assert_equal "$stack_test_id" "baz"
  assert_equal "$stack_test_id_d" "foo${TAB_C}bar"
  stack_test_id_push baz
  assert_equal "$stack_test_id_d" "foo${TAB_C}bar${TAB_C}baz"

  stack_test_id_shift
  assert_equal "$stack_test_id" "foo"
  assert_equal "$stack_test_id_d" "bar${TAB_C}baz"
  stack_test_id_unshift foo
  assert_equal "$stack_test_id_d" "foo${TAB_C}bar${TAB_C}baz"

  stack_test_id_shift
  assert_equal "$stack_test_id" "foo"
  stack_test_id_shift
  assert_equal "$stack_test_id" "bar"
  stack_test_id_shift
  assert_equal "$stack_test_id" "baz"
  assert_equal "$stack_test_id_d" ""
  stack_test_id_unshift foo
  assert_equal "$stack_test_id_d" "foo"
  stack_test_id_pop
  assert_equal "$stack_test_id_d" ""
  stack_test_id_push foo
  assert_equal "$stack_test_id_d" "foo"
}
