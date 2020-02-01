package LedgerSMB::Mailer::TransportSMTP;

=head1 NAME

LedgerSMB::Mailer::TransportSMTP - Workaround for SASL and Email::Sender

=head1 DESCRIPTION

Email::Sender::Transport::SMTP encapsulates too much of Authen::SASL
as it hides the possibility to select authentication mechanisms.

This module works around that by allowing C<sasl_username> to be a
fully configured (including mechanisms) C<Authen::SASL> instance.

=cut

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

extends 'Email::Sender::Transport::SMTP';


has '+sasl_username' => (isa => AnyOf[ Str, InstanceOf['Authen::SASL']]);

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
