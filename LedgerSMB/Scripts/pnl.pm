=head1 NAME

LedgerSMB::Scripts::pnl - PNL report workflows for LedgerSMB

=head1 SYNOPSIS

Called via lsmb-handler.pl:

 LedgerSMB::Scripts::pnl->can($request->{action})->($request);

=head1 DESCRIPTION

This module provides workflow logic for producing various reports regaridng 
profit and loss.

=head1 METHODS/WORKFLOWS

=over

=item generate_income_statement

Generates an income statement.

=cut

package LedgerSMB::Scripts::pnl;

use LedgerSMB::Report::PNL::Income_Statement;
use LedgerSMB::Report::PNL::Product;
use LedgerSMB::Report::PNL::ECA;
use LedgerSMB::Report::PNL::Invoice;
use LedgerSMB::Report;
use LedgerSMB::App_State;


sub generate_income_statement {
    my ($request) = @_;
    my $rpt;
    if ($request->{pnl_type} eq 'invoice'){
        $rpt = LedgerSMB::Report::PNL::Invoice->new(%$request);
    } elsif ($request->{pnl_type} eq 'eca'){
        $rpt = LedgerSMB::Report::PNL::ECA->new(%$request);
    } elsif ($request->{pnl_type} eq 'product'){
        $rpt = LedgerSMB::Report::PNL::Product->new(%$request);
    } else {
        my $rpt =LedgerSMB::Report::PNL::Income_Statement->new(%$request);
    }
    $rpt->render($request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
