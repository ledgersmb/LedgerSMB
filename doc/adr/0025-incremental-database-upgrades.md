# 0025 Mechanism for incremental database upgrades

Date: 2016-02-18 (during 1.5 release cycle)

## Status

Accepted

## Summary

Addresses the design decision regarding the database upgrade process.

## Context

Database migration from 1.x to 1.3 and from 1.3 to 1.4 involved "full schema
migrations": the existing schema would be moved out of the way, allowing the
new schema to be loaded.  After that happened, all data was copied from the
existing schema to the new one.  Each new minor version required the
development of a completely new migration. This turned out to be a very error
prone and fragile approach, because the new schema included new constraints
which needed to be retroactively identified and catered for.

Additionally, patch upgrades were handled using the `Fixes.sql` module: a
pseudo module which loaded all changes to the schema every time the modules
were reloaded.  Sometimes these changes had already been applied to the base
schema as well.  This included all changes that already had been applied; the
approach turned out to be highly confusing for users monitoring their database
logs during the loading process: it caused tons of error messages to scroll by.

Many hours have been spent chatting on #ledgersmb to identify/explain the
*actual* upgrade problem(s).

### Requirements to a solution

LedgerSMB needs a database schema upgrade system which takes the following
in mind:

* Data must be validated to be compliant with the fix before
  applying the fix
* The user must be offered the opportunity to fix their data, if possible;
  other feedback must be provided otherwise
* Upgrades will be applied only once
* Upgrades will be applied in a specific (deterministic) order
* When upgrading from 1.x to 1.y, all "missing" upgrades will be executed

The use-case for the last point can be demonstrated more specifically by
considering the case where a bugfix is being backported from master through
1.y.21 all the way back to 1.x.37. Now, when a schema evolves along the 1.x
line just past the point where the bugfix has been applied (1.x.37), then the
upgrade should *not* be applied when the schema will be upgraded from 1.x.37
to 1.y.28. Other schema upgrades such as the key "minor version" differences
(differences between 1.x.0 and 1.y.0) should still be applied.

#### Requirements for data validation infrastructure

* Data validations should be changeable after release: user feedback may
  require additional checks and balances to be implemented
* Multiple data validations may be associated with a single schema change
* Schema changes must be absolutely frozen after their initial release
* Possible resolution actions are
  * Provide replacement data (in case of e.g. duplicates detected)
  * Allow deletion of data (in case of e.g. `NULL` or zero values in amounts)
  * Allow insertion of additional data (in case of failing `REFERENCES`
    foreign keys where enough data is available to retroactively fit the data)
  * Allow insertion of additional data in a specific table (regardless of the
    data being verified/updated)
* Multiple alternatives may be offered to the user
* Sufficient information is included for the user to be able to understand
  what information is being presented, including drop-downs-with-descriptions
  for foreign keys on `id` values -- sufficient means that a web-app should be
  able to generate a comprehensible grid from the data
* Feedback and resolution mechanisms __must__ not assume a web application
  context (schema upgrades may be triggered from command line applications)
* Data validations can stop the application process in order to ask the user
  for feedback asynchronously
* Data validations can be provided with "all the answers" in advance
* The change application process can be repeated / restarted after the user
  completes the asynchronous feedback process
* Data validations are to be executed *only* when the related change will be
  executed

To explain the last point:
1. To execute all data validations for changes ever applied, the upgrade
   process execution time would be ever-increasing
2. Data validations for changes having been long applied may depend on schema
   elements which themselves changed in follow-up changes (or even -likely- in
   the change itself), making repeated execution impossible

Note that data validations only serve the purpose that the user can squash
the data in a way that the change script can be successfully applied: they
are not consistency checks for the data in the database.

## Decision

LedgerSMB needs a system to upgrade its database schema based on small
upgrade steps for which the complexity is low so data can be verified to
be compliant with the new schema *or* a UI can be offered allowing the
user to fix the data.

## Consequences

The following solution needs to be implemented.

### The solution (DDL scripts)

The system groups related changes into SQL scripts -one per change- which are
stored in the `sql/changes/` directory. The specific load order is determined
by the order in which the scripts are enumerated in the file
`sql/changes/LOADORDER`.

Each SQL script is atomically considered applied or failed. (With the
notable point that scripts can be marked as "failure should be ignored".)

Once a change-file has been applied, its MD5-hash is calculated and the
successful application is registered in the schema. Upon further iterations
of applying change files, the MD5s are being compared against those of the
eligible changes. When an MD5 matches, the change file is not applied under
the assumption that it has already been applied.

Under this scheme, it's of vital importance that the change files **do not**
get edited once they have been published (in any way that a production
database may be affected. This includes on any non-released branch such as
1.5 or master).

**NOTE**: A mechanism was devised to allow releasing fixes to the scripts,
taking into account that the scripts may already have run successfully in
some installations.

### The solution (data validations)

The solution consists of several components:

1. The change application driver
2. The schema changes themselves
3. The schema change data-pre-validations
4. The schema data-pre-validation failed data handler
5. The UI handler (renderer)

The first two (change application driver and schema changes) are existing
components. The first will need to be adapted to accommodate the requirements;
the second will need to be enhanced with data-pre-validations, where
applicable.

The other components are new and need their full design specified below.

#### Specifying data-pre-validations

Data-pre-validations will be specified in files named like the schema change
itself, with the additional extension `.pre.<number>.pl`; e.g. with a change
named `sql/changes/1.5/parts_fkeys.sql` the two associated data pre
validations will be:

* `sql/changes/1.5/parts_fkeys.sql.1.pl`; and
* `sql/changes/1.5/parts_fkeys.sql.2.pl`

Each of these files contains commands for a small DSL:

```perl

summary "The validation of ...";
description qq|
   Part of the validations which ...
   and which ...
|;

validation_query qq|
   SELECT ...
|;

on_failure {
   my ($dbh, $renderer, $failed_rows) = @_;

   my @data_map = $dbh->do(qq|SELECT something, something FROM somewhere|);
   $renderer->results_table(1, $failed_rows);
   $renderer->key(['col1', 'col2']);  # composed key
   $renderer->columns(['col1', 'col2', ...]); # headings, types, etc.
   $renderer->editable('col2', type => 'dropdown', values => \@data_map);
   $renderer->rows_deletable(1);
   $renderer->rows_insertable(0);

   $renderer->results_table(2, []);
   $renderer->columns(...);
   $renderer->rows_insertable(1);

   my $response = $renderer->get_response;

   # early exit if we're waiting for a user response
   # this may be used to defer responding like in a request/reponse
   # cycle in the web browser
   return undef unless defined $response;

   for my $row (@{$response->table_rows(2)}) {
      $dbh->do(qq|INSERT INTO here (col1, col2) VALUES (?, ?)|, {}, @$row);
   }

   for my $update (@{$response->table_rows(1)}) {
      $dbh->do(qq|UPDATE ...|, {}, @$update);
   }

   return 1;
};
```

#### Failed data-pre-validation handler

The data-pre-validation failure handler is specified as part of the
data-pre-validation specification, as indicated above. The failure handler
is a closure (function) of three parameters: a database handle connected to
the company database being validated, a renderer object responsible for
communicating with the user and a reference to an array containing the
failing rows.

The failure handler is responsible for indicating to the renderer which rows
should be rendered (and how), if rows are deletable and/or whether rows are
insertable. Or if additional tables should be rendered in order to insert
data into different tables (e.g. to fix referential integrity by inserting
the 'referred to' items).

Once the failure handler finishes to indicate what input is requested from
the user, it indicates so by calling 'get_response', which returns a response
object *or* `undef` in case a response is not available at this point and
will be available later (e.g. in later web-requests). An action the renderer
has taken when returning undef could be to send a response page to the web
client. After submission by that client, the process could start, this time
*with* a provided response. On this second time around, the renderer would
not actually send the response page to the client, but instead return a
`$response` instance in response to the `get_response` call.

#### The UI handler (renderer) API

The main purpose of the renderer API is to separate concerns between the
failure handler which indicates which feedback is to be collected from the
user and what information should be available to the user in order to collect
that feedback (column names, types, content editability, etc) from the actual
presentation of the data on the screen.

There are three types of presentations envisioned at this time:

* The web UI which most users will want to use
* An (as of yet non-existing) terminal (curses) client
* A command-line application with no actual UI -- which has the expected
  answers readily available from configuration

The renderer has the following API methods:

* `get_response()`  
  Marks the end of the rendering preparation phase; hands over control to the
  renderer to ask the user for feedback
* `results_table(N, \@rows, \%columns, rows_deletable => 1, rows_insertable => 1, key => ['col1','col2',...])`  
  Provides the renderer with the results of the validation to be presented as "Table number N"  
  Note: For the `rows_insertable` option to work, all required columns in the
  table being mapped to must be shown in the rendered table so the user is
  able to provide these required inputs

The `$response` instance returned by `get_response()` has the following methods:



## Annotations

Note that this document moves an existing description of the upgrade
system design from the wiki into the ADR repository.