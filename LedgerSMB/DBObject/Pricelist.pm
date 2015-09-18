=head1 NAME

LedgerSMB::DBObject::Pricelist - Pricelists for customers and vendors

=head1 SYNOPSIS

 my $pl = LedgerSMB::DBObject::Pricelist->new({base => $request});
 $pl->save(\@lines);

=cut

package LedgerSMB::DBObject::Pricelist;
use base qw(LedgerSMB::PGOld);
use strict;
use warnings;

=head1 DESCRIPTION

This module contains the pricelist saving routines for 1.3.  In 1.4 more
pricelist routines will be added.

=head1 PROPERTIES

=over

=item entity_class

This tells us whether this is a customer or vendor's pricelist.

=item credit_id

tells us who this is for.

=back

=head1 METHODS

=over

=item save(\@array);

Saves the pricelist.

=cut

sub save {
    my ($self, $lines) = @_;
    for my $ref (@$lines){
        my $line = __PACKAGE__->new({base => $self,
                               copy => 'list',
                              merge => ['entity_class', 'credit_id'], }
        );
        $line->merge($ref);
        $line->call_dbmethod(funcname => 'pricelist__save');
    }
}

=back

=over

=item delete(entry_id);

Deletes the referred pricelist entry.

=cut

sub delete {
    my ($self, $entry_id) = @_;

    my $line = __PACKAGE__->new({base => $self,
                                 merge => ['credit_id', 'entry_id'] }
        );
    $line->call_dbmethod(funcname => 'pricelist__delete');
}



=back


=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the included LICENSE.txt for more information.

=cut

1;
