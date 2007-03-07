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

sub make_object {
	my ($request, $name, $package_name) = @_;
	my $self = {};
	$self->{__dbh} = $request->{dbh};
	$self->{__name} = $name;
	$self->{__methods} = [];

	my $query = 
		"SELECT proname, proargnames FROM pg_proc
		  WHERE proname ilike ?";
	my $sth = $self->{__dbh}->prepare($query);
	$sth->execute("$name".'_%');
	my $ref;

	while ($ref = $sth->fetchrow_hashref(NAME_lc)){
		my $m_name = $ref->{proname};
		my $args = $ref->{proargnames};
		my $subcode
		if ($m_name ~= s/$name\_//){
			push @{$self->{__methods}}, $m_name;
			if ($args){
				$subcode = "sub {
					LedgerSMB::callproc($self->{proname}"
				for $arg (@$args){
					if ($arg =~ s/in_//){
						$subcode .= ", \$self->{$arg}";
					}
				}
				$subcode .= "); }"
				*{$package_name . "::" . $m_name}
					= eval $subcode;
				
			}
			else {
				$subcode = "sub {
					LedgerSMB::callproc($self->{proname}, ".
					"\@_); }"
			}
		}
		*{$package_name . "::" . $m_name} = eval $subcode;
	}	
}
