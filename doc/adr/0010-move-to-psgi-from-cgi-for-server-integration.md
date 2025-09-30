# 0010 Move to PSGI from CGI for web server integration

Date: October 2014, as-of 1.3.45

## Status

Accepted

## Summary

Addresses the design decision to move from CGI to PSGI for web server
integration.

## Context

With the growing popularity of webservers that do not natively "speak"
CGI, the project needs to provide a wider range of options to integrate.
PSGI supports:

 * CGI
 * FastCGI
 * mod_perl
 * Various Perl-based HTTP servers

At the same time, response generation is significantly slower for version
1.3 than it ever was for earlier versions, due to longer load-times of the
scripts.  For the most part this longer load-time is attributed to the use
of more dependencies as well as the use of technology which is 'compilation
heavy' (runs fast, but loads slow -- Template::Toolkit and Moose are big
factors in this).

The desire to support e.g. FastCGI and the desire to pre-load large parts
of the code base, both fuel the desire for a long-running process.

Additional benefit of PSGI is that response handling can be modified and/or
enhanced through the use of so called "middleware": Perl code that can
modify or intercept request processing by wrapping the actual LedgerSMB
handler.  This allows for (better) separation of concerns and decomposition.

Although PSGI provides the same request parameters using the same field
identifiers as CGI, it provides them in a different variable ($env instead
of %ENV).  The impact on response handling is much bigger: instead of
writing the response to STDOUT, the response needs to be returned as a
3-element array with the body being the third element of the array.

Complicating matter in this transition is the fact that the inherited code
scripts (old/bin/??.pl) use global state extensively and have proven not to
be able to cope with more than a single request on a given Perl interpreter
instance.

## Decision

Server integration will use [PSGI](https://metacpan.org/pod/PSGI) to realize
a long-running (pre-loaded) process to serve FastCGI, mod_perl and HTTP-based
web application integration.

The following [PSGI extensions](https://metacpan.org/dist/PSGI/view/PSGI/Extensions.pod)
may be assumed to be available:

 * psgix.logger
 * psgix.session

## Consequences

- During a transition period, STDOUT must be captured and transformed into
  the 3-element PSGI-array for code that hasn't been rewritten to directly
  return PSGI responses.  The codebase will use CGI::Emulate::PSGI for this.
- Execution of 'old code' needs to take place in a `fork()`-ed process with
  the invoker reading the results (CGI results, presumably) from STDIN, waiting
  for the forked process to complete before continuing its own execution.
- Although PSGI supports CGI deployments, it's not possible to achieve long
  running processes with it.  The code base will not target startup performance
  required for acceptable use with CGI.
