=pod

=head1 NAME

LedgerSMB::Scripts::recon

=head1 SYOPSIS

This module acts as the UI controller class for Reconciliation. It controls
interfacing with the Core Logic and database layers.

=head1 METHODS

=cut

# NOTE:  This is a first draft modification to use the current parameter type.
# It will certainly need some fine tuning on my part.  Chris

package LedgerSMB::Scripts::recon;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Reconciliation;
use LedgerSMB::Setting;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Report::Reconciliation::Summary;
use strict;
use warnings;

=over

=item display_report($self, $request, $user)

Renders out the selected report given by the incoming variable report_id.
Returns HTML, or raises an error from being unable to find the selected
report_id.

=cut

sub display_report {
    my ($request) = @_;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request, copy => 'all'});
    _display_report($recon);
}

=item search($self, $request, $user)

Renders out a list of reports based on the search criteria passed to the
search function.
Meta-reports are report_id, date_range, and likely errors.
Search criteria accepted are

=over

=item date_begin

=item date_end

=item account

=item status

=back

=item update_recon_set

Updates the reconciliation set, checks for new transactions to be included,
and re-renders the reconciliation screen.

=cut

sub update_recon_set {
    my ($request) = shift;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    $recon->{their_total} = LedgerSMB::PGNumber->from_input($recon->{their_total}) if defined $recon->{their_total};
    if ($recon->{line_order}){
       $recon->set_ordering(
        {method => 'reconciliation__report_details_payee',
        column  => $recon->{line_order}}
       );
    }
    $recon->save() if !$recon->{submitted};
    $recon->update();
    _display_report($recon);
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
    update_recon_set($request);

}

=item reject

Rejects the recon set and returns it to non-submitted state

=cut

sub reject {
    my ($request) = @_;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    $recon->reject;
    search($request);
}

=item submit_recon_set

Submits the recon set to be approved.

=cut

sub submit_recon_set {
    my ($request) = shift;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    $recon->submit();
    my $template = LedgerSMB::Template->new(
            user => $request->{_user},
            template => 'reconciliation/submitted',
            locale => $request->{_locale},
            format => 'HTML',
            path=>"UI");
    return $template->render($recon);

}

=item save_recon_set

Saves the reconciliation set for later use.

=cut

sub save_recon_set {
    my ($request) = @_;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request});
    if ($recon->close_form){
        $recon->save();
        return search($request);
    } else {
        $recon->{notice} = $recon->{_locale}->text('Data not saved.  Please update again.');
        return _display_report($recon);
    }
}

=item get_results

Displays the search results

=cut

sub get_results {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Reconciliation::Summary->new($request);
    $report->render($request);
}

=item search

Displays search criteria screen

=cut

sub search {
    my ($request) = @_;

    my $recon = LedgerSMB::DBObject::Reconciliation->new({base=>$request, copy=>'all'});
    if (!$recon->{hide_status}){
            $recon->{show_approved} = 1;
            $recon->{show_submitted} = 1;
        }
        @{$recon->{recon_accounts}} = $recon->get_accounts();
    unshift @{$recon->{recon_accounts}}, {id => '', name => '' };
    $recon->{report_name} = 'reconciliation_search';
    LedgerSMB::Scripts::reports::start_report($recon);
}



=item new_report ($self, $request, $user)

Creates a new report, from a selectable set of bank statements that have been
received (or can be received from, depending on implementation)

Allows for an optional selection key, which will return the new report after
it has been created.

=cut

sub _display_report {
        my $recon = shift;
        $recon->get();
        my $setting_handle = LedgerSMB::Setting->new({base => $recon});
        $recon->{reverse} = $setting_handle->get('reverse_bank_recs');
        delete $recon->{reverse} unless $recon->{account_info}->{category}
                                        eq 'A';
        $recon->close_form;
        $recon->open_form;
        $recon->unapproved_checks;
        $recon->add_entries($recon->import_file('csv_file')) if !$recon->{submitted};
        $recon->{can_approve} = $recon->is_allowed_role({allowed_roles => ['reconciliation_approve']});
        $recon->get();
        my $template = LedgerSMB::Template->new(
            user=> $recon->{_user},
            template => 'reconciliation/report',
            locale => $recon->{_locale},
            format=>'HTML',
            path=>"UI"
        );
        $recon->{sort_options} = [
        {id => 'clear_time', label => $recon->{_locale}->text('Clear date')},
        {id => 'scn', label => $recon->{_locale}->text('Source')},
        {id => 'post_date', label => $recon->{_locale}->text('Post Date')},
        {id => 'our_balance', label => $recon->{_locale}->text('Our Balance')},
        {id => 'their_balance', label => $recon->{_locale}->text('Their Balance')},
        ];
        if (!$recon->{line_order}){
           $recon->{line_order} = 'scn';
        }
        $recon->{total_cleared_credits} = LedgerSMB::PGNumber->from_input(0);
        $recon->{total_cleared_debits} = LedgerSMB::PGNumber->from_input(0);
        $recon->{total_uncleared_credits} = LedgerSMB::PGNumber->from_input(0);
        $recon->{total_uncleared_debits} = LedgerSMB::PGNumber->from_input(0);
        my $neg_factor = 1;
        if ($recon->{account_info}->{category} =~ /(A|E)/){
           $recon->{their_total} *= -1;
           $neg_factor = -1;

        }


        # Credit/Debit separation (useful for some)
        for my $l (@{$recon->{report_lines}}){
            if ($l->{their_balance} > 0){
               $l->{their_debits} = LedgerSMB::PGNumber->from_input(0);
               $l->{their_credits} = $l->{their_balance};
            }
            else {
               $l->{their_credits} = LedgerSMB::PGNumber->from_input(0);
               $l->{their_debits} = $l->{their_balance}->bneg;
            }
            if ($l->{our_balance} > 0){
               $l->{our_debits} = LedgerSMB::PGNumber->from_input(0);
               $l->{our_credits} = $l->{our_balance};
            }
            else {
               $l->{our_credits} = LedgerSMB::PGNumber->from_input(0);
               $l->{our_debits} = $l->{our_balance}->bneg;
            }

            if ($l->{cleared}){
                 $recon->{total_cleared_credits}->badd($l->{our_credits});
                 $recon->{total_cleared_debits}->badd($l->{our_debits});
            } else {
                 $recon->{total_uncleared_credits}->badd($l->{our_credits});
                 $recon->{total_uncleared_debits}->badd($l->{our_debits});
            }

            $l->{their_balance} = $l->{their_balance}->to_output(money => 1);
            $l->{our_balance} = $l->{our_balance}->to_output(money => 1);
            $l->{their_debits} = $l->{their_debits}->to_output(money => 1);
            $l->{their_credits} = $l->{their_credits}->to_output(money => 1);
            $l->{our_debits} = $l->{our_debits}->to_output(money => 1);
            $l->{our_credits} = $l->{our_credits}->to_output(money => 1);
        }

    $recon->{zero_string} = LedgerSMB::PGNumber->from_input(0)->to_output(money => 1);

    $recon->{statement_gl_calc} = $neg_factor *
                ($recon->{their_total}
        + $recon->{outstanding_total}
                + $recon->{mismatch_our_total});
    $recon->{out_of_balance} = $recon->{their_total} - $recon->{our_total};
        $recon->{cleared_total} = $recon->{cleared_total}->to_output(money => 1);
        $recon->{outstanding_total} = $recon->{outstanding_total}->to_output(money => 1);
        $recon->{mismatch_our_debits} =
                $recon->{mismatch_our_debits}->to_output(money => 1);
        $recon->{mismatch_our_credits} =
        $recon->{mismatch_our_credits}->to_output(money => 1);
        $recon->{mismatch_their_debits} =
        $recon->{mismatch_their_debits}->to_output(money => 1);
        $recon->{mismatch_their_credits} =
        $recon->{mismatch_their_credits}->to_output(money => 1);
        $recon->{statement_gl_calc} =
        $recon->{statement_gl_calc}->to_output(money => 1);
        $recon->{total_cleared_debits} =
                $recon->{total_cleared_debits}->to_output(money => 1);
        $recon->{total_cleared_credits} =
                $recon->{total_cleared_credits}->to_output(money => 1);
        $recon->{total_uncleared_debits} =
                $recon->{total_uncleared_debits}->to_output(money => 1);
        $recon->{total_uncleared_credits} =
                $recon->{total_uncleared_credits}->to_output(money => 1);
    $recon->{their_total} = $recon->{their_total} * $neg_factor;
        $recon->{their_total} = $recon->{their_total}->to_output(money => 1);
    $recon->{our_total} = $recon->{our_total}->to_output(money => 1);
    $recon->{beginning_balance} =
        $recon->{beginning_balance}->to_output(money => 1);
    $recon->{out_of_balance} =
        $recon->{out_of_balance}->to_output(money => 1);

        return $template->render($recon);
}


=item new_report

Displays the new report screen.

=cut
sub new_report {
    my ($request) = @_;

    # Trap user error: dates accidentally entered in the amount field
    if ($request->{total} && $request->{total} =~ m|\d[/-]|){
        $request->error($request->{_locale}->text(
           'Invalid statement balance.  Hint: Try entering a number'
        ));
    }

    $request->{total} = LedgerSMB::PGNumber->from_input($request->{total});
    my $template;
    my $return;
    my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request, copy => 'all'});
    # This method detection makes debugging a bit harder.
    # Not sure I like it but won't refactor until 1.4..... --CT
    #
    if ($request->type() eq "POST") {

        # We can assume that we're doing something useful with new data.
        # We can also assume that we've got a file.

        # $self is expected to have both the file handling logic, as well as
        # the logic to load the processing module.

        # Why isn't this testing for errors?
        my ($report_id, $entries) = $recon->new_report($recon->import_file());
        if ($recon->{error}) {
            #$recon->{error};

            $template = LedgerSMB::Template->new(
                user=>$recon->{_user},
                template=> 'reconciliation/upload',
                locale => $recon->{_locale},
                format=>'HTML',
                path=>"UI"
            );
            return $template->render($recon);
        }
        _display_report($recon);
    }
    else {

        # we can assume we're to generate the "Make a happy new report!" page.
        @{$recon->{accounts}} = $recon->get_accounts;
        $template = LedgerSMB::Template->new(
            user => $recon->{_user},
            template => 'reconciliation/upload',
            locale => $recon->{_locale},
            format => 'HTML',
            path=>"UI"
        );
        return $template->render($recon);
    }
    return undef;

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
                         base=>$request,
                         copy=>'all'
    });

    my $resp = $recon->delete($request->{report_id});

    delete($request->{report_id});
    return search($request);
}

=item approve ($self, $request, $user)

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

    # Approve will also display the report in a blurred/opaqued out version,
    # with the controls removed/disabled, so that we know that it has in fact
    # been cleared. This will also provide for return-home links, auditing,
    # etc.

    if ($request->type() eq "POST") {

        # we need a report_id for this.

        my $recon = LedgerSMB::DBObject::Reconciliation->new({base => $request, copy=> 'all'});

        my $template;
        my $code = $recon->approve($request->{report_id});
        if ($code == 0) {

            $template = LedgerSMB::Template->new(
                user => $recon->{_user},
                template => 'reconciliation/approved',
                locale => $recon->{_locale},
                format => 'HTML',
                path=>"UI"
                );

            return $template->render($recon);
        }
        else {

            # failure case

            $template = LedgerSMB::Template->new(
                user => $recon->{_user},
                template => 'reconciliation/report',
            locale => $recon->{_locale},
                format => 'HTML',
                path=>"UI"
                );
            return $template->render($recon
            );
        }
    }
    else {
        return _display_report($request);
    }
}

=item pending ($self, $request, $user)

Requires {date} and {month}, to handle the month-to-month pending transactions
in the database. No mechanism is provided to grab ALL pending transactions
from the acc_trans table.

=cut


sub pending {

    my ($request) = @_;

    my $recon = LedgerSMB::DBObject::Reconciliation->new({base=>$request, copy=>'all'});
    my $template;

    $template= LedgerSMB::Template->new(
        user => $request->{_user},
        template=>'reconciliation/pending',
        locale => $request->{_locale},
        format=>'HTML',
        path=>"UI"
    );
    if ($request->type() eq "POST") {
        return $template->render(
            {
                pending=>$recon->get_pending($request->{year}."-".$request->{month})
            }
        );
    }
    else {

        return $template->render();
    }
}

sub __default {

    my ($request) = @_;

    my $recon = LedgerSMB::DBObject::Reconciliation->new({base=>$request, copy=>'all'});
    my $template;

    $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'reconciliation/list',
        locale => $request->{_locale},
        format=>'HTML',
        path=>"UI"
    );
    return $template->render(
        {
            reports=>$recon->get_report_list()
        }
    );
}

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/recon.pl" };
1;

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
