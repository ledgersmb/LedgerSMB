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
use parent qw( LedgerSMB::Workflow::Persister );

use Log::Any qw($log);

use Workflow::Exception qw( persist_error );
use English;

=head2 fetch_workflow

Fetches the latest order/quote data and stores it in the C<_extra>
context parameter.

=cut

sub fetch_workflow {
    my ($self, $wf_id) = @_;

    my $wf_info = $self->SUPER::fetch_workflow( $wf_id );
    if ($wf_info) {
        my $sql =
            q{ SELECT * FROM oe WHERE workflow_id = ? ORDER BY id DESC LIMIT 1 };

        my ($sth);
        eval {
            $sth = $self->handle->prepare($sql);
            $sth->execute( $wf_id );
        };
        if ($EVAL_ERROR) {
            persist_error 'Failed to retrieve extra data from table ',
                $self->table, ": $EVAL_ERROR";
        } else {
            my $row = $sth->fetchrow_hashref('NAME_lc');
            if ( ref $row ) {
                $wf_info->{context}->{_extra} = $row;
            }
            else {
                $wf_info->{context}->{_extra} = {};
            }
        }
    }

    return $wf_info;
}

1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

