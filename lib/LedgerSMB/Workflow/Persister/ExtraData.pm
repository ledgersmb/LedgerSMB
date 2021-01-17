package LedgerSMB::Workflow::Persister::ExtraData;

=head1 NAME

LedgerSMB::Workflow::Persister::ExtraData - Store additional workflow data

=head1 SYNOPSIS

  <persisters>
    <persister name="Email"
               class="LedgerSMB::Workflow::Persister::ExtraData"
               driver="Pg"
               extra_table="email"
               extra_data_field="from,to,cc,bcc,notify,subject,body,sent_date">
    </persister>
  </persisters>

=head1 DESCRIPTION

This module loads additional data for workflows from a specified table.

The class inherits from Workflow::Persister::DBI::ExtraData and uses
the same configuration semantics. Like L<LedgerSMB::Workflow::Persister>,
this module uses the existing database connection from
C<LedgerSMB::App_State::DBH>.

=head1 METHODS

=cut


use warnings;
use strict;
use base qw( Workflow::Persister::DBI::ExtraData );



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

