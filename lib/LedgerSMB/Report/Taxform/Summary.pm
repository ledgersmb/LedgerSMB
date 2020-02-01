
package LedgerSMB::Report::Taxform::Summary;

=head1 NAME

LedgerSMB::Report::Taxform::Summary - Summary reports for 1099 and similar
forms for LedgerSMB

=head1 SYNPOSIS

 $report = LedgerSMB::Report::Taxform::Summary->new(%$request);
 $report->render($request);

=cut

use LedgerSMB::DBObject::TaxForm;
use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

Taxforms are used to handle VAT reporting in Europe and 1099 reporting in the
US.  These can be set up to do accrual or cash basis reporting (different
countries have different requirements).

This particular report shows the summary for a vendor over a given period of
time.  The numbers are broken up into transactions and with inventory.  Although
this usually has no significance regarding tax reporting, it is helpful for
internally revieing the numbers for accuracy.

=head1 CRITERIA PROPERTIES

In addition to the standard dates, there is only one property expected.

=head2 tax_form_id

This is the id of the taxform.

=cut

has tax_form_id => (is => 'ro', isa => 'Int', required => '1');

has taxform => (is => 'rw', isa => 'Str', required => 0);

=head1 REPORT CONSTANTS

=head2 columns

=over

=item legal_name

=item account_type

=item meta_number

=item acc_sum

=item invoice_sum

=item total

=back

=cut

sub columns {
    my ($self) = @_;
    return [{
        col_id => 'legal_name',
        type   => 'text',
        name   => $self->Text('Company'), },

      { col_id => 'account_type',
        type   => 'text',
        name   => $self->Text('Account Type'), },

      { col_id => 'meta_number',
        type   => 'text',
        name   => $self->Text('Account Number'), },

     { col_id  => 'control_code',
       type    => 'text',
       name    => $self->Text('Control Code') },

     { col_id  => 'acc_sum',
       type    => 'text',
       name    => $self->Text('Transactions') },

     { col_id  => 'invoice_sum',
       type    => 'text',
       name    => $self->Text('Invoices') },

     { col_id  => 'total',
       type    => 'href',
       href_base => 'taxform.pl?action=generate_report&',
       name    => $self->Text('Total') },
     ];
}

=head2 header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [
       { name => 'from_date', text => $self->Text('From Date') },
       { name => 'to_date',   text => $self->Text('To Date') },
       { name => 'taxform',   text => $self->Text('Tax Form') },
    ];
}

=head2 name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Tax Form Report');
}

=head2 buttons

=cut

sub buttons {
    my ($self) = @_;
    return [{name => 'action',
             type => 'submit',
             text => $self->Text('Print'),
            value => 'print'}];
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my $tf = LedgerSMB::DBObject::TaxForm->get($self->tax_form_id);
    $self->taxform($tf->{form_name});
    my $fname = 'tax_form_summary_report';
    $fname .= '_accrual' if $tf->{is_accrual};
    my @rows = $self->call_dbmethod(funcname => $fname);

    my $href_suffix_base = 'from_date=' . $self->from_date
                         . '&to_date=' . $self->to_date
                         . '&tax_form_id=' . $self->tax_form_id;
    for my $row(@rows){
       $row->{total_href_suffix} = $href_suffix_base
                                 . '&meta_number=' . $row->{meta_number};
       $row->{total} = $row->{acc_total} + $row->{invoice_total};
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
