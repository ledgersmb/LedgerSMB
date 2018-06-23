
package LedgerSMB::Scripts::lreports_co;

=head1 NAME

LedgerSMB::Scripts::lreports_co - Colombian local reports

=head1 DESCRIPTION

This module holds Colombia-specific reports.

=head1 METHODS

=cut

use LedgerSMB::Template;
use LedgerSMB::Report::co::Caja_Diaria;
use LedgerSMB::Report::co::Balance_y_Mayor;
use strict;
use warnings;

our $VERSION = '1.0';

=pod

=over

=item start_caja_diaria

Displays the filter screen for Caja Diaria

=cut

sub start_caja_diaria {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/Reports/co',
        template => 'filter_cd',
        format => 'HTML'
    );
    return $template->render($request);
}

=item start_bm

Displays the filter screen for Balance y Mayor

=cut

sub start_bm {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/Reports/co',
        template => 'filter_bm',
        format => 'HTML'
    );
    return $template->render($request);
}

=item run_caja_diaria

Runs a Caja Diaria and displays results.

=cut

sub run_caja_diaria {
    my ($request) = @_;
    my $report = LedgerSMB::Report::co::Caja_Diaria->new(%$request);
    $report->run_report;
    return $report->render($request);
}

=item run_bm

Runs Balance y Mayor and displays results.

=cut

sub run_bm {
    my ($request) = @_;
    my $report = LedgerSMB::Report::co::Balance_y_Mayor->new(%$request);
    $report->run_report;
    return $report->render($request);
}


{
    local ($!, $@) = ( undef, undef);
    my $do_ = 'scripts/custom/lreports_co.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error (lreports_co.pm)\n\n" );
            }
        }
    }
};

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
