# 0023 An administrative Command Line Interface (CLI)

Date: 2020-11-14

## Status

Accepted

## Summary

Addresses the design decision for scripting use-cases using the `ledgersmb-admin`
command line application, its environment variables, and its YAML configuration.

## Context

In order to support scripting use-cases, LedgerSMB needs a CLI application.
Such an application will benefit multiple scenarios:

 1. Perform admin tasks while 'setup.pl' access is disabled
 2. Automate repeated test setup tasks for developers

The resulting application should take from `git` and `docker` for the way
its arguments are interpreted, because that's what developers and power users
are accustomed to:

```plain
ledgersmb-admin [<global-options>] <command> [<options>] <sub-command> [<more options>]
```

## Decision

LedgerSMB will offer much of its (administrative) functionality through
a command line interface application called `ledgersmb-admin`, which is
intended to run on the same server as the LedgerSMB server application
(thus giving it access to the same configuration and customization).

## Consequences

 1. Functionality at the Perl level must be coded into modules usable
    from both the web and cli applications (so as to prevent implementing
    functionality twice)
 2. A configuration mechanism must be put in place to allow efficient
    command line use against the same server, repeatedly
 3. Further investigation is required with respect to the configuration
    of workflows and their use in the command line client (as opposed to
    being used from the server)

### Configuration


The tool resolves configuration (e.g. which postgresql server to connect
to) in the following order (in descending priority):

* Command line
* Configuration file
  * ./.ledgersmb-admin.yaml
  * ~/.ledgersmb-admin.yaml
  * /usr/local/etc/ledgersmb-admin.yaml
  * /etc/ledgersmb-admin.yaml
* Environment variables (`PG*`)

There is full support for `libpq`'s configuration files `./.pg_pass`,
`~/.pg_pass`, `~/.pg_service.conf` and `$PGSYSCONFDIR/pg_service.conf`.


## Annotations

This document is a conversion from the Wiki page formerly published on
https://github.com/ledgersmb/LedgerSMB/wiki/ledgersmb-admin.