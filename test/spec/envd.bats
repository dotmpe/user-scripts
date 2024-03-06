#!/usr/bin/env bats

base=envd
load ../init

setup ()
{
  sh_mode dev strict build
  init &&
  load assert extra stdtest &&
  lib_load envd
}

@test "$base loaded" {
  run lib_uc_loaded envd 
}

@test "$base load" {
  . ./test/var/bash/env-parts.sh
  envd_loadenv
  for part in part-{A,B,C,D}
  do 
    run envd_loaded $part
    test_ok_empty || stdfail $part
  done
}

@test "$base declare" {

  . ./test/var/bash/env-parts.sh
  envd_loadenv

  run envd_declare part-D
  test_ok_empty || stdfail A

  envd_declare part-D
  run envd_declared part-D
  test_ok_empty || stdfail B

  envd_declare part-A
  run envd_declared part-B
  test_ok_empty || stdfail C1
  run envd_declared part-C
  test_ok_empty || stdfail C2
}

@test "$base boot" {
  . ./test/var/bash/env-parts.sh
  envd_loadenv

  run envd_boot part-A
  test_ok_empty || stdfail A

  envd_boot part-A
  for part in part-{A,B,C,D}
  do 
    run envd_declared $part
    test_ok_empty || stdfail $part
  done
}
