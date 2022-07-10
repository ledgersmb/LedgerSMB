
package LedgerSMB::Printers;

=head1 NAME

LedgerSMB::Printers -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Moo;

our $VERSION = '0.0.1';

has fallback => (is => 'ro');

has printers => (is => 'ro', default => sub { {} });

=head1 METHODS

=head2 as_options



=cut

sub as_options {
    my $self = shift;

    my @options = map {
        {
            text  => $_,
            value => $_
        }
    } keys $self->printers->%*;
    return wantarray ? @options : \@options;
}


=head2 get

=cut

sub get {
    my $self = shift;
    my $printer = shift;

    return $self->printers->{$printer};
}


=head2 names

=cut

sub names {
    my $self = shift;

    my @names = keys $self->printers->%*;
    return wantarray ? @names : \@names;
}

1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

