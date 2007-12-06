=pod

=head1 NAME

LedgerSMB::Scripts::Reconciliation - LedgerSMB class defining the Controller
functions, template instantiation and rendering.

=head1 SYOPSIS

This module acts as the UI controller class for Reconciliation. It controls
interfacing with the Core Logic and database layers.

=head1 METHODS

=cut

# NOTE:  This is a first draft modification to use the current parameter type.
# It will certainly need some fine tuning on my part.  Chris

package LedgerSMB::Scripts::Reconciliation;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Reconciliation;

=pod

=over

=item display_report($self, $request, $user)

Renders out the selected report given by the incoming variable report_id.
Returns HTML, or raises an error from being unable to find the selected
report_id.

=back

=cut

sub display_report {
    my ($class, $request) = @_;
    my $recon = LedgerSMB::Employee->new(base => $request, copy => 'all'); 
    my $template = LedgerSMB::Template->new( user=>$user, 
        template => "reconciliation_report.html", language => $user->{language},
            format=>'html'
        );
    my $report = $recon->get_report();
    my $total = $recon->get_total();
    $template->render({report=>$report, total=>$total});
}

sub search {
    my ($class, $request) = @_;
    my $search = LedgerSMB::Employee->new(base => $request, copy => 'all');
    $employee->{search_results} = $employee->search();
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'employee_search.html', language => $user->{language}, 
        format => 'html');
    $template->render($employee);
}

=pod

=over

=item correct ($self, $request, $user)

Requires report_id, entry_id.

Correct is a strange one. Based on the type of transaction listed in the
report, it will run one of several correction functions in the database.
This is to prevent arbitrary editing of the database by unscrupulous users.

=back

=cut

sub correct {
    my ($class, $request) = @_;
    
    my $recon = LedgerSMB::DBObject::Reconciliation->new(base => $request, copy => 'all');
    
    $recon->correct_entry();
     
    if ($recon->{corrected_id}) {
        
        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'reconciliation_report.html', language => $user->{language}, 
            format => 'html');
    
        $template->render( { 
            corrected=> $recon->{corrected_id}, 
            report=> $recon->get_report(),
            total=> $recon->get_total()
        } );
    } 
    else {
        
        # indicate we were unable to correct this entry, with the error code 
        # spat back to us by the DB.
        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'reconciliation_report.html', language => $user->{language}, 
            format => 'html');
    
        $template->render( { 
            recon => $recon,
            report=> $recon->get_report(),
            total=> $recon->get_total()
        } );
    }
}

=pod

=over

=item new_report ($self, $request, $user)

Creates a new report, from a selectable set of bank statements that have been
received (or can be received from, depending on implementation)

Allows for an optional selection key, which will return the new report after
it has been created.

=back

=cut

sub new_report {
    my ($class, $request) = @_;
    # how are we going to allow this to be created? Grr.
    # probably select a list of statements that are available to build 
    # reconciliation reports with.
    
    my $template;
    my $recon = LedgerSMB::DBObject::Reconciliation->new(base => $request, copy => 'all');
    my $return;
    if ($request->{selection}) {
        
        $template = LedgerSMB::Template->new( user => $user, 
    	template => 'reconciliation_report.html', language => $user->{language}, 
            format => 'html');
            
        $template->render($recon->new_report());
    } 
    else {
        
        # Generate the list of available bank statements/bank statements that
        # we have access to.
    }
    return $return;
    
}

=pod

=over

=item approve ($self, $request, $user)

Requires report_id

Approves the given report based on id. Generally, the roles should be 
configured so as to disallow the same user from approving, as created the report.

Returns a success page on success, returns a new report on failure, showing 
the uncorrected entries.

=back

=cut

sub approve {
    my ($class, $request) = @_;
    
    # Approve will also display the report in a blurred/opaqued out version,
    # with the controls removed/disabled, so that we know that it has in fact
    # been cleared. This will also provide for return-home links, auditing, 
    # etc.
    
    my $recon = LedgerSMB::DBObject::Reconciliation->new(base => request, copy=> 'all');
    
    my $template;
    my $report;
    if ($recon->approve()) {
        
        $template = LedgerSMB::Template->new( user => $user, 
    	template => 'reconciliation_approve.html', language => $user->{language}, 
            format => 'html');
    }
    else {
        
        $template = LedgerSMB::Template->new( user => $user, 
    	template => 'reconciliation_report.html', language => $user->{language}, 
            format => 'html');
        $report = $recon->get_report();
        
        ## relies on foreknowledge in the template
        ## we basically tell the template, we can't approve, this uncorrected
        ## error is preventing us.
        
        $report->{ error } = { approval => 1 }; 
    }
    $template->render($report);
}

=pod

=over

=item corrections ($self, $request, $user)

Requires report_id and entry_id.

Loads the selected entry id and all corrections associated with it. If there
aren't any corrections, it will display "no corrections found".
=back

=cut

sub corrections {
    my ($class, $request) = @_;
    
    # Load the corrections for a given report & entry id.
    # possibly should use a "micro" popup window?
    
    my $recon = LedgerSMB::DBObject::Reconciliation->new(base => request, copy=> 'all');
    
    my $template;
        
    $template = LedgerSMB::Template->new( user => $user, 
	template => 'reconciliation_corrected.html', language => $user->{language}, 
        format => 'html');
    
    return $template->render(
        {
            corrections=>$recon->get_corrections(), 
            entry=>$recon->entry($self->{report_id}, $self->{entry_id})
        }
    );
}

eval { do "scripts/custom/Reconciliation.pl"};
1;

=pod

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
