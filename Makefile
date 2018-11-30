BASH := $(shell which bash)
export SHELL=$(BASH)
export BASH_ENV=.htd/env.sh

MAKEFLAGS += --no-builtin-rules
#MAKEFLAGS += --no-builtin-variables
export package_build_tool=make
#export scriptname=$(shell echo $$scriptname):Makefile

default: ; @echo "Targets: $$( tail -n +22 "Makefile" | sed 's/^\([^:]*\):.*/\1/g' | tr '\n' ' ')"

all: init check build test clean

%.tap: %.bats Makefile
	@bats "$<" | tee "$@" | ./tools/sh/bats-colorize.sh >&2

build-%:: scriptname = $(shell echo "$$scriptname:make:$*")
build-%::
	@print_yellow "$(scriptname)" "Starting.."
	@scriptname=$(scriptname) ./.build.sh "$*"
	@print_green "$$scriptname" "OK"

init:: build-init check base
check:: build-check
base:: build-baselines
lint:: ; @./test/lint.sh all
units:: ; @./test/unit.sh all
specs:: ; @./test/spec.sh all
build:: build-check
test:: build-test
clean:: build-clean

negative: build-bats-negative
