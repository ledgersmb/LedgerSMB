
=pod

=head1 NAME

LedgerSMB::DBObject::Reconciliation - LedgerSMB class defining the core 
database interaction logic for Reconciliation.

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.  

=head1 METHODS

=over

=item new ($class, base => $LedgerSMB::hash)

This is the base constructor for all child classes.  It must be used with base
argument because this is necessary for database connectivity and the like.

Of course the base object can be any object that inherits LedgerSMB, so you can
use any subclass of that.  The per-session dbh is passed between the objects 
this way as is any information that is needed.

=item reconcile($self, $total, $month, $entries)

Accepts the total balance, as well as a list of all entries from the bank
statement as an array reference, and generates the pending report from
this list. 
The first entry is always the total balance of the general ledger as 
compared to the balance held by the bank.

Month is taken to be the date that the statement as represented by Entries
is applicable to.

Returns the new report ID. || An arrayref of entries.

=item approve($self,$reportid)

Approves the pending report $reportid.
Checks for error codes in the pending report, and approves the report if none
are found.

Limitations: The creating user may not approve the report.

Returns 1 on success.

=item correct_entry($self, $report_id, $source_control_number, $new_balance)

If the given entry $source_control_number in the report $report_id has an error
code, the entry will be updated with $new_balance, and the error code 
recomputed.

Returns the error code assigned to this entry. 

    0 for success
    1 for found in general ledger, but does not match $new_balance
    2 $source_control_number cannot be found in the general ledger
    
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

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::DBObject::Reconciliation;

use base qw(LedgerSMB::DBObject);
use LedgerSMB::DBObject;
use LedgerSMB::Reconciliation::CSV;


# don't need new

sub update {
    my $self = shift @_;
    $self->exec_method(funcname=>'reconciliation__pending_transactions');
}

sub submit {
    my $self = shift @_;
    $i = 1;
    my $ids = ();
    $self->{line_ids} = '{';
    while (my $id = $self->{"id_$i"}){
        if ($self->{"cleared_$id"}){
            push @$ids, $id;
            $self->{line_ids} =~ s/$/$id,/;
        }
        ++ $i;
    }
    $self->{line_ids} =~ s/,$/}/; 
    $self->exec_method(funcname=>'reconciliation__submit_set');
    $self->{dbh}->commit; 
}

sub import_file {
    
    my $self = shift @_;
    
    # We need to know what the format is, for the text file. We should have a set of formats
    # for the given file, listed in the DB, or based on modules available.
    # 
    # Probably based on modules.
    
    # my $module = 'LedgerSMB/Reconciliaton/CSV/'.$self->{file_format};
    # require $module."pm";
    # my $obj_name = $module;
    # $obj_name =~ s/\//::/g;
    # my $parser = $obj_name::new(base=>$self);
    
    # $self->filename is currently a lie. There's no facility in the LSMB 
    # design to accomadate an uploaded file.
    my $csv = LedgerSMB::Reconciliation::CSV->new(base=>$self);
    $csv->process();
    
    return $self->{entries};
}

sub approve {
    
    my $self = shift @_;
    # the user should be embedded into the $self object.
    my $report_id = shift @_;
    
    my $code = $self->exec_method(funcname=>'report_approve', args=>[$report_id]); # user 
    
    if ($code == 0) {  # no problem.
        return $code;
    } 
    # this is destined to change as we figure out the Error system.
    elsif ($code == 99) {
        
        $self->error("User $self->{user}->{name} cannot approve report, must be a different user.");
    }
}

sub new_report {

    my $self = shift @_;
    my $total = shift @_;
    my $month = shift @_;
    my $entries = shift @_; # expects an arrayref.
    
    # Total is in here somewhere, too
    
    # gives us a report ID to insert with.
    my @reports = $self->exec_method(funcname=>'reconciliation__new_report_id');
    my $report_id = $reports[0]->{reconciliation__new_report_id};
    $self->{report_id} = $report_id;
    $self->exec_method(funcname=>'reconciliation__pending_transactions');
    
    # Now that we have this, we need to create the internal report representation.
    # Ideally, we OUGHT to not return anything here, save the report number.
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
        $code = $self->exec_method(
            funcname=>'reconciliation__add_entry', 
            args=>[
                $report_id,
                $entry->{scn},
                $self->{user},
                $entry->{cleared_date},
                $entry->{amount}, # needs leading 0's trimmed.
            ]
        );
        $entry{report_id} = $report_id;        
    }
   
    $self->{dbh}->commit;
    
    return ($report_id, $entries); # returns the report ID.
}

sub correct_entry {
    
    my $self = shift @_;
    my $report_id = $self->{report_id}; # shift @_;
    my $scn = $self->{id}; #shift @_;
    my $new_amount = $self->{new_amount}; #shift @_;
    
    # correct should return the new code value - whether or not it actually "matches"
    my $code = $self->exec_method(
        funcname=>'reconciliation__correct',
        args=>[$report_id, $scn, $new_amount]
    );
    return $code[0]->{'correct'}; 
}

sub get_report {
    
    my $self = shift @_;
    
    return $self->exec_method(funcname=>'reconciliation__report', args=>[$self->{report_id}]);    
}

sub get_corrections {
    
    my $self = shift @_;
    
    return $self->exec_method(
        funcname=>'reconciliation__corrections',
        args=>[$self->{report_id}, $self->{entry_id}]
    );
}

sub entry {
    
    my $self = shift @_;
    
    return $self->exec_method(
        funcname=>'reconciliation__single_entry',
        args=>[$self->{report_id}, $self->{entry_id}]
    );
}

sub search {
    
    my $self = shift @_;
    my $type = shift;
    return $self->exec_method(
        funcname=>'reconciliation__search',
    );
}

sub get_pending {
    
    my $self = shift @_;
    return $self->exec_method(
        funcname=>'reconciliation__pending'
    );
}

sub get_report_list {
    
    my $self = shift @_;
    
    return $self->exec_method(
        funcname=>'reconciliation__report_list',
        args=>[$self->{account},$self->{report}]
    );
}

sub get {
    my ($self) = shift @_;
    my ($ref) = $self->exec_method(funcname=>'reconciliation__report_summary');
    $self->merge($ref);
    @{$self->{report_lines}} = $self->exec_method(
		funcname=>'reconciliation__report_details'
    );
    my ($ref) = $self->exec_method(
                funcname=>'reconciliation__get_cleared_balance'
    );

    $our_balance = $ref->{reconciliation__get_cleared_balance};
    $self->{beginning_balance} = $our_balance;
    for my $line (@{$self->{report_lines}}){
        $our_balance += $line->{our_balance} if $self->{"cleared_$line->{id}"};
    } 
    $self->{our_total} = $our_balance;
    $self->{format_amount} = sub { return $self->format_amount(@_); }
}

sub get_accounts {
    
    my $self = shift @_;
    return $self->exec_method(
        funcname=>'reconciliation__account_list',
    );
}
1;
