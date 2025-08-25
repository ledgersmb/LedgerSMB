
package LedgerSMB::Report::GL;

=head1 NAME

LedgerSMB::Report::GL - GL Reports for LedgerSMB

=head1 SYNPOSIS

  my $glreport = LedgerSMB::Report::GL->new(%$request);
  $glreport->render();

=head1 DESCRIPTION

This module provides GL reports for LedgerSMB.  GL reports are useful for
searching for and reporting financial transactions.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Report;

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates',
    'LedgerSMB::Report::Approval_Option',
    'LedgerSMB::Report::Voided_Option';

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=item id

=item reference

=item eca_name

=item description

=item transdate

=item source

=item memo

=item debits

=item credits

=item curr

=item fx_debits

=item fx_credits

=item entry_id

=item cleared

=item chart_id

=item accno

=item accname

=item gifi_accno

=item running_balance

=item one for each business unit class returned

=back

=cut

sub columns {
    my ($self) = @_;
    my @COLS = (
    {col_id => 'id',
       name => $self->Text('ID'),
       type => 'text',
     pwidth => 1, },

    {col_id => 'transdate',
       name => $self->Text('Date'),
       type => 'text',
     pwidth => '4', },

    {col_id => 'reference',
       name => $self->Text('Reference'),
       type => 'href',
  href_base => '',
     pwidth => '3', },

    {col_id => 'eca_name',
       name => $self->Text('Vendor Customer'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'description',
       name => $self->Text('Description'),
       type => 'text',
     pwidth => '6', },

    {col_id => 'entry_id',
       name => $self->Text('Entry ID'),
       type => 'text',
     pwidth => '1', },

    {col_id => 'debits',
       name => $self->Text('Debits'),
       type => 'text',
      money => 1,
     pwidth => '2', },

    {col_id => 'credits',
       name => $self->Text('Credits'),
       type => 'text',
      money => 1,
     pwidth => '2', },

    {col_id => 'curr',
       name => $self->Text('Curr'),
       type => 'text' },

    {col_id => 'fx_debits',
       name => $self->Text('FX Debits'),
       type => 'text',
      money => 1,
     pwidth => '2', },

    {col_id => 'fx_credits',
       name => $self->Text('FX Credits'),
       type => 'text',
      money => 1,
     pwidth => '2', },

    {col_id => 'source',
       name => $self->Text('Source'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'memo',
       name => $self->Text('Memo'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'cleared',
       name => $self->Text('Cleared'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'chart_id',
       name => $self->Text('Chart ID'),
       type => 'text',
     pwidth => '1', },

    {col_id => 'accno',
       name => $self->Text('Account Number'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'accname',
       name => $self->Text('Account Name'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'gifi_accno',
       name => $self->Text('GIFI'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'running_balance',
       name => $self->Text('Balance'),
       type => 'text',
      money => 1,
     pwidth => '3', },
    );
    my @bclasses = LedgerSMB::Business_Unit_Class->list('1', 'gl');
    for my $class (@bclasses){
        push @COLS, {col_id =>  'bc_' . $class->id,
                       name => $self->Maketext($class->label),
                       type => 'text',
                     pwidth => '2'};
    }
    return \@COLS;
}

=item filter_template

Returns the template name for the filter.

=cut

sub filter_template {
    return 'journal/search';
}

=item name

Returns the localized template name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('General Ledger Report');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    my ($self) = @_;
    return [{value => $self->from_date,
             text => $self->Text('Start Date')},
            {value => $self->to_date,
             text => $self->Text('End Date')},
            {value => $self->accno,
             text => $self->Text('Account Number')},
            {value => $self->reference,
             text => $self->Text('Reference')},
            {value => $self->source,
             text => $self->Text('Source')}];
}

=back

=head2 Criteria Properties

Note that in all cases, undef matches everything.

=over

=item reference (text)

Exact match on reference or invoice number.

=cut

has 'reference' => (is => 'rw', isa => 'Maybe[Str]');

=item accno

Exact match for the account number

=cut

has 'accno'  => (is => 'rw', isa => 'Maybe[Str]');


=item category

Is one of A (Asset), L (Liability), Q (Equity), I (Income), or E (Expense).

When set only matches lines attached to transactions of specified type.

=cut

has 'category' => (is => 'rw', isa => 'Maybe[Str]');

=item source

Exact match of source field

=cut

has 'source' => (is => 'rw', isa => 'Maybe[Str]');

=item memo

Full text search of memo field

=cut

has 'memo' => (is => 'rw', isa => 'Maybe[Str]');

=item description

Full text search of description field of GL transaction

=cut

has 'description' => (is => 'rw', isa => 'Maybe[Str]');


=item from_amount

The lowest value that can match, amount-wise for the line item.

=item to_amount

The highest value that can match, amount-wise for the line item.

=cut

has 'from_amount' => (is => 'rw', isa => 'LedgerSMB::PGNumber');
has 'to_amount' => (is => 'rw', isa => 'LedgerSMB::PGNumber');

=item business_units

Array of business unit id's

=cut

has 'business_units' => (is => 'rw', isa => 'Maybe[ArrayRef[Int]]');

=back

=head1 METHODS

=over

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub _exclude_from_totals {
    return {running_balance => 1};
}

sub _exclude_row_from_totals {
    my ($self, $row) = @_;
    return (not defined $row or not defined $row->{id});
}

sub run_report{
    my ($self) = @_;
    my $accno = $self->accno;
    $accno =~ s/--.*//;
    $self->accno($accno);
    $self->approved;
    my @rows = $self->call_dbmethod(funcname => 'report__gl');
    for my $ref(@rows){
        if ($ref->{amount} < 0){
            $ref->{debits} = $ref->{amount} * -1;
            $ref->{credits} = 0;
        } else {
            $ref->{credits} = $ref->{amount};
            $ref->{debits} = 0;
        }
        if ($ref->{amount_tc} < 0){
            $ref->{fx_debits} = $ref->{amount_tc} * -1;
            $ref->{fx_credits} = 0;
        } else {
            $ref->{fx_credits} = $ref->{amount_tc};
            $ref->{fx_debits} = 0;
        }
        if ($ref->{type} eq 'gl'){
           $ref->{reference_href_suffix} = "gl.pl?__action=edit&id=$ref->{id}";
        } elsif ($ref->{type} eq 'ar'){
           if ($ref->{invoice}){
                $ref->{reference_href_suffix} = 'is.pl';
           } else {
                $ref->{reference_href_suffix} = 'ar.pl';
           }
           $ref->{reference_href_suffix} .= "?__action=edit&id=$ref->{id}";
        } elsif ($ref->{type} eq 'ap'){
           if ($ref->{invoice}){
                $ref->{reference_href_suffix} = 'ir.pl';
           } else {
                $ref->{reference_href_suffix} = 'ap.pl';
           }
           $ref->{reference_href_suffix} .= "?__action=edit&id=$ref->{id}";
        }
        if ($ref->{cleared}){
            $ref->{cleared} = 'X';
        } else {
            $ref->{cleared} = '';
        }
        $self->process_bclasses($ref);
    }
    # to add opening balance and closing balance as first row and last row respectively
    # firstly, check whether user filtered report by account number or not
    # and check there is data rows
    if (defined $self->accno && @rows){
       my $first_row = $rows[0];
       my $last_row = $rows[$#rows];

       my $starting_balance =
           $first_row->{running_balance} - $first_row->{amount};
       my @starting_debcred;
       if ($starting_balance < 0) {
           @starting_debcred = (debits => -$starting_balance);
       }
       elsif ($starting_balance > 0) {
           @starting_debcred = (credits => $starting_balance);
       }
       unshift(@rows, {
           html_class => 'listsubtotal',
           NOINPUT => 1,
           description => $self->Text('Starting Balance'),
           running_balance => $first_row->{running_balance} - $first_row->{amount},
           @starting_debcred
       });

       my $ending_balance = $last_row->{running_balance};
       my @ending_debcred;
       if ($ending_balance < 0) {
           @ending_debcred = (debits => -$ending_balance);
       }
       elsif ($ending_balance > 0) {
           @ending_debcred = (credits => $ending_balance);
       }
       push(@rows, {
           html_class => 'listsubtotal',
           NOINPUT => 1,
           description => $self->Text('Ending Balance'),
           running_balance => $last_row->{running_balance},
           @ending_debcred
       });
    }
    return $self->rows(\@rows);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
