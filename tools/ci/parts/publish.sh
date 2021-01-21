#!/usr/bin/env bash
# Pub/dist

# XXX: export publish_ts=$(epoch_microtime)
export publish_ts=$($gdate +%s.%N)
ci_stages="$ci_stages publish"

ci_announce "Starting ci:publish"

#echo "\
#--------------------------------------------------------------------------- env"
#env
#echo "\
#------------------------------------------------------------------------- local"
#set | grep '^[a-z0-9_]*='
#echo "\
#-------------------------------------------------------------------------------"

#lib_load git vc
## XXX: os-htd git-htd vc-htd
#test -e /srv/scm-git-local || {
#  sudo mkdir -vp /srv/scm-git-local/ || true
#  sudo chown travis /srv/scm-git-local || true
#}
#set -- "dotmpe/script-mpe"
#git_scm_find "$1" || {
#  git_scm_get "$SCM_VND" "$1" || return
#}

sh_include "report-times"

stage_cnt=$(echo $ci_stages | wc -w | awk '{print $1}')

echo TRAVIS_TEST_RESULT=${TRAVIS_TEST_RESULT-}

test "${CIRCLECI:-}" != "true" || mkdir -p ~/project/reports/junit
test "${SHIPPABLE:-}" != "true" || mkdir -p shippable/testresults

publish_tap ()
{
  tap-xunit --oneAssertionPerTestcase --outputToFailure --package "User-Scripts.$1"
}

test_pass= test_cnt=
echo 'assertions (suite, basename, passed/total):'
shopt -s nullglob
for x in $B/reports/*/*.tap
do
  suite=$(basename "$(dirname "$x")")
  bn=$(basename "$x" .tap )
  test "${CIRCLECI:-}" != "true" || {
    mkdir -p ~/project/reports/$suite
    publish_tap "$bn:$suite" < "$x" > ~/project/reports/$suite/$bn.xml
  }
  test "${SHIPPABLE:-}" != "true" || {
    publish_tap "$bn:$suite" < "$x" > shippable/testresults/$suite-$bn.xml
  }

  pass=$( grep -i '^OK' $x | wc -l ) || true
  fail=$( grep -i '^NOT OK' $x | wc -l ) || true
  total=$(( $pass + $fail )) || true
  echo $suite $bn $pass/$total
  test_pass=$(( $test_pass + $pass ))
  test_cnt=$(( $test_cnt + $total ))
done
shopt -u nullglob

ctx_if @Docker@Build || {
  return 0
}

echo "# job-nr build-status branch commit runtime stages pass-/total-steps pass-/total-reports #v0" | {
  test -e "$results_log" && cat || tee "$results_log"
}

ci_announce 'Adding results log-line'
echo "$JOB_NR $BUILD_STATUS $TRAVIS_BRANCH $TRAVIS_COMMIT $RUNTIME $stage_cnt $pass_cnt/$step_cnt ${test_pass:-0}/${test_cnt:-0} # $GIT_COMMIT_LINE" >>"$results_log"
ci_announce 'Last three results:'
tail -n 3 "$results_log" || true

lib_reload u_s-ledge u_s-dckr
test -z "${TRAVIS-}" || mv -v /tmp/docker-config.json $HOME/.docker/config.json
ledge_pushlogs

sh_include build-info

# Id: user-script/ tools/ci/parts/publish.sh
