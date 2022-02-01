# ChangeLog
Docs have their own *changes log* at <doc/ChangeLog.md>

## Prototype v0

### (0.0) [2018-08-24--]
- Initial tools all lacking, but found candidate for static Sh script analysis (Oil)
- Setup tooling skeleton for Travis and local with Makefile.
- Include wiki as submodule, means local vs. global URL conflict and obviously
  wiki has precedence. Maybe something to solve later, doc->wiki.
  But using file paths based on root-project in other source, outside docs/wiki repo.

#### (0.0.2)
- Lots of rework of tooling and attempt at deduplication across
  other +U_s projects, CI and other tooling setups. [2019-2020]
- But lost need for test/report, and already concluded neither `Bash` nor `redo` or any of the other build tools suffice for the problem except maybe `make`.

  However, instead have been working first at (and re-working) more elementary
  user-shell support in my own Composure repository and now in [+U-c][1]. [2022]

#### 0.0.1 [2018-12-15] 'lib-load'
- Initial release 'lib-load' so other repos can get testing.
