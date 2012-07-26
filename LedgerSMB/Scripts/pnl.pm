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

sub generate_income_statement {
    my ($request) = @_;
    use LedgerSMB::DBObject::Report::PNL::Income_Statement;
    my $rpt =LedgerSMB::DBObject::Report::PNL::Income_Statement->new(%$request);
    $rpt->render($request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
