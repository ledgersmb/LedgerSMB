# 0101 Perl pragma declarations on top of file

Date: 2025-01-03

## Status

Draft

## Context

The `use` statement in Perl is used for two distinct purposes. The most
straight forward being loading of dependency modules (e.g., `use LedgerSMB;`).
The other purpose is to enable "pragmas" (e.g. `use strict;`); these change
Perl's behaviour in the scope in which they are declared.

Traditionally, Perl pragmas have been declared after the opening `package`
line in a module; like this:

```perl
package LedgerSMB::PGDate;

use Moose;

use strict;
use warnings;

...

1;
```

In recent years, syntax was added to Perl which depends on the correct pragmas
to be enabled (or on older Perls compatibility modules to be loaded); e.g.:

```perl
use v5.40;

class LedgerSMB::PGDate {
   ...
}
```

## Decision

1. Pragmas such as `utf8`, `warnings`, `strict`, `vX.YY` (minimum Perl version
   requirement declaration) should be declared
   *before* the first line of of code (e.g. the `package` declaration)
2. Modules which modify or enhance syntax, such as `Syntax::*`, `Feature::Compat::*`
   and `Object::Pad`, should be declared *after* the pragmas and before the
   `package` or `class` declarations
3. All regular module dependencies need to be declared *after* the `package`
   declaration
4. All code in `lib/`, `t/` and `xt/` must declare the minimum Perl version using
   the `vX.YY` syntax.

## Consequences



## Annotations

