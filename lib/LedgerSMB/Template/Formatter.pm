package LedgerSMB::Template::Formatter;

=head1 NAME

LedgerSMB::Template::Formatter - Module to manage template output format plugins

=head1 DESCRIPTION

This module manages the collection available output formats.

=head1 SYNOPSIS

  output_formats:
    $class: LedgerSMB::Template::Formatter
    plugins:
      - $class: LedgerSMB::Template::Plugin::LaTeX
        format: "PDF"           # Supports Postscript too, but suppress that
      - $class: LedgerSMB::Template::Plugin::CSV
      - $class: MyTemplate::Plugin::Format

=cut

use strict;
use warnings;

use Module::Runtime;
use List::Util qw(first);

use Moo;


=head1 ATTRIBUTES

=head2 plugins

Contains an array of configured output formats.

=cut

has plugins => (is => 'ro', default => sub { [] });


=head1 METHODS

=head2 get( $output_format )

Retrieves the formatter C<$output_format> from the configured list.

=cut

sub get {
    my ($self, $fmt) = @_;

    return first { $_->format eq $fmt } $self->plugins->@*;
}

=head2 get_formats

Retrieves the list of configured output formats. Returns a list in
list context or an arrayref in scalar context.

=cut

sub get_formats {
    my $self = shift;

    my @f = map { $_->format } $self->plugins->@*;
    return wantarray ? @f : \@f;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
