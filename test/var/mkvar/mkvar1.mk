#!/usr/bin/env make

# 1. Normal make macro definition
#
TPL_1 = MACRO

# 2. Make simple expanded definition ':' (POSIX ::=)
#
TPL_2 := EXPANDED

# 3. "Default assignment", conditional based on dest-var
#
TPL_3 ?= CONDITIONAL_MACR

# 4. "Append" modifier: add expression to existing macro
#
TPL_4 += APPEND_MACRO # RIGHT ADD


# TPL4b -= REMOVE MACRO?
#
TPL4c -= REMOVE_~

TPL4b ++= INSERT_~ # LEFT ADD MACRO

#TPL8a %%= LEFT-CONCAT-SEMI
#TPL8b %= RIGHT-CONCAT-SEMO
#TPL8a %%:= LEFT-CONCAT-SEMI
#TPL8b %:= RIGHT-CONCAT-SEMO
#TPL8b -:= RIGHT-CONCAT-SEMO


# 5. Shell expression with make macro: '!'
#
# Command output (or error?)
TPL_5 != CMDOUT


# 6. File paths with make macro
#
# File path if exists
# File path if non-zero
# File contents
#
TPL_6 @


# Plenty of service protocols and possible heuristics for other macros,
# only some characters left for sytax sugar. Maybe. Don't touch the others.

TPL_01 ,
TPL_02 .
TPL_03 ;
TPL_04 >
TPL_05 <
TPL_06 ^
TPL_07 $
TPL_08 &
TPL_09 |

#      ' " `
# / ( [ { } ] ) \
