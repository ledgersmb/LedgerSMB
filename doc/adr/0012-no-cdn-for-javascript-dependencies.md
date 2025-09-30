# 0012 No use of CDNs for JavaScript dependencies

Date: During 1.3 release cycle (when adding Scriptaculous)

## Status

Accepted

## Summary

Addresses the design decisions to include all dependencies for JavaScript, 
images, CSS, etc. in the LedgerSMB distribution and to not use Content 
Distribution Networks for any browser related resources.

## Context

Content Distribution Networks (short: CDNs) are in wide use for serving
JavaScript dependencies, such as Dojo Toolkit.  Their purpose is both
ease of distribution of the web applications which depend on it as well
as a promise of better performance (because the same assets might be
cached for a single user across multiple domains). LedgerSMB depends on
Dojo Toolkit, so could benefit from a CDN.

LedgerSMB is an accounting application or ERP, keeping restricted data
for its users.  To protect their information, users of the system may
want to host it in a secured environment without external network
connectivity (so called "airgapped" setups).  We want to support even
these most strict use-cases for LedgerSMB.

CDNs - even if not *easy* targets - could be very **interesting** targets
for criminals to infect; after all, the impact will be tremendous.
Self-hosted installations are far less attractive, with only minor
returns, compared to the impact of CDNs.

Due to their nature, with multiple sites including CDN resources, a
CDN may be able to "see" users move from one site to another, collecting
statistics and user data in the process.

## Decision

LedgerSMB will *not* use CDNs for the distribution of its JavaScript
dependencies, because:

 * Access to these externally hosted resources cannot be guaranteed
 * Uncontrolled resources are a bigger security risk than local ones
 * CDNs can be used to collect data about the users visiting sites
   including them

## Consequences

- All JavaScript, image and CSS dependencies need to be included in
  some shape or form in the distribution tarball.
- All HTML dependencies need to be loaded from the same URL as the
  main application.
- The project does not benefit from any optimizing transformations that
  have been applied by the CDN networks -- will need to apply its
  own page load optimizations.
