=head1 NAME

LedgerSMB::Scripts::lreports_co - Colombian local reports

=head1 SYNOPSIS

This module holds Colombia-specific reports.

=head1 METHODS

=cut

package LedgerSMB::Scripts::lreports_co;

use LedgerSMB;
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
    $template->render($request);
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
    $template->render($request);
}

=item run_caja_diaria

Runs a Caja Diaria and displays results.

=cut

sub run_caja_diaria {
    my ($request) = @_;
    my $report = LedgerSMB::Report::co::Caja_Diaria->new(%$request);
    $report->run_report;
    $report->render($request);
}

=item run_bm

Runs Balance y Mayor and displays results.

=cut

sub run_bm {
    my ($request) = @_;
    my $report = LedgerSMB::Report::co::Balance_y_Mayor->new(%$request);
    $report->run_report;
    $report->render($request);
}

=back

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your
option).  For more information please see the included LICENSE and COPYRIGHT
files.

=cut

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/lreports_co.pl"};
1;
