# Docker.sh lib for User-Scripts

docker-sh-lib-load
                  Set some variables.

docker-sh-names
                  List names for running containers.

docker-sh-c CMD [Container-Id] [Args...]
                  Defer to ``docker-sh-c-CMD [Container-Id] [Args..]``

docker-sh-c-status [Container-Id]
                  Print label indicating current docker container state.

docker-sh-c-exists [Container-Id]
                  Call for status but void output, return error status whenever
                  container does not exist.

docker-sh-c-inspect Expr [Container-Id]

docker-sh-c-ip [Container-Id]
                  Inspect container for its IP address.

docker-sh-c-port [Container-Id] [22]
                  Inspect container for its exposed SSH port or given internal
                  port.

docker-sh-c-image-name [Container-Id]
                  Inspect container for its original image name.


[//]:             (Comment)
