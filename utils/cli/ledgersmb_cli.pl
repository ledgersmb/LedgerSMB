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

use Parse::RecDescent;
use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;

$form = new Form;

$syntax = << '_END_SYNTAX_';

	KEY : /\w[a-z0-9_]*/i
	FNKEY : /\w[a-z0-9_]*/i
	MODSTR: /\w[a-z0-9_:]*/i
	OP       : m([-+*/%])
	NUMBER : /[+-]?\d*\.?\d+/

	ARGSTR : /\w[a-z0-9_,\s]*/i 

	expression : NUMBER OP expression
              { return main::expression(@item) }
              | key OP expression
              { return main::expression(@item) }
              | INTEGER
              | VARIABLE

	assign_instruction : KEY "=" expression
		{ ${main::stackref}->{$item{key}} = $item{expression} }

	call_and_assign : /call/i FNKEY(ARGSTR) /into/i KEY
		{ main::call_and_assign($item{FNKEY}, $item{ARGSTR}, $item{KEY}) }	

	call : /call/i FNKEY(ARGSTR)
		{ main::call($item{FNKEY}, $item{ARGSTR}) }

	for : /for/i KEY
		{ main::push_loop($item{KEY}) }

	done : /^\s*done\s*$/
		{ main::pop_loop() }

	if : /^\s*if/i KEY
		{ main::if_handler($item{KEY} }

	# IF is terminated by END IF or FI on its own line

	login : /login/i
		{ main::login() }

	module : /module/i MODSTR
		{ main::load_mod($item{MODSTR} }

	instruction : assign_instruction
		| call_and_assign
		| call
		| for
		| done
		| if
		| login
		| module

	startrule : instruction

_END_SYNTAX_

my $stackref;
my @loopstack;

sub call {
	my ($call, $argstr) = @_;
	$argstr =~ s/form/\\\%\$form/;
	$argstr =~ s/user/\\\%myconfig/;
	my @args = split /,\s/, $argstr;
	return $call(@args);
}

sub call_and_assign {
	my $key = pop;
	$stackref->{key} = call(@_);
}

sub push_loop {
	my $key = shift;
	push @loopstack, \$stackref->{$key};
	$stackref = \$loopstack[$#loopstack];
}

sub pop_loop {
	pop @loopstack;
	$stackref = \$loopstack[$#loopstack];
}

sub if_handler {
	my $key = shift;
	if (!$stackref->{$key}){
		while ($line !~ /^(\s*FI\s*|\s*END\s+IF\s*)$/ ){
			$line = <>;
		}
	}
}

sub login {
	$myconfig = new LedgerSMB::User 
		"${LedgerSMB::Sysconfig::memberfile}", "$form->{login}";
}

sub load_mod {
	my $mod = shift;
	$mod =~ s/::/\//;
	eval { require "$mod.pm"; };
}

my $scriptparse = new Parse::RecDescent($grammer);

while ($line = <>){
	$scriptparse->instruction($line);
}

delete $form->{password};

for (keys %$form){
	print "$_ = $form->{$_}\n";
}
