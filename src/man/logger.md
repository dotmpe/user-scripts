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


