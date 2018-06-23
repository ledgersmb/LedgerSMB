
package LedgerSMB::Inventory::Adjust;

=head1 NAME

LedgerSMB::Inventory::Adjust - Inventory Adjustments for LedgerSMB

=head1 SYNPOSIS

 my $adjustment = LedgerSMB::Inventory::Adjust->new(%$request);
 $adjustment->add_line({parts_id => 1024, expected => 37, counted => 42});
 $adjustment->lines_from_request($request);
 $adjustment->save;

=cut

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject';
use LedgerSMB::MooseTypes;
use LedgerSMB::Inventory::Adjust_Line;

sub _get_prefix { return 'inventory_adjust__' }

=head1 DESCRIPTION

This module includes the basic routines for importing inventory adjustments,
initial inventory and the like.  Inventory adjustments follow the following
rules:

=over

=item Shrinkage and Loss

If the counted is less than expected (the normal case) then an we sell the
goods to ourselves at a 100% discount thus recording cost of goods sold for the
missing parts.

=item More than Expected

In the case where more is counted than expected we purchase the difference
from ourselves at last cost.  This invoice would be expected to be paid using an
equity account, though this is not currently automated.

=back

The process of counting inventory is a periodic one and therefore this needs to handle both initial inventory import and periodic corrections.

=head1 PROPERTIES

=over

=item id int

This is the id of the report, only valid once stored

=cut

has id => (is => 'rw', isa => 'Int', required => '0');

=item transdate date

This is the date the inventory was counted at.  The invoices take effect on
this date.  Required.

=cut

has transdate => (is => 'ro',      isa => 'LedgerSMB::Moose::Date',
              coerce => '1',  required => '1');

=item source text

This is the reference number or description of the count, may be the username
of the individual or the like.

=cut

has source => (is => 'ro', isa => 'Str', required => '1');

=item rows arrayref[LedgerSMB::Inventory::Adjust_Line]

This is a an array of journal entry lines to be added (lines are added one at
a time.)

=cut

has rows => (is => 'rw',
            isa => 'ArrayRef[LedgerSMB::Inventory::Adjust_Line]',
       required => '0');


=back

=head1 CONSTRUCTORS

=over

=item new

This constructor is the standard Moose constructor.

=item get( key => { id => $id } )

This constructor retrieves the adjustment with primary key C<id> equal to
C<$id> from the database and returns a C<LedgerSMB::Inventory::Adjust>
instance.

=back

=cut

sub get {
    my $class = shift;
    my %args = @_;

    my @dblines = __PACKAGE__->call_dbmethod( funcname => 'get_lines',
                                                args => $args{key} );
    my @lines = map { LedgerSMB::Inventory::Adjust_Line->new(%$_) } @dblines;

    my ($values) = __PACKAGE__->call_dbmethod( funcname => 'get',
                                               args => $args{key} );
    return __PACKAGE__->new(%$values, rows => \@lines);
}

=head1 METHODS

=over

=item add_line($hashref)

This function adds a line from a hashref.  Typically used by automatic import
routines and the like.

=cut

sub add_line{
    my ($self, $hashref) = @_;
    return if not $hashref->{partnumber} and not $hashref->{parts_id};
    my $line = LedgerSMB::Inventory::Adjust_Line->new(%$hashref);
    my @lines = @{$self->rows};
    push @lines, $line;
    return $self->rows(\@lines);
}

=item save

This saves the report.  In the process we run every line through a variance
check which allows the expected number of parts to be looked up if not provided.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'save_info');
    $self->id($ref->{id});
    for my $row(@{$self->rows}){
        $row->check_variance($self->transdate);
        $row->save($self->id);
    }
    return;
}

=item approve

Approves the inventory adjustment and creates the (draft) AR/AP invoices.
These can then be approved, adjusted, have payment lines recorded, and the like.

=cut

sub approve {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'approve');
    return;
};


=item delete

Deletes the inventory adjustment.  This can only be done if the inventory
adjustment is not approved.

=cut

sub delete {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'delete');
    return;
}

=item get_part_at_date

Returns a hashref with the information of the part's inventory information at
a given date.

=cut

sub get_part_at_date {
    my ($self, $transdate, $partnumber) = @_;
    my ($ref) = $self->call_procedure(funcname => 'get_item_at_day',
                                        args => [$transdate, $partnumber],
                                    funcprefix => 'inventory_');
    return $ref;
}

=back

=head1 LICENSE AND COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
