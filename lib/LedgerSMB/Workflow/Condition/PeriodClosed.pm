
use v5.36;
use warnings;

package LedgerSMB::Workflow::Condition::PeriodClosed;

=head1 NAME

LedgerSMB::Workflow::PeriodClosed - Workflow condition testing closed periods

=head1 SYNOPSIS

  # condition configuration
  <conditions>
    <condition name="is-period-closed"
               class="LedgerSMB::Workflow::Condition::PeriodClosed" />
  </conditions>


=head1 DESCRIPTION

This module implements the condition to check for closed accounting periods.
Note that to check for open accounting periods, simply check for the negated
value of this condition by prefixing it with an exclamation
mark (C<!period-closed>).

=head1 PARAMETERS

=head2 offset

  <condition .... >
    <param name="offset" value="1 day" />
  </condition>

Interval to be added to the C<workflow_parameter> to check for being in
a closed period. Defaults to C<0 days>.

=head2 workflow_parameter

  <condition .... >
    <param name="workflow_parameter" value="transdate" />
  </condition>

Name of the parameter in the workflow context which holds the date to check
for being in a closed period. Defaults to C<transdate>.


=head1 METHODS

=cut


use parent qw( Workflow::Condition );

use Log::Any qw($log);

my @PROPS = qw( offset workflow_parameter );
__PACKAGE__->mk_accessors(@PROPS);


=head2 init( \%params )

=cut

sub init($self, $params) {
    $self->SUPER::init( $params );
    $self->offset( $params->{offset} // '0 days' );
    $self->workflow_parameter( $params->{workflow_parameter} // 'transdate' );
}

=head2 evaluate( $wf )

Implements the C<Workflow::Condition> protocol, throwing a condition
error in case the workflow C<transdate> parameter is defined and not
in a closed period.

=cut

sub evaluate($self, $wf) {
    my $dbh = $wf->handle;
    my $date = $wf->context->param( $self->workflow_parameter );
    my $opened;
    if ($date) {
        ($opened) = $dbh->selectrow_array(
            q|SELECT (?::date + ?::interval) > MAX(end_date)
                     OR MAX(end_date) IS NULL
                FROM account_checkpoint|,
            {},
            $date,
            $self->offset
            );
        die $dbh->errstr if $dbh->err;
    }

    return not $opened;
}



1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

