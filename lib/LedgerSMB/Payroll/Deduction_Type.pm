=head1 NAME

LedgerSMB::Payroll::Deduction_Type - Deduction Types for LedgerSMB's Payroll
Engine

=head1 SYNOPSIS

To get a type

 my $dtype = LedgerSMB::Payroll::Deduction_Type->get($id)

To save a type

 $dtype->save()

=cut

package LedgerSMB::Payroll::Deduction_Type;
use Moose;
with 'LedgerSMB::PGObject';

=head1 DESCRIPTION

Deduction types are one of two of the main building blocks of the LedgerSMB's
payroll engine.  These represent anything deducted from the net expense of wages
before the worker is paid.  Thus they can represent income taxes, excise taxes
on work (like workers comp in the US), benefits-related deductions, and more.

Deduction types are categorized into tax-jurisdiction-dependent classes.
Deduction types are organization-specific manifestations of these, but unlike
income types, there may be many for whom standard deduction types for a tax
jurisdiction apply.  For example, an organization may employ some workers in
different states and have to pay differing state income taxes and workers comp
rates.  Similearly different classes might be used to indicate
different health insurance plans, or for tracking liabilities relating to
vacation pay and the like. Employees are attached to income types and deduction
types, allowing organizations to set up payroll flexibly for their own
businesses.

Unlike payroll income types, the deduction types are calculated using specific
stored procedures per payroll deduction class.  These classes are divided per
country, and this allows some centralization of tax logic.

=head1 PROPERTIES

=over

=item id int

The id.  Saving returns a new id with this set.

=cut

has id => (is => 'ro', isa => 'Int', required => 0);

=item account_id int

This is the account to report the deduction in.  It is required.

=cut

has account_id => (is => 'ro', isa => 'Int', required => 1);

=item pdc_id int

This is the payroll deduction class.  These are not defined through the user
interface but rather defined country-wise.  It is required.

=cut

has pdc_id  => (is => 'ro', isa => 'Int', required => 1);

=item country_id int

This is the id of the country.  It is required.

=cut

has country_id  => (is => 'ro', isa => 'Int', required => 1);

=item label text

This is the human-readable designation for the deduction type.

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

Retrieves an deduction type by id from the database and returns it to the
application.

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(
              funcname => 'payroll_deduction_type__get', args => [$id]
    );
    return __PACKAGE__->new(%$ref);
}

=item save()

This saves the entry to the database and returns a new object with ID and other
defaults set as applicable.

=cut

sub save {
    my ($self, $id) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'payroll_deduction_type__save');
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

