#!/usr/bin/perl
#===========================================================================
#
# LedgerSMB Command-line script host
#
#
# LedgerSMB 
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# 
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License 
# Version 2 or, at your option, any later version.  See COPYRIGHT file for 
# details.
#
# This is a simple wrapper that allows you to write simple scripts with LSMB
# See sample for the file format.
#
# THIS IS EXPERIMENTAL AND THE INTERFACE IS SUBJECT TO CHANGE


use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;

$form = new Form;

while ($line = <>){
	$line =~ s/#.*//; # strip out comments
	if ($line =~ /^\s*CALL\s+(.+)\s+INTO\s+(.+)/i){
		$form->{$2} = &{$1}(\%$form);
	} elsif ($line =~ /^\s*MODULE (.+)/i){
		$module = $1;
		$module =~ s/::/\//;
		eval { require $module; };
	} elsif ($line =~ /^\s*ENV:(.+)\s*=\s*(.*)/i){
		my ($key, $value) = ($1, $2);
		$key =~ s/\s?(.*)\s?/$1/;
		$value =~ s/\s?(.*)\s?/$1/;
		$ENV{$1} = $2;
	} elsif ($line =~ /^\s*(.+)\s*=\s*(.+)/){
		$form->{$1} = $2;
	} elsif ($line =~ /^\s*CALL\s+(.+)/i){
		{$1};
	} elsif ($line =~ /^\s*LOGIN\s*/i){
		$myconfig = new LedgerSMB::User 
			"${LedgerSMB::Sysconfig::memberfile}", "$form->{login}";
	} elsif ($line !~ /^\s*$/) {
		die "Parse error in script file: $line";
	}
}

delete $form->{password};

for (keys %$form){
	print "$_ = $form->{$_}\n";
}
