package LedgerSMB::Magic;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(
    BC_AP
    BC_AR
    BC_PAYMENT
    BC_PAYMENT_REVERSAL
    BC_GL
    BC_RECEIPT
    BC_RECEIPT_REVERSAL
    BC_SALES_INVOICE
    BC_VENDOR_INVOICE

    CENTURY_START_YEAR

    EC_COLD_LEAD
    EC_CONTACT
    EC_CUSTOMER
    EC_EMPLOYEE
    EC_HOT_LEAD
    EC_LEAD
    EC_REFERRAL
    EC_VENDOR

    EDI_PATHNAME_MAX

    FC_TRANSACTION
    FC_ORDER
    FC_PART
    FC_ENTITY
    FC_ECA
    FC_INTERNAL
    FC_INCOMING

    FUTURE_YEARS_LIMIT

    HTTP_454
    HTTP_BAD_REQUEST
    HTTP_FOUND
    HTTP_INTERNAL_SERVER_ERROR
    HTTP_OK
    HTTP_SEE_OTHER
    HTTP_UNAUTHORIZED

    MAX_DAYS_IN_MONTH
    MEGABYTE
    MIN_PER_HOUR
    MONEY_EPSILON
    MONTHS_PER_QUARTER
    MONTHS_PER_YEAR

    NC_ENTITY
    NC_INVOICE
    NC_ENTITY_CREDIT_ACCOUNT
    NC_JOURNAL_ENTRY

    OEC_SALES_ORDER
    OEC_PURCHASE_ORDER
    OEC_QUOTATION
    OEC_RFQ

    PERL_TIME_EPOCH
    RATIO_TO_PERCENT

    RC_DEPRECIATION
    RC_DISPOSAL
    RC_IMPORT
    RC_PARTIAL_DISPOSAL

    SEC_PER_HOUR
    SATURDAY
    SUNDAY

    UNI_Aring
    UNI_aring

    YEARS_PER_CENTURY
);

use constant {

    # temporal
    CENTURY_START_YEAR => 2000,    # start of current century
    FUTURE_YEARS_LIMIT => 20,      # go to last century if too far in future
    SEC_PER_HOUR       => 3600,
    MIN_PER_HOUR       => 60,
    MONTHS_PER_QUARTER => 3,
    MONTHS_PER_YEAR    => 12,
    MAX_DAYS_IN_MONTH  => 31,
    PERL_TIME_EPOCH    => 1900,
    YEARS_PER_CENTURY  => 100,
    SUNDAY             => 0,
    SATURDAY           => 6,

    # miscellany
    MEGABYTE      => 1024 * 1024,
    MONEY_EPSILON => 0.001,         # XXX GAP/IFRS require .0001  maybe???
                                    # I read that somewhere, maybe Celko --rir
    RATIO_TO_PERCENT => 100,

    # our batch classes
    BC_AP               => 1,
    BC_AR               => 2,
    BC_PAYMENT          => 3,
    BC_PAYMENT_REVERSAL => 4,
    BC_GL               => 5,
    BC_RECEIPT          => 6,
    BC_RECEIPT_REVERSAL => 7,
    BC_SALES_INVOICE    => 8,
    BC_VENDOR_INVOICE   => 9,

    # our entity classes
    EC_VENDOR    => 1,
    EC_CUSTOMER  => 2,
    EC_EMPLOYEE  => 3,
    EC_CONTACT   => 4,
    EC_LEAD      => 5,
    EC_REFERRAL  => 6,
    EC_HOT_LEAD  => 7,
    EC_COLD_LEAD => 8,

    # our file classes:  files attached to sql records
    FC_TRANSACTION => 1,
    FC_ORDER       => 2,
    FC_PART        => 3,
    FC_ENTITY      => 4,
    FC_ECA         => 5,
    FC_INTERNAL    => 6,
    FC_INCOMING    => 7,

    # our note classes
    NC_ENTITY                => 1,
    NC_INVOICE               => 2,
    NC_ENTITY_CREDIT_ACCOUNT => 3,
    NC_JOURNAL_ENTRY         => 5,

    # our order entry classes
    OEC_SALES_ORDER    => 1,
    OEC_PURCHASE_ORDER => 2,
    OEC_QUOTATION      => 3,
    OEC_RFQ            => 4,

    # our asset report classes
    RC_DEPRECIATION     => 1,
    RC_DISPOSAL         => 2,
    RC_IMPORT           => 3,
    RC_PARTIAL_DISPOSAL => 4,

    # codes

    # EDI
    EDI_PATHNAME_MAX => 180,    # default max length of EDI pathname
                                # code says 180, perldoc says 179

    # HTTP  These can be taken from HTTP::Status
    HTTP_OK                    => 200,
    HTTP_FOUND                 => 302,
    HTTP_SEE_OTHER             => 303,
    HTTP_BAD_REQUEST           => 400,
    HTTP_UNAUTHORIZED          => 401,
    HTTP_INTERNAL_SERVER_ERROR => 500,

    HTTP_454 => 454,

    # Unicode
    UNI_Aring => 0x00c5,
    UNI_aring => 0x00e5,

};

1;

# Other magical stuff that might help

#INSERT INTO lsmb_module (id, label)
#VALUES (1, 'AR'),
#       (2, 'AP'),
#       (3, 'GL'),
#       (4, 'Entity'),
#       (5, 'Manufacturing'),
#       (6, 'Fixed Assets'),
#       (7, 'Timecards');

#INSERT INTO location_class(id,class,authoritative)
#VALUES ('1','Billing',TRUE);
#       ('2','Sales',FALSE);
#       ('3','Shipping',FALSE);
#       ('4','Physical',TRUE);
#       ('5','Mailing',FALSE);

# INSERT INTO salutation (id,salutation) VALUES
#    ('1','Dr.');
#    ('2','Miss.');
#    ('3','Mr.');
#    ('4','Mrs.');
#    ('5','Ms.');
#    ('6','Sir.');

# INSERT INTO contact_class (id,class) values
#   (1,'Primary Phone');
#   (2,'Secondary Phone');
#   (3,'Cell Phone');
#   (4,'AIM');
#   (5,'Yahoo');
#   (6,'Gtalk');
#   (7,'MSN');
#   (8,'IRC');
#   (9,'Fax');
#   (10,'Generic Jabber');
#   (11,'Home Phone');
#   -- The e-mail classes are hard-coded into LedgerSMB/Form.pm by class_id
#   -- i.e. 'class_id's 12 - 17
#   (12,'Email');
#   (13,'CC');
#   (14,'BCC');
#   (15,'Billing Email');
#   (16,'Billing CC');
#   (17,'Billing BCC');
#   (18,'EDI Interchange ID');
#   (19,'EDI ID');

# COMMENT ON TABLE journal_type IS
# $$ This table describes the journal entry type of the transaction.  The
# following values are hard coded by default:
# 1:  General journal
# 2:  Sales (AR)
# 3:  Purchases (AP)
# 4:  Receipts
# 5:  Payments

# INSERT INTO business_unit_class (id, label, active, ordering)
# VALUES (1, 'Department', '0', '10'),
#       (2, 'Project', '0', '20'),
#       (3, 'Job', '0', '30'),
#       (4, 'Fund', '0', '40'),
#       (5, 'Customer', '0', '50'),
#       (6, 'Vendor', '0', '60'),
#       (7, 'Lot',  '0', 50);

# INSERT INTO jctype (id, label, description, is_service, is_timecard)
# (1, 'time', 'Timecards for project services', true, true);
# (2, 'materials', 'Materials for projects', false, false);
# (3, 'overhead', 'Time/Overhead for payroll, manufacturing, etc', false, true);

# menu node's 1 -- 253

# Menu attribute ids  1 -- 681

__END__

=head1 NAME

LedgerSMB::Magic - Magic number constants for LedgerSMB

=head1 SYNOPSIS

 use LedgerSMB::Magic qw( EC_EMPLOYEE );

 if ($entity_code == EC_EMPLOYEE) {
     print "This entity  is an employee.";
 }

=head1 DESCRIPTION

I<LedgerSMB::Magic> is a library of constants used by the
LedgerSMB system.  Mostly, these are peculiar to LedgerSMB,
but where a small part of of a published code is used, the
constants may be found here rather than separate modules.

=head1 CONSTANTS

The following constant functions are available.  None are exported by
default; they can be imported individually.

These were all extracted from our source code in a ad hoc manner;
the names are subject to change.

=head3  LedgerSMB temporal constants

    CENTURY_START_YEAR              2000
    FUTURE_YEARS_LIMIT              20
    SEC_PER_HOUR                    3600
    MIN_PER_HOUR                    60
    MONTHS_PER_QUARTER              3
    MONTHS_PER_YEAR                 12
    MAX_DAYS_IN_MONTH               31
    PERL_TIME_EPOCH                 1900
    YEARS_PER_CENTURY               100
    SUNDAY                          0
    SATURDAY                        6

=head3  LedgerSMB miscellaneous contants

    MEGABYTE                        1024*1024
    MONEY_EPSILON                   0.001

GAP/IFRS seems to require .0001  (maybe???  I read that somewhere, 
maybe Celko --rir).

    RATIO_TO_PERCENT        100

=head3  LedgerSMB batch class codes

    BC_AP                     1
    BC_AR                     2
    BC_PAYMENT                3
    BC_PAYMENT_REVERSAL       4
    BC_GL                     5
    BC_RECEIPT                6
    BC_RECEIPT_REVERSAL       7
    BC_SALES_INVOICE          8
    BC_VENDOR_INVOICE         9

=head3  LedgerSMB entity class codes

    EC_VENDOR                 1
    EC_CUSTOMER               2
    EC_EMPLOYEE               3
    EC_CONTACT                4
    EC_LEAD                   5
    EC_REFERRAL               6
    EC_HOT_LEAD               7
    EC_COLD_LEAD              8

=head3  LedgerSMB attached file class codes

    FC_TRANSACTION            1
    FC_ORDER                  2
    FC_PART                   3
    FC_ENTITY                 4
    FC_ECA                    5
    FC_INTERNAL               6
    FC_INCOMING               7

=head3  LedgerSMB note_class codes

    NC_ENTITY                   1
    NC_INVOICE                  2
    NC_ENTITY_CREDIT_ACCOUNT    3
    NC_JOURNAL_ENTRY            5

=head3  LedgerSMB order entry class codes

    OEC_SALES_ORDER             1
    OEC_PURCHASE_ORDER          2
    OEC_QUOTATION               3
    OEC_RFQ                     4

=head3  LedgerSMB asset report class codes

    RC_DEPRECIATION             1
    RC_DISPOSAL                 2
    RC_IMPORT                   3
    RC_PARTIAL_DISPOSAL         4

=head2    Codes from other organizations

=head3  EDI

    EDI_PATHNAME_MAX            180    

Default max length of EDI pathname code says 180, perldoc says 179.

=head3  HTTP

    HTTP_OK                     200
    HTTP_FOUND                  302
    HTTP_SEE_OTHER              303
    HTTP_BAD_REQUEST            400
    HTTP_UNAUTHORIZED           401
    HTTP_INTERNAL_SERVER_ERROR  500

    HTTP_454                    454

=head3  Unicode

    UNI_Aring               0x00c5
    UNI_aring               0x00e5

=head1 BUGS

Are more organized.


