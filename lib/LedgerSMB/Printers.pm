
package LedgerSMB::Printers;

=head1 NAME

LedgerSMB::Printers - A set of configured printers

=head1 SYNOPSIS

  printers:
    $class: LedgerSMB::Printers
    fallback: printer1
    printers:
       printer1: lpr -Pprinter1
       printer2: lpr -Pprinter2

=head1 DESCRIPTION

This is a helper module to hold a list of printers with their commands
mainly used for dependency injection.

=cut

use strict;
use warnings;

use Moo;

our $VERSION = '0.0.1';

=head1 ATTRIBUTES

=head2 fallback

Name of the printer to use for scheduled transactions in case the printer
indicated in the recurring transaction isn't available.

=head2 printers

Holds a hashref with the names of the printers as keys and the shell
commands to send output, as the values.

=cut

has fallback => (is => 'ro');

has printers => (is => 'ro', default => sub { {} });

=head1 METHODS

=head2 as_options

Generates a list of printer names to be used as options in a SELECT
tag as generated through C<elements.html>.

Returns a list of options in list context or an arrayref in
scalar context.

=cut

sub as_options {
    my $self = shift;

    my @options = map {
        +{ text  => $_, value => $_ }
    } keys $self->printers->%*;
    return wantarray ? @options : \@options;
}


=head2 get( $printer )

Returns the command associated with the C<$printer>.

=cut

sub get {
    my $self = shift;
    my $printer = shift;

    return $self->printers->{$printer};
}


=head2 names

Returns the list of names of configured printers.

In list context, returns a list; in scalar context, returns an arrayref.

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

