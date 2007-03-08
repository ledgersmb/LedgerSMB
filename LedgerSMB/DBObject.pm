=head1 NAME

LedgerSMB::DBObject - LedgerSMB class for building objects from db relations

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.  

=head1 METHODS

=item find_method ($hashref, $function_name, @args)

=item merge ($hashref, @attrs)
copies @attrs from $hashref to $self.


=head1 Copyright (C) 2007, The LedgerSMB core team.
This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=back

=cut

package LedgerSMB::DBObject;
use LedgerSMB;
use strict;
no strict 'refs';
use warnings;

@ISA = (LedgerSMB);

sub new {
	my $lsmb = shift @_;
	if (! $lsmb->isa(LedgerSMB)){
		$self->error("Constructor called without LedgerSMB object arg");
	my $self = {};
	for $attr (keys $lsmb){
		$self->{$attr} = $lsmb->{$attr};
	}
	bless $self;
}


sub exec_method {
	my ($self) = shift @_;
	my ($funcname) = shift @_;

	my $query = 
		"SELECT proname, proargnames FROM pg_proc WHERE proname = ?";
	my $sth = $self->{__dbh}->prepare($query);
	$sth->execute($funcname);
	my $ref;

	$ref = $sth->fetchrow_hashref(NAME_lc);

	if (!$ref){ # no such function
		$self->error($locale->text("No such function: ") .$funcname;
		die;
	}
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
	$self->callproc($funcname, @proc_args);
}


