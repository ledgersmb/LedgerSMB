=head1 NAME

LedgerSMB::Report::Taxform::List - A list of tax forms defined in LedgerSMB

=head1 SYNPOSIS

Since there are no criteria, no $request required.

  my $report = LedgerSMB::Report::Taxform::List->new();
  $report->render();

=head1 DESCRIPTION

This is a simple list of tax forms.

=cut

package LedgerSMB::Report::Taxform::List;
use Moose;
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
    return [
      {col_id => 'form_name',
         type => 'href',
    href_base => 'taxform.pl?action=edit&id=',
         name => LedgerSMB::Report::text('Form Name')},

      {col_id => 'country_name',
         type => 'text',
         name => LedgerSMB::Report::text('Country Name')},

      {col_id => 'default_reportable',
         type => 'text',
         name => LedgerSMB::Report::text('Default Reportable')}
    ];
}

=head2 header_lines

=cut

sub header_lines { return []; }

=head2 name

Tax Form List

=cut

sub name { return LedgerSMB::Report::text('Tax Form List'); }

=head2 buttons

=cut

sub buttons {
    return  [{
         text => LedgerSMB::Report::text('Add New Tax Form'),
        value => 'add_taxform',
         name => 'action',
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
                                     ? LedgerSMB::Report::text('Yes')
                                     : LedgerSMB::Report::text('No');
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright(C) 2013 The LedgerSMB Core Team

This file may be re-used in accordance with the GNU General Public License
version 2 or at your option any later version.  Please see the LICENSE.TXT
included.

=cut

__PACKAGE__->meta->make_immutable;

1;
