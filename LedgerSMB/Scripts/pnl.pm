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

use LedgerSMB::PGDate;

sub generate_income_statement {
    my ($request) = @_;
    $ENV{LSMB_ALWAYS_MONEY} = 1;

    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }

    my $rpt;
    if ($request->{pnl_type} eq 'invoice'){
        $rpt = LedgerSMB::Report::PNL::Invoice->new(%$request);
    } elsif ($request->{pnl_type} eq 'eca'){
        $rpt = LedgerSMB::Report::PNL::ECA->new(%$request);
    } elsif ($request->{pnl_type} eq 'product'){
        $rpt = LedgerSMB::Report::PNL::Product->new(%$request);
    } else {
        if ( $request->{comparison_type} eq 'by_periods'
             && $request->{interval} ne 'none') {
            if (! $request->{from_date} && $request->{from_month}) {
                #this is a copy/pasto from LedgerSMB::Report::Hierarchical
                $request->{from_date} =
                    $request->{from_year} . '-' . $request->{from_month} . '-01';
                delete $request->{from_year};
                delete $request->{from_month};
            }

            # to_date = from_date + 1 period - 1 day
            my $date =
                LedgerSMB::Report::Hierarchical::_date_interval(
                    LedgerSMB::Report::Hierarchical::_date_interval($request->{from_date},
                                                                    $request->{interval}),
                    'day',-1);
            $request->{"to_date"} = $date->to_output;
        }
        $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
            %$request,
            column_path_prefix => [ 0 ]);
        $rpt->run_report;
        $rpt->init_comparisons($request);
        my $counts = $request->{comparison_periods} || 0;
        for my $c_per (1 .. $counts) {
            my $found = 0;
            for (qw(from_month from_year from_date to_date interval)){
                delete $request->{$_};
                $request->{$_} = $request->{"${_}_$c_per"}
                    if exists $request->{"${_}_$c_per"};
                $found = 1 if defined $request->{$_} and $_ ne 'interval';
            }
            next unless $found;
            my $comparison =
                LedgerSMB::Report::PNL::Income_Statement->new(
                    %$request,
                    column_path_prefix => [ $c_per ]);
            $comparison->run_report;
            $rpt->add_comparison($comparison);
        }
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
