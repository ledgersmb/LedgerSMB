package LedgerSMB::DBObject::Asset_Class;

=head1 NAME

LedgerSMB::DBObject::Asset_Class.pm, LedgerSMB Base Class for Asset Classes

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving depreciation categories of assets.

=head1 STANDARD PROPERTIES

=over

=item id

Integer ID of record.

=item lable

Text description of asset class

=item asset_account_id 

Integer id of asset account.

=item dep_account_id 

Integer id of depreciation account.

=item method 

Integer id of depreciation method.

=back

=head1 METHODS

=over

=cut

use base qw(LedgerSMB::DBObject);
use strict;

=item save

Properties used:
id:  (Optional) ID of existing class to overwrite. 
asset_account_id: Account id to store asset values
dep_account_id: Account id for depreciation information 
method:  ID of depreciation method
label:  Name of the asset class
unit_label:  Label of the depreciation unit

Typically sets ID if no match found or if ID not provided.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset_class__save');
    $self->merge($ref);
    $self->{dbh}->commit || $self->error(
                  $self->{_locale}->text("Unable to save [_1] object", 
                          $self->{_locale}->text('Asset Class'))
    );
    return $ref if $self->{dbh}->commit;
}

=item get_metadata 

sets:

asset_accounts to arrayref of asset accounts
dep_accounts to arrayref of depreciation accounts
dep_methods to arrayrefo of depreciation methods

=cut

sub get_metadata {
    my ($self) = @_;
    @{$self->{asset_accounts}} = $self->exec_method(funcname => 'asset_class__get_asset_accounts');
    @{$self->{dep_accounts}} = $self->exec_method(funcname => 'asset_class__get_dep_accounts');
    @{$self->{dep_methods}} = $self->exec_method(funcname => 'asset_class__get_dep_methods');
    for my $acc (@{$self->{asset_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
    for my $acc (@{$self->{dep_accounts}}){
        $acc->{text} = $acc->{accno} . '--' . $acc->{description};
    }
}

=item get_asset_class()

Requires id to be set.

Sets all other standard properties if the record is found.

=cut

sub get_asset_class {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset_class__get');
    $self->merge($ref);
    return $ref;
}

=item list_asset_classes

Sets classes to a list of all asset classes, ordered as per db.

=cut

sub list_asset_classes {
    my ($self) = @_;
    my @refs = $self->exec_method(funcname => 'asset_class__list');
    $self->{classes} = \@refs;
    return @refs;
}

=back

=head1 Copyright (C) 2010, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
