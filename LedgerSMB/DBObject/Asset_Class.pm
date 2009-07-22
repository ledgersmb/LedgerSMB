package LedgerSMB::DBObject::Asset_Class;

=head1 NAME

LedgerSMB::DBObject::Asset_Class.pm, LedgerSMB Base Class for Asset Classes

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving depreciation categories of assets.

=cut

use base qw(LedgerSMB::DBObject);
use strict;

sub save_asset_class {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset_class__save');
    $self->merge($ref);
    $self->{dbh}->commit || $self->error(
                  $self->{_locale}->text("Unable to save [_1] object", 
                          $self->{_locale}->text('Asset Class'))
    );
    return $ref if $self->{dbh}->commit;
}

sub get_metadata {
    my ($self) = @_;
    @{$self->{asset_accounts}} = $self->exec_method(funcname => 'asset_class__get_asset_accounts');
    @{$self->{dep_accounts}} = $self->exec_method(funcname => 'asset_class__get_dep_accounts');
    @{$self->{life_units}} = $self->exec_method(funcname => 'asset_class__get_life_units');
    @{$self->{dep_methods}} = $self->exec_method(funcname => 'asset_class__get_dep_methods');
}

sub get_asset_class {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset_class__get');
    $self->merge($ref);
    return $ref;
}

sub list_asset_classes {
    my ($self) = @_;
    my @refs = $self->exec_method(funcname => 'asset_class__list');
    $self->{classes} = \@refs;
    return @refs;
}

1;
