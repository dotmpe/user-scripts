# Spec Outline

sh / std-runner

TODO: sh-baseline

concept:

  while read varspec
  do
    while read cmdspec
    do
      eval $varspec$cmdspec
    done
  done

need indented reader first..

when combining varspec one edge case appears;
does the std-runner deal with var unset internally?
Or should we avail it of a proper 'clean' env.
I think it should manage that; would've used '\' but that requires escaping
with readline; find '/' more fitting, use as prefix to unset varname

/LOG
LOG=''
LOG=val




trying table; columns varspec, cmdspec; rules:

1. varspec is not required, empty cell no varspec; however cmdspec can also be
   empty, see 3.
2. cmdspec is required, empty cell uses previous non-empty cell above

3. varspec indents to add to previous value;
   need a metavalue keyword to indicate empty varspec, using '=' now.

4. skip empty lines or unixy comment/preproc lines



### outline rules
- each outline node represents a varspec part;
- the leafs; the final nodes or lists are all cmdspec(s).

- During denormalization each outline node is read until a leaf is found;
  the result is output as ``$varspec$cmdspec``.

- Leaf nodes should not be terminated, ie. no trailing ';'.

- Denormalization encomasses merging all previous (or root-ward) varspecs.

- Unterminated varspecs generate two testcases: one with and one without.

- Unterminated varspecs are concatenated after concatening all terminated
  varspecs.

This should help in building test matrices.

Iow. the level at and above an unterminated varspec node is not listed by
itself during denormalization. But at and below two cases are generated
for each true varspec node in the outline. "non-true" or pure varspec nodes
are script segments prepended to


- Var nodes are terminated automatically, unless they match
  ``^[A-Za-z_][A-Za-z0-9_]=.*``.


So varspecs can contain ``unset <var>`` or any other shell script part. But
only variable assignments are aggregated and concatenated as the local-env
prefix for the command line.

Order does not matter.

If they are explicitly terminated, they are treated the same. But a second
case with no value will be added to the cartesian set as well.


unset x;
  y=b
    ..

  y=a
    ..
