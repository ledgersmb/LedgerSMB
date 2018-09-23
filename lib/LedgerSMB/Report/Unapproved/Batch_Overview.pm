
package LedgerSMB::Report::Unapproved::Batch_Overview;

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

=item L<LedgerSMB::Report>

=back

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

=head1 PROPERTIES

=over

=item class_name

Read-only property returning the class name (e.g. 'AP', 'AR, 'Payment')
corresponding to the specified C<class_id> filter parameter.

Updated automatically when C<class_id> is set. Is C<undef> if C<class_id>
has not been set.

=cut

has 'class_name' => (
    is => 'ro',
    isa => 'Maybe[Str]',
    writer => '_set_class_name',
);

=back

=head2 Query Filter Properties:

Note that in all cases, undef matches everything.

=over

=item description (text)

Partial match on batch C<description> field.

=cut

has 'description' => (is => 'rw', isa => 'Maybe[Str]');

=item class_id

The batch class_id, as detailed in the C<batch_class> database
table. (1=>AP, 2=>AR, 3=>Payment etc).

=cut

has class_id => (
    is => 'rw',
    isa => 'Maybe[Int]',
    predicate => 'has_class_id',
    trigger => \&_build_class_name,
);

=item amount_gt

The batch amount must be greater than or equal to this.

=cut

has 'amount_gt' => (is => 'rw', isa => 'Maybe[Str]');

=item amount_lt

The batch amount must be less than or equal to this.

=cut

has 'amount_lt' => (is => 'rw', isa => 'Maybe[Str]');

=item approved

Bool:  if approved show only approved batches.  If not, show unapproved

=cut

has approved => (is => 'rw', 'isa' => 'Maybe[Bool]');

=back


=head1 METHODS

=head2 columns()

Read-only accessor, returns a list of columns.

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

    return \@COLUMNS;
}

=head2 name

Returns the localized template name

=cut

sub name {
    my ($self) = @_;
    return $self->_locale->text('Batch Search');
}

=head2 header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    my ($self) = @_;
    return [
            {name => 'class_name',
             text => $self->_locale->text('Transaction Type')},
            {name => 'description',
             text => $self->_locale->text('Description')},
            {name => 'amount_gt',
             text => $self->_locale->text('Amount Greater Than')},
            {name => 'amount_lt',
             text => $self->_locale->text('Amount Less Than')},
    ];
}

=head2 run_report()

Calls C<get_buttons> and C<get_rows> methods to query database for batches
matching our filter properties, then populate C<rows> and C<buttons>
properties.

=cut

sub run_report{
    my ($self) = @_;
    $self->get_buttons();
    $self->get_rows();
    return;
}

=head2 get_buttons()

Sets the object's C<buttons> property to define which buttons are shown
on the report.

If the report includes 'approved' batches, no buttons are displayed, as
their actions are not possible once a batch has been approved (meaning its
vouchers have been posted to the books).

Returns the object's C<buttons> property.

=cut

sub get_buttons {
    my ($self) = @_;

    if($self->approved || !defined $self->approved) {
        # Results include approved batches which cannot be altered
        $self->buttons([]);
    }
    else {
        # Results comprise only unapproved batches
        $self->buttons([
            {
                name  => 'action',
                type  => 'submit',
                text  => $self->_locale->text('Post'),
                value => 'batch_approve',
                class => 'submit',
            },
            {
                name  => 'action',
                type  => 'submit',
                text  => $self->_locale->text('Delete'),
                value => 'batch_delete',
                class => 'submit',
            },
            {
                name  => 'action',
                type  => 'submit',
                text  => $self->_locale->text('Unlock'),
                value => 'batch_unlock',
                class => 'submit',
            }
        ]);
    }

    return $self->buttons;
}

=head2 get_rows()

Queries the database for batches which fulfil the filter criteria, populating
the object C<rows> property.

For each row, the retrieved C<id> field is copied to an additional C<row_id>
field.

Returns the object's C<rows> property.

=cut

sub get_rows {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'batch__search');
    for my $r (@rows){
       $r->{row_id} = $r->{id};
    }

    $self->rows(\@rows);
    return $self->rows;
}


# PRIVATE METHODS

# _build_class_name()
#
# Returns the class_name corresponding to the object's class_id property,
# or undef if that is not defined. Sets the object's class_name property.

sub _build_class_name {
    my ($self, $class_id) = @_;
    my $class_name;

    if($class_id) {
        my $r = $self->call_dbmethod(funcname => 'batch_get_class_name');
        $class_name = $r->{batch_get_class_name};
    }

    return $self->_set_class_name($class_name);
}



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
