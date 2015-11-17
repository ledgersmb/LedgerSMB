
=pod

=head1 NAME

LedgerSMB::DBObject::Reconciliation - LedgerSMB class defining the core
database interaction logic for Reconciliation.

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.

=head1 METHODS

Please note, this module needs a lot of cleanup.

=over

=item new ($class, base => $LedgerSMB::hash)

This is the base constructor for all child classes.  It must be used with base
argument because this is necessary for database connectivity and the like.

Of course the base object can be any object that inherits LedgerSMB, so you can
use any subclass of that.  The per-session dbh is passed between the objects
this way as is any information that is needed.

=item get_report($self, $report_id)

Collects all the rows from the database in the given report. Returns an
arrayref of entries in the table for the given report_id.

Returns undef in the event of no records found.

=item get_corrections($self, $report_id, $entry_id)

Returns the corrections made for the selected report and entry.
Returns undef in the event of no corrections found.

=item entry ($self,$report_id,$entry_id)

Returns a single entry from the pending reports table, either cleared or
uncleared.

=cut

package LedgerSMB::DBObject::Reconciliation;

use strict;
use warnings;

use base qw(LedgerSMB::PGOld);
use LedgerSMB::Reconciliation::CSV;


# don't need new

=item update

Updates the report, pulling in any new transactions in the date range into the
transaction list.

=cut

sub update {
    my $self = shift @_;
    $self->call_dbmethod(funcname=>'reconciliation__pending_transactions');
}

sub _pre_save {
    my $self = shift @_;
    my $i = 1;
    my $ids = ();
    $self->{line_ids} = '{';
    while (my $id = $self->{"id_$i"}){
        if ($self->{"cleared_$id"}){
            push @$ids, $id;
            $self->{line_ids} =~ s/$/$id,/;
        }
        ++ $i;
    }
    $self->{line_ids} =~ s/,?$/}/;
}

=item submit

Submits the reconciliation set for approval.

=cut

sub submit {
    my $self = shift @_;
    $self->_pre_save;
    $self->call_dbmethod(funcname=>'reconciliation__submit_set');
}



=item save

Saves the reconciliation set for later work

=cut

sub save {
    my $self = shift @_;
    $self->_pre_save;
    $self->call_dbmethod(funcname=>'reconciliation__save_set');
}

=item import_file

Calls the file import function.  This is generally assumed to be a csv file
although the plugin is very modular and plugins could be written for other
formats.  The format structure is per account id.

=cut

sub import_file {

    my $self = shift @_;

    my $csv = LedgerSMB::Reconciliation::CSV->new({base=>$self});
    $self->{import_entries} = $csv->process($self, 'csv_file');

    return $self->{import_entries};
}

=item unapproved_checks

Checks for unapproved

 * transactions (generally, since these could change)
 * payments against the account
 * reconciliation reports

Sets $self->{check} with the name of the test and the number of failures

=cut

sub unapproved_checks {
    my $self = shift @_;
    $self->{check} = { map { $_->{setting_key} => $_->{value} } $self->call_dbmethod(funcname=>'reconciliation__check') };
}

=item approve($self,$reportid)

Approves the pending report $reportid.
Checks for error codes in the pending report, and approves the report if none
are found.

Limitations: The creating user may not approve the report.

Returns 1 on success.

=cut

sub approve {

    my $self = shift @_;
    # the user should be embedded into the $self object.
    my $report_id = shift @_;

    my $code = $self->call_dbmethod(funcname=>'reconciliation__report_approve', args=>[$report_id]); # user

    if ($code == 0) {  # no problem.
        return $code;
    }
    # this is destined to change as we figure out the Error system.
    elsif ($code == 99) {

        $self->error("User $self->{user}->{name} cannot approve report, must be a different user.");
    }
}

=item new_report

Creates a new report with data entered.

=cut

sub new_report {

    my $self = shift @_;
    my $total = shift @_;
    my $month = shift @_;

    # Total is in here somewhere, too

    # gives us a report ID to insert with.
    my @reports = $self->call_dbmethod(funcname=>'reconciliation__new_report_id');
    my $report_id = $reports[0]->{reconciliation__new_report_id};
    $self->{report_id} = $report_id;
    $self->call_dbmethod(funcname=>'reconciliation__pending_transactions');

    # Now that we have this, we need to create the internal report representation.
    # Ideally, we OUGHT to not return anything here, save the report number.


    return ($report_id,
            ###TODO-ISSUE-UNDECLARED-ENTRIES $entries
        ); # returns the report ID.
}


=item delete ($self, $report_id)

Requires report_id

This will allow the deletion of a report if the report is not approved and
the user either owns the unsubmitted report, or the user has the right to
approve reports.

Returns 0 if successful, or a true result if not.

=cut

sub delete {

    my $self = shift @_;

    my ($report_id) = @_;
    my $retval;
    my $found;
    if ($self->is_allowed_role({allowed_roles => ['reconciliation_approve']})){
        ($found) = $self->call_procedure(
                           funcname => 'reconciliation__delete_unapproved',
                               args => [$report_id]);
    } else {
        ($found) = $self->call_procedure(
                           funcname => 'reconciliation__delete_my_report',
                               args => [$report_id]);

    }
    if ($found){
        $retval = '0';
    } else {
        $retval = '1';
    }
    return $retval;
}

=item reject

This rejects a submitted but not approved report.

=cut

sub reject {
    my ($self) = @_;
    $self->call_dbmethod(funcname => 'reconciliation__reject_set');
}

=item add_entries

Adds entries from the import file routine.

This function is extremely order dependent.  Meaningful scn's must be submitted
first it is also recommended that amounts be ordered where scn's are not found.

=cut

sub add_entries {
    my $self = shift;
    my $entries = $self->{import_entries};
    for my $entry ( @{$entries} ) {

        # Codes:
        # 0 is success
        # 1 is found, but mismatch
        # 2 is not found

        # in_scn INT,
        #in_amount INT,
        #in_account INT,
        #in_user TEXT,
        #in_date TIMESTAMP
        my $code = $self->call_procedure(
            funcname=>'reconciliation__add_entry',
            args=>[
                $self->{report_id},
                $entry->{scn},
                $entry->{type},
                $entry->{cleared_date},
                $entry->{amount}, # needs leading 0's trimmed.
            ]
        );
        ###TODO-ISSUE-UNDECLARED-ENTRIES
        #$entry->{report_id} = $report_id;
    }
}

=item get

Gets all information relating to a reconciliation report.

id must be set.

Populates main hash with values from cr_report

Also populates

=over

=item report_lines

a list of report lines

=item account_info

a hashrefo of information from the account table.

=item beginning_balance

=item cleared_total

=item outstanding_total

=item mismatch_our_total

=item mismatch_our_credits

=item mismatch_our_debits

=item mismatch_their_total

=item mismatch_their_credits

=item mismatch_their_debits

=back

=cut

sub get {
    my ($self) = shift @_;
    my ($ref) = $self->call_dbmethod(funcname=>'reconciliation__report_summary');
    $self->merge($ref);
    if (!$self->{submitted}){
        $self->call_dbmethod(
        funcname=>'reconciliation__pending_transactions'
        );
    }
    @{$self->{report_lines}} = $self->call_dbmethod(
        funcname=>'reconciliation__report_details_payee'
    );
    ($ref) = $self->call_dbmethod(funcname=>'account_get',
                                args => {id => $self->{chart_id} });
    my $neg = 1;
    if ($self->{account_info}->{category} =~ /(A|E)/){
        $neg = -1;
    }
    $self->{account_info} = $ref;
    ($ref) = $self->call_dbmethod(
                funcname=>'reconciliation__get_cleared_balance'
    );

    my $our_balance = $ref->{reconciliation__get_cleared_balance};
    $self->{beginning_balance} = $our_balance;
    $self->{cleared_total} = $self->parse_amount(amount => 0);
    $self->{outstanding_total} = $self->parse_amount(amount => 0);
    $self->{mismatch_our_total} = $self->parse_amount(amount => 0);
    $self->{mismatch_our_credits} = $self->parse_amount(amount => 0);
    $self->{mismatch_our_debits} = $self->parse_amount(amount => 0);
    $self->{mismatch_their_total} = $self->parse_amount(amount => 0);
    $self->{mismatch_their_credits} = $self->parse_amount(amount => 0);
    $self->{mismatch_their_debits} = $self->parse_amount(amount => 0);


    for my $line (@{$self->{report_lines}}){
        if ($line->{cleared}){
            $our_balance += ($neg * $line->{our_balance});
            $self->{cleared_total} += ($neg * $line->{our_balance});
    }elsif ((($self->{their_balance} != '0')
        and ($self->{their_balance} != $self->{our_balance}))
        or $line->{our_balance} == 0){

            $line->{err} = 'mismatch';
            $self->{mismatch_our_total} += $line->{our_balance};
            $self->{mismatch_their_total} += $line->{their_balance};
            if ($line->{our_balance} < 0){
                $self->{mismatch_our_debits} += -$line->{our_balance};
            } else {
        $self->{mismatch_our_credits} += $line->{our_balance};
            }
            if ($line->{their_balance} < 0){
                $self->{mismatch_their_debits} += -$line->{their_balance};
            } else {
        $self->{mismatch_their_credits} += $line->{their_balance};
            }
        } else {
            $self->{outstanding_total} += $line->{our_balance};
        }
    }
    $self->{our_total} = $our_balance;
    @{$self->{accounts}} = $self->get_accounts;
    for (@{$self->{accounts}}){
       if ($_->{id} == $self->{chart_id}){
           $self->{account} = $_->{name};
       }
    }
    $self->{format_amount} = sub { return $self->format_amount(@_); };
    if ($self->{account_info}->{category} =~ /(A|E)/){
       $self->{our_total} *= -1;
       $self->{mismatch_their_total} *= -1;
    }
}

=item get_accounts

This is a simple wrapper around reconciliation__account_list

=cut

sub get_accounts {
    my $self = shift @_;

    return $self->call_dbmethod(
        funcname=>'reconciliation__account_list',
    );
}

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
