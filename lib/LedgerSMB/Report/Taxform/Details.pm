
package LedgerSMB::Report::Taxform::Details;

=head1 NAME

LedgerSMB::Report::Taxform::Details - 1099 and similar details forms for
LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Taxform::Details->new(%$request);
  $report->render($report);

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

Taxforms are used to handle VAT reporting in Europe and 1099 reporting in the
US.  These can be set up to do accrual or cash basis reporting (different
countries have different requirements).

This report provides a listing of transactions and invoices which are reported
for a given vendor.  This is used largely for verifying the values reported.

=head1 CRITERIA PROPERTIES

=head2 tax_form_id

This is the id of the taxform.

=cut

has tax_form_id => (is => 'ro', isa => 'Int', required => '1');

has taxform => (is => 'rw', isa => 'Str', required => 0);

has is_accrual => (is => 'rw', isa => 'Bool', required => 0, default => 0);

=head2 meta_number

This is the vendor number.

=cut

has meta_number => (is => 'ro', isa => 'Str', required => '1');

=head1 REPORT CONSTANTS

=head2 columns

=over

=item legal_name

=item account_type

=item meta_number

=item invnumber

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

     { col_id  => 'invnumber',
       type    => 'text',
       name    => $self->Text('Invoice Number') },

     { col_id  => 'acc_sum',
       type    => 'text',
       name    => $self->Text('Ledger sum') },

     { col_id  => 'invoice_sum',
       type    => 'text',
       name    => $self->Text('Invoice sum') },

     { col_id  => 'total',
       type    => 'text',
       name    => $self->Text('Total') },
     ];
}

=head2 header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [
        { value => $self->from_date,   text => $self->Text('From Date') },
        { value => $self->to_date,     text => $self->Text('To Date') },
        { value => $self->taxform,     text => $self->Text('Tax Form') },
        { value => $self->meta_number, text => $self->Text('Account Number') },
    ];
}

=head2 name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Tax Form Details Report');
}

=head2 buttons

=cut

sub buttons {
    my ($self) = @_;
    return [{name => '__action',
             type => 'submit',
             'data-dojo-type' => 'lsmb/PrintButton',
             'data-dojo-props' => 'minimalGET: false',
             text => $self->Text('Print'),
            value => 'print'}];
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my $fname = 'tax_form_details_report';
    $fname .= '_accrual' if $self->is_accrual;
    my @rows = $self->call_dbmethod(funcname => $fname);

    for my $row(@rows){
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
