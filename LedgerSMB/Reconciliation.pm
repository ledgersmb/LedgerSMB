
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

=item reconcile($self, $total, $entries)

Accepts the total balance, as well as a list of all entries from the bank
statement as an array reference, and generates the pending report from
this list. 
The first entry is always the total balance of the general ledger as 
compared to the balance held by the bank.

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

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::DBObject::Reconciliation;

use base qw(LedgerSMB::DBObject);

# don't need new

sub reconcile {

    my $self = shift @_;
    my $total = shift @_;
    my $entries = shift @_; # expects an arrayref.
    
    # Total is in here somewhere, too
    
    my $report_id = $self->new_report(); # gives us a report ID to insert with.
    
    # Now that we have this, we need to create the internal report representation.
    # Ideally, we OUGHT to not return anything here, save the report number.
    unshift @{$entries}, {scn => 0, balance=> $total, old_balance=> $self->current_balance, code=> $self->compare_total($total) };    
    for my $entry (@{$entries}) {
        
        # Codes:
        # 0 is success
        # 1 is found, but mismatch
        # 2 is not found
        $entry{report_id} = $report_id;
        $entry{code} = $self->add_entry( $entry );
        
    }
    # Based on chatting with Chris T, we are going to use an arrayref of hashrefs to handle
    # the varying return states.
    return $entries; # returns the report ID.
}

sub approve {
    
    my $self = shift @_;
    # the user should be embedded into the $self object.
    my $report_id = shift @_;
    
    my $code = $self->report_approve($report_id,$self->{user}->{id}); # user 
    
    if ($code == 0) {  # no problem.
        return $code;
    } 
    # this is destined to change as we figure out the Error system.
    elsif ($code == 99) {
        
        $self->error("User $self->{user}->{name} cannot approve report, must be a different user.");
    }
}

sub correct_entry {
    
    my $self = shift @_;
    my $report_id = shift @_;
    my $scn = shift @_;
    my $new_amount = shift @_;
    
    # correct should return the new code value - whether or not it actually "matches"
    my $code = $self->correct($report_id, $scn, $new_amount);
    return $code[0]->{'correct'}; 
}

1;
