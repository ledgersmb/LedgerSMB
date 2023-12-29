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

use LedgerSMB::Template;

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

=head2 report_doc_renderer( $dbh, $format, $options, $extra_vars )

Returns a renderer function to be passed to the C<render> function of
C<LedgerSMB::Report>. This renderer causes the report C<render> function
to return an evaluated C<LedgerSMB::Template>.

=cut

sub report_doc_renderer {
    my ($self, $dbh, $format, $options, $extra_vars) = @_;
    $extra_vars //= {};

    return sub {
        my ($template_name, $report, $vars, $cvars) = @_;
        my $template = LedgerSMB::Template->new( # printed document
            template => $template_name,
            path     => 'DB',
            dbh      => $dbh,
            formatter_options => {
                $options->%{ qw( numberformat dateformat ) }
            },
            output_options => {
                filename => $report->output_name . '.' . lc($format),
            },
            format_plugin   =>
               $self->get( uc($format) ),
            );

        my %combined_vars = ( %$extra_vars, %$vars );
        $combined_vars{SETTINGS}->{papersize} //= 'letter';
        $template->render( \%combined_vars, $cvars);

        return $template;
    };
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
