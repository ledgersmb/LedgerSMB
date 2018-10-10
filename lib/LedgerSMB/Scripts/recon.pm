
package LedgerSMB::Scripts::recon;

=head1 NAME

LedgerSMB::Scripts::recon - web entry points for reconciliation workflow

=head1 DESCRIPTION

This module acts as the UI controller class for Reconciliation. It controls
interfacing with the Core Logic and database layers.

=head1 METHODS

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_BAD_REQUEST);

use LedgerSMB::DBObject::Reconciliation;
use LedgerSMB::PGNumber;
use LedgerSMB::Report::Reconciliation::Summary;
use LedgerSMB::Template::UI;

=over

=item display_report($request)

Retrieves and displays the specified reconciliation report.

C<$request> is a L<LedgerSMB> object reference. The following request keys
must be set:

  * dbh
  * report_id

=cut

sub display_report {
    my ($request) = @_;

    my $recon_data = {
        dbh => $request->{dbh},
        report_id => $request->{report_id}
    };

    my $recon = LedgerSMB::DBObject::Reconciliation->new({
        base => $recon_data,
    });

    return _display_report($recon, $request);
}

=item update_recon_set

Updates the reconciliation set, checks for new transactions to be included,
and re-renders the reconciliation screen.

=cut

sub update_recon_set {
    my ($request) = shift;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    $recon->{their_total} = LedgerSMB::PGNumber->from_input($recon->{their_total}) if defined $recon->{their_total};
    $recon->save() if !$recon->{submitted};
    $recon->update();
    return _display_report($recon, $request);
}

=item select_all_recons

Checks off all reconciliation items and updates recon set

=cut

sub select_all_recons {
    my ($request) = @_;
    my $i = 1;
    while (my $id = $request->{"id_$i"}){
        $request->{"cleared_$id"} = $id;
        ++ $i;
    }
    return update_recon_set($request);
}

=item reject

Rejects the recon set and returns it to non-submitted state

=cut

sub reject {
    my ($request) = @_;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    $recon->reject;
    return search($request);
}

=item submit_recon_set

Submits the recon set to be approved.

=cut

sub submit_recon_set {
    my ($request) = shift;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    $recon->submit();
    my $can_approve = $request->is_allowed_role({allowed_roles => ['reconciliation_approve']});
    if ( !$can_approve ) {
        my $template = LedgerSMB::Template::UI->new_UI;
        return $template->render($request, 'reconciliation/submitted',
                                 $recon);
    }
    return _display_report($recon, $request);
}

=item save_recon_set

Saves the reconciliation set for later use.

=cut

sub save_recon_set {
    my ($request) = @_;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    if ($request->close_form){
        $recon->save();
        return search($request);
    } else {
        $recon->{notice} = $request->{_locale}->text('Data not saved.  Please update again.');
        return _display_report($recon, $request);
    }
}

=item get_results

Displays the search results

=cut

sub get_results {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Reconciliation::Summary->new(%$request);
    return $report->render($request);
}

=item search($request)

Displays bank reconciliation report search criteria screen.

C<$request> is a L<LedgerSMB> object reference. The following request keys
must be set:

  * dbh

Search criteria accepted are

  * date_begin
  * date_end
  * account
  * status

=cut

sub search {
    my ($request) = @_;

    my $recon = LedgerSMB::DBObject::Reconciliation->new();
    $recon->set_dbh($request->{dbh});
    $recon->get_accounts();

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render(
        $request,
        'Reports/filters/reconciliation_search',
        $recon
    );
}

=item new_report ($recon, $request)

Creates a new report, from a selectable set of bank statements that have been
received (or can be received from, depending on implementation)

Allows for an optional selection key, which will return the new report after
it has been created.

=cut

sub _display_report {
    my ($recon, $request) = @_;
    my $neg_factor;

    $request->close_form;
    $request->open_form;

    $recon->{form_id} = $request->{form_id};
    $recon->{can_approve} = $request->is_allowed_role({allowed_roles => ['reconciliation_approve']});
    $recon->{decimal_places} = $request->setting->get('decimal_places');
    _set_sort_options($recon, $request);

    $recon->get_accounts;
    $recon->get;
    $recon->unapproved_checks;

    if ($recon->{account_info}->{category} =~ /^(A|E)$/){
       $recon->{their_total} *= -1;
       $neg_factor = -1;
    }
    else {
        $neg_factor = 1;
    }

    if ($recon->{account_info}->{category} eq 'A') {
        $recon->{reverse} = $request->setting->get('reverse_bank_recs');
    }

    _process_upload($recon, $request) unless $recon->{submitted};

    $recon->build_totals;
    $recon->build_statement_gl_calc;
    $recon->build_variance;
    _highlight_suspect_rows($recon);

    $recon->{submit_enabled} = ($recon->{variance} == 0);

    for my $amt_name (qw/ mismatch_our_ mismatch_their_ total_cleared_ total_uncleared_ /) {
        for my $bal_type (qw/ credits debits/) {
            $recon->{"$amt_name$bal_type"} = $recon->{"$amt_name$bal_type"}->to_output(money=>1);
        }
    }
    $recon->{their_total} *= $neg_factor;

    for my $field (qw/ cleared_total outstanding_total statement_gl_calc their_total variance /) {
        $recon->{$field} = $recon->{$field}->to_output(money => 1);
    }

    for my $field (qw/ our_total beginning_balance /) {
        $recon->{$field} ||= LedgerSMB::PGNumber->from_db(0);
        $recon->{$field} = $recon->{$field}->to_output(money => 1);
    }

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'reconciliation/report', $recon);
}


=item new_report($request)

Displays the Create New Report screen, allowing the user to input parameters
for the creation of a new reconcilition report..

C<$request> is a L<LedgerSMB> object reference. The following request keys
must be set:

  * dbh

=cut

sub new_report {
    my ($request) = @_;

    my $recon = LedgerSMB::DBObject::Reconciliation->new();
    $recon->set_dbh($request->{dbh});
    $recon->get_accounts();

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render(
        $request,
        'reconciliation/new_report',
        $recon
    );
}

=item start_report($request)

Creates a new reconciliation report in the database, using the supplied
parameters and displays the blank report.

C<$request> is a L<LedgerSMB> object reference. The following request keys
must be set:

  * dbh
  * chart_id  [the account to be reconciled]
  * end_date  [the end date]
  * total     [the end balance]

Optionally the following request key may be set:

  * recon_fx  [boolean, default false]

=cut

sub start_report {
    my ($request) = @_;

    # Trap user error: dates accidentally entered in the amount field
    if ($request->{total} && $request->{total} =~ m|\d[/-]|){
        $request->error($request->{_locale}->text(
           'Invalid statement balance.  Hint: Try entering a number'
        ));
    }

    my $recon_data = {
        dbh => $request->{dbh},
        chart_id => $request->{chart_id},
        end_date => $request->{end_date},
        total => $request->{total},
        recon_fx => $request->{recon_fx},
    };

    my $recon = LedgerSMB::DBObject::Reconciliation->new({
        base => $recon_data,
    });

    # Insert new report into database
    $recon->new_report;

    # Format ending balance as a PGNumber - required for display
    $recon->{their_total} = LedgerSMB::PGNumber->from_input($request->{total});
    delete $recon->{total};

    return _display_report($recon, $request);
}

=item delete_report($request)

Requires report_id

This deletes a report.  Reports may not be deleted if approved (this will throw
a database-level exception).  Users may delete their own reports if they have
not yet been submitted for approval.  Those who have approval permissions may
delete any non-approved reports.

=cut

sub delete_report {
    my ($request) = @_;

    my $recon = LedgerSMB::DBObject::Reconciliation->new({
        base => $request,
    });

    $recon->delete($request->{report_id});

    delete($request->{report_id});
    return search($request);
}

=item approve ($request)

Requires report_id

Approves the given report based on id. Generally, the roles should be
configured so as to disallow the same user from approving, as created the report.

Returns a success page on success, returns a new report on failure, showing
the uncorrected entries.

=cut

sub approve {
    my ($request) = @_;
    if (!$request->close_form){
        return get_results($request);
    }

    return [ HTTP_BAD_REQUEST,
             [ 'Content-Type' => 'text/plain; charset=utf-8' ],
             [ q{'report_id' parameter missing} ]
        ] if ! $request->{report_id};

    my $recon = LedgerSMB::DBObject::Reconciliation->new({
        base => $request
    });

    my $code = $recon->approve;
    my $template = $code == 0 ? 'reconciliation/approved'
        : 'reconciliation/report';
    return LedgerSMB::Template::UI->new_UI
        ->render($request, $template, $recon);
}

=item pending ($request)

Requires {date} and {month}, to handle the month-to-month pending transactions
in the database. No mechanism is provided to grab ALL pending transactions
from the acc_trans table.

=cut


sub pending {

    my ($request) = @_;

    my $recon = LedgerSMB::DBObject::Reconciliation->new({base=>$request});

    my $template= LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'reconciliation/pending', {});
}


{
    local ($!, $@) = (undef, undef);
    my $do_ = 'scripts/custom/recon.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error (recon.pm)\n\n" );
            }
        }
    }
};


# _process_upload($recon, $request)
#
# If the request data includes a csv_file upload, import it and
# apply the contents to the current reconciliation report.

sub _process_upload {
    my ($recon, $request) = @_;
    my $contents;
    {
        my $handle = eval { $request->upload('csv_file') };
        local $/ = undef;
        $contents = <$handle> if defined $handle;
    }

    # An empty string is recognized by the entry-importer (ISO20022)
    # as a file name (due to absense of '<' and '>'); only call it
    # when there's actual content to handle.
    if ($contents) {
        $recon->add_entries($recon->import_file($contents));
    }

    return;
}


# _set_sort_options($recon, $request)
#
# Define the available sort options for display on a reconciliation report.
# Set a default sort order, if otherwise unspecified.

sub _set_sort_options {
    my ($recon, $request) = @_;

    $recon->{sort_options} = [
            {id => 'clear_time', label => $request->{_locale}->text('Clear date')},
            {id => 'scn', label => $request->{_locale}->text('Source')},
            {id => 'post_date', label => $request->{_locale}->text('Post Date')},
            {id => 'our_balance', label => $request->{_locale}->text('Our Balance')},
            {id => 'their_balance', label => $request->{_locale}->text('Their Balance')},
    ];

    $recon->{line_order} ||= 'scn';
    return;
}


# _highlight_suspect_rows
#
# If there is a variance in the report, highlight any rows which
# exactly match the variance, to help identify if a single row is
# responsible for the mismatch.
#
# Does nothing if the variance is zero.

sub _highlight_suspect_rows {
    my ($recon) = @_;

    if ($recon->{variance} == 0) {
        # No differences to highlight    
        return;
    }

    # Check if only one entry could explain the difference
    for my $l (@{$recon->{report_lines}}){
        $l->{suspect} = $l->{our_credits} == -$recon->{variance}
                     || $l->{our_debits}  ==  $recon->{variance}
                     ? 1 : 0;
    }

    return;
}


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
