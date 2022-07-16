
package LedgerSMB::LanguageResolver;

=head1 NAME

LedgerSMB::LanguageResolver -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use File::Find::Rule;
use HTTP::AcceptLanguage;

use Moo;

our $VERSION = '0.0.1';

=head1 ATTRIBUTES

=head2 directory

The directory in which the C<.po> language files are located which are
available for translation.

=cut

has directory => (is => 'ro');

# The list of available language codes as extracted from the files in the
# tranlation directory.

has _languages => (is => 'rw', lazy => 1, builder => '_build_languages');

sub _build_languages {
    my $self = shift;

    return [
        map {
            (lc($_) =~ s/_/-/r) =~ s/\.po//r;
        } File::Find::Rule
        ->new
        ->name( '*.po' )
        ->relative
        ->in( $self->directory )
        ];
}

=head1 METHODS

=head2 from_header( $accept_language )

Selects the most appropriate of available languages, based on the user's
preference as given by the C<Accept-Language> header, of which the value
is passed as the argument to this method.

=cut

sub from_header {
    my $self = shift;
    my $value = shift;

    return HTTP::AcceptLanguage->new($value)
        ->match($self->_languages->@*);
}


1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

