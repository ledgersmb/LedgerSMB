
=head1 NAME

LedgerSMB::Scripts::journal - LedgerSMB slim ajax script for journal's
account search request.

=head1 SYNOPSIS

A script for journal ajax requests: accepts a search string and returns a
list of matching accounts in a ul/li pair acceptable for scriptaculous's
autocomplete library..

=head1 METHODS

=cut

package LedgerSMB::Scripts::journal;
our $VERSION = '1.0';

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Business_Unit;
use LedgerSMB::DBObject::Report::GL;
use LedgerSMB::DBObject::Report::COA;
use strict;

=pod

=over

=item __default

Get the search string, query the database, return the results in a ul/li
pair easily queried by scriptaculous's autocompleter.

=cut

sub __default {
    my ($request) = @_;
    my $template;
    my %hits = ();
    
    $template = LedgerSMB::Template->new(
            path => 'UI',
            template => 'ajax_li',
	    format => 'HTML',
    );
    
    my $funcname = 'chart_list_search';
    my %results_hash;
    my $search_field = $request->{search_field};
    $search_field =~ s/-/_/g;
    my @call_args = ($request->{$search_field}, $request->{link_desc});
    my @results = $request->call_procedure( procname => $funcname, args => \@call_args, order_by => 'accno' );
    foreach (@results) { $results_hash{$_->{'accno'}.'--'.$_->{'description'}} = $_->{'accno'}.'--'.$_->{'description'}; 
    }
    
    $request->{results} = \%results_hash;
    $template->render($request);
}

=item chart_of_accounts

Returns and displays the chart of accounts

=cut

sub chart_of_accounts {
    my ($request) = @_;
    for my $col(qw(accno description gifi_accno debit_balance credit_balance)){
        $request->{"col_$col"} = '1'; 
    }
    if ($request->is_allowed_role({allowed_roles => ['account_edit']})){
       for my $col(qw(link edit delete)){
           $request->{"col_$col"} = '1'; 
       }
    }
    my $report = LedgerSMB::DBObject::Report::COA->new(%$request);
    $report->run_report();
    $report->render($request);
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
    chart_of_accounts($request);
}

=item search

Runs a search and displays results.

=cut

sub search {
    my ($request) = @_;
    delete $request->{category} if ($request->{category} = 'X');
    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    #LedgerSMB::DBObject::Report::GL->prepare_criteria($request);
    my $report = LedgerSMB::DBObject::Report::GL->new(%$request);
    $report->run_report;
    $report->render($request);
}

=item search_purchases

Runs a search of AR or AP transactions and displays results.

=cut

sub search_purchases {
    my ($request) = @_;
    use LedgerSMB::DBObject::Report::Contact::Purchase;
    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    LedgerSMB::DBObject::Report::Contact::Purchase->prepare_criteria($request);
    my $report = LedgerSMB::DBObject::Report::Contact::Purchase->new(%$request);
    $report->run_report;
    $report->render($request);
}

=back

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your 
option).  For more information please see the included LICENSE and COPYRIGHT 
files.

=cut

eval { do "scripts/custom/journal.pl"};
1;
