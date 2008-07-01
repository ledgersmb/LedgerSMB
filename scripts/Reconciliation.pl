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
        template => "reconciliation/report.html", language => $user->{language},
            format=>'html'
        );
    my $report = $recon->get_report();
    my $total = $recon->get_total();
    $template->render({report=>$report, total=>$total, recon=>$recon});
}

=pod

=over

=item search($self, $request, $user)

Renders out a list of meta-reports based on the search criteria passed to the
search function.
Meta-reports are report_id, date_range, and likely errors.
Search criteria accepted are 
date_begin
date_end
account
status

=back

=cut

sub search {
    my ($class, $request) = @_;
    
    if ($request->type() eq "POST") {
        # WE HAS DATUMS
        # INTENTIONAL BAD PLURALIZATION OF LATIN
        
        my $template = LedgerSMB::Template->new(
            user => $user,
            template=>'reconciliation/search.html',
            language=>$user->{language},
            format=>'html'
        );
        return $template->render();
        
    } else {
        my $search = LedgerSMB::Reconciliation->new(base => $request, copy => 'all');
        my $results = $search->search();
        my $total = $search->total();
    
    
        my $template = LedgerSMB::Template->new( user => $user, 
    	    template => 'reconciliation/report.html', language => $user->{language}, 
            format => 'html');
        return $template->render({report => $results, total => $total});
    }
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
    
    if ($request->type() eq "POST") {
        
        my $recon = LedgerSMB::DBObject::Reconciliation->new(base => $request, copy => 'all');

        $recon->correct_entry();
        
        #  Are we getting data?
        if ($recon->{corrected_id}) {

            my $template = LedgerSMB::Template->new( user => $user, 
        	template => 'reconciliation/report.html', language => $user->{language}, 
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
        	template => 'reconciliation/report.html', language => $user->{language}, 
                format => 'html');

            $template->render( { 
                recon   => $recon,
                report  => $recon->get_report(),
                total   => $recon->get_total()
            } );
        }
    }
    else {
        
        # We are not getting data sent
        # ergo, we render out stuff.
        
        if ($request->{report_id} && $request->{entry_id}) {
            
            # draw the editor interface.
            
            my $template = LedgerSMB::Template->new(
                user=>$user,
                template=>"reconciliation/correct.html",
                language=> $user->{language},
                format=>'html'
            );
            my $recon = LedgerSMB::DBObject::Reconciliation->new(base=>$request, copy=>'all');
            
            $template->render($recon->details($request->{report_id}));
        }
        elsif ($request->{report_id}) {
            
            my $template = LedgerSMB::Template->new(
                user=>$user,
                template=>"reconciliation/correct.html",
                language=> $user->{language},
                format=>'html'
            );
            $class->display_report();
        }
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
    
    # This should do some fun stuff.
    
    my $template;
    my $return;
    
    if ($request->type() eq "POST") {
        
        # We can assume that we're doing something useful with new data.
        # We can also assume that we've got a file.
        my $recon = LedgerSMB::DBObject::Reconciliation->new(base => $request, copy => 'all');
        
        # $self is expected to have both the file handling logic, as well as 
        # the logic to load the processing module.
        
        # Why isn't this testing for errors?
        my ($report_id, $entries) = $recon->new_report($recon->import_file());
        if ($recon->is_error()) {
            
            $template = LedgerSMB::Template->new(
                user=>$user,
                template=> 'reconciliation/upload.html',
                language=>$user->{language},
                format=>'html'
            );
            return $template->render({error=>$recon->error()});
        }
        
        $template = LedgerSMB::Template->new( 
            user=> $user,
            template => 'reconciliation/new_report.html', 
            language => $user->{language},
            format=>'html'        
        );
        return $template->render(
            {
                entries=>$entries,
                report_id=>$report_id
            }
        );
    }
    else {
        
        # we can assume we're to generate the "Make a happy new report!" page.
        $template = LedgerSMB::Template->new( 
            user => $user, 
            template => 'reconciliation/upload.html', 
            language => $user->{language}, 
            format => 'html'
        );
        return $template->render();
    }
    return undef;
    
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
    
    if ($request->type() eq "POST") {
        
        # we need a report_id for this.
        
        my $recon = LedgerSMB::DBObject::Reconciliation->new(base => request, copy=> 'all');

        my $template;
        my $code = $recon->approve($request->{report_id});
        if ($code == 0) {

            $template = LedgerSMB::Template->new( user => $user, 
        	template => 'reconciliation/approve.html', language => $user->{language}, 
                format => 'html');
                
            return $template->render();
        }
        else {
            
            # failure case
            
            $template = LedgerSMB::Template->new( 
                user => $user, 
        	    template => 'reconciliation/report.html', 
        	    language => $user->{language}, 
                format => 'html');
            return $template->render(
                {
                    entries=>$recon->get_report($request->{report_id}),
                    total=>$recon->get_total($request->{report_id}),
                    error_code => $code
                }
            );
        }
    }
    else {
        return $class->display_report($request);
    }
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
	template => 'reconciliation/corrected.html', language => $user->{language}, 
        format => 'html');
    
    return $template->render(
        {
            corrections=>$recon->get_corrections(), 
            entry=>$recon->entry($self->{report_id}, $self->{entry_id})
        }
    );
}
# eval { do "scripts/custom/Reconciliation.pl" };
1;

=pod

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
