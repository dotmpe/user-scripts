# User Scripts [![](http://img.shields.io/travis/bvberkum/user-scripts.svg)](https://travis-ci.org/bvberkum/user-scripts) ![repo license](https://img.shields.io/github/license/bvberkum/user-scripts.svg) ![commits per year](https://img.shields.io/github/commit-activity/y/bvberkum/user-scripts.svg) ![code size](https://img.shields.io/github/languages/code-size/bvberkum/user-scripts.svg) ![repo size](https://img.shields.io/github/repo-size/bvberkum/user-scripts.svg)

Bourne shell compatible scripts in various modules, and a method for loading
modules.


### Usage

Use the ``lib_load`` function to source ``<my_lib>.lib.sh`` found anywhere on ``SCRIPTPATH``:
```sh
lib_load <my_lib>
```

If function ``<my_lib>_load`` exists it is executed directly after sourcing.

Set and export SCRIPTPATH for a script environment with ``init.sh``:
```
scriptpath=$PWD . ./tools/sh/init.sh
lib_load <my_lib>
```
or set from master/for dev:
```
test -e ./tools/sh/init.sh ||
  curl -sSO https://github.com/user-tools/user-scripts/blob/master/tools/sh/init-gh.sh | sh -
scriptpath=$PWD . ./tools/sh/init.sh
```
A predefined set of modules is loaded.


### Status
Released `lib_load` and some other routines for testing in the field. All other commits on 0.0 dev line (branch ``r0.0``).


Version: 0.0.1

* [AGPL-3.0](COPYING)

