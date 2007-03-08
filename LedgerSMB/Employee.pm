=head1 NAME

LedgerSMB::Employee - LedgerSMB class for managing Employees 

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.  

=head1 METHODS

The following method is static:
=item new ($LedgerSMB object);

The following methods are passed through to stored procedures via Autoload.
=item save
=item get
=item search
=item list_managers

The above list may grow over time, and may depend on other installed modules.

=head1 Copyright (C) 2007, The LedgerSMB core team.
This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=back

=cut

package LedgerSMB::Employee;
use LedgerSMB;
use LedgerSMB::DBObject;
@ISA = (LedgerSMB::DBObject);

sub AUTOLOAD {
	my $procname = "employee_$LedgerSMB::Employee::Autoload";
	$self->exec_method($procname);
}

sub save {
	my $hashref = shift ($self->exec_method("employee_save"));
	$self->merge($hashref, 'id');
}

sub get {
	my $hashref = shift ($self->exec_method("employee_get"));
	$self->merge($hashref, keys $hashref);
}

sub delete {
	$self->exec_method("employee_delete");
}

sub list_managers {
	$self->{manager_list} = $self->exec_method("employee_list_managers");
}

sub search {
	$self->{search_results} = $self->exec_method("employee_search");
}

1;
