# LedgerSMB ADR (Architecture Decision Records) Index

| ADR Link | Status | Summary |
|-----|------|---------|
| [0000](./0000-use-of-architecture-decision-records.md) | Accepted | Addresses the design decision to use ADRs to describe  most important decisions that impact the structure and future direction of the code base.  |
| [0001](./0001-database-restricted-to-postgresql.md) | Accepted | Addresses the design decision to use PostgreSQL instead of other  relational database systems. |
| [0002](./0002-database-consistency-procedural-api.md) | Accepted | Addresses the design decision for assuring database consistency independently of any application accessing the database. |
| [0003](./0003-use-database-for-authn.md) | Accepted | Addresses the design decision to use database roles as the  authentication provider for the LedgerSMB application. |
| [0004](./0004-use-database-for-authz.md) | Accepted | Addresses the design decision to use fine grained access rights in the the form of PostgreSQL roles for authorization in the LedgerSMB application. |
| [0005](./0005-business-logic-in-database-and-UI-in-Perl.md) | Accepted | Addresses the design decisions regarding the role of the Perl layer versus the database layer, web server and web browser. |
| [0006](./0006-perl-ui-uses-template-toolkit.md) | Accepted | Address the design decision regarding which template toolkit will be used to generate UI. |
| [0007](./0007-use-of-perl-dependencies.md) | Accepted | Addresses the design decisions regarding the acceptable use of Perl dependencies. |
| [0008](./0008-schema-installable-by-database-owner.md) | Accepted | Addresses the design decision that super user rights should not be required to install and run LedgerSMB. |
| [0009](./0009-schema-must-be-configurable.md) | Accepted | Addresses the design decision related to which database schemas the LedgerSMB data can reside. |
| [0010](./0010-move-to-psgi-from-cgi-for-server-integration.md) | Accepted | Addresses the design decision to move from CGI to PSGI for web server integration. |
| [0011](./0011-use-Dojo-Toolkit-for-active-UI.md) | Superseded by [ADR 0105](./0105-change-ui-from-dojo-to-quasar.md) | Addresses the original design decision to use Dojo toolkit. |
| [0012](./0012-no-cdn-for-javascript-dependencies.md) | Accepted | Addresses the design decisions to include all dependencies for JavaScript,  images, CSS, etc. in the LedgerSMB distribution and to not use Content  Distribution Networks for any browser related resources. |
| [0013](./0013-no-use-of-web-framework-dancer.md) | Accepted | Addresses the design decision to not use Perl development frameworks like Catalyst, Dancer, Mojolicious etc. |
| [0014](./0014-rest-api-not-using-jsonapi.md) | Accepted | Addresses the design decision regarding REST web service API, documented the API  using OpenAPI, semantic versioning of the API, and thin client requirements.  |
| [0015](./0015-js-spa-client-using-vue.md) | Accepted | Addresses the design decision to start incorporating Vue components into the UI, eventually removing the use of Dojo, but keeping the Dojo look and feel until after all components are converted. |
| [0016](./0016-state-machines-for-UI-state.md) | Accepted | Addresses the design decision to use state machines robot3 (XState) for UI state management. |
| [0017](./0017-state-machines-for-resource-state-management.md) | Accepted | Addresses the design decision to use state machines for managing resources like  invoices, orders, e-mails, document templates, recurrence patterns, etc. |
| [0018](./0018-resource-state-machine-engine-with-dependency-injection.md) | Accepted | Addresses the design decisions regarding state machine usage in the Perl layer using the perl pod WorkFlow, the modification of database state using its  procedural API, and the need for dependency injection in the state machine. |
| [0019](./0019-configuration-using-dependency-injection.md) | Accepted | Addresses the design decision to use Beam::Wire, dependency injection, YAML for new configurations and deprecation of the INI configuration format. |
| [0020](./0020-postgresql-timestamp-with-timezone.md) | Accepted | Addresses the design decision to use TIMESTAMP WITHOUT TIME ZONE for all database timestamps. |
| [0021](./0021-restricted-list-of-postgresql-extensions.md) | Accepted | Addresses the design decision to only use the listed in-core PostgreSQL  extensions. |
| [0022](./0022-perl-layer-only-glue-between-apache-and-pg.md) | Accepted | Addresses the design decision regarding the separation of responsibilities for web request serving, HTML composition, Template::Toolkit, and  business logic. |
| [0023](./0023-cli-application.md) | Accepted | Addresses the design decision for scripting use-cases using the `ledgersmb-admin` command line application, its environment variables, and its YAML configuration. |
| [0024](./0024-chart-of-accounts-schema.md) | Accepted | Addresses the design decision for the `account` and `account_heading`  tables in LedgerSMB, specifically whether to move to inheritance across tables  or use the current methods like triggers to maintain referential integrity. |
| [0025](./0025-incremental-database-upgrades.md) | Accepted | Addresses the design decision regarding the database upgrade process. |
| [0026](./0026-resource-locking-over-stateless-http.md) | Accepted | Addresses the design decision to use a `session` concept for each logged in user which persists in the database. |
| [0027](./0027-templating-with-custom-web-elements.md) | Accepted | Addresses the design decision to wrap Dojo widgets and adding abstractions which could make transitions to other other widget libraries in the future. |
| [0100](./0100-restrictions-on-use-of-global-state-and-localized-variables.md) | Accepted | Addresses the design decision regarding reducing the use of global state to situations where no other choice is available, the deprecation of  `LedgerSMB::App_State`, the use of `local` to limit Perl built in variables and the appropriate layer for state to be stored. |
| [0101](./0101-separating-concerns-between-persisters-actions.md) | Accepted | Addresses the design decisions regarding persisting workflow states, the use  of actions, and overriding `WorkFlow` with `LedgerSMB::Workflow`. |
| [0102](./0102-perl-pragmas-top-declarations.md) | Accepted | Addresses the design decisions regarding the proper location and order for Perl  pragmas, modules, and package declarations. Also defines where and when to  declare minimum Perl versions. |
| [0103](./0103-core-data-model-entity-deletion.md) | Accepted | Addresses the design decision for limited use of ON DELETE in REFERENCES  table relations to reduce database clutter of unused rows. |
| [0104](./0104-business-logic-in-perl.md) | Accepted | Addresses the design decision regarding using the PostgreSQL layer to  actively manage the consistency and correctness of the data. It also clarifies the responsibilities of the active and passive PostgreSQL layers. |
| [0105](./0105-change-ui-from-dojo-to-quasar.md) | Accepted | Addresses the design decision to move the code base from Dojo to Vue and Quasar. |
| [0106](./0106-coding-style-new-perl-syntax.md) | Accepted | Addresses the design decisions regarding Perl coding style and the limited use of newer Perl syntax. |
| [0107](./0107-using-postgresql-json-jsonb-data-type.md) | Draft | Addresses the design decisions regarding the use of JSON and JSONB data types, and the preferential use of relational schema in the PostgreSQL database.. |

Index Generated: Wed Oct  1 22:29:31 2025 UTC
