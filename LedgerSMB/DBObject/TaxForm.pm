=pod

=head1 NAME

LedgerSMB::DBObject::TaxForm - Includes methods for saving and retrieving tax forms.

=head1 SYNOPSIS

This module includes methods for saving and retrieving tax forms, and running
reports.  The tax forms are for reporting purchases or sales to tax bodies, and
as of 1.3.0, the only tax forms officially included are those of the 1099-MISC
and 1099-INT forms of the USA.

Currently there is no abstraction layer to allow replacing the various reports
on the fly, but this will have to be implemented in the future.

=head1 METHODS

=over

=cut


package LedgerSMB::DBObject::TaxForm;

use base qw(LedgerSMB::PGOld);

use strict;
use warnings;

=item save
Saves the tax form. Inputs are:

=over

=item form_name (required)
The name of the form, eg, 1099-MISC

=item country_id (required)
The id of the country

=item id (optional)
The id of the tax form to overwrite

=back

In the future it is likely that we will add a taxform_sproc_id too as part of
an abstraction layer.

=cut

sub save
{

    my ($self) = shift @_;
    my ($ref) = $self->call_dbmethod(funcname => 'tax_form__save');
    $self->{taxform_id} = $ref->{'tax_form__save'};

}

=item get($id)

Retrieves information on the tax form specified and merges it with the current
object.  Properties set are:

=over

=item id
ID of tax form

=item form_name
Name of tax form (eg, 1099-MISC)

=item country_id
ID of country attached to tax form

=back

=cut

sub get
{
    my ($self, $id) = @_;

    my @results = $self->call_procedure(
                funcname => 'tax_form__get', args => [$id]
    );
    return $results[0];
}

=item get_full_list

No inputs required.  Provides a list of hashrefs (and attaches them to the
form property of the object hashref).

Each hashref has the same properties as are set by get($id) above, but also
includes country_name which is the full name of the country (eg, 'United
States').

Default ordering is by country name and then by tax form name.

=cut

sub get_full_list
{
    my ($self) = @_;

    @{$self->{forms}} = $self->call_dbmethod(
                funcname => 'tax_form__list_ext',
    );
    return @{$self->{forms}};
}

=item get_forms

No inputs needed

Returns a list of hashrefs representing tax forms.  Each hashref contains
the same properties as from get() above.  Default ordering is by country id
then tax form id.

=cut

sub get_forms
{
    my ($self) = @_;

    @{$self->{forms}} = $self->call_dbmethod(
                funcname => 'tax_form__list_all',
    );
    return @{$self->{forms}};
}

=item get_metadata

Gets metadata for the screen.

Sets the following hashref properties

=over

=item countries
A list of all countries, for drop down box purposes.

=item default_country
The default country of the organization, to set the dropdown box.

=back

=cut

sub get_metadata
{
    my ($self) = @_;

    @{$self->{countries}} = $self->call_dbmethod(
                funcname => 'location_list_country'
    );

    my ($ref) = $self->call_procedure(funcname => 'setting_get', args => ['default_country']);
    $self->{default_country} = $ref->{setting_get};
}



=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
