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

has 'tax_id' => (is => 'rw', isa => 'Str', default => '');

=item sales_tax_id

Sales tax identifier for the company (like a GST or VAT number)

=cut

has 'sales_tax_id' => (is => 'rw', isa => 'Str', default => '');

=item license_number

Buisness license number for the company

=cut

has 'license_number' => (is => 'rw', isa => 'Str', default => '');

=item sic_code

Business categorization code.  SIC, NAICS, or other systems can be used.

=cut

has 'sic_code' => (is => 'rw', isa => 'Str', default => '');

=item created 

Date when the company was entered into LedgerSMB

=back

=cut

has 'created' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=head1 METHODS

=over

=item get($id)

This retrieves and returns the item as a blessed reference

=item save()

Saves the item and populates db defaults in id and created.

=item delete()

Deletes the item from the db.  Only valid if it has no 

=item search({})

Retrieves a list of companies matching search criteria.

=back

=head1 COPYRIGHT
