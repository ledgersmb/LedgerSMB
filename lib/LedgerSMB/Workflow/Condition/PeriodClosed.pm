package LedgerSMB::Workflow::Condition::PeriodClosed;

=head1 NAME

LedgerSMB::Workflow::ACL - Workflow condition testing for allowed role

=head1 SYNOPSIS

  # condition configuration
  <conditions>
    <condition name="acl-draft-modify"
               class="LedgerSMB::Workflow::Condition::ACL"
               role="draft-modify" />
  </conditions>


=head1 DESCRIPTION

This module implements the condition to check for closed accounting periods. Note that
to check for open accounting periods, simply check for the negated value of this condition
by prefixing it with an exclamation mark (C<!period-closed>).

=head1 METHODS

=cut


use strict;
use warnings;
use parent qw( Workflow::Condition );

use LedgerSMB::Setting;

use Log::Any qw($log);
use Workflow::Exception qw( condition_error );


=head2 evaluate( $wf )

Implements the C<Workflow::Condition> protocol, throwing a condition
error in case separation of duties is I<not> enabled.

=cut

sub evaluate {
    my ($self, $wf) = @_;
    my $dbh = $wf->_factory->
        get_persister_for_workflow_type( $wf->type )->handle;

    return $wf->context->param( '_is_closed' );
}



1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

