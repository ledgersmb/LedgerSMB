
package LedgerSMB::Report::Unapproved::Drafts;

=head1 NAME

LedgerSMB::Report::Unapproved::Drafts - Unapproved Drafts (single
transactions) in LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Unapproved::Drafts->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This provides an ability to search for (and approve or delete) pending
transactions.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

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

=item transdate

Post date of transaction

=item reference text

Invoice number or GL reference

=item description

Description of transaction

=item amount

Amount

=back

=cut

sub columns {
    my ($self) = @_;
    return [
    {col_id => 'select',
       name => '',
       type => 'checkbox' },

    {col_id => 'type',
       name => $self->Text('Type'),
       type => 'text' },

    {col_id => 'id',
       name => $self->Text('ID'),
       type => 'href',
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

    {col_id => 'description',
       name => $self->Text('Description'),
       type => 'text',
     pwidth => '6', },

    {col_id => 'amount',
       name => $self->Text('AR/AP/GL Amount'),
       type => 'text',
      money => 1,
     pwidth => '2', },
    ];
    # TODO:  business_units int[]
}


=item name

Returns the localized template name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Draft Search');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    my ($self) = @_;
    return [{name => 'type',
             text => $self->Text('Draft Type')},
            {name => 'reference',
             text => $self->Text('Reference')},
            {name => 'amount_gt',
             text => $self->Text('Amount Greater Than')},
            {name => 'amount_lt',
             text => $self->Text('Amount Less Than')}, ]
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

has 'type' => (is => 'rw', isa => 'Maybe[Str]');

=item amount_gt

The amount of the draft must be greater than this for it to show up.

=cut

has 'amount_gt' => (is => 'rw', coerce => 1, isa =>'LedgerSMB::Moose::Number');

=item amount_lt

The amount of the draft must be less than this for it to show up.

=cut

has 'amount_lt' => (is => 'rw', coerce => 1, isa =>'LedgerSMB::Moose::Number');

=back

=head1 METHODS

=over

=item set_buttons

=cut

sub set_buttons {
    my ($self) = @_;
    return [
      {name => 'action',
       type => 'submit',
       text => $self->Text('Approve'),
      value => 'approve',
      class => 'submit', },

      {name => 'action',
       type => 'submit',
       text => $self->Text('Delete'),
      value => 'delete',
      class => 'submit', },
    ];
}

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'draft__search');
    for my $ref (@rows){
        my $script = $ref->{type};
        $ref->{row_id} = $ref->{id};
        if ($ref->{invoice}) {
            $script = 'is' if $script eq 'ar';
            $script = 'ir' if $script eq 'ap';
        }
        $ref->{reference_href_suffix} = "$script.pl?action=edit&id=$ref->{id}";
        $ref->{id_href_suffix} = $ref->{reference_href_suffix};
    }
    return $self->rows(\@rows);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
