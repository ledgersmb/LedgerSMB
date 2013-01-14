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
	MODSTR : /\w[a-z0-9_:]*/i
	FNKEY : /(?:\w|:|\-\>)+/
	OP       : m([-+*/%])
	NUMBER : /[+-]?\d*\.?\d+/

	ARGS : /(\w[a-z0-9_]*,?\s?)+/i 

	expression : NUMBER OP expression
              { return main::expression(@item) }
              | KEY OP expression
              { return main::expression(@item) }
              | NUMBER
              | KEY

	assign_instruction : KEY "=" expression
		{ main::assignval($item{KEY}, $item{expression}) }

	call_and_assign : /call/i FNKEY '(' ARGS ')' /into/i KEY
		{ main::call_and_assign($item{FNKEY}, $item{ARGSTR}, $item{KEY}) }	

	FUNCTIONCALL : /call/i FNKEY '(' ARGS ')'
		{ main::call($item{FNKEY}, $item{ARGS});}

	for : /for/i KEY
		{ main::push_loop($item{KEY}) }

	done : /^\s*done\s*$/
		{ main::pop_loop() }

	if : /^\s*if/i KEY
		{ main::if_handler($item{KEY}) }

	# IF is terminated by END IF or FI on its own line

	login : /login/i
		{ main::login() }

	module : /module/i MODSTR
		{ main::load_mod($item{MODSTR}) }

	instruction : assign_instruction
		| call_and_assign
		| FUNCTIONCALL
		| for
		| done
		| if
		| login
		| module

	startrule : instruction

_END_SYNTAX_

$::RD_HINT   = 1;
$::RD_ERRORS = 1;    # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1;    # Enable warnings. This will warn on unused rules &c.`

#$::RD_TRACE = 1;
my @loopstack;
my $loopindex;
my $stackref;
my @control_stack;

push @loopstack, $form;

sub assignval {
    my ( $key, $value ) = @_;
    if ( $key =~ /^ENV:/i ) {
        $ENV{$key} = $value;
    }
    else {
        %{ $loopstack[ $#loopstack - 1 ] }->{$key} = $value;
    }
}

sub expression {
    shift;
    my ( $lhs, $op, $rhs ) = @_;
    $lhs = $VARIABLE{$lhs} if $lhs =~ /[^-+0-9]/;
    return eval "$lhs $op $rhs";
}

sub call {
    my ( $call, $argstr ) = @_;
    $argstr =~ s/form/\\\%\$form/;
    $argstr =~ s/user/\\\%myconfig/;
    my @args = split /,\s/, $argstr;
    eval "$call($argstr);\n" || print STDERR $@ . "\n";
}

sub call_and_assign {
    my $key = pop;
    $stackref->{key} = call(@_);
}

sub push_loop {
    my $key     = shift;
    my $is_hash = 0;
    if ( ref( $stackref->{$key} ) =~ /HASH/ ) {
        $is_hash = 1;
    }
    elsif ( ref( $stackref->{$key} ) !~ /ARRAY/ ) {
        print STDERR "Warning:  Must loop through array or hash.";
    }
    push @loopstack, \$stackref->{$key};
    push @controlstack,
      {
        "key"     => $key,
        'index'   => 0,
        'linenum' => $#linestack,
        is_hash   => $is_hash
      };
}

sub pop_loop {
    pop @loopstack;
    $stackref = \$loopstack[$#loopstack];
}

sub if_handler {
    my $key = shift;
    if ( !$stackref->{$key} ) {
        $if_count = 1;
    }
}

sub login {
    $myconfig = new LedgerSMB::User "${LedgerSMB::Sysconfig::memberfile}",
      "$form->{login}";
    $form->db_init($myconfig);
}

sub load_mod {
    my $mod = shift;
    $mod =~ s/::/\//;
    require "$mod.pm";
}

my $scriptparse = new Parse::RecDescent($syntax);

$loopindex = 0;
my @linestack;

while ( $line = <> ) {
    push @linestack, $line;
    if ($if_count) {
        if ( $line =~ /^\s*IF\s/ ) {
            ++$if_count;
        }
        if ( $line =~ /^(\s*FI\s*|\s*END\s+IF\s*)$/ ) {
            --$if_count;
        }
    }
    next if ($if_count);
    $line =~ s/#.*$//;    # strip comments
    $scriptparse->startrule($line);
}

delete $form->{password};

for ( keys %$form ) {
    print "$_ = $form->{$_}\n";
}
