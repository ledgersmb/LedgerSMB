package LedgerSMB::DBObject::Asset;

=head1 NAME

LedgerSMB::DBObject::Asset - LedgerSMB Base Class for Fixed Assets

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving fixed assets for depreciation

=head1 STANDARD PROPERTIES

=over

=item id (integer)

Unique id number of asset.

=item description (text)

Text description of asset.

=item tag (text)

Arbitrary tag identifier, unique for current, non-disposed assets.

=item purchase_value (numeric)

Numeric representation of purchase value.

=item salvage_value (numeric)

Numeric representation of estimated salvage value.

=item usable_life (numeric)

Numeric representation of estimated usable life.

=item purchase_date (date)

Date item was purchase

=item start_depreciation (date)

Date item is put into service, when depreciation should start.  If unknown
we use the purchase_date instead.

=item location_id (int)

ID of business location where asset is stored.

=item department_id (int)

ID of department where asset is stored

=item invoice_id (int)

ID of purchasing invoice

=item asset_account_id (int)

ID of account to store asset value

=item dep_account_id (int)

ID of account to store cumulative depreciation

=item exp_account_id (int)

ID of account to store expense when disposed of.

=item obsolete_by (int)

Obsolete by other asset id.  Undef if active, otherwise the id of the active
asset that replaces this. Used for partial depreciation.

=item asset_class_id (int)

ID of asset class.

=back

=head1 METHODS

=over

=cut

use base qw(LedgerSMB::PGOld);
use strict;
use warnings;

=item save

Uses standard properties

Saves the asset item to the database

Sets any properties set by the database that were not in the original object,
usually ID (if no match to current ID or if ID was undef).

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'asset__save');
    $self->merge($ref);
    return $ref;
}

=item import_file

Parses a csv file.  Sets $self->{import_entries} to an arrayref where each
member is an arrayref of fields.  It is up to the workflow script to handle
these entries.

Header information is set to $self->{import_header}.

=cut

sub import_file {

    my $self = shift @_;

    my $handle = $self->{_request}->upload('import_file');
    my $contents = join("\n", <$handle>);

    $self->{import_entries} = [];
    for my $line (split /(\r\n|\r|\n)/, $contents){
        next if ($line !~ /,/);
        my @fields;
        $line =~ s/[^"]"",/"/g;
        while ($line ne '') {
            if ($line =~ /^"/){
                $line =~ s/"(.*?)"(,|$)//;
                my $field = $1;
                $field =~ s/\s*$//;
                push @fields, $field;
            } else {
                $line =~ s/([^,]*),?//;
                my $field = $1;
                $field =~ s/\s*$//;
                push @fields, $field;
            }
        }
        push @{$self->{import_entries}}, \@fields;
    }
                   # get rid of header line
    @{$self->{import_header}} = shift @{$self->{import_entries}};
    return @{$self->{import_entries}};
}

=item get

Gets a fixed asset, sets all standard properties.  The id property must be set.

=cut

sub get {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'asset__get');
    $self->merge($ref);
    return $ref;
}

=item search

Searches for asset_items matching criteria.  Sets $self->{search_results} to
the result.

Search criteria set by the following properties:
* id
* asset_class
* description
* tag
* purchase_date
* purchase_value
* usable_life
* salvage_value
* start_depreciation
* warehouse_id
* department_id
* invoice_id
* asset_account_id
* dep_account_id

Tag and description are partial matches.  All other matches are exact.  Undef
matches all values.

=cut

sub search {
    my ($self) = @_;
    my @results = $self->call_dbmethod(funcname => 'asset_item__search');
    $self->{search_results} = \@results;
    return @results;
}

=item save_note

Saves a note.  Uses the following properties:

* id
* subject
* note

=cut

sub save_note {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'asset_item__add_note');
}

=item get_metadata

Sets the following:

* asset_classes:  List of all asset classes
* locations:  List of all warehouses/locations
* deprtments:  List of all departments
* asset_accounts:  List of all asset accounts
* dep_accounts:  List of all depreciation accounts
* exp_accounts:  List of all expense accounts

=cut

sub get_metadata {
    my ($self) = @_;
    @{$self->{asset_classes}} = $self->call_dbmethod(funcname => 'asset_class__list');
   @{$self->{locations}} = $self->call_dbmethod(funcname => 'warehouse__list_all');
   @{$self->{departments}} = $self->call_procedure(funcname => 'business_unit__list_by_class', args => [1, undef, undef, undef]);
    @{$self->{asset_accounts}} = $self->call_dbmethod(funcname => 'asset_class__get_asset_accounts');
    @{$self->{dep_accounts}} = $self->call_dbmethod(funcname => 'asset_class__get_dep_accounts');
    @{$self->{exp_accounts}} = $self->call_dbmethod(
                   funcname => 'asset_report__get_expense_accts'
    );
    my @dep_methods = $self->call_dbmethod(
                                funcname => 'asset_class__get_dep_methods'
    );
    for my $dep(@dep_methods){
        $self->{dep_method}->{$dep->{id}} = $dep;
    }
    for my $acc (@{$self->{asset_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
    for my $acc (@{$self->{dep_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
    for my $acc (@{$self->{exp_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
}

=item get_next_tag

Returns next tag number

Sets $self->{tag} to that value.

=cut

sub get_next_tag {
    my ($self) =  @_;
    my ($ref) = $self->call_procedure(
          funcname => 'setting_increment',
          args     => ['asset_tag']
    );
    $self->{tag} = $ref->{setting_increment};
}

=item import_asset

Uses standard properties.  Saves record in import report for batch review and
creation.

=cut

sub import_asset {
    my ($self) =  @_;
    my ($ref) = $self->call_dbmethod(funcname => 'asset_report__import');
    return $ref;
}

sub get_invoice_id {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'get_vendor_invoice_id');
    if (!$ref) {
        $self->error($self->{_locale}->text('Invoice not found'));
    } else {
        $self->{invoice_id} = $ref->{get_vendor_invoice_id};
    }
}


=back

=head1 Copyright (C) 2010-2014, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
