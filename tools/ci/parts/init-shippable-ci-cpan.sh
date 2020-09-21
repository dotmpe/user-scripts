#!/usr/bin/env bash

not_falseish "$SHIPPABLE" && {
  cpan reload index
  cpan install CAPN
  cpan reload cpan
  cpan install XML::Generator
  test -x "$(which tap-to-junit-xml)" ||
    basher install jmason/tap-to-junit-xml
  tap-to-junit-xml --help || true
}
