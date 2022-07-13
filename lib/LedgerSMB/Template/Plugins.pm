package LedgerSMB::Template::Plugins;

=head1 NAME

LedgerSMB::Template::Plugins - Module to manage template output format plugins

=head1 DESCRIPTION



=head1 SYNOPSIS

  output_formats:
    $class: LedgerSMB::Template::Plugins
    plugins:
      - $class: LedgerSMB::Template::Plugin::LaTeX
        formats: [ "PDF" ]           # Supports PDF too, but suppress that
      - $class: LedgerSMB::Template::Plugin::CSV
      - $class: MyTemplate::Plugin::Format

=cut

use strict;
use warnings;

use Module::Runtime;
use List::Util qw(any first);

use Moo;


=head1 ATTRIBUTES

=head2 plugins

=cut

has plugins => (is => 'ro', default => sub { [] });

has _cache => (is => 'ro', default => sub { {} });

=head1 METHODS

=head2 get( $output_format )

=cut

sub get {
    my ($self, $fmt) = @_;
    return $self->_cache->{$fmt} if exists $self->_cache->{$fmt};

    return $self->_cache->{$fmt} =
        first { $_->format eq $fmt } $self->plugins->@*;
}

=head2 get_formats

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
