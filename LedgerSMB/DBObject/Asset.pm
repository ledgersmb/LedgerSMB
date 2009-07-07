package LedgerSMB::DBObject::Asset;

=head1 NAME

LedgerSMB::DBObject::Asset.pm, LedgerSMB Base Class for Fixed Assets

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving fixed assets for depreciation

=cut

use base qw(LedgerSMB::DBObject);
use strict;

sub save_asset {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset__save');
    $self->merge($ref);
    $self->{dbh}->commit || $self->error(
                  $locale->text("Unable to save [_1] object", 
                          $locale->text('Asset'))
    );
    return $ref if $self->{dbh}->commit;
}

sub get_asset {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'asset__get');
    $self->merge($ref);
    return $ref;
}

sub search_assets {
    # TODO
}


sub get_metadata {
    # TODO
}


1;
