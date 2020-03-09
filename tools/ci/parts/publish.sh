#!/usr/bin/env bash
# Pub/dist

# XXX: export publish_ts=$(epoch_microtime)
export publish_ts=$($gdate +%s.%N)
ci_stages="$ci_stages publish"

ci_announce "Starting ci:publish"

lib_load git vc
# XXX: os-htd git-htd vc-htd
test -e /srv/scm-git-local || {
  sudo mkdir -vp /srv/scm-git-local/ || true
  sudo chown travis /srv/scm-git-local || true
}

#set -- "dotmpe/script-mpe"
#git_scm_find "$1" || {
#  git_scm_get "$SCM_VND" "$1" || return
#}

sh_include "report-times"

test_pass= test_cnt=
echo 'assertions:'
for x in $B/reports/*/*.tap
do
  suite=$(basename "$(dirname "$x")")
  bn=$(basename "$x" .tap )
  pass=$( grep -i '^OK' $x | wc -l ) || true
  fail=$( grep -i '^NOT OK' $x | wc -l ) || true
  total=$(( $pass + $fail )) || true
  echo $suite $bn $pass/$total
  test_pass=$(( $test_pass + $pass ))
  test_cnt=$(( $test_cnt + $total ))
done

stage_cnt=$(echo $ci_stages | wc -w | awk '{print $1}')

echo "# timer-start job-nr branch commit runtime stages pass-/total-steps pass-/total-reports #v0"
echo "$TRAVIS_TIMER_START_TIME $TRAVIS_JOB_NUMBER $TRAVIS_BRANCH $TRAVIS_COMMIT $RUNTIME $stage_cnt $pass_cnt/$step_cnt $test_pass/$test_cnt # $GIT_COMMIT_LINE" | tee -a $results_log

ci_announce 'Last three results:'
tail -n 3 "$results_log" || true

mv /tmp/docker-config.json $HOME/.docker/config.json
ledge_pushlogs

sh_include build-info

# Id: user-script/ tools/ci/parts/publish.sh
