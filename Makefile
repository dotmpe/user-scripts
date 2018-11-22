BASH := $(shell which bash)
export SHELL=$(BASH)
export BASH_ENV=.htd/env.sh

MAKEFLAGS += --no-builtin-rules
#MAKEFLAGS += --no-builtin-variables
export scriptpath=$(shell pwd)
export package_build_tool=make


default: ; @echo "Targets: $$( tail -n +11 "Makefile" | sed 's/^\([^:]*\):.*/\1/g' | tr '\n' ' ')"

all: init check build test clean

%.tap: %.bats Makefile
	@bats "$<" | tee "$@" | ./tools/sh/bats-colorize.sh >&2

init:: ; @./.build.sh "$@"
check:: ; @./.build.sh "$@"
build:: ; @./.build.sh "$@"
baseline:: ; @./test/base.sh all
lint:: ; @./test/lint.sh all
units:: ; @./test/unit.sh all
specs:: ; @./test/spec.sh all
test:: ; @./.build.sh "$@"
clean:: ; @./.build.sh "$@"
