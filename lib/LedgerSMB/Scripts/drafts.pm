
package LedgerSMB::Scripts::drafts;

=head1 NAME

LedgerSMB:Scripts::drafts - web entry points for managing to-be posted docs

=head1 DESCRIPTION

This module contains the workflows for managing unapproved, unbatched financial
transactions.  This does not contain facities for creating such transactions,
only searching for them, and posting them to the books or deleting those
which have not been approved yet.

=head1 METHODS

=over

=cut

use strict;
use warnings;

use LedgerSMB::Report::Unapproved::Drafts;

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
    return LedgerSMB::Scripts::reports::start_report($request);
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
    my $sth = $request->{dbh}->prepare(
        q|select workflow_id from transactions where id = ?|
        ) or die $request->{dbh}->errstr;
    for my $row (1 .. $request->{rowcount_}){
        my $id = $request->{"select_$row"};
        if ($id){
            $request->{dbh}->do(
                q|update ar
                     set invnumber = setting_increment('sinumber')
                   where id = ? and invnumber is null|,
                {},
                $id)
                or die $request->{dbh}->errstr;
            $request->call_procedure(
                funcname => 'draft_approve',
                args     => [ $id ]);
            $sth->execute( $id )
                or die $sth->errstr;
            my ($workflow_id) = $sth->fetchrow_array;
            my $wf = $request->{_wire}->get('workflows')
                ->fetch_workflow( 'AR/AP', $workflow_id );
            $wf->execute_action( 'approve' ) if $wf;
        }
    }
    return search($request);
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
    for my $row (1 .. $request->{rowcount_}){
        if ($request->{"select_$row"}){
            $request->call_procedure(
                funcname => 'draft_delete',
                args     => [ $request->{"select_$row"} ]);
        }
    }
    return search($request);
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

    $request->open_form;
    return $request->render_report(
        LedgerSMB::Report::Unapproved::Drafts->new(
            $request->%{ qw( reference type ) },
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
            amount_gt => $request->parse_amount( $request->{amount_gt} ),
            amount_lt => $request->parse_amount( $request->{amount_lt} ),
        ));
}



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
