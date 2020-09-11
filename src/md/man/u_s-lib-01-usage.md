% U-S(7) User-Scripts Manuals: main 'lib' user-library | User-Scripts/0.1-alpha

The main module to provide ``lib_load``

This has a bit of a chicken of the egg problem, in that we want to reuse routines
that we have not loaded yet.


is the first line of defense to deal
with the chicken-and-the-egg problem

the second is tools/sh/init\*sh
