package LedgerSMB::Template::DBProvider;

=head1 NAME

LedgerSMB::Template::Provider - Implements template loading from database

=head1 SYNOPSIS

 use Template;
 use LedgerSMB::Template::DBProvider;

 my $template = Template->new({
       LOAD_TEMPLATES => [ LedgerSMB::Template::DBProvider->new() ]
 });


=cut

use strict;
use warnings;

use Template::Provider;
use PGObject::Type::DateTime;

use Moose;
use namespace::autoclean;
use MooseX::NonMoose;
extends 'Template::Provider';
with 'LedgerSMB::PGObject';

my $logger = Log::Log4perl->get_logger(__PACKAGE__);


=head1 DESCRIPTION

This template provider loads templates, including those referenced by
INCLUDE, INSERT and PROCESS statements, from the company database.

=head1 ATTRIBUTES

=over

=item language_code

The language for which to retrieve the templates.

=cut

has 'language_code' => (is => 'ro');

=item format

The format for which to retrieve the templates.

=cut

has 'format' => (is => 'ro');


=back

=cut

sub _retrieve_template_data {
    my ($self, $name) = @_;
    my @langs;

    if (defined $self->language_code) {

        # First search for a specific dialect - for example 'fr_BE'
        push @langs, $self->language_code
            if $self->language_code =~ m/_/;

        # Then try the base language - for example 'fr'
        my $lang = $self->language_code;
        $lang =~ s/_.*//;
        push @langs, $lang;
    }

    # As a last resort, look for a template with no language
    push @langs, undef;

    my $rv;
    foreach my $lang (@langs) {
        $logger->info("Retrieving template for ($name, " . ( $lang // '-undef-' ) . ', '
                      . $self->format . ')');
        $rv = $self->call_procedure(
            funcname => 'template__get',
            args => [
                $name,
                $lang,
                $self->format
            ]
        );
        last if defined $rv->{template};
    }
    $logger->warn("No match found retrieving the template '$name'")
        unless defined $rv->{template};
    return undef unless defined $rv->{template};

    $logger->info('Match found');
    $rv->{last_modified} = PGObject::Type::DateTime->from_db(
        $rv->{last_modified}
    );
    return $rv;
}

=head1 METHODS

=over

=item _template_modified($path)

Implements the super's protocol: returns the epoch() integer calculated
from the database's 'last_modified' column.


=cut

sub _template_modified {
    my ($self, $path) = @_;
    # TT thinks <path> and ./<path> are the same thing.
    $logger->info("last modified date requested for $path");
    $path =~ s#^./##;

    my $tpl = $self->_retrieve_template_data($path);
    $logger->warn("No last modified date for $path")
        unless $tpl->{last_modified};
    return ($tpl->{last_modified}) ? int($tpl->{last_modified}->epoch) : undef;
}

=item _template_content($path) {

Implements the super's protocol, depending on context, returns:

 - scalar: template content or 'undef'
 - list: ($content, $error, $mtime) where $error is a string and $mtime an int

=cut

sub _template_content {
    my ($self, $path) = @_;
    # TT thinks <path> and ./<path> are the same thing.

    $logger->info("Retrieving template content for $path");
    $path =~ s#^./##;

    my $tpl = $self->_retrieve_template_data($path);
    $logger->error("Template for $path not found")
        if ! defined $tpl->{template};
    return wantarray
        ? ($tpl->{template},
           (defined $tpl->{template}) ? undef : 'not found',
           ($tpl->{last_modified}) ? int($tpl->{last_modified}->epoch) : undef)
        : $tpl->{template};
}

=item _compiled_filename()

Overrides the parent's compiled file name calculation in order to
disable caching: the filename (template name) isn't the only
factor determining the template content (other factors: format, language).

=cut

sub _compiled_filename {
    $logger->debug('declining template caching');
    return undef;
}



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
