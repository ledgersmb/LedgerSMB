# 0013 No use of Dancer(2) server side web framework

Date: During 1.6 development cycle

## Status

Accepted

## Summary

Addresses the design decision to not use Perl development frameworks
like Catalyst, Dancer, Mojolicious etc.

## Context

Perl has several well known web development frameworks with
Catalyst, Dancer and Mojolicious being the most well-known ones.

Of these, Dancer/Dancer2 is the one which advocates simplicity in
all its aspects.  It provides a Domain Specific Language (DSL) for
writing web applications in Perl modules, without loosing the taste
of Perl.  The Dancer DSL can be extended by loading extensions.  On
CPAN many of these are available for use.

Among the available extensions are those for [authentication](https://metacpan.org/search?q=dancer::plugin::auth::) and
[building REST APIs](https://metacpan.org/search?q=dancer::plugin::rest).
Consequently, Dancer(2) was an interesting target to research moving
the server-side development to.  Findings from this research were:

 * The REST modules available didn't add much towards creating a truely
   REST API; there were only entry-point handlers there -- which were
   not even true to the HTTP protocol, requiring an extension to indicate
   the desired return type (which must be dictated by the **Accept** headers,
   not the *extension*)
 * The main complexity in the server side handling of request data is
   *not* in the ability to generate a response, but instead in the complexity
   of translating the submitted data into comprehensive and coherent state
   representation of the state *in the client*
 * The `Dancer::Plugin::Auth::Extensible` toolchain assumes login pages need
   just the combination of 'username' and 'password', where LedgerSMB needs
   the name of the company being logged into as well
 * Dancer plugins are available for a wide range of functionalities to be
   used to simplify the core LedgerSMB code base; however, many of these
   exist as `Plack::Middleware` functionality too

## Decision

Although Dancer(2) looks like an compelling enhancement for LedgerSMB
development, we decide *not* to move to Dancer(2):  given that we're
on PSGI which comes with loads of "plugins" on CPAN and the fact that
the switch would not address the core complexity in LedgerSMB's Perl
code, the benefit looks small, despite an estimated huge cost of the
rewrite to take us there.

## Consequences


## Annotations
