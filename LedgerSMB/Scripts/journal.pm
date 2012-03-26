
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
use LedgerSMB::DBObject::Report::GL;
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

=item start_search

Displays the search screen

=cut

sub start_search {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/journal',
        template => 'search',
        format => 'HTML'
    );
    $template->render($request);
}

=item search

Runs a search and displays results.

=cut

sub search {
    my ($request) = @_;
    delete $request->{category} if ($request->{category} = 'X');
    my $report = LedgerSMB::DBObject::Report::GL->new(%$request);
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
