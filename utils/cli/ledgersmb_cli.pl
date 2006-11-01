#!/usr/bin/perl

# This is a simple wrapper that allows you to write simple scripts with LSMB
# See sample for the file format.

use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;

$form = new Form;

while ($line = <>){
	if ($line =~ /^\s*CALL (.+) INTO (.+)/){
		$form->{$2} = %${$1};
	} elsif ($line =~ /^\s*MODULE (.+)/){
	} elsif ($line =~ /^\s*ENV:(.+)\s*=\s*(.*)/){
	} elsif ($line =~ /^\s*(.+)\s*=\s*(.+)/){
	} else {
		die "Parse error in script file: $line";
	}
}
