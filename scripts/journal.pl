#!/usr/bin/perl


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
use strict;

=pod

=over

=item __default

Get the search string, query the database, return the results in a ul/li
pair easily queried by scriptaculous's autocompleter.

=back

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
    my @call_args = ($request->{'account-ac-search'});
    my @results = $request->call_procedure( procname => $funcname, args => \@call_args, order_by => 'accno' );
    my %results_hash;
    foreach (@results) { $results_hash{$_->{'accno'}.'--'.$_->{'description'}} = $_->{'accno'}.'--'.$_->{'description'}; }
    
    $request->{results} = \%results_hash;
    $template->render($request);
}

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your 
option).  For more information please see the included LICENSE and COPYRIGHT 
files.

=cut

eval { do "scripts/custom/journal.pl"};
1;
