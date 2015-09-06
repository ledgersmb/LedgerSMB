=head1 NAME

LedgerSMB::Report::Axis - Models axes of financial reports

=head1 SYNPOSIS

  my $axis = LedgerSMB::Report::Axis->new();
  my $id = $axis->map_path(['head1','head2','head3','acc']);
  my $axis_ids = $axis->sort();

=head1 DESCRIPTION

This module provides a mapping of (hierarchical) account reporting to
a flat axis as required for generation of the table that makes up the
final report.

=cut

package LedgerSMB::Report::Axis;
use Moose;


=head1 PROPERTIES

=over

=item tree

Read-only accessor, a hash of hashes, keyed on the "account number".

E.g.:

 { 'head1' => { id => 1,
                children => { 'head2' => { id => 2,
                                           children => {} }
                            }
              }
 }

=cut

has 'tree' => ( is => 'ro',
                default => sub { {} },
                isa => 'HashRef' );

=item ids

Read-only accessor; a list of IDs of axis elements.

=cut

has 'ids' => ( is => 'ro',
               default => sub { {} },
               isa => 'HashRef' );


has '_last_id' => ( is => 'rw',
                    default => 0,
                    isa => 'Int' );

=back

=head1 METHODS

=over

=item map_path()

Maps a given path to an axis ID

=cut

sub map_path {
    my ($self, $path) = @_;
    my $subtree = $self->tree;

    my $elem;
    my $this_path = [];
    for my $step (@$path) {
        push @$this_path, $step;
        $self->_new_elem($subtree, $step, $this_path)
            if ! exists $subtree->{$step};

        $elem = $subtree->{$step};
        $subtree = $subtree->{$step}->{children};
    }
    return $elem->{id};
}

sub _new_elem {
    my ($self, $subtree, $step, $path) = @_;

    $subtree->{$step} = {
        id => $self->_last_id($self->_last_id + 1),
        path => [ (@$path) ],
        children => {},
    };
    $self->ids->{$subtree->{$step}->{id}} = $subtree->{$step};
}

=item sort

Returns an array reference with axis IDs, alphabetically sorted
by the elements in the path (usually header and account numbers)

=cut

sub sort {
    my ($self) = @_;

    return _sort_aux($self->tree);
}

sub _sort_aux {
    my ($subtree) = @_;

    my @sorted;
    for (sort { $a cmp $b } keys %$subtree) {
        push @sorted, $subtree->{$_}->{id};
        push @sorted, @{_sort_aux($subtree->{$_}->{children})};
    }
    return \@sorted;
}

=item $self->id_props($id, [\@props])

Returns the properties registered for the given ID.

If an array reference is provided as the second parameter,
that value is used to set the ID's properties.

=cut

sub id_props {
    my ($self, $id, $props) = @_;

    $self->ids->{$id}->{props} = $props
        if defined $props;

    return $self->ids->{$id}->{props};
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2015 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
