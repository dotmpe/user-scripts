# User Scripts [![](http://img.shields.io/travis/bvberkum/user-scripts.svg)](https://travis-ci.org/bvberkum/user-scripts) ![repo license](https://img.shields.io/github/license/bvberkum/user-scripts.svg) ![commits per year](https://img.shields.io/github/commit-activity/y/bvberkum/user-scripts.svg) ![code size](https://img.shields.io/github/languages/code-size/bvberkum/user-scripts.svg) ![repo size](https://img.shields.io/github/repo-size/bvberkum/user-scripts.svg)

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

```sh
U_S=/src/github.com/bvberkum/user-script

# Load into current shell
scriptpath=$U_S/src/sh . $U_S/tools/init.sh

# Or with init-here helper command (ie. local script file)
$scriptpath/tools/sh/init-here.sh /src "lib_load <my_lib> && ..."

# Or with here-doc
$scriptpath/tools/sh/init-here.sh /src "$(cat <<EOM

  lib_load <my_lib>

  ...

EOM
)"
```

### Status

- Experimental project setup, but Sh library should work as advertized.
- Secondary objectives being setup, 

### Sections

- [Docs](doc) ([Wiki](https://github.com/bvberkum/user-scripts/wiki))
- [Dev-Docs](wiki/dev/main)
- [ChangeLog](CHANGELOG.md)

Version: 0.0

* [AGPL-3.0](COPYING)

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

