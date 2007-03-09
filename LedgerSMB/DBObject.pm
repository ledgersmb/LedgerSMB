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

our @ISA = qw(LedgerSMB);

sub new {
	my $lsmb = shift @_;
	my $self = {};
	if (! $lsmb->isa('LedgerSMB')){
		$self->error("Constructor called without LedgerSMB object arg");
	}

	my $attr;
	for $attr (keys %{$lsmb}){
		$self->{$attr} = $lsmb->{$attr};
	}
	bless $self;
}


sub exec_method {
	my ($self) = shift @_;
	my ($funcname) = shift @_;

	my $query = 
		"SELECT proname, proargnames FROM pg_proc WHERE proname = ?";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute($funcname);
	my $ref;

	$ref = $sth->fetchrow_hashref('NAME_lc');
	my $args = $ref->{proargnames};
	$args =~ s/\{(.*)\}/$1/;
	my @proc_args = split /,/, $args;
	print "Ref: $ref\n";
	print "Args: $ref->{proargnames}\n";

	if (!$ref){ # no such function
		$self->error("No such function: ", $funcname);
		die;
	}
	my $m_name = $ref->{proname};

	if ($args){
		for my $arg (@proc_args){
			if ($arg =~ s/^in_//){
				print "Arg: $arg\n";
				push @proc_args, $self->{$arg};
			}
		}
	}
	else {
		@proc_args = @_;
	}
	print "Arg2s: @_ \n";
	$self->callproc($funcname, @proc_args);
}

1;
