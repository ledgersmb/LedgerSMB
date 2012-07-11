=head1 NAME

LedgerSMB::DBObject::Report::Unapproved::Drafts - Unapproved Drafts (single 
transactions) in LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::DBObject::Report::Unapproved::Drafts->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This provides an ability to search for (and approve or delete) pending
transactions.  

=head1 INHERITS

=over

=item LedgerSMB::DBObject::Report;

=back

=cut

package LedgerSMB::DBObject::Report::Unapproved::Drafts;
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

our @COLUMNS = (
    {col_id => 'select',
       name => '',
       type => 'checkbox' },

    {col_id => 'id',
       name => $locale->text('ID'),
       type => 'text',
     pwidth => 1, },

    {col_id => 'transdate',
       name => $locale->text('Date'),
       type => 'text',
     pwidth => '4', },

    {col_id => 'reference',
       name => $locale->text('Reference'),
       type => 'href',
  href_base => '',
     pwidth => '3', },

    {col_id => 'description',
       name => $locale->text('Description'),
       type => 'text',
     pwidth => '6', },

    {col_id => 'amount',
       name => $locale->text('AR/AP/GL Amount'),
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
    return $locale->text('Draft Search');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [{name => 'type',
             text => $locale->text('Draft Type')},
            {name => 'reference',
             text => $locale->text('Reference')},
            {name => 'amount_gt',
             text => $locale->text('Amount Greater Than')},
            {name => 'amount_lt',
             text => $locale->text('Amount Less Than')}, ]
}

=item subtotal_cols

Returns list of columns for subtotals

=cut

sub subtotal_cols {
    return [];
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
    my @rows = $self->exec_method({funcname => 'draft__search'});
    for my $ref (@rows){
        my $script = $self->type;
        if ($ref->{invoice}){
            $script = 'is' if $self->type eq 'ar';
            $script = 'ir' if $self->type eq 'ap';
        }
        $ref->{reference_href_suffix} = "$script.pl?action=edit&id=$ref->{id}";
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
return 1;
