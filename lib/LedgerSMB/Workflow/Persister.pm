package LedgerSMB::Workflow::Persister;

=head1 NAME

LedgerSMB::Workflow::Persister - Store workflow data in a LedgerSMB company

=head1 SYNOPSIS

  <persisters>
    <persister class="LedgerSMB::Workflow::Persister"
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
use base qw( Workflow::Persister::DBI );

use LedgerSMB::App_State;

=head2 create_handle()

Implements Workflow::Persister::DBI protocol; returns undef.

=cut

sub create_handle {
    return undef;
}

=head2 handle()

Implements Workflow::Persister::DBI protocol; returns the handle for the
current request from C<LedgerSMB::App_State::DBH()>.

=cut

sub handle {
    LedgerSMB::App_State::DBH()->{RaiseError} = 1
        if LedgerSMB::App_State::DBH();
    return LedgerSMB::App_State::DBH();
}

1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

