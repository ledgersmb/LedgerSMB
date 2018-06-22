
package LedgerSMB::Scripts::journal;

=head1 NAME

LedgerSMB::Scripts::journal - Web entrypoint for ajax account search.

=head1 DESCRIPTION

A script for ajax requests: accepts a search string and returns a
list of matching accounts in a ul/li pair

=head1 METHODS

=cut

use LedgerSMB::Template;
use LedgerSMB::Business_Unit;
use LedgerSMB::Report::GL;
use LedgerSMB::Report::COA;
use strict;
use warnings;

our $VERSION = '1.0';

=pod

=over

=item chart_json

Returns a json array of all accounts

=cut

sub chart_json {
    my ($request) = @_;
    my $label = $request->{label};
    $label //= '';
    $label =~ s/\*//g;
    my $funcname = 'chart_list_all';
    my @results =
        $request->call_procedure( funcname => $funcname, order_by => 'accno' );
    @results =
        grep { (! $label) || $_->{label} =~ m/\Q$label\E/i }
        map { $_->{label} = $_->{accno} . '--' . $_->{description}; $_ }
        @results;
    return $request->to_json(\@results);
}

=item chart_of_accounts

Returns and displays the chart of accounts

=cut

sub chart_of_accounts {
    my ($request) = @_;
    for my $col(qw(accno description gifi debit_balance credit_balance)){
        $request->{"col_$col"} = '1';
    }
    if ($request->is_allowed_role({allowed_roles => ['account_edit']})){
       for my $col(qw(link edit delete)){
           $request->{"col_$col"} = '1';
       }
    }
    my $report = LedgerSMB::Report::COA->new(%$request);
    $report->run_report();
    return $report->render($request);
}

=item delete_account

This deletes an account and returns to the chart of accounts screen.

This is here rather than in LedgerSMB::Scripts::Account because the redirect
occurs to here.

=cut

sub delete_account {
    my ($request) = @_;
    use LedgerSMB::DBObject::Account;
    my $account =  LedgerSMB::DBObject::Account->new({base => $request});
    $account->delete;
    return chart_of_accounts($request);
}

=item search

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
    return LedgerSMB::Report::GL->new(%$request)->render($request);
}

=item search_purchases

Runs a search of AR or AP transactions and displays results.

=cut

sub search_purchases {
    my ($request) = @_;
    use LedgerSMB::Report::Contact::Purchase;
    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    my $report = LedgerSMB::Report::Contact::Purchase->new(%$request);
    $report->run_report;
    return $report->render($request);
}


{
    local ($!, $@) = (undef, undef);
    my $do_ = 'scripts/custom/journal.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error (journal.pm)\n\n" );
            }
        }
    }
};

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
