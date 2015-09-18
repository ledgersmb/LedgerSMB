=head1 NAME

LedgerSMB::Report::Listings::Templates - A List of templates installed in the
db for LedgerSMB

=head1 SYNOPSIS

   LedgerSMB::Report::Listings::Templates->new(%$request)->render($request);

=head1 DESCRIPTION

Provides a listing of templates installed in the db (for things like invoices
and orders).  This is not used for the user interface templates.

=cut

package LedgerSMB::Report::Listings::Templates;
use Moose;
extends 'LedgerSMB::Report';

=head1 CRITERIA PROPERTIES

=head2 language_code (string)

Filters by language code.  If undefined, lists only ones with no language
defined.

=cut

has language_code => (is => 'ro', isa => 'Str', required => 0);

=head1 REPORT CONSTANT FUNCTIONS

=head2 columns

=over

=item template_name

=item format

=back

=cut

sub columns {
    return [
      { col_id => 'template_name',
          name => LedgerSMB::Report::text('File Name'),
          type => 'href',
     href_base => 'templates.pl?action=display&' },
      { col_id => 'format',
          name => LedgerSMB::Report::text('Format'),
          type => 'text' },
   ];
}


=head2 header_lines

Just the language_code

=cut

sub header_lines { return [
      { name => 'language_code', text => LedgerSMB::Report::text('Language') },
    ]
};

=head2 name

=cut

sub name { return LedgerSMB::Report::text('Template Listing') };

=head1 METHODS

=head2 run_report

Populates the $report->rows.

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'templates__list');
    for my $ref(@rows){
        $ref->{row_id} =
          "template_name=$ref->{template_name}&" .
          "language_code=$ref->{language_code}&format=$ref->{format}";
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2014 The LedgerSMB Core Team

This file may be re-used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.txt for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;
