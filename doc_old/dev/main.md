# Main Dev Doc

immediate objectives:

- record script body under ID (using some key/value store CLi client)
- record script executions (idem ditto)

* Bourne shell compatible dist.
  But building all dev/build components out of Bash, Dash compat.

## Status

- Initial project setup, slightly unorganized docs
- Code still in other repos, looking at dev and [ci] setup.

[ci]: /doc/dev/ci.md

## Overview

- [tasks](todo.txt), .done.txt
- ``test/*.sh`` to maintain project for now
- ``build/*.sh`` later for env init, profile
- ``src/sh`` for source probably
- ``dist/sh`` etc. perhaps

## Static analysis

### bashlex
idank/bashlex (Python, used by explainshell.com) was less than satisfactory on
larger routines and complex scripts

### shellcheck
shellcheck (Haskell) does a nice job, looks like I have not written anything it
could not parse. But what libs does it use and does it have an API to the AST.

<https://github.com/koalaman/shellcheck/blob/master/ShellCheck.cabal>
It does expose stuff but I don't know Haskell.

### bash-parser
another promising canidate was the NPM package bash-parser [2018-04-23] But
open issues are:

- Here-doc implementation <https://github.com/vorpaljs/bash-parser/issues/52>
- Sub-shell nesting ```dirname "$(dirname "$(dirname "$1")")"```

Need to learn Bison. If above issues are solved and I can see how then I think
other blocking issues would be minor.
