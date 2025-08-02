# 0106 Coding style and Use of new Perl syntax

Date: 2025-08-01

## Status

Draft

## Context

A series of new syntax features have been added to Perl, with several more
scheduled for addition. To name a few:

- postfix dereference ($var->@* instead of @{ $var })
- function signatures (sub fun($x, $y) { ... } instead of sub fun { my ($x, $y) = @_; ... })
- isa operator ($x isa 'b' instead of eval { $x->isa('b') })
- try/catch (try {} catch ($err) {} finally {} instead of Try::Tiny)
- class/field/method class syntax (instead of 'use Moo'/'use Moose')
- any/all operators (instead of grep { ... } @ary)

In addition to these extensions of the 'core' Perl language, a large number of modules
have been developed by Paul Evans (PEVANS on CPAN) to further enhance the language:

- [Object::Pad](https://metacpan.org/dist/Object-Pad)
- [Sublike::Extended](https://metacpan.org/pod/Sublike::Extended)
- [Future::AsyncAwait](https://metacpan.org/pod/Future::AsyncAwait)
- [Object::Pad::Operator::Of](https://metacpan.org/pod/Object::Pad::Operator::Of)
- [Syntax::Keyword::Match](https://metacpan.org/pod/Syntax::Keyword::Match)
- [Syntax::Operator::In](https://metacpan.org/pod/Syntax::Operator::In)
- [Syntax::Operator::Eqr](https://metacpan.org/pod/Syntax::Operator::Eqr)
- [Syntax::Operator::Equ](https://metacpan.org/pod/Syntax::Operator::Equ)

A decision is required regarding which language features are to be used in the codebase. This
serves harmonization of the codebase.

Please note that the decision in this ADR complements the one taken in
[ADR 0102 - Perl pragma declarations on top of file](./0102-perl-pragmas-top-declarations.md).

## Decision

The following new builtin syntax is to be used for new modules:

- postfix dereference
- function signatures
- the isa operator
- try/catch

The function signatures functionality will be extended with named parameters using
Sublike::Extended. The set of operators will be extended using Syntax::Operator::In and
Syntax::Operator::Equ as well as Syntax::Keyword::Match.

The any/all operators will be adopted into the code base as soon as the minimum required
Perl version exceeds v5.40 (at the time of writing, the minimum is v5.36).

Existing modules should be developed in the style they already have, when applying minor changes. In
case of major change, modules should be modified to use these features.

The 'class' feature (and with it the Object::Pad(::*) modules) can't be used (yet): they are
incompatible with PGObject due to the way they store their field values.

Future::AsyncAwait does not apply to LedgerSMB's code base since it does not handle many requests on
a single thread (PSGI doesn't allow it). As such, there's no need to adopt it.

## Consequences

New modules should start with the following header:

```perl
use v5.x; # the latest minimum Perl version for the current release series
use warnings;
use experimental qw( signatures try );
use Sublike::Extended 0.29 'sub';
use Syntax::Keyword::Match; # if used by the module
use Syntax::Operator::In;   # if used by the module
use Syntax::Operator::Equ;  # if used by the module

package ...;

```

Additionally, function declarations in new modules should use signatures:

```perl
sub func1($x, $y = undef) { ... }
sub func2($u, :$v = undef) { ... }
```

## Annotations

