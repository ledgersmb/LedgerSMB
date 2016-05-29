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
use MooseX::NonMoose;
extends 'Template::Provider';
with 'PGObject::Simple::Role';


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

    my @rv = $self->call_dbmethod(funcname => 'template__get',
                                  args => { template_name => $name });

    return undef unless @rv;

    my $rv = pop @rv;
    $rv->{last_modified} =
        PGObject::Type::DateTime->from_db($rv->{last_modified});
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
    $path =~ s#^./##;

    my ($tpl) = $self->_retrieve_template_data($path);
    return int($tpl->{last_modified}->epoch);
}

=item _template_content($path) {

Implements the super's protocol, depending on context, returns:

 - scalar: template content or 'undef'
 - list: ($content, $error, $mtime) where $error is a string and $mtime an int

=cut

sub _template_content {
    my ($self, $path) = @_;
    # TT thinks <path> and ./<path> are the same thing.
    $path =~ s#^./##;

    my $tpl = $self->_retrieve_template_data($path);
    return wantarray
        ? ($tpl->{template}, undef, int($tpl->{last_modified}->epoch))
        : $tpl->{template};
}

=item _compiled_filename()

Overrides the parent's compiled file name calculation in order to
disable caching: the filename (template name) isn't the only
factor determining the template content (other factors: format, language).

=cut

sub _compiled_filename {
    return undef;
}



=back

=cut

__PACKAGE__->meta->make_immutable;

1;
