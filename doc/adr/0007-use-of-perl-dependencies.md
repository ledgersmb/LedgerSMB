# 0007 Use of Perl dependencies

Date: During development of 1.2

## Status

Accepted

## Summary

Addresses the design decisions regarding the acceptable use of Perl dependencies.

## Context

Historically, the code base has had no external Perl dependencies apart from
the [DBI](https://metacpan.org/pod/DBI) and [DBD::Pg](https://metacpan.org/pod/DBD::Pg)
modules.  This has the following benefits:

 * Easy installation (just download the tarball)
 * Very fast HTTP responses

Next to these advantages, the major disadvantage to consider is that the
CPAN library contains a lot of code that is both better tested, battle
tested, more standards compliant and foremost doesn't come with a maintenance
cost to the project.

## Decision

The project will use dependencies from CPAN to prevent inventing the wheel.

To mitigate the negative impact on installation complexity, the following criteria
need to be weighed when considering addition of a new dependency:

 * Availability of the dependency in distribution package repositories
 * Dependencies of the dependency overlapping as much as possible with
   existing dependencies (of dependencies) in the project
 * Maintenance cost of monitoring the dependency and the added installation
   complexity should outweigh the cost of maintaining the functionality in
   the project itself
 * Dependencies should be listed with the oldest version satisfying the
   project's requirements, allowing for the widest possible range of
   packaged versions to be installed from package repositories

## Consequences

- Trivial dependencies will not be added, because the cost of added installation
  complexity does not outweigh own development.
- Dependencies depending on core modules only are preferred over dependencies
  depending on other CPAN modules.
- Dependency minimum versions of Perl dependencies are only ever increased when
  their use is expanded or other dependencies become conflicting -- not when new
  versions become available.
