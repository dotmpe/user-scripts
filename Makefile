default: ; @echo "Targets: $$(sed 's/^\([^:]*\):.*/\1/g' Makefile|tr '\n' ' ')"
all: init check build test
init check build test:: ; ./.build.sh "$@"
