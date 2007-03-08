=head1 NAME

LedgerSMB::DBObject - LedgerSMB class for building objects from db relations

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.  

=head1 METHODS

Most methods are dynamically created. The following methods are static, however.

=item make_object hashref, string, 

This creates a new data object instance based on information in the PostgreSQL
catalogs.

=back

=cut

use LedgerSMB;
package LedgerSMB::DBObject;
use strict;
no strict 'refs';
use warnings;

sub AUTOLOAD {
	my ($ref) = shift @_;
	my ($funcname) = shift @_;

	my $query = 
		"SELECT proname, proargnames FROM pg_proc WHERE proname = ?";
	my $sth = $self->{__dbh}->prepare($query);
	$sth->execute($funcname);
	my $ref;

	$ref = $sth->fetchrow_hashref(NAME_lc);
	my $m_name = $ref->{proname};
	my $args = $ref->{proargnames};
	my @proc_args;

	if ($m_name ~= s/$name\_//){
		push @{$self->{__methods}}, $m_name;
		if ($args){
			for $arg (@$args){
				if ($arg =~ s/^in_//){
					push @proc_args, $ref->{$arg};
				}
			}
		}
		else {
			@proc_args = @_;
		}
	}
	LedgerSMB::callproc($funcname, @proc_args);
}
