#!/usr/bin/env bash

ctx_if "@Docker@Build" || return 0

log_name init-docker-cache
sh_require env-docker-hub

ci_announce 'Initializing for build-stats and statusdir-cache'

ci_announce "Logging into docker hub '$DOCKER_USERNAME'"
# NOTE: use stdin to prevent user re-prompt; but cancel build on failure
echo "$DOCKER_PASSWORD" | \
  ${dckr_pref-}docker login --username $DOCKER_USERNAME --password-stdin || exit $?

sh_include env-docker-cache
lib_require u_s-dckr u_s-ledge

ci_announce "Looking for image at hub..."
ledge_exists && {
  ci_announce "Found image, extracting build log."
  ledge_refreshlogs || return

  ci_announce 'Retrieved logs'
}

test -s "$builds_log" && {
  ci_announce "Existing builds log found, last three logs (of $(wc -l "$builds_log"|awk '{print $1}')) where:"
  read_nix_style_file "$builds_log" | tail -n 3
} ||
  ci_announce "No existing builds log found"

# TODO: gather results into log uid:Jn7E
test -s "$results_log" && {
  ci_announce "Existing results log found; last three logs (of $(wc -l "$results_log"|awk '{print $1}')) where:"
  read_nix_style_file "$results_log" | tail -n 3
} ||
  ci_announce "No existing results log found"


echo "# timer-start job-nr build-status branch commit runtime stages pass-/total-steps pass-/total-reports #v0" | {
  test -e "$builds_log" && cat || tee "$builds_log"
}

test -n "${JOB_NR-}" || {

  last_local_buildnr=$(grep "$HOST-[0-9]\+ " "$builds_log" | cut -d' ' -f3  | tr -dC '0-9\n'| sort -n | tail -n1)

  test -n "$last_local_buildnr" && {
    JOB_NR=$HOST-$(echo $last_local_buildnr + 1 | bc)
  } || {
    JOB_NR=$HOST-1
  }
  echo JOB_NR: $JOB_NR
}

# Add new build-announce log line

printf '%s %s %s %s %s %s\n' "${ci_env_1_ts//./}" \
 "${TRAVIS_JOB_ID:-"-"}" \
 "$JOB_NR" \
 "$BRANCH_NAME" \
 "$COMMIT_RANGE" \
 "$BUILD_ID" >>"$builds_log"
ci_announce 'New builds log:'
tail -n 1 "$builds_log"
wc -l "$builds_log" || true

test ${announce:-0} -eq 0 || {

  ledge_pushlogs
}
