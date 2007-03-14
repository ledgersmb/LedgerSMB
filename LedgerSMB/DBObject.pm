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
use Scalar::Util;
use base qw(LedgerSMB);
use strict;
use warnings;

our $AUTOLOAD;

sub AUTOLOAD {
	my ($self) = shift;
	my $type = (Scalar::Util::reftype $self) =~  m/::(.*?)$/;
	print "Type: $type\n";
	$type =~ m/::(.*?)$/; 
	$type  = lc $1;
	$self->exec_method("$type" . "_" . $AUTOLOAD, @_);
}

sub new {
	my $self = shift @_;
	my $lsmb = shift @_;
	if (! $lsmb->isa('LedgerSMB')){
		$self->error("Constructor called without LedgerSMB object arg");
	}

	$self = {};
	my $attr;
	for $attr (keys %{$lsmb}){
		$self->{$attr} = $lsmb->{$attr};
	}
	bless $self;
}


sub exec_method {
	my ($self) = shift @_;
	my %args = @_; 
	my $funcname = $args{funcname}; 
	my @in_args = @{$args{args}};
	my @call_args;

	my $query = 
		"SELECT proname, proargnames FROM pg_proc WHERE proname = ?";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute($funcname);
	my $ref;

	$ref = $sth->fetchrow_hashref('NAME_lc');
	my $args = $ref->{proargnames};
	$args =~ s/\{(.*)\}/$1/;
	my @proc_args = split /,/, $args;

	if (!$ref){ # no such function
		$self->error("No such function: ", $funcname);
		die;
	}
	my $m_name = $ref->{proname};


	if ($args){
		for my $arg (@proc_args){
			if ($arg =~ s/^in_//){
				push @call_args, $self->{$arg};
			}
		}
	}
	else {
		@call_args = @_;
	}
	$self->callproc($funcname, @call_args);
}

sub run_custom_queries {
	my ($self, $tablename, $query_type, $linenum) = @_;
	my $dbh = $self->{dbh};
	if ($query_type !~ /^(select|insert|update)$/i){
		# Commenting out this next bit until we figure out how the locale object
		# will operate.  Chris
		#$self->error($locale->text(
		#	"Passed incorrect query type to run_custom_queries."
		#));
	}
	my @rc;
	my %temphash;
	my @templist;
	my $did_insert;
	my @elements;
	my $query;
	my $ins_values;
	if ($linenum){
		$linenum = "_$linenum";
	}

	$query_type = uc($query_type);
	for (@{$self->{custom_db_fields}{$tablename}}){
		@elements = split (/:/, $_);
		push @{$temphash{$elements[0]}}, $elements[1];
	}
	for (keys %temphash){
		my @data;
		my $ins_values;
		$query = "$query_type ";
		if ($query_type eq 'UPDATE'){
			$query = "DELETE FROM $_ WHERE row_id = ?";
			my $sth = $dbh->prepare($query);
			$sth->execute->($self->{"id"."$linenum"})
				|| $self->dberror($query);
		} elsif ($query_type eq 'INSERT'){
			$query .= " INTO $_ (";
		}
		my $first = 1;
		for (@{$temphash{$_}}){
			$query .= "$_";
			if ($query_type eq 'UPDATE'){
				$query .= '= ?';
			}	
			$ins_values .= "?, ";
			$query .= ", ";
			$first = 0;
			if ($query_type eq 'UPDATE' or $query_type eq 'INSERT'){
				push @data, $self->{"$_$linenum"}; 
			}
		}
		if ($query_type ne 'INSERT'){
			$query =~ s/, $//;
		}
		if ($query_type eq 'SELECT'){
			$query .= " FROM $_";
		}
		if ($query_type eq 'SELECT' or $query_type eq 'UPDATE'){
			$query .= " WHERE row_id = ?";
		}
		if ($query_type eq 'INSERT'){
			$query .= " row_id) VALUES ($ins_values ?)";
		}
		if ($query_type eq 'SELECT'){
			push @rc, [ $query ];
		} else {
			unshift (@data, $query);
			push @rc, [ @data ];
		}
	}
	if ($query_type eq 'INSERT'){
		for (@rc){
			$query = shift (@{$_});
			my $sth = $dbh->prepare($query) 
				|| $self->db_error($query);
			$sth->execute(@{$_}, $self->{id})
				|| $self->dberror($query);;
			$sth->finish;
			$did_insert = 1;
		}
	} elsif ($query_type eq 'UPDATE'){
		@rc = $self->run_custom_queries(
			$tablename, 'INSERT', $linenum);
	} elsif ($query_type eq 'SELECT'){
		for (@rc){
			$query = shift @{$_};
			my $sth = $self->{dbh}->prepare($query);
			$sth->execute($self->{id});
			my $ref = $sth->fetchrow_hashref('NAME_lc');
			$self->merge($ref, keys(%$ref));
		}
	}
	@rc;
}


1;
