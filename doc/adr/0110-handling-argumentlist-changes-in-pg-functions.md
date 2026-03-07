# 0110 Handling argumentlist changes in Pg functions

Date: 2026-03-07

## Status

Draft

## Summary

Addresses how to deal combine the requirement of having exactly one
version of each function when redefining a function with a different
argument list (as Pg supports simultaneous functions by
the same name with different argument lists).

## Context

One of the requirements for our object mapping frame work `PGObject` to
function, is to have exactly one definition for each function name: it
dynamically maps Perl object fields into the arguments of the function.
However, it can only do that if there is a single function definition.

As a consequence, all prior definitions with differing argument lists
need to be dropped when creating a new argument list variant for the
same function. Resulting in an accumulated total of 118 old function
definitions in the `sql/modules/` files function definitions being
dropped each time the function modules are being loaded. In addition,
the module definition files have accumulated a lot of clutter (drop
statements that are not relevant to the current implementations of
the module).

## Decision

Dropping deprecated functions, including functions with argument
lists that are no longer applicable, will be considered schema
evolution and dropping these functions will be done through a
schema change file in `sql/changes/`.

## Consequences

A one-off cleaning script will need to be generated to clear
all old DROP FUNCTION statements from the modules.

## Annotations

