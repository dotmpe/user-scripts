 #!/usr/bin/env bats

base=std-runner
load ../init

setup()
{
  init && load stdtest &&
  . ./tools/sh/util.sh &&
  OUT=echo . "./tools/ci/parts/std-runner.sh" &&
  . "./tools/ci/parts/std-stack.sh"
}


@test "$base: sh-spec-table (I) sh-spec (txt) baseline 1 test 1" {

  verbosity=4

  run sh_spec "test/var/table/baseline-1-test-1.txt"

  # Input should be 12 lines, and output is
  # 3 matrices of 3 values should be 12 lines (plus report line)
  { test_ok_nonempty 13 && test_lines \
\
"unset LOG; . ./tools/sh/env.sh" \
"LOG=\$PWD/tools/sh/log.sh . ./tools/sh/env.sh" \
"LOG= . ./tools/sh/env.sh" \
"unset LOG; . ./tools/sh/parts/env-0.sh" \
"LOG=\$PWD/tools/sh/log.sh . ./tools/sh/parts/env-0.sh" \
"LOG= . ./tools/sh/parts/env-0.sh" \
"unset LOG; bash ./tools/sh/env.sh" \
"LOG=\$PWD/tools/sh/log.sh bash ./tools/sh/env.sh" \
"LOG= bash ./tools/sh/env.sh" \
"unset LOG; bash ./tools/sh/parts/env-0.sh" \
"LOG=\$PWD/tools/sh/log.sh bash ./tools/sh/parts/env-0.sh" \
"LOG= bash ./tools/sh/parts/env-0.sh" \
"# Read 12 lines"

  } || stdfail 1.
}


@test "$base: sh-spec-table (II) outline/tree col (I) inner" {
  verbosity=4

  sh_new_stack ind
  sh_new_stack varspec

  varspec='spec1='               new_cmdspec=1.
  run sh_spec_table_inner
  { test_ok_empty
  } || stdfail 1.

  load assert

  local done= ln=0 ind= ind_d= ind_lvl=0 \
    varspec= last_varspec= varspec_d= varspec_d_lvl=0 \
    cmdspec= last_cmdspec= \
    indent=

  verbosity=6
  diag $base:$BATS_TEST_NR.3
  new_varspec='spec1='           new_cmdspec=1.
  sh_spec_table_inner

  assert_equal "$ind_d" "0"
  assert_equal "$ind_lvl" "1"
  assert_equal "$varspec_d" "spec1="
  assert_equal "$varspec_lvl" "1"

  diag $base:$BATS_TEST_NR.3
  new_varspec='  spec2=0.A'      new_cmdspec=2.out-1
  sh_spec_table_inner
  assert_equal "$ind_d" "0	2"
  assert_equal "$ind_lvl" "2"
  assert_equal "$varspec_lvl" "2"
  assert_equal "$varspec_d" "spec1=	spec2=0.A"

  diag $base:$BATS_TEST_NR.3
  new_varspec='spec1=1'          new_cmdspec=3.
  sh_spec_table_inner
  assert_equal "$ind_d" "0"
  assert_equal "$ind_lvl" "1"
  assert_equal "$ind" "2"
  assert_equal "$varspec_lvl" "1"
  assert_equal "$varspec_d" "spec1=1"
  assert_equal "$varspec" "spec1="

  new_varspec='  spec2=1.B.1'    new_cmdspec=4.out-2
  sh_spec_table_inner
  assert_equal "$varspec_d" "spec1=1	spec2=1.B.1"

  new_varspec='  spec2=1.B.2'    new_cmdspec=5.out-3
  sh_spec_table_inner
  assert_equal "$varspec_d" "spec1=1	spec2=1.B.2"

  new_varspec='spec1=2'          new_cmdspec=6.out-4
  sh_spec_table_inner
  assert_equal "$varspec_d" "spec1=2"

  new_varspec='/spec1'           new_cmdspec=7.
  sh_spec_table_inner
  assert_equal "$varspec_d" "/spec1"

  new_varspec='  spec2=u.C'      new_cmdspec=8.
  sh_spec_table_inner
  assert_equal "$varspec_d" "/spec1	spec2=u.C"

  new_varspec='    spec3=u.C.1'  new_cmdspec=9.out-5
  sh_spec_table_inner
  assert_equal "$varspec_d" "/spec1	spec2=u.C	spec3=u.C.1"
}


@test "$base: sh-spec-table (III) sh-spec (txt) test 2 outline/tree col" {
  verbosity=4

  run sh_spec "test/var/spec-outline/test-2.txt"

  { test_ok_nonempty 6 && test_lines \
\
"spec1= spec2=0.A 2.out-1" \
"spec1=1 spec2=1.B.1 4.out-2" \
"spec1=1 spec2=1.B.2 5.out-3" \
"spec1=2 6.out-4" \
"unset spec1; spec2=u.C spec3=u.C.1 9.out-5" \
"# Read 9 lines"

  } || stdfail 2.
}


@test "$base: sh-spec-table (IV) sh-spec (txt) test 3" {

  verbosity=4

  run sh_spec "test/var/table/baseline.txt"

  # Input should be 17 lines, and output is
  # one matrix of 3 times 3 values ie. 27 lines (plus report line)
  { test_ok_nonempty 10 && test_lines \
"unset CWD; unset LOG; unset SCRIPTPATH; . ./tools/sh/env.sh" \
"unset CWD; unset LOG; SCRIPTPATH=\$PWD . ./tools/sh/env.sh" \
"unset CWD; unset LOG; SCRIPTPATH= . ./tools/sh/env.sh" \
"unset CWD; unset SCRIPTPATH; LOG=\$PWD/tools/sh/log.sh . ./tools/sh/env.sh" \
"unset CWD; LOG=\$PWD/tools/sh/log.sh SCRIPTPATH=\$PWD . ./tools/sh/env.sh" \
"unset CWD; unset SCRIPTPATH; LOG= . ./tools/sh/env.sh" \
"unset LOG; unset SCRIPTPATH; CWD=\$PWD/tools/sh/log.sh . ./tools/sh/env.sh" \
"unset LOG; CWD=\$PWD/tools/sh/log.sh SCRIPTPATH=\$PWD . ./tools/sh/env.sh" \
"unset LOG; unset SCRIPTPATH; CWD= . ./tools/sh/env.sh" \
"# Read 17 lines"

  } || stdfail 3.
}


@test "$base: sh-spec-outline (I) sh-spec (list) test 1" {

	skip "FIXME: also do var. along dim"

  #run _run "sh-baseline-specs.list"
  run sh_spec "test/var/spec-outline/test-1.list"

  { test_ok_nonempty 2 && test_lines \
    "varspec1=foo varspec2=a cmdline" \
    "varspec1=foo varspec2=a cmdline"
  } || stdfail 1.
}
