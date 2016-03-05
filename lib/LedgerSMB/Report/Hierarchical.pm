=head1 NAME

LedgerSMB::Report::Hierarchical - Table reports with hierarchical axes

=head1 SYNOPSIS

use LedgerSMB::Report::Hierarchical

=head1 DESCRIPTION

This report class is an abstract class.

=cut

package LedgerSMB::Report::Hierarchical;
use Moose;
extends 'LedgerSMB::Report';

use LedgerSMB::Report::Axis;

=head1 CRITERIA PROPERTIES

=over

=item to_date LedgerSMB::PGDate

=back

=head1 INTERNAL PROPERTIES

=head2 rheads

This stores the row (account) headings

=cut

has 'rheads' => (is => 'ro', isa => 'LedgerSMB::Report::Axis',
                 builder => '_build_row_axis');

sub _build_row_axis {
    return &_build_axis;
}

=head2 cheads

This stores the column (account) headings

=cut

has 'cheads' => (is => 'ro', isa => 'LedgerSMB::Report::Axis',
                 builder => '_build_col_axis');

sub _build_col_axis {
    return &_build_axis;
}

sub _build_axis {
    return LedgerSMB::Report::Axis->new;
}


=head2 cells

This stores the cell contents. This is a hash of hashes,
where the primary hash is keyed on row IDs as maintained by the 'rheads'
attribute.  The secondary hashes are keyed on row IDs as maintained by the
'cheads' attribute.  The values of the secondary hashes are numbers.

=cut

has 'cells' => (is => 'ro', isa => 'HashRef',
                default => sub { {} });


=head2 sorted_row_ids

Don't use! This field is here as a workaround for the fact that TT2
doesn't allow us to call methods on objects referenced through
retrieved values.

=cut

has sorted_row_ids => (is => 'rw');



=head1 STATIC METHODS

=over

=item columns

Implement inherited protocol.
Returns an empty arrayref since this is not applicable.

=cut

sub columns {
    return [];
};

=item header_lines

Implement inherited protocol.
Returns an empty arrayref since this is not applicable.

=cut

sub header_lines {
    return [];
}


=back

=head1 SEMI-PUBLIC METHODS

=head2 cell_value($row_id, $col_id, [$value])

Returns the value of the cell specified by $row_id and $col_id,
  optionally setting the value to $value if specified.

=cut

sub cell_value {
    my ($self, $row_id, $col_id, $value) = @_;

    $self->cells->{$row_id} = {}
        if ! exists $self->cells->{$row_id};

    $self->cells->{$row_id}->{$col_id} = $value
        if defined $value;

    return $self->cells->{$row_id}->{$col_id};
}

=head2 accum_cell_value($row_id, $col_id, $increment)

Returns the value of the cell identified by $row_id and $col_id,
  after incrementing the value of the cell by $increment.

If the cell doesn't exist yet, a value of 0 (zero) is assumed,
  effectively setting the value to $increment.

=cut

sub accum_cell_value {
    my ($self, $row_id, $col_id, $increment) = @_;

    return $self->cell_value($row_id, $col_id,
                             ($self->cell_value($row_id, $col_id) || 0)
                             + $increment);
}



=head2 add_comparison($compared, col_path_prefix => [],
    row_path_prefix => [])

TODO!!

=cut

sub add_comparison{
    my ($self, $compared, @args) = @_;
    my %args = (@args);
    my $row_path_prefix = $args{row_path_prefix} || [];
    my $col_path_prefix = $args{column_path_prefix} || [];

    for my $orig_row_id (keys %{$compared->rheads->ids}) {
        my $rprops = $compared->rheads->id_props($orig_row_id);
        next if $rprops->{section_for};

        for my $orig_col_id (keys %{$compared->cheads->ids}) {
            my $cprops = $compared->cheads->id_props($orig_col_id);
            next if $cprops->{section_for};

            my $row_id =
                $self->rheads->map_path([
                    (@$row_path_prefix),
                    (@{$compared->rheads->ids->{$orig_row_id}->{path}}) ]);
            my $col_id =
                $self->cheads->map_path([
                    (@$col_path_prefix),
                    (@{$compared->cheads->ids->{$orig_col_id}->{path}}) ]);
            $self->cell_value($row_id, $col_id,
                              $compared->cells->{$orig_row_id}->{$orig_col_id})
                if exists $compared->cells->{$orig_row_id}->{$orig_col_id};

            $self->rheads->id_props($row_id,
                                    $compared->rheads->id_props($orig_row_id))
                if ! defined $self->rheads->id_props($row_id);
            $self->cheads->id_props($col_id,
                                    $compared->cheads->id_props($orig_col_id))
                if ! defined $self->cheads->id_props($col_id);
        }
    }
}


before 'render' => sub {
    my ($self) = @_;

    $self->sorted_row_ids($self->rheads->sort);
};

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
