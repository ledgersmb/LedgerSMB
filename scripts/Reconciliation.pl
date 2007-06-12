=pod

=head1 NAME

=cut

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
    
    my $recon = LedgerSMB::DBObject::Reconciliation->new(base => $request, copy => 'all');
     
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'reconciliation_correct.html', language => $user->{language}, 
        format => 'html');
    $recon->correct_entry();
    $template->render($recon->get_report());
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

=item ($self, $request, $user)

Requires report_id

Approves the given report based on id. Generally, the roles should be 
configured so as to disallow the same user from approving, as created the report.

Returns a success page on success, returns a new report on failure, showing 
the uncorrected entries.

=back

=cut

sub approve {
    
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
1;