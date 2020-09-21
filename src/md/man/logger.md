This merges old mkdoc:
```
    log header-type targets description sources
```

and stderr
```
    ( log level | error | warn | note | info | debug ) msg [ exit status ]
```

logger_log(line_type, target_ids, description, source_ids, status_code)
: Iterates ``logger_${hook}`` for `hook` in `logger-log-hooks`.

  This is meant to establish a common signature, compatible with ``$LOG``,
  and suitable for sorting into various channels. But only if desired.

  The standard user script setup is not to setup log output but readable
  work output.

    unless status-code < verbosity
    do write pretty stderr line


Level name-number mapping is needed to observe verbosity settings.

1. emerg
2. crit
3. error
4. warn
5. note
6. info
7. debug

Two Verbosity threshold settings cause to ignore below a value and to exit
above a certain value resp. Setting a ret-stat exits regardless.

Besides standard syslog levels, other messages should be passed to `$LOG`.
But besides verbositoy handling, templating also can only be done for a
predefined set.

In a test-harnass, the following are useful steps. Most generic first:

1. OK, test or task passed.
2. Not OK, test or task step failed one or more assertions.
3. Errored, test or task step raised an unexpected state.

4. Skipped, test or task step skipped as per settings or request.
5. Aborted, test or task step bailed out unexpectedly and ended further steps.

Maybe a combined line-type tag/number line-type offers the best solution.
Also, some dynamic env based on current verbosity and other preferenes.

$abort   $v = $exit-lvl     The level at which processing aborts
$error   $v = $echo-lvl +2  The level for errors and increased risk, unless taken care of (ie. test-harnass)
$warn    $v = $echo-lvl +1  The level for warnins but little increased risk.
$notice  $v = $echo-lvl     The level at which a line is output for user view
$info    $v = $echo-lvl -1  Hidden, the level at which a line is output for machine 'view' (ie. log or MQ)
$debug   $v = $echo-lvl -2  Other hidden and below

TODO: in case have time to play more with log, templates etc. For now hardcoded
preference into logger.lib:

- $notice.1 OK
- $warn.2 Fail
- $abort.3 Err
- $info.4 Skip
- $crit.5 Bail
