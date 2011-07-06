=head1 NAME

LedgerSMB::Location - LedgerSMB class for managing Business Locations

=head1 SYOPSIS

This module contains location management routines.  This subclasses 
LedgerSMB::DBObject to provide access to automatice mapping of function 
arguments and the like.

=head1 METHODS

=over

=item delete 

=cut

package LedgerSMB::Location;
use LedgerSMB;
use LedgerSMB::DBObject;
use strict;
our $VERSION = '1.0.0';

use base qw(LedgerSMB::DBObject);

=item save

Saves the location.  Properties to be set to be saved are:

* location_id: Optional:  Overwrite location with this id.
* address1: First line of the address.
* address2: Second line of the address
* address3: Third line of the address
* city
* state: state or province
* zipcode: zipcode or mail code, 
* country:  The id of the country as per the country table

=cut

sub save {
    my $self = shift;
    my $ref = shift @{ $self->exec_method( procname => "location_save" ) };
    $self->merge( $ref, 'id' );
}

=item get

Retrieves a location record based on the id field of the object.  Merges the 
properties into the object.

=cut

sub get {
    my $self = shift;
    my $ref = shift @{ $self->exec_method( procname => 'location__get' ) };
    $self->merge( $ref, keys %{$ref} );
}

=item search
Returns anarrayref (and stores it on $self->{search_results} based on the 
search of addresses.  Not currently used.

Attributes used as search criteria:
address1: Partial match for address line 1
address2: Partial match for address line 2,
city:  Partial match for city name
state: Partial match for state or province name, 
zipcode:  Partial match for zip or postal code,
country: Partial name for country name)

=cut

sub search {
    my $self = shift;
    $self->{search_results} =
      $self->exec_method( procname => 'location_search' );
}

=item list_all

Provides a list of all locations, ordered by country, then city, then state.

=cut

sub list_all {
    my $self = shift;
    $self->{search_results} =
      $self->exec_method( procname => 'location_list_all' );
}

=item delete

Deletes the location identified by id

=cut

sub delete {
    my $self = shift;
    $self->exec_method( procname => 'location_delete' );
    $self->{dbh}->commit;
}

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
