# User-Scripts `dckr` commands support lib

Depends on docker-sh and FIXME: docker-sh-htd.


`u_s-dckr` contains routines for these `u-s` subocmmands:

dckr [CMD ARG...]
                  Execue U-S sub-command in container

dckr-init         Create docker container

dckr-reset        Delete docker container

dckr-req          ...

dckr-exec

dckr-shell CMD    Execute login shell at U-S dir

dckr-cmd CMD      Execute inline command with dckr-shell

dckr-cmd make [init|check|base|lint|units|specs|build|test|clean]

dckr-list         List running container names.

dckr-update

Internal: these can be called but should have no observable action.

dckr-lib-load     Set env.
dckr-load         Load env, can be used to test script bootstrap is working.


[//]:             (Comment)
