# User Scripts [![](http://img.shields.io/travis/dotmpe/user-scripts/master.svg)](https://travis-ci.org/dotmpe/user-scripts) ![repo license](https://img.shields.io/github/license/dotmpe/user-scripts.svg) ![commits per year](https://img.shields.io/github/commit-activity/y/dotmpe/user-scripts.svg) ![code size](https://img.shields.io/github/languages/code-size/dotmpe/user-scripts.svg) ![repo size](https://img.shields.io/github/repo-size/dotmpe/user-scripts.svg)

> every complex working system started out simple -- Gall's Law

[//]: # 'Principles of System Design, John Gall http://www.principles-wiki.net/principles:gall_s_law'


Bourne shell compatible scripts in various modules, and a method for loading
modules.

### Usage

Use the ``lib_load`` function to source ``<my_lib>.lib.sh`` found anywhere on ``SCRIPTPATH``.

```sh
scriptpath=$PWD . ./tools/init.sh
lib_load <my_lib>
```

If function ``<my_lib>_load`` exists it is executed after source.

These and following ``tools/sh/*.sh`` scripts provide entry-points for basic
setups, see XXX: tooling ref
and  [libv0:lib_load](/doc/src/lib#v0:lib_load) docs.

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

```sh
U_S=/src/github.com/dotmpe/user-script

# Load into current shell
scriptpath=$U_S/src/sh/lib . $U_S/tools/init.sh

# Or with init-here helper command (ie. local script file)
$scriptpath/tools/sh/init-here.sh $PWD/lib:$U_s/src/sh/lib "lib_load <my_lib> && ..."

# Or with here-doc
$scriptpath/tools/sh/init-here.sh $ "$(cat <<EOM

  lib_load <my_lib>

  ...

EOM
)"
```

### Status

Released `lib_load` and some other routines for testing in the field. 

- Experimental project setup, moving over libs and porting tests.
  ``lib_load`` works and some libs may.
- Secondary objectives regard shell/project tooling. See dev docs.

Version: 0.0

* [AGPL-3.0](COPYING)

### Sections

- [Docs](doc) ([Wiki](https://github.com/dotmpe/user-scripts/wiki))
- [Dev-Docs](wiki/dev/main)
- [ChangeLog](CHANGELOG.md)

### Hacking

#### Install (for dev & test only)

```sh
redo init
# or
make init
# or
./.build.sh init
```

#### Testing

```sh
redo test
# or
make test
# or
./.build.sh test
```
