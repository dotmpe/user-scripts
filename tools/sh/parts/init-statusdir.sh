#!/usr/bin/env bash

for d in ~/.statusdir ~/.statusdir/log ~/.statusdir/cache ~/.statusdir/tree ~/.statusdir/shell ~/.statusdir/index
do test -d $d || mkdir "$d"
done

# Id: U-S:
