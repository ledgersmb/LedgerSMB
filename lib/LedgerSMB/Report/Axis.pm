
package LedgerSMB::Report::Axis;

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

use Moose;
use namespace::autoclean;

=head1 PROPERTIES

=over

=item tree

Read-only accessor, a hash of hashes, keyed on the "account number".

E.g.:

 { 'head1' => { id => 1,
                accno => 'head1',
                path => [ 'head1' ],
                section => { id => 2,
                             props => { section_for => 1 }
                           },
                children => { 'head2' => { id => 3,
                                           accno => 'head2',
                                           path => [ 'head1', 'head2' ],
                                           children => {},
                                           parent_id => 1
                                         }
                            }
              }
 }

=cut

has 'tree' => ( is => 'ro',
                default => sub { {} },
                isa => 'HashRef' );

=item ids

Read-only accessor; a list of IDs of axis elements, including section heads.

To skip section heads, skip IDs for which a props key 'section_for' exists.

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
        $self->_new_elem($subtree, $step, $this_path, $elem)
            if ! exists $subtree->{$step};

        $elem = $subtree->{$step};
        $subtree = $subtree->{$step}->{children};
    }
    return $elem->{id};
}

sub _new_elem {
    my ($self, $subtree, $step, $path, $parent) = @_;

    $subtree->{$step} = {
        id => $self->_last_id($self->_last_id + 1),
        accno => $step,
        path => [ (@$path) ],
        children => {},
        parent_id => $parent->{id},
    };
    $self->ids->{$subtree->{$step}->{id}} = $subtree->{$step};

    my $section = {
        id => $self->_last_id($self->_last_id + 1),
        path => [ (@$path) ],
        props => {
            section_for => $subtree->{$step}->{id},
        },
    };
    $self->ids->{$section->{id}} = $section;
    $subtree->{$step}->{section} = $section;

    return $subtree->{$step};
}

=item classify_leaves

Calculates the number of leaf subnodes on every level in the
tree that constitutes the axis. It sets the C<is_leaf> indicator
on leaf nodes and sets the C<leaves> key to the calculated value.

=cut

sub _classify_leaves {
    my ($subtree) = @_;

    if (not $subtree->{children}
        or not $subtree->{children}->%*) {
        $subtree->{leaves} = 1;
        $subtree->{is_leaf} = 1;
        return 1;
    }

    my $leaves = 0;
    for my $child (values $subtree->{children}->%*) {
        $leaves += _classify_leaves( $child );
    }
    return $subtree->{leaves} = $leaves;
}

sub classify_leaves {
    my $self = shift;

    _classify_leaves( $_ ) for (values $self->tree->%*);
}

=item sort

Returns an array reference with axis IDs, alphabetically sorted
by the elements in the path (usually header and account numbers),
unless the 'order' property is defined, in which case that's used.

=cut

sub sort {
    my ($self) = @_;

    return _sort_aux($self->tree);
}

sub _sort_aux {
    my ($subtree) = @_;

    my $cmpv = sub {
        return ((defined $subtree->{$_[0]}->{props}
                 && $subtree->{$_[0]}->{props}->{order}) || $_[0]);
    };
    my @sorted = ();
    for (sort { &$cmpv($a) cmp &$cmpv($b) } keys %$subtree) {
        push @sorted, $subtree->{$_}->{section}->{id}
            if scalar(keys %{$subtree->{$_}->{children}}) > 0;
        push @sorted, @{_sort_aux($subtree->{$_}->{children})};
        push @sorted, $subtree->{$_}->{id};
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

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
