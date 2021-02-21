package LedgerSMB::Workflow::Persister::Order;

=head1 NAME

LedgerSMB::Workflow::Persister::Order - Store Order/Quote workflow data

=head1 SYNOPSIS

  <persisters>
    <persister class="LedgerSMB::Workflow::Persister::Order"
               driver="Pg" />
    </persister>
  </persisters>

=head1 DESCRIPTION

This module handles persistence of workflow (history) data through the
existing database connection in C<LedgerSMB::App_State::DBH()>.

The class inherits from Workflow::Persister::DBI and uses
the same configuration semantics.

=head1 METHODS

=cut

use warnings;
use strict;
use base qw( LedgerSMB::Workflow::Persister );

use Workflow::Exception qw( persist_error );
use English;

=head2 fetch_extra_workflow_data

Fetches the latest order/quote data and stores it in the C<_extra>
context parameter.

=cut

sub fetch_extra_workflow_data {
    my ( $self, $wf ) = @_;
    my $sql =
        q{ SELECT * FROM oe WHERE workflow_id = ? ORDER BY id DESC LIMIT 1 };

    my ($sth);
    eval {
        $sth = $self->handle->prepare($sql);
        $sth->execute( $wf->id );
    };
    if ($EVAL_ERROR) {
        persist_error 'Failed to retrieve extra data from table ',
            $self->table, ": $EVAL_ERROR";
    } else {
        my $row = $sth->fetchrow_hashref('NAME_lc');
        if ( ref $row ) {
             $wf->context->param( _extra => $row );
        }
        else {
            $wf->context->param( _extra => {} );
        }
    }
}

1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

