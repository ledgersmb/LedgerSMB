=head1 NAME
LedgerSMB::DBObject::Journal_Entry

=cut

package LedgerSMB::DBObject::Journal_Entry;

=head1 SYNOPSYS

This module contains the routines for managing and recording journal entries.
Such journal entries are the base of the accounting software and include all
invoices issued to customers and vendors, all payments and receipts, all 
transfers between bank accounts, etc.

=head1 INHERITANCE

the following modules are in the inheritance tree of this module

=over 

=item Moose

=item LedgerSMB

=item LedgerSMB::DBObject

=back

=cut

use Moose;
use base qw(LedgerSMB::DBObject);

=head1 PROPERTIES

=over

=cut

has dbtype          => (is => 'ro', isa => 'str',
                                                default => 'journal_entry_ext');

has id              => (is => 'rw', isa => 'int',     required => 0);

=item id (rw, int, not required)
This is the id of the journal entry, auto-generated when saved.  Should be undef
when the journal entry has not yet been saved.  Will be set on all entries 
retrieved from the database.

=cut

has reference       => (is => 'rw', isa => 'str',     required => 1);

=item reference (rw, string, required)
This is the source document number for the journal entry.  For an invoice this
will be the invoice number.  For a check it will be the check number.  In other
cases, it could be other specified identifiers.  All GL and all sales references
must be unique.

=cut 

has description     => (is => 'rw', isa => 'str',     required => 0);

=item description (rw, string, not required)

This is an optional description for the transaction, such as the memo field
of a check.

=cut

has journal         => (is => 'rw', isa => 'int',     required => 1);

=item journal (rw, int, required)

This tells us which journal the transaction is being entered in and hence what 
the transaction type is.  The following values are hard-coded in the database:

=over

=item 1 General

Used for general journal entries, for example transfers between bank accounts,
adjustments, and the like.

=item 2 Sales

Used for sales invoices with or without inventory.

=item 3 Purchases

Used to record vendor invoices with or without inventory.

=item 4 Receipts

Used to record moneys received from customers.

=item 5 Dispursements

Used to record moneys paid to vendors

=back

=cut

has post_date       => (is => 'rw', isa => 'pg_date', required => 1);

=item post_date (rw, date, required)
This records the date the transaction officially hits the books (with or without
adjustments).

=cut

has effective_start => (is => 'rw', isa => 'pg_date', required => 0);

=item effective_start(rw, date, optional)
Records the date the transaction begins to take effect (for example the
beginning of a lease).  Used for manually calculating adjustments and could be
used for an add-on to do the same.  If not provided, defaults to post_date.

=cut

has effective_end   => (is => 'rw', isa => 'pg_date', required => 0);

=item effective_end (rw, date, optional)
Records the date the transaction ceases to take effect (for example the ending 
date of a year-long pre-paid lease).  Used for manually calculating adjustments
and could be used for an add-on to do the same.  if not provided, defaults to
post_date.

=cut

has currency        => (is => 'rw', isa => 'str',     required => 1);

=item currency(rw, string, required)
Three characters identifying the currency in use (for example USD, CAD, or EUR).

=cut

has approved        => (is => 'ro', isa => 'bool',    required => 1, 
                                                                  default => 0);

=item approved (ro, bool, required, defaults to 0)
Reports whether the transaction has been approved.  Is not saved when the 
journal entry is saved. 

=cut

has is_template     => (is => 'rw', isa => 'bool',    required => 1,
                                                                  default => 0);

=item is_template (rw, bool, required, defaults to 0)

This is set as true when saving as a template.  Templates can be copied to new
transactions or deleted but cannot be approved themselves.

=cut

has entered_by      => (is => 'ro', isa => 'int',     required => 0);

=item entered_by (ro, int, not required)
This is the entity id of the one entering the transaction.  It is set 
automatically by the database.

=cut

has entered_by_name  => (is => 'ro', isa => 'str',     required => 0);
has approved_by      => (is => 'ro', isa => 'int',     required => 0);
has approved_by_name => (is => 'ro', isa => 'str',     required => 0);
has lines           => (is => 'rw', isa => 'list',    required => 1);
