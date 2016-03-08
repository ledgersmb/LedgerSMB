=pod

=head1 NAME

LedgerSMB:Scripts::drafts, LedgerSMB workflow scripts for managing drafts

=head1 SYNOPSIS

This module contains the workflows for managing unapproved, unbatched financial
transactions.  This does not contain facities for creating such transactions,
only searching for them, and posting them to the books or deleting those
which have not been approved yet.

=head1 METHODS

=over

=cut


package LedgerSMB::Scripts::drafts;

use LedgerSMB::DBObject::Draft;
use LedgerSMB::Template;
use strict;
use warnings;

our $VERSION = '0.1';

=item search

Displays the search filter screen.  No inputs required.

The following inputs are optional and become defaults for the search criteria:

type:  either 'ar', 'ap', or 'gl'
with_accno: Draft transaction against a specific account.
from_date:  Earliest date for match
to_date: Latest date for match
amount_le: total less than or equal to
amount_ge: total greater than or equal to

=cut

sub search {
    use LedgerSMB::Scripts::reports;

    my $request = shift @_;
    $request->{search_type} = 'drafts';
    $request->{report_name} = 'unapproved';
    LedgerSMB::Scripts::reports::start_report($request);
}

=item approve

Required hash entries (global):

rowcount: number of total drafts in the list

Required hash entries:
row_$runningnumber: transaction id of the draft on that row.
draft_$id:  true if selected.


Approves selected drafts.  If close_form fails, does nothing and lists
drafts again.

=cut


sub approve {
    my ($request) = @_;
    if (!$request->close_form){
        list_drafts($request);
        return;
    }
    my $draft= LedgerSMB::DBObject::Draft->new({base => $request});
    for my $row (1 .. $request->{rowcount_}){
        if ($draft->{"select_$row"}){
             $draft->{id} = $draft->{"select_$row"};
             $draft->approve;
        }
    }
    search($request);
}


=item delete

Required hash entries (global):

rowcount: number of total drafts in the list

Required hash entries:
row_$runningnumber: transaction id of the draft on that row.
draft_$id:  true if selected.


Deletes selected drafts.  If close_form fails, does nothing and lists
drafts again.

=cut

sub delete {
    my ($request) = @_;
    if (!$request->close_form){
        list_drafts($request);
        return;
    }
    my $draft= LedgerSMB::DBObject::Draft->new({base => $request});
    for my $row (1 .. $draft->{rowcount_}){
        if ($draft->{"select_$row"}){
             $draft->{id} = $draft->{"select_$row"};
             $draft->delete;
        }
    }
    search($request);
}

=item list_drafts

Searches for drafts and lists those matching criteria:

Required hash variables:

type:  either 'ar', 'ap', or 'gl'


The following inputs are optional and used for filter criteria

with_accno: Draft transaction against a specific account.
from_date:  Earliest date for match
to_date: Latest date for match
amount_le: total less than or equal to
amount_ge: total greater than or equal to

=cut

sub list_drafts {
    my ($request) = @_;
    use LedgerSMB::Report::Unapproved::Drafts;
    my $report = LedgerSMB::Report::Unapproved::Drafts->new(%$request);
    $request->open_form;
    $report->run_report;
    $report->render($request);
}



=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
