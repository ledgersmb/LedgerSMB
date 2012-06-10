=head1 NAME

LedgerSMB::DBObject::Report::Unapproved::Batch_Detail - List Vouchers by Batch 
in LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::DBObject::Report::Unapproved::Batch_Detail->new(
      %$request
  );
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This provides an ability to search for (and approve or delete) pending
transactions grouped in batches.  This report only handles the vouchers in the 
bach themselves. For searching for batches, use
LedgerSMB::DBObject::Report::Unapproved::Batch_Overview instead.

=head1 INHERITS

=over

=item LedgerSMB::DBObject::Report;

=back

=cut

package LedgerSMB::DBObject::Report::Unapproved::Batch_Detail;
use Moose;
extends 'LedgerSMB::DBObject::Report';

use LedgerSMB::DBObject::Business_Unit_Class;
use LedgerSMB::DBObject::Business_Unit;
use LedgerSMB::App_State;

my $locale = $LedgerSMB::App_State::Locale;

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=item select

Select boxes for selecting the returned items.

=item id

ID of transaction

=item batch_class

Text description of batch class

=item transdate

Post date of transaction
use LedgerSMB::DBObject::Report::Unapproved::Batch_Overview;

=item reference text

Invoice number or GL reference

=item description

Description of transaction

=item amount

Total on voucher.  For AR/AP amount, this is the total of the AR/AP account 
before payments.  For payments, receipts, and GL, it is the sum of the credits.

=back

=cut

our @COLUMNS = (
    {col_id => 'select',
       name => '',
       type => 'checkbox' },

    {col_id => 'id',
       name => $locale->text('ID'),
       type => 'text',
     pwidth => 1, },

    {col_id => 'batch_class',
       name => $locale->text('Batch Class'),
       type => 'text', 
     pwidth => 2, },

    {col_id => 'default_date',
       name => $locale->text('Date'),
       type => 'text',
     pwidth => '4', },

    {col_id => 'Reference',
       name => $locale->text('Reference'),
       type => 'href',
  href_base => '',
     pwidth => '3', },

    {col_id => 'description',
       name => $locale->text('Description'),
       type => 'text',
     pwidth => '6', },

    {col_id => 'amount',
       name => $locale->text('Amount'),
       type => 'text',
     pwidth => '2', },

);

sub columns {
    return \@COLUMNS;
}

    # TODO:  business_units int[]

=item name

Returns the localized template name

=cut

sub name {
    return $locale->text('Voucher List');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [{name => 'batch_id',
             text => $locale->text('Batch ID')}, ]
}

=item subtotal_cols

Returns list of columns for subtotals

=cut

sub subtotal_cols {
    return [];
}

=head2 Criteria Properties

Note that in all cases, undef matches everything.

=item batch_id (Int)

ID of batch to list vouchers of.

=cut

has 'batch_id' => (is => 'rw', isa => 'Int');

=head1 METHODS

=over

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    $self->buttons([{
                    name  => 'action',
                    type  => 'submit',
                    text  => $locale->text('Post Batch'),
                    value => 'batch_approve',
                    class => 'submit',
                 },{
                    name  => 'action',
                    type  => 'submit',
                    text  => $locale->text('Delete Batch'),
                    value => 'batch_delete',
                    class => 'submit',
                 },{
                    name  => 'action',
                    type  => 'submit',
                    text  => $locale->text('Delete Vouchers'),
                    value => 'vouchers_delete',
                    class => 'submit',
                }]);
    my @rows = $self->exec_method({funcname => 'batch__search'});
    for my $r (@rows){
       # TODO hrefs
       $r->{row_id} = $r->{id};
    }
    $self->rows(\@rows);
}


=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;
return 1;
