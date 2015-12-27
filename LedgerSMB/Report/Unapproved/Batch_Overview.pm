=head1 NAME

LedgerSMB::Report::Unapproved::Batch_Overview - Search Batches in
LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Unapproved::Batch_Overview->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This provides an ability to search for (and approve or delete) pending
transactions grouped in batches.  This report only handles the batches
themselves.  You cannot delete individual vouchers in this report.  For that,
use LedgerSMB::Report::Unapproved::Batch_Detail instead.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

package LedgerSMB::Report::Unapproved::Batch_Overview;
use Moose;
extends 'LedgerSMB::Report';

use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Business_Unit;

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=item select

Select boxes for selecting the returned items.

=item id

ID of transaction

=item post_date

Post date of transaction

=item reference text

Invoice number or GL reference

=item description

Description of transaction

=item transaction_total

Total of AR/AP/GL vouchers (GL vouchers credit side only is counted)

=item payment_total

Total of payment lines (credit side)

Amount

=back

=cut


sub columns {
    my ($self) = @_;
    my @COLUMNS = (
        {col_id => 'select',
         name => '',
         type => 'checkbox' },

        {col_id => 'batch_class',
         name => $self->_locale->text('Type'),
         type => 'text'},

        {col_id => 'id',
         name => $self->_locale->text('ID'),
         type => 'text',
         pwidth => 1, },

        {col_id => 'default_date',
         name => $self->_locale->text('Date'),
         type => 'text',
         pwidth => '4', },

        {col_id => 'control_code',
         name => $self->_locale->text('Control Code'),
         type => 'href',
         href_base => 'vouchers.pl?action=get_batch&batch_id=',
         pwidth => '3', },

        {col_id => 'description',
         name => $self->_locale->text('Description'),
         type => 'text',
         pwidth => '6', },

        {col_id => 'transaction_total',
         name => $self->_locale->text('AR/AP/GL Amount'),
         type => 'text',
         money => 1,
         pwidth => '2', },

        {col_id => 'payment_total',
         name => $self->_locale->text('Payment Amount'),
         type => 'text',
         money => 1,
         pwidth => '2', },
        );

    return @COLUMNS;
}

    # TODO:  business_units int[]

=item name

Returns the localized template name

=cut

sub name {
    my ($self) = @_;
    return $self->_locale->text('Batch Search');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    my ($self) = @_;
    return [{name => 'batch_class',
             text => $self->_locale->text('Batch Type')},
            {name => 'reference',
             text => $self->_locale->text('Reference')},
            {name => 'amount_gt',
             text => $self->_locale->text('Amount Greater Than')},
            {name => 'amount_lt',
             text => $self->_locale->text('Amount Less Than')}, ]
}

=item subtotal_cols

Returns list of columns for subtotals

=cut

sub subtotal_cols {
    return [];
}

sub text {
    my ($self) = @_;
    return $self->_locale->maketext(@_);
}

=back

=head2 Criteria Properties

Note that in all cases, undef matches everything.

=over

=item reference (text)

Exact match on reference or invoice number.

=cut

has 'reference' => (is => 'rw', isa => 'Maybe[Str]');

=item type

ar for AR drafts, ap for AP drafts, gl for GL ones.

=cut

has 'type' => (is => 'rw', isa => 'Int');

=item class_id

class id associated with type

=cut

has class_id => (is => 'rw', isa => 'Int');

=item amount_gt

The amount of the draft must be greater than this for it to show up.

=cut

has 'amount_gt' => (is => 'rw', isa => 'Maybe[Str]');

=item amount_lt

The amount of the draft must be less than this for it to show up.

=cut

has 'amount_lt' => (is => 'rw', isa => 'Maybe[Str]');

=back

=head1 METHODS

=over

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    $self->class_id($self->type) if $self->type;
    $self->buttons([{
                    name  => 'action',
                    type  => 'submit',
                    text  => $self->_locale->text('Post'),
                    value => 'batch_approve',
                    class => 'submit',
                 },{
                    name  => 'action',
                    type  => 'submit',
                    text  => $self->_locale->text('Delete'),
                    value => 'batch_delete',
                    class => 'submit',
                 },{
                    name  => 'action',
                    type  => 'submit',
                    text  => $self->_locale->text('Unlock'),
                    value => 'batch_unlock',
                    class => 'submit',
                }]);
    my @rows = $self->call_dbmethod(funcname => 'batch__search');
    for my $r (@rows){
       $r->{row_id} = $r->{id};
    }
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
