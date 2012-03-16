=head1 NAME

LedgerSMB::DBObject::Entity::Company -- Company (business) handling for LedgerSMB

=head1 SYNOPSIS

This handles the overall data management for companies as customers, vendors, sales 
leads etc.

=head1 INHERITS

=over 

=item LedgerSMB::DBObject::Entity

=back

=cut

package LedgerSMB::DBObject::Entity::Company;
use Moose;
extends 'LedgerSMB::DBObject::Entity';

=head1 PROPERTIES

=over

=item legal_name

Legal name of the company.  Will also map back to the entity's name field.

=cut

has 'legal_name' => (is => 'rw', isa => 'Str', default => '');

=item tax_id

Tax identifier for the company.

=cut

has 'tax_id' => (is => 'rw', isa => 'Maybe[Str]', default => '');

=item sales_tax_id

Sales tax identifier for the company (like a GST or VAT number)

=cut

has 'sales_tax_id' => (is => 'rw', isa => 'Maybe[Str]', default => '');

=item license_number

Buisness license number for the company

=cut

has 'license_number' => (is => 'rw', isa => 'Maybe[Str]', default => '');

=item sic_code

Business categorization code.  SIC, NAICS, or other systems can be used.

=cut

has 'sic_code' => (is => 'rw', isa => 'Maybe[Str]', default => '');

=item created 

Date when the company was entered into LedgerSMB

=back

=cut

has 'created' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=head1 METHODS

=over

=item get($id)

This retrieves and returns the item as a blessed reference

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = $self->call_procedure(procname => 'company__get',
                                          args => [$id]);
    $self->prepare_dbhash($ref);
    return $self->new(%$ref);
}

=item save()

Saves the item and populates db defaults in id and created.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'company__save'});
    $self->prepare_dbhash($ref);
    $self = $self->new(%$ref);
}

=item search({account_class => int, contact => string, contact_info => arrayref(string),
              meta_number => string, address => string, city => string, state => string,
              mail_code => string, country => string, date_from => date, 
              date_to => date, business_id => int, legal_name => string, 
              control_code string})

Retrieves a list of companies matching search criteria.

account_class is required and is an exact match.
control_code and business_id are exact matches.
All other criteria are partial matches.

Except with account_class, undef matches all values.

=cut

sub search {
    my ($self, $criteria) = @_;
    my @results = $self->exec_method({funcname => 'company__search', 
                                       arghash => $criteria}
    );
    for my $ref (@results){
        $self->prepare_dbhash($ref);
        $ref = $self->new(%$ref);
    }
    return @results;
}

=back

=head1 COPYRIGHT

Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under the GNU GPL
version 2 or at your option any future version.  Please see the accompanying LICENSE 
file for details.

=cut

__PACKAGE__->meta->make_immutable;

return 1;
