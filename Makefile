default: ; @echo "Targets: $$(sed 's/^\([^:]*\):.*/\1/g' Makefile|tr '\n' ' ')"
all: init check build test
init:: ; . .build/init.sh
check:: ; . .build/check.sh
build::
test:: ; . .build/ci.sh
