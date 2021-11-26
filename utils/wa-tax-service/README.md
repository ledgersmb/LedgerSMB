
# WA Tax rate lookup and calculation module

This module implements tax calculation based on webservice
lookup through https://webgis.dor.wa.gov/webapi/addressrates.aspx
as required for Washington State tax regulations.

## Prerequisites

This module works with LedgerSMB 1.10 and higher.

## Installation

In order to install this module, execute the following commands
from the root of the LedgerSMB working tree:

```bash
cp utils/wa-tax-service/WA.pm lib/LedgerSMB/Taxes/WA.pm
psql -U postgres -h localhost -d YOURCOMPANY \
   -c 'INSERT INTO "public"."taxmodule" ("taxmodulename") VALUES (''WA'')'
cd utils/wa-tax-service
cpanm --installdeps .
```

## Configuration

The module needs a dedicated GL account, marked as a Tax account (through
the Tax checkmark on the account configuration screen).

Additionally, in the System > Taxes configuration, the account needs to
have the "WA" tax rules loaded.

## Use

In order for the tax rate to be applied to invoices and transactions against
a specific customer, the billing address for the customer's Account must be
in Washington State ("State" equal to "WA") the tax account must be checked
in the customer's 'Account' screen (Contacts > Search | (Customer) > Account
tab).

For invoices, the additional requirement is that the parts and services being
sold also have the checkmark for the specific tax checked (in the Part or
Service configuration screen).

## Webservice availability

The tax calculation module contacts a webservice to retrieve the correct tax
rate. When this service is not available - or the customer's billing address
does not fit the requirement of being in Washington state - the fallback tax
rate is used. This rate is the rate specified in the System > Taxes screen
on the line where the "WA" tax rules have been selected.

