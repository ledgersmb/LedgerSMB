# 0019 Configuration using Dependency Injection

Date: During 1.10 development cycle

## Status

Accepted

## Summary

Addresses the design decision to use Beam::Wire, dependency injection, YAML
for new configurations and deprecation of the INI configuration format.

## Context

Considering the project's slogan "Foundation for your business", users should
expect a great deal of flexibility to customize LedgerSMB.  Any configuration
mechanism plays a big part in providing that flexibility and hence should be
evaluated against this requirement.

Up to the time of this decision, LedgerSMB has used the INI file configuration
format, which succeeded the SQL Ledger configuration mechanism of using a Perl
source file.  The latter set global variables when evaluated.  Ideally, a
configuration mechanism is decoupled from the internal application.  Based on
this requirement, the SQL Ledger configuration mechanism needs to be rejected
as unsuitable.

The current configuration mechanism based on the INI file needs to be equally
rejected as unsuitable, because it allows to configure existing functionality
which was foreseen to require (small) variations at development time.  The
definition of customization (over configuration) is that the adjustments in
application behavior have *not* been foreseen at development time.  By
consequence, the code required to achieve the new application behavior
likely is not part of the standard application distribution.

[Dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) is
a design pattern which adds a high degree of freedom to load application
functionality at configuration time, in support of the requirements above.

Within the Perl ecosystem, multiple distributions support the concept of
dependency injection at configuration time.  Of the various options,
[Beam::Wire](https://metacpan.org/pod/Beam::Wire) has a balanced design
which supports loading the configuration from file (supporting various
formats).

## Decision

1. The configuration file will offer flexibility needed for customization
   by using dependency injection.
2. The [Beam::Wire](https://metacpan.org/pod/Beam::Wire) distribution will
   be used to transform the configuration into object instances
   which the code base uses at specifically identified extension points,
   such as an e-mail transport or generation of invoice documents.
3. The existing INI format will remain to be supported for the existing scope
   of functionality for the foreseeable future -- by generating the required
   input to make the dependency injection work.
4. New functionality will only be supported in a suitable new format for
   Beam::Wire.
5. The format of choice is YAML, because it is *the* mainstream format for
   hierarchical configuration data and is in use in an increasing number
   of use-cases such as GitHub Actions.


## Consequences

1. The current INI format configuration file will be replaced,
   because Beam::Wire needs a hierarchical format.
2. The code base needs carefully designed extension points for which the
   configuration file provides the implementation (with fixed APIs); natural
   candidates are functionalities which have a high likelihood of needing
   customization, such as document generators and bank statement importers.

## Annotations

See

* [0104 Business logic in Perl (revised)](./0104-business-logic-in-perl.md)
