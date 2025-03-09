
package LedgerSMB::Entity::Company;

=head1 NAME

LedgerSMB::Entity::Company -- Company (business) handling for LedgerSMB

=head1 DESCRIPTION

This handles the overall data management for companies as customers, vendors,
sales leads etc.

=head1 INHERITS

=over

=item LedgerSMB::Entity

=back

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Entity';
use LedgerSMB::MooseTypes;

=head1 PROPERTIES

=over

=item entity_id

ID of entity attached.  This is also an interal reference to this company.

=cut

has 'entity_id' => (is => 'rw', isa => 'Int', required => 0);

=item legal_name

Legal name of the company.  Will also map back to the entity's name field.

=cut

has 'legal_name' => (is => 'rw', isa => 'Str', required => 0);

=item tax_id

Tax identifier for the company.

=cut

has 'tax_id' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item sales_tax_id

Sales tax identifier for the company (like a GST or VAT number)

=cut

has 'sales_tax_id' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item license_number

Buisness license number for the company

=cut

has 'license_number' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item sic_code

Business categorization code.  SIC, NAICS, or other systems can be used.

=cut

has 'sic_code' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item created

Date when the company was entered into LedgerSMB

=cut

has 'created' => (is => 'rw', isa => 'LedgerSMB::PGDate');

=back

=head1 METHODS

=over

=item get($id)

This retrieves and returns the item as a blessed reference

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(funcname => 'company__get',
                                          args => [$id]);
    return undef unless $ref->{control_code};
    $ref->{name} = $ref->{legal_name};
    return __PACKAGE__->new(%$ref);
}

=item get_by_cc($cc)

This retrieves a company associated with a control code.  Dies with error if
company does not exist.

=cut

sub get_by_cc {
    my ($self, $cc) = @_;
    my ($ref) = __PACKAGE__->call_procedure(funcname => 'company__get_by_cc',
                                          args => [$cc]);
    return undef unless $ref->{control_code};
    $ref->{name} = $ref->{legal_name};
    return __PACKAGE__->new(%$ref);
}


=item save()

Saves the item and populates db defaults in id and created.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'company__save');
    $ref->{control_code} = $self->{control_code};
    $ref->{country_id} = $self->{country_id};
    $ref->{name} = $ref->{legal_name};
    $self = $self->new(%$ref);
    return ($self);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
