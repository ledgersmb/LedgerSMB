
package LedgerSMB::Scripts::journal;

=head1 NAME

LedgerSMB::Scripts::journal - Web entrypoint for ajax account search.

=head1 DESCRIPTION

A script for ajax requests: accepts a search string and returns a
list of matching accounts in a ul/li pair

=cut

use LedgerSMB::Report::GL;
use LedgerSMB::Report::COA;
use LedgerSMB::Report::Contact::Purchase;
use LedgerSMB::Scripts::account;
use strict;
use warnings;


=head1 METHODS

=head2 chart_of_accounts

Returns and displays the chart of accounts

=cut

sub chart_of_accounts {
    my ($request) = @_;

    return $request->render_report(
        LedgerSMB::Report::COA->new(
            formatter_options => $request->formatter_options,
            _locale => $request->{_locale},
            _uri => $request->{_uri},
            dbh => $request->{dbh}),
        formatter_options => $request->formatter_options
        );
}

=head2 new_account

Forwards request processing to LedgerSMB::Scripts::account.

=cut

sub new_account {
    # The CoA report buttons submit here, but functionality is in 'account'
    return LedgerSMB::Scripts::account::new_account(@_);
}

=head2 new_heading

Forwards request processing to LedgerSMB::Scripts::account.

=cut

sub new_heading {
    # The CoA report buttons submit here, but functionality is in 'account'
    return LedgerSMB::Scripts::account::new_heading(@_);
}



=head2 delete_account

This deletes an account and returns to the chart of accounts screen.

This is here rather than in LedgerSMB::Scripts::Account because the redirect
occurs to here.

=cut

sub delete_account {
    my ($request) = @_;

    if ($request->{charttype} eq 'A') {
        $request->call_procedure(
            funcname => 'account__delete',
            args     => [ $request->{id} ],
            );
    } elsif ($request->{charttype} eq 'H') {
        $request->call_procedure(
            funcname => 'account_heading__delete',
            args     => [ $request->{id} ],
            );
    } else {
        die 'Unknown charttype';
    }
    return chart_of_accounts($request);
}

=head2 search

Runs a search and displays results.

=cut

sub search {
    my ($request) = @_;
    delete $request->{category} if ($request->{category} eq 'X');
    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    #tshvr4 trying to mix in period from_month from_year interval
    return $request->render_report(
        LedgerSMB::Report::GL->new(
            $request->%{(qw( reference accno category source memo
                            business_units
                            is_voided
                            is_approved
                            interval
                            from_month from_year
                            comparison_periods comparison_type
                            comparisons
                         ),
                         grep { m/^(bc_|col_)/ } keys $request->%*)},
            formatter_options => $request->formatter_options,
            from_amount => $request->parse_amount( $request->{from_amount} ),
            to_amount => $request->parse_amount( $request->{to_amount} ),
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
            locale => $request->{_locale},
        ));
}

=head2 search_purchases

Runs a search of AR or AP transactions and displays results.

=cut

sub search_purchases {
    my ($request) = @_;

    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    return $request->render_report(
        LedgerSMB::Report::Contact::Purchase->new(
            %$request,
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
            as_of => $request->parse_date( $request->{as_of} ),
            formatter_options => $request->formatter_options
        ));
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
