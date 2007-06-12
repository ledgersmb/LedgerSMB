# The handler, prior to handing the execution off to this script will create a
# $request object from the LedgerSMB namespace.  This object contains the http
# request parameters, db connections, and the like.  A $user object is also 
# created
#
# Entrence points are functions which do not begin with an underscore (_)
use LedgerSMB::Template;

sub save {
    my $employee = LedgerSMB::Employee->new(base => $request, copy => 'all');
    $employee->save();
    &_display;
}

sub search {
    my $search = LedgerSMB::Employee->new(base => $request, copy => 'all');
    $employee->{search_results} = $employee->search();
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'employee_search.html', language => $user->{language}, 
        format => 'html');
    $template->render($employee);
}

sub add {
    my $employee = LedgerSMB::Employee->new(base => $request, copy => 'all');
    &_display;
}

sub edit {
    my $employee = LedgerSMB::Employee->new(base => $request, copy => 'all');
    $employee->get();
    &_display;
}

sub _display {
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'employee.html', language => $user->{language}, 
        format => 'html');
    $template->render($employee);

}

1;
