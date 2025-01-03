
use v5.36;
use warnings;

package LedgerSMB::Workflow::Condition::SeparateDuties;

=head1 NAME

LedgerSMB::Workflow::SeparatingDuties - Workflow condition indicating if separation of duties is activated

=head1 SYNOPSIS

  # condition configuration
  <conditions>
    <condition name="separate-duties"
               class="LedgerSMB::Workflow::Condition::SeparateDuties" />
  </conditions>


=head1 DESCRIPTION

This module implements the condition to check for company configuration of
separation of duties.

=head1 METHODS

=cut


use parent qw( Workflow::Condition );

use LedgerSMB::Setting;

use Log::Any qw($log);


=head2 evaluate( $wf )

Implements the C<Workflow::Condition> protocol, throwing a condition
error in case separation of duties is I<not> enabled.

=cut

sub evaluate($self, $wf) {
    my $dbh = $wf->handle;
    my $separate_duties = LedgerSMB::Setting->new(dbh => $dbh)->get('separate_duties');
    $log->info("separate duties: $separate_duties");

    return $separate_duties;
}



1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

