
package LedgerSMB::Report::Taxform::List;

=head1 NAME

LedgerSMB::Report::Taxform::List - A list of tax forms defined in LedgerSMB

=head1 SYNPOSIS

Since there are no criteria, no $request required.

  my $report = LedgerSMB::Report::Taxform::List->new();
  $report->render();

=head1 DESCRIPTION

This is a simple list of tax forms.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

=head1 CRITERIA PROPERTIES

none

=head1 REPORT CONSTANTS

=head2 columns

=over

=item form_name

=item country_name

=item default_reportable

=back

=cut

sub columns {
    my ($self) = @_;
    return [
      {col_id => 'form_name',
         type => 'href',
    href_base => 'taxform.pl?__action=edit&id=',
         name => $self->Text('Form Name')},

      {col_id => 'country_name',
         type => 'text',
         name => $self->Text('Country Name')},

      {col_id => 'default_reportable',
         type => 'text',
         name => $self->Text('Default Reportable')}
    ];
}

=head2 name

Tax Form List

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Tax Form List'); }

=head2 buttons

=cut

sub buttons {
    my ($self) = @_;
    return  [{
         text => $self->Text('Add Tax Form'),
        value => 'add_taxform',
         name => '__action',
         type => 'submit',
         class => 'submit'
    }];
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'tax_form__list_all');
    for my $row(@rows){
        $row->{row_id} = $row->{id};
        $row->{default_reportable} = ($row->{default_reportable})
                                     ? $self->Text('Yes')
                                     : $self->Text('No');
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
