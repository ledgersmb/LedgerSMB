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
                  $self->{_locale}->text("Unable to save [_1] object", 
                          $self->{_locale}->text('Asset'))
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
    my ($self) = @_;
    my @results = $self->exec_method(funcname => 'asset__search');
    $self->{search_results} = \@results;
    return @results;
}


sub get_metadata {
    my ($self) = @_;
}


1;
