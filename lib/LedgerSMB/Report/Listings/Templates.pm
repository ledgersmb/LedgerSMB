
package LedgerSMB::Report::Listings::Templates;

=head1 NAME

LedgerSMB::Report::Listings::Templates - A List of templates installed in the
db for LedgerSMB

=head1 SYNOPSIS

   LedgerSMB::Report::Listings::Templates->new(%$request)->render($request);

=head1 DESCRIPTION

Provides a listing of templates installed in the db (for things like invoices
and orders).  This is not used for the user interface templates.

=cut

use Moose;
use namespace::autoclean;
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
    my ($self) = @_;
    return [
      { col_id => 'template_name',
          name => $self->Text('File Name'),
          type => 'href',
     href_base => 'templates.pl?action=display&' },
      { col_id => 'format',
          name => $self->Text('Format'),
          type => 'text' },
   ];
}


=head2 header_lines

Just the language_code

=cut

sub header_lines {
    my ($self) = @_;
    return [
        { name => 'language_code', text => $self->Text('Language') },
        ];
};

=head2 name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Template Listing');
};

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
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
