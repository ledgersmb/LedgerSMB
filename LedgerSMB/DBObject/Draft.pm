=pod

=head1 NAME

LedgerSMB::DBObject::Draft - LedgerSMB base class for managing "drafts."

=head1 SYNOPSIS

This module contains the methods for managing unapproved, unbatched financial
transactions.  This does not contain facities for creating such transactions,
only searching for them, and posting them to the books.

=head1 METHODS

=over

=cut

package LedgerSMB::DBObject::Draft;

use strict;
use warnings;

use base qw/LedgerSMB::PGOld/;

=item search()

returns a list of results for the search criteria.  This list is also stored
in $draft->{search_resuts}

Requres $self->{type} to be one of 'ar', 'ap', or 'gl'

Optional hash entries for search criteria are:

with_accno: Draft transaction against a specific account.
from_date:  Earliest date for match
to_date: Latest date for match
amount_le: total less than or equal to
amount_ge: total greater than or equal to

=cut

sub search {
    my ($self) = @_;
    @{$self->{draft_results}} = $self->call_dbmethod(funcname => 'draft__search');
    return @{$self->{draft_results}};
}

=item approve()

Approves the draft identified by the transaction id in $draft->{id}.  Once
approved, the draft shows up in financial reports.

=cut

sub approve {
   my ($self) = @_;
   if (!$self->{id}){
       $self->error($self->{_locale}->text('No ID Set'));
   }
   ($self->{approved}) = $self->call_dbmethod(funcname => 'draft_approve');
   return $self->{approved};
}

=item delete()

Deletes the draft associated with transaction id in $draft->{id}.

Naturally, only unapproved transactions can be deleted.  Once posted to the
books, a draft may not be deleted.

=cut

sub delete {
   my ($self) = @_;
   if (!$self->{id}){
       $self->error($self->{_locale}->text('No ID Set'));
   }
   ($self->{deleted}) = $self->call_dbmethod(funcname => 'draft_delete');
   return $self->{deleted};
}

=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut

1;
