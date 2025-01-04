
package LedgerSMB::Scripts::pnl;

=head1 NAME

LedgerSMB::Scripts::pnl - PNL report workflows for LedgerSMB

=head1 SYNOPSIS

Called via lsmb-handler.pl:

 LedgerSMB::Scripts::pnl->can($request->{__action})->($request);

=head1 DESCRIPTION

This module provides workflow logic for producing various reports regarding
profit and loss.

=head1 METHODS

=over

=item generate_income_statement

Generates an income statement.

=cut

use LedgerSMB::Report::PNL::Income_Statement;
use LedgerSMB::Report::PNL::Product;
use LedgerSMB::Report::PNL::ECA;
use LedgerSMB::Report::PNL::Invoice;
use LedgerSMB::Report;

use LedgerSMB::PGDate;
use strict;
use warnings;

sub generate_income_statement {
    my ($request) = @_;

    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }

    my $rpt;
    $request->{pnl_type} = '' unless defined $request->{pnl_type};
    if ($request->{pnl_type} eq 'invoice'){
        $rpt = LedgerSMB::Report::PNL::Invoice->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date  => $request->parse_date( $request->{from_date} ),
            to_date  => $request->parse_date( $request->{to_date} ),
            transdate => $request->parse_date( $request->{transdate} ),
            );
    } elsif ($request->{pnl_type} eq 'eca'){
        $rpt = LedgerSMB::Report::PNL::ECA->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date  => $request->parse_date( $request->{from_date} ),
            to_date  => $request->parse_date( $request->{to_date} ),
            );
    } elsif ($request->{pnl_type} eq 'product'){
        $rpt = LedgerSMB::Report::PNL::Product->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date  => $request->parse_date( $request->{from_date} ),
            to_date  => $request->parse_date( $request->{to_date} ),
            );
    } else {
        $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date  => $request->{from_date} ? $request->parse_date( $request->{from_date} ) : undef,
            to_date  => $request->{to_date} ? $request->parse_date( $request->{to_date} ) : undef,
            column_path_prefix => [ 0 ]);
        $rpt->run_report($request);

        for my $key (qw(from_month from_year from_date to_date interval)) {
            delete $request->{$_} for (grep { /^$key/ } keys %$request);
        }

        for my $cmp_dates (@{$rpt->comparisons}) {
            my $cmp = LedgerSMB::Report::PNL::Income_Statement->new(
                %$request,
                formatter_options => $request->formatter_options,
                %$cmp_dates);
            $cmp->run_report($request);
            $rpt->add_comparison($cmp);
        }
    }
    return $request->render_report($rpt);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
