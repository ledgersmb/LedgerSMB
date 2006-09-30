#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# 
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (C) 2002
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#   Tony Fraser <tony@sybaspace.com>
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# routines to retrieve / manipulate win ini style files
# ORDER is used to keep the elements in the order they appear in .ini
#
#=====================================================================

package Inifile;


sub new {
	my ($type, $file) = @_;

	warn "$type has no copy constructor! creating a new object." 
		if ref($type);
	$type = ref($type) || $type;
	my $self = bless {}, $type;
	$self->add_file($file) if defined $file;

	return $self;
}


sub add_file {
	my ($self, $file) = @_;
  
	my $id = "";
	my %menuorder = ();

	for (@{$self->{ORDER}}) { $menuorder{$_} = 1 }
  
	open FH, "$file" or Form->error("$file : $!");

	while (<FH>) {
		next if /^(#|;|\s)/;
		last if /^\./;

		chop;

		# strip comments
		s/\s*(#|;).*//g;
    
		# remove any trailing whitespace
		s/^\s*(.*?)\s*$/$1/;

		if (/^\[/) {
			s/(\[|\])//g;
			$id = $_;
			push @{$self->{ORDER}}, $_ if ! $menuorder{$_};
			$menuorder{$_} = 1;
			next;
		}

		# add key=value to $id
		my ($key, $value) = split /=/, $_, 2;
    
		$self->{$id}{$key} = $value;

	}
	close FH;
  
}


1;

