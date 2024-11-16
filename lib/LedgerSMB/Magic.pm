package LedgerSMB::Magic;
use strict;
use warnings;

use parent 'Exporter';


our @EXPORT_OK = qw(
    BC_AP
    BC_AR
    BC_GL
    BC_PAYMENT
    BC_PAYMENT_REVERSAL
    BC_RECEIPT
    BC_RECEIPT_REVERSAL
    BC_SALES_INVOICE
    BC_VENDOR_INVOICE
    BRU_DEPARTMENT
    BRU_PROJECT
    BRU_JOB
    BRU_FUND
    BRU_CUSTOMER
    BRU_VENDOR
    BRU_LOT
    CENTURY_START_YEAR
    DEFAULT_NUM_PREC
    DAYS_PER_WEEK
    CC_EMAIL_TO
    CC_EMAIL_CC
    CC_EMAIL_BCC
    CC_BILLING_EMAIL_TO
    CC_BILLING_EMAIL_CC
    CC_BILLING_EMAIL_BCC
    EC_COLD_LEAD
    EC_CONTACT
    EC_CUSTOMER
    EC_EMPLOYEE
    EC_HOT_LEAD
    EC_LEAD
    EC_REFERRAL
    EC_VENDOR
    EDI_PATHNAME_MAX
    EDIT_BUDGET_ROWS
    FC_ECA
    FC_EMAIL
    FC_ENTITY
    FC_INCOMING
    FC_INTERNAL
    FC_ORDER
    FC_PART
    FC_RECONCILIATION
    FC_TRANSACTION
    FUTURE_YEARS_LIMIT
    HTTP_454
    JRNL_AP
    JRNL_AR
    JRNL_CD
    JRNL_CR
    JRNL_GJ
    MAX_DAYS_IN_MONTH
    MIN_PER_HOUR
    MONTHS_PER_QUARTER
    MONTHS_PER_YEAR
    NC_ENTITY
    NC_ENTITY_CREDIT_ACCOUNT
    NC_INVOICE
    NC_JOURNAL_ENTRY
    NC_UNKNOWN_4
    OEC_PURCHASE_ORDER
    OEC_QUOTATION
    OEC_RFQ
    OEC_SALES_ORDER
    PERL_TIME_EPOCH
    RC_DEPRECIATION
    RC_DISPOSAL
    RC_IMPORT
    RC_PARTIAL_DISPOSAL
    SCRIPT_OLDSCRIPTS
    SCRIPT_NEWSCRIPTS
    SATURDAY
    SEC_PER_HOUR
    NEW_BUDGET_ROWS
    SUNDAY
    YEARS_PER_CENTURY
);


=head1 NAME

LedgerSMB::Magic - Magic number constants for LedgerSMB

=head1 DESCRIPTION

I<LedgerSMB::Magic> is a library of constants used by the
LedgerSMB system.  Mostly, these are peculiar to LedgerSMB,
but where a small part of of a published code is used, the
constants may be found here rather than separate modules.

=head1 SYNOPSIS

 use LedgerSMB::Magic qw( EC_EMPLOYEE );

 if ($entity_code == EC_EMPLOYEE) {
     print "This entity  is an employee.";
 }

=head1 METHODS

This module doesn't specify any (public) methods.

=head1  ACCEPTED NUMERIC LITERALS

Numeric literal values that are not considered magical in LedgerSMB code.

    -1  for use as a fat minus or array index
     0
     1
     2
     100 for use finding percentages or shifting monetary values

=head1 CONSTANTS

The following constant functions are available.  None are exported by
default.

=head3  LedgerSMB batch class code enumeration.

    BC_AP                1
    BC_AR                2
    BC_PAYMENT           3
    BC_PAYMENT_REVERSAL  4
    BC_GL                5
    BC_RECEIPT           6
    BC_RECEIPT_REVERSAL  7
    BC_SALES_INVOICE     8
    BC_VENDOR_INVOICE    9

=cut

use constant BC_AP               => 1;
use constant BC_AR               => 2;
use constant BC_PAYMENT          => 3;
use constant BC_PAYMENT_REVERSAL => 4;
use constant BC_GL               => 5;
use constant BC_RECEIPT          => 6;
use constant BC_RECEIPT_REVERSAL => 7;
use constant BC_SALES_INVOICE    => 8;
use constant BC_VENDOR_INVOICE   => 9;

=head3  Business (reporting) units enumeration.

    BRU_DEPARTMENT      1
    BRU_PROJECT         2
    BRU_JOB             3
    BRU_FUND            4
    BRU_CUSTOMER        5
    BRU_VENDOR          6
    BRU_LOT             7

=cut

use constant BRU_DEPARTMENT     => 1;
use constant BRU_PROJECT        => 2;
use constant BRU_JOB            => 3;
use constant BRU_FUND           => 4;
use constant BRU_CUSTOMER       => 5;
use constant BRU_VENDOR         => 6;
use constant BRU_LOT            => 7;

=head3  LedgerSMB entity contact class code enumeration.

    CC_EMAIL_TO           12
    CC_EMAIL_CC           13
    CC_EMAIL_BCC          14
    CC_BILLING_EMAIL_TO   15
    CC_BILLING_EMAIL_CC   16
    CC_BILLING_EMAIL_BCC  17

=cut

use constant CC_EMAIL_TO          => 12;
use constant CC_EMAIL_CC          => 13;
use constant CC_EMAIL_BCC         => 14;
use constant CC_BILLING_EMAIL_TO  => 15;
use constant CC_BILLING_EMAIL_CC  => 16;
use constant CC_BILLING_EMAIL_BCC => 17;

=head3  LedgerSMB entity class code enumeration.

    EC_VENDOR      1
    EC_CUSTOMER    2
    EC_EMPLOYEE    3
    EC_CONTACT     4
    EC_LEAD        5
    EC_REFERRAL    6
    EC_HOT_LEAD    7
    EC_COLD_LEAD   8

=cut

use constant EC_VENDOR    => 1;
use constant EC_CUSTOMER  => 2;
use constant EC_EMPLOYEE  => 3;
use constant EC_CONTACT   => 4;
use constant EC_LEAD      => 5;
use constant EC_REFERRAL  => 6;
use constant EC_HOT_LEAD  => 7;
use constant EC_COLD_LEAD => 8;



=head3  LedgerSMB attached file class code enumeration.

    FC_TRANSACTION    1
    FC_ORDER          2
    FC_PART           3
    FC_ENTITY         4
    FC_ECA            5
    FC_INTERNAL       6
    FC_INCOMING       7
    FC_EMAIL          8
    FC_RECONCILIATION 9

=cut

use constant FC_TRANSACTION    => 1;
use constant FC_ORDER          => 2;
use constant FC_PART           => 3;
use constant FC_ENTITY         => 4;
use constant FC_ECA            => 5;
use constant FC_INTERNAL       => 6;
use constant FC_INCOMING       => 7;
use constant FC_EMAIL          => 8;
use constant FC_RECONCILIATION => 9;

=head3   LedgerSMB Accounting Journal code enumeration.

    JRNL_GJ    1
    JRNL_AR    2
    JRNL_AP    3
    JRNL_CR    4
    JRNL_CD    5

=cut

use constant JRNL_GJ => 1;
use constant JRNL_AR => 2;
use constant JRNL_AP => 3;
use constant JRNL_CR => 4;
use constant JRNL_CD => 5;


=head3  LedgerSMB note_class code enumeration.

    NC_ENTITY                   1
    NC_INVOICE                  2
    NC_ENTITY_CREDIT_ACCOUNT    3
    NC_UNKNOWN_4                4
    NC_JOURNAL_ENTRY            5

=cut

use constant NC_ENTITY                => 1;
use constant NC_INVOICE               => 2;
use constant NC_ENTITY_CREDIT_ACCOUNT => 3;
use constant NC_UNKNOWN_4             => 4;
use constant NC_JOURNAL_ENTRY         => 5;


=head3  LedgerSMB order entry class code enumeration.

    OEC_SALES_ORDER             1
    OEC_PURCHASE_ORDER          2
    OEC_QUOTATION               3
    OEC_RFQ                     4

=cut

use constant OEC_SALES_ORDER    => 1;
use constant OEC_PURCHASE_ORDER => 2;
use constant OEC_QUOTATION      => 3;
use constant OEC_RFQ            => 4;


=head3  LedgerSMB asset report class code enumeration.

    RC_DEPRECIATION      1
    RC_DISPOSAL          2
    RC_IMPORT            3
    RC_PARTIAL_DISPOSAL  4

=cut

use constant RC_DEPRECIATION     => 1;
use constant RC_DISPOSAL         => 2;
use constant RC_IMPORT           => 3;
use constant RC_PARTIAL_DISPOSAL => 4;

=head3  Entrypoint defining scripts

Whitelist for e.g. redirect destination

=cut

use constant SCRIPT_NEWSCRIPTS => [ qw(
   account.pl admin.pl asset.pl budget_reports.pl budgets.pl business_unit.pl
   configuration.pl contact.pl contact_reports.pl currency.pl drafts.pl email.pl
   erp.pl file.pl goods.pl import_csv.pl inventory.pl invoice.pl inv_reports.pl
   journal.pl login.pl logout.pl order.pl payment.pl
   payroll.pl pnl.pl recon.pl report_aging.pl reports.pl setup.pl taxform.pl
   template.pl timecard.pl transtemplate.pl trial_balance.pl user.pl vouchers.pl
                                    ) ];

use constant SCRIPT_OLDSCRIPTS => [
    'aa.pl', 'am.pl',    'ap.pl',
    'ar.pl', 'arap.pl',  'arapprn.pl', 'gl.pl',
    'ic.pl', 'ir.pl',
    'is.pl', 'oe.pl',    'pe.pl',
    ];


=head3  LedgerSMB temporal constants

    CENTURY_START_YEAR  2000    Start of current century.
    DEFAULT_NUM_PREC       5
    FUTURE_YEARS_LIMIT    20    When exceeded dates default to last century.
    SEC_PER_HOUR        3600
    MIN_PER_HOUR          60
    MONTHS_PER_QUARTER     3
    MONTHS_PER_YEAR       12
    MAX_DAYS_IN_MONTH     31
    PERL_TIME_EPOCH     1900
    YEARS_PER_CENTURY    100
    SUNDAY                 0    Unixy numeric for day of week.
    SATURDAY               6
    DAYS_PER_WEEK          7

=cut

use constant CENTURY_START_YEAR => 2000;
use constant DAYS_PER_WEEK      => 7;
use constant DEFAULT_NUM_PREC   => 5;
use constant FUTURE_YEARS_LIMIT => 20;
use constant SEC_PER_HOUR       => 3600;
use constant MIN_PER_HOUR       => 60;
use constant MONTHS_PER_QUARTER => 3;
use constant MONTHS_PER_YEAR    => 12;
use constant MAX_DAYS_IN_MONTH  => 31;
use constant PERL_TIME_EPOCH    => 1900;
use constant YEARS_PER_CENTURY  => 100;
use constant SUNDAY             => 0;
use constant SATURDAY           => 6;


=head3  LedgerSMB miscellaneous contants

    EDIT_BUDGET_ROWS     5
    NEW_BUDGET_ROWS     25

    Display lines to allocate for a user to start or add to
a budget.

=cut

use constant EDIT_BUDGET_ROWS => 5;
use constant NEW_BUDGET_ROWS  => 25;

=head3 External codes.

    These constants are derived from the standards or practices
of other organizations or systems.

=head3  EDI

    EDI_PATHNAME_MAX   180

Maximum length of EDI pathname.

=cut

use constant EDI_PATHNAME_MAX => 180;    # TODO possible fencepost error


=head3  Our HTTP status code extensions.

    HTTP_454           454

=cut

use constant HTTP_454 => 454;


=head1 BUGS

Are more organized.

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
