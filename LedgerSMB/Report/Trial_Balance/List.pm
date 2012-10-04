=head1 NAME

LedgerSMB::Report::Trial_Balance::List - List saved trial balances in LedgerSMB

=head1 SYNPOPSIS

 my $tblist = LedgerSMB::Report::Trial_Balance::List->new(%$request);
 $tblist->render($request);

=cut

package LedgerSMB::Report::Trial_Balance::List;
use Moose;
extends 'LedgerSMB::Report';

use LedgerSMB::App_State;
my $locale = $LedgerSMB::App_State::Locale;

=head1 DESCRIPTION

This module lists trial balances for LedgerSMB.

=head1 CRITERIA PROPERTIES

None used

=head1 REPORT-RELATED CONSTANT FUNCTIONS

=over

=item name

=cut

sub name { return $locale->LedgerSMB::Report::text('Trial Balance List') }

=item header_lines

=cut

sub header_lines { return [] };

=item columns

=cut

sub columns {
    return [{ col_id => 'description',
                type => 'href',
           href_base => 'trial_balance.pl?action=get&id=',
                name => $locale->LedgerSMB::Report::text('Description') },
            { col_id => 'date_from',
                type => 'text',
                name => $locale->LedgerSMB::Report::text('Start Date') },
            { col_id => 'date_to',
                type => 'text',
                name => $locale->LedgerSMB::Report::text('End Date') },
            { col_id => 'yearend',
                type => 'text',
                name => $locale->LedgerSMB::Report::text('Ignore Yearends') },
           ];
}

=back

=head1 METHODS

=over

=item run_report

=cut

sub run_report {
    my ($self) = (@_);
    my @rows = $self->exec_method({funcname => 'trial_balance__list'});
    $_->{row_id} = $_->{id} for @rows;
    $self->rows(\@rows);
}

=over

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject_Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
