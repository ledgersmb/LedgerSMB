package LedgerSMB::Workflow::Action::Null;

=head1 NAME

LedgerSMB::Workflow::Action::Null - Workflow 'empty' Action

=head1 SYNOPSIS

  # action configuration
  <actions>
    <action name="Send" class="LedgerSMB::Workflow::Action::Null"
            history-text="Some description for the workflow history" />
  </actions>


=head1 DESCRIPTION

This module implements an action which does nothing more than logging
a description provided in the action configuration to the history table.

=head1 METHODS

=cut


use strict;
use warnings;
use parent qw( LedgerSMB::Workflow::Action );

use DateTime;
use Log::Any qw($log);
use Workflow::Factory qw(FACTORY);

my @PROPS = qw( history_text );
__PACKAGE__->mk_accessors(@PROPS);

=head2 init($wf, $params)

Implements the C<Workflow::Action> protocol.

=cut

sub init {
    my ($self, $wf, $params) = @_;
    $self->SUPER::init($wf, $params);

    $self->history_text( $params->{'history-text'} );
}

=head2 execute($wf)

Implements the C<Workflow::Action> protocol.


=cut

sub execute {
    my ($self, $wf) = @_;

    if ($self->description) {
        $wf->add_history(
            {
                action      => $self->name,
                description => $self->history_text,
                date        => DateTime->now(),
                state       => $wf->state,
            });
    }
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

