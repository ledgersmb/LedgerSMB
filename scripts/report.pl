
package LedgerSMB::Scripts::report;
use strict;
use LedgerSMB::DBObject::Report;
our $VERSION = 0.1;

sub generate_report {
    my ($request) = @_;
    my $template = $request->{template};
    my $report = new LedgerSMB::DBObject::Report->new({base => $request });
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI/report',
        template => $template,
        format => 'HTML'
    );

    $report->run_report;
    $report->{columns_shown} = [];
    for (@{$report->{columns}}) {
        if ($request->{$_}){
            push (@{$report->{columns_shown}}, $_);
        }
    }
}

sub select_criteria {
    my ($request) = @_;
    my $report = new LedgerSMB::DBObject::Report->new({base => $request });
    $report->can("definition_$request->{report}")->();
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI/report',
        template => 'criteria',
        format => 'HTML'
    );
    $template->render($report);
}    

1;
