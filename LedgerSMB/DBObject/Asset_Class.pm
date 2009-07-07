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
                  $locale->text("Unable to save [_1] object", 
                          $locale->text('Asset Class'))
    );
    return $ref if $self->{dbh}->commit;
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
