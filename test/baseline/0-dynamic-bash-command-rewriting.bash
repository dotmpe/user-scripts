# Interestingly, you do not want to rewrite running Bash script files.
#
# Copyright 2018-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
script=$(head -n 7 foo.bash)
cat > foo.bash <<<"$script
echo not okay at all"
echo all okay

# Id: dynamic-bash-command-rewriting             vim:set ft=bash sw=2 sts=2 et:
