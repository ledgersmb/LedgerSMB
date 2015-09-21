=head1 NAME

LedgerSMB::Payroll::Income_Type - Income Types for LedgerSMB's Payroll Engine

=head1 SYNOPSIS

To get a type

 my $itype = LedgerSMB::Payroll::Income_Type->get($id)

To save a type

 $itype->save()

=cut

package LedgerSMB::Payroll::Income_Type;
use Moose;
with 'LedgerSMB::PGObject';

=head1 DESCRIPTION

Income types are one of two of the main building blocks of the LedgerSMB's
payroll engine.  These represent the building blocks of gross income before
deductions and taxes.

Income types are categorized into tax-jurisdiction-dependent classes.  In the
US, for example, we might see Pay-for-production, hourly, salary, and salary
exempt.  Income types are organization-specific manifestations of these.  For
example, an organization may employ some hourly workers, some salary workers,
and some salary exempt workers but may want to split up expense reporting on
the income statement.  Similearly different classes might be used to indicate
different default amounts, or to track efforts worked for profit sharing and
other purposes.  Employees are attached to income types and deduction type,
allowing organizations to set up payroll flexibly for their own businesses.

=head1 PROPERTIES

=over

=item id int

The id.  Saving returns a new id with this set.

=cut

has id => (is => 'ro', isa => 'Int', required => 0);

=item account_id int

This is the account to report the income in.  It is required.

=cut

has account_id => (is => 'ro', isa => 'Int', required => 1);

=item pic_id int

This is the payroll income class.  These are not defined through the user
interface but rather defined country-wise.  It is required.

=cut

has pic_id  => (is => 'ro', isa => 'Int', required => 1);

=item country_id int

This is the id of the country.  It is required.

=cut

has country_id  => (is => 'ro', isa => 'Int', required => 1);

=item label text

This is the human-readable designation for the income type.

=cut

has label => (is => 'ro', isa => 'Str', required => 1);

=item unit text

This is a human-readable label for unit of work.  Perhaps "hour" or "month' for
US would be the most common values.

=cut

has unit  => (is => 'ro', isa => 'Str', required => 1);

=item default_amount numeric

This is the default amount for each unit of work.  It can be overridden for each
employee.

=cut

has default_amount => (is => 'ro', isa => 'Num', required => 1);

=back

=head1 METHODS

=over

=item get($id)

Retrieves an income type by id from the database and returns it to the
application.

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(
              funcname => 'payroll_income_type__get', args => [$id]
    );
    return __PACKAGE__->new(%$ref);
}

=item save()

This saves the entry to the database and returns a new object with ID and other
defaults set as applicable.

=cut

sub save {
    my ($self, $id) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'payroll_income_type__save');
    return $self->new($ref);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;

