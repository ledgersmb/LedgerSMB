
=head1 NAME

LedgerSMB::Employee - LedgerSMB class for managing Employees 

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.  

=head1 METHODS

The following method is static:

=over

=item new ($LedgerSMB object);

=back

The following methods are passed through to stored procedures via Autoload.

=over

=item save

=item get

=item search

=item list_managers

The above list may grow over time, and may depend on other installed modules.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::Employee;
use base qw(LedgerSMB::DBObject);
use strict;
our $VERSION = '1.0.0';

sub save {
    my $self = shift;
    my $hashref = shift @{ $self->exec_method( procname => "employee_save" ) };
    $self->merge( $hashref, 'id' );
}

sub get {
    my $self = shift;
    my $hashref = shift @{ $self->exec_method( procname => "employee_get" ) };
    $self->merge( $hashref, keys %{$hashref} );
}

sub list_managers {
    my $self = shift;
    $self->{manager_list} =
      $self->exec_method( procname => "employee_list_managers" );
}

sub search {
    my $self = shift;
    $self->{search_results} =
      $self->exec_method( procname => "employee_search" );
}

1;
