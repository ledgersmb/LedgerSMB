#!/usr/bin/perl

use strict;
use warnings;

$ENV{TMPDIR} = 't/var';

use Test::More 'no_plan';
use Test::Exception;
use Test::Trap qw(trap $trap);
use Math::BigFloat;

use LedgerSMB::Sysconfig;
use LedgerSMB;

sub redirect {
	print "redirected\n";
}

sub lsmb_error_func {
	print $_[0];
}

##line	subroutine
##108	new
##235	redirect
##254	format_amount
##364	parse_amount
##408	round_amount
##423	call_procedure
##454	date_to_number
##490	db_init
##522	redo_rows
##547	merge


my $lsmb = LedgerSMB->new();
my %myconfig;
my $utfstr;
my @r;

ok(defined $lsmb);
isa_ok($lsmb, 'LedgerSMB');

# $lsmb->escape checks
my $lsmb = LedgerSMB->new();
$utfstr = "\xd8\xad";
utf8::decode($utfstr);
ok(!$lsmb->escape, 'escape: (undef)');
ok(!$lsmb->escape('foo' => 'bar'), 'escape: (invalid args)');
cmp_ok($lsmb->escape('string' => ' '), 'eq', '%20',
	'escape: \' \'');
cmp_ok($lsmb->escape('string' => 'foo'), 'eq', 'foo', 
	'escape: foo');
cmp_ok($lsmb->escape('string' => 'foo bar'), 'eq', 'foo%20bar', 
	'escape: foo bar');
TODO: {
	local $TODO = 'Fun with Unicode';
	cmp_ok($lsmb->escape('string' => $utfstr), 'eq', '%d8%ad', 
		'escape: U+D8AD');
}

# $lsmb->is_blank checks
my $lsmb = LedgerSMB->new();
$lsmb->{blank} = '    ';
$lsmb->{notblank} = ' d   ';
TODO: {
	local $TODO = 'Errors should be thrown';
	throws_ok{$lsmb->is_blank} 'Error::Simple', 'is_blank: (undef)';
	throws_ok{$lsmb->is_blank('foo' => 'bar')} 'Error::Simple', 
		'is_blank: (invalid args)';
}
is($lsmb->is_blank('name' => 'notblank'), 0, 'is_blank: notblank');
is($lsmb->is_blank('name' => 'blank'), 1, 'is_blank: blank');

# $lsmb->is_run_mode checks
my $lsmb = LedgerSMB->new();
$ENV{GATEWAY_INTERFACE} = 'foo';
is($lsmb->is_run_mode('cgi'), 1, 'is_run_mode: CGI - CGI');
is($lsmb->is_run_mode('cli'), 0, 'is_run_mode: CGI - CLI');
is($lsmb->is_run_mode('mod_perl'), 0, 'is_run_mode: CGI - mod_perl');
is($lsmb->is_run_mode('foo'), 0, 'is_run_mode: CGI - (bad mode)');
is($lsmb->is_run_mode, 0, 'is_run_mode: CGI - (unknown mode)');
$ENV{MOD_PERL} = 'foo';
is($lsmb->is_run_mode('cgi'), 1, 'is_run_mode: CGI/mod_perl - CGI');
is($lsmb->is_run_mode('cli'), 0, 'is_run_mode: CGI/mod_perl - CLI');
is($lsmb->is_run_mode('mod_perl'), 1, 'is_run_mode: CGI/mod_perl - mod_perl');
is($lsmb->is_run_mode('foo'), 0, 'is_run_mode: CGI/mod_perl - (bad mode)');
is($lsmb->is_run_mode, 0, 'is_run_mode: CGI/mod_perl - (unknown mode)');
delete $ENV{GATEWAY_INTERFACE};
is($lsmb->is_run_mode('cgi'), 0, 'is_run_mode: mod_perl - CGI');
is($lsmb->is_run_mode('cli'), 0, 'is_run_mode: mod_perl - CLI');
is($lsmb->is_run_mode('mod_perl'), 1, 'is_run_mode: mod_perl - mod_perl');
is($lsmb->is_run_mode('foo'), 0, 'is_run_mode: mod_perl - (bad mode)');
is($lsmb->is_run_mode, 0, 'is_run_mode: mod_perl - (unknown mode)');
delete $ENV{MOD_PERL};
is($lsmb->is_run_mode('cgi'), 0, 'is_run_mode: CLI - CGI');
is($lsmb->is_run_mode('cli'), 1, 'is_run_mode: CLI - CLI');
is($lsmb->is_run_mode('mod_perl'), 0, 'is_run_mode: CLI - mod_perl');
is($lsmb->is_run_mode('foo'), 0, 'is_run_mode: CLI - (bad mode)');
is($lsmb->is_run_mode, 0, 'is_run_mode: CLI - (unknown mode)');

# $lsmb->num_text_rows checks
my $lsmb = LedgerSMB->new();
is($lsmb->num_text_rows('string' => "apple\npear", 'cols' => 10, 'max' => 5),
	2, 'num_text_rows: 2 rows, no column breakage, max 5 rows');
is($lsmb->num_text_rows('string' => "apple\npear", 'cols' => 10, 'max' => 1),
	1, 'num_text_rows: 2 rows, no column breakage, max 1 row');
is($lsmb->num_text_rows('string' => "apple\npear", 'cols' => 10, 'max' => 2),
	2, 'num_text_rows: 2 rows, no column breakage, max 2 rows');
is($lsmb->num_text_rows('string' => "apple\npear", 'cols' => 10),
	2, 'num_text_rows: 2 rows, no column breakage, no max row count');
is($lsmb->num_text_rows('string' => "01234567890123456789", 'cols' => 10),
	2, 'num_text_rows: 2 rows, non-word column breakage, no max row count');
is($lsmb->num_text_rows('string' => "012345 67890123 456789", 'cols' => 10),
	3, 'num_text_rows: 3 rows, word column breakage, no max row count');
is($lsmb->num_text_rows('string' => "0123456789", 'cols' => 10),
	1, 'num_text_rows: 1 rows, no breakage, max cols, no max row count');
is($lsmb->num_text_rows('string' => "01234567890", 'cols' => 10),
	2, 'num_text_rows: 2 rows, no breakage, max cols+1, no max row count');
is($lsmb->num_text_rows('string' => "1\n\n2", 'cols' => 10),
	3, 'num_text_rows: 3 rows, no breakage, blank line, no max row count');
is($lsmb->num_text_rows('string' => "012345 67890123456789", 'cols' => 10),
	3, 'num_text_rows: 3 rows, word and non column breakage, no max row count');

# $lsmb->debug checks
my $lsmb = LedgerSMB->new();
@r = trap{$lsmb->debug()};
like($trap->stdout, qr|\n\$VAR1 = bless\( {[\n\s]+'action' => '',[\n\s]+'dbversion' => '\d+\.\d+\.\d+',[\n\s]+'path' => 'bin/mozilla',[\n\s]+'version' => '$lsmb->{version}'[\n\s]+}, 'LedgerSMB' \);|,
	'debug: $lsmb->debug');
SKIP: {
	skip 'Environment for file test not clean' if -f "t/var/lsmb-11.$$";
	$lsmb->{file} = "t/var/lsmb-11.$$";
	$lsmb->debug({'file' => $lsmb->{file}});
	ok(-f "t/var/lsmb-11.$$", "debug: output file t/var/lsmb-11.$$ created");
	open(my $FH, '<', "t/var/lsmb-11.$$");
	my @str = <$FH>;
	close($FH);
	chomp(@str);
	like(join("\n", @str), qr|\$VAR1 = 'file';\n\$VAR2 = 't/var/lsmb-11.$$';\n\$VAR3 = bless\( {[\n\s]+'action' => '',[\n\s]+'dbversion' => '\d+\.\d+\.\d+',[\n\s]+'file' => 't/var/lsmb-11.$$',[\n\s]+'path' => 'bin/mozilla',[\n\s]+'version' => '$lsmb->{version}'[\n\s]+}, 'LedgerSMB' \);|,
		'debug: $lsmb with file, contents');
	is(unlink("t/var/lsmb-11.$$"), 1, "debug: removing t/var/lsmb-11.$$");
	ok(!-e "t/var/lsmb-11.$$", "debug: t/var/lsmb-11.$$ removed");
};

$lsmb->{file} = 't/this is a bad directory, I do not exist/foo';
@r = trap {$lsmb->debug('file' => $lsmb->{file}, $lsmb)};
like($trap->die, qr/No such file or directory/,
	"debug: open failure causes death");
ok(!-e $lsmb->{file}, "debug: file creation failed");

# $lsmb->new checks
my $lsmb = LedgerSMB->new();
ok(defined $lsmb, 'new: blank, defined');
isa_ok($lsmb, 'LedgerSMB', 'new: blank, correct type');
ok(defined $lsmb->{action}, 'new: blank, action defined');
ok(defined $lsmb->{dbversion}, 'new: blank, dbversion defined');
ok(defined $lsmb->{path}, 'new: blank, path defined');
ok(defined $lsmb->{version}, 'new: blank, version defined');

my $lsmb = LedgerSMB->new();
ok(defined $lsmb, 'new: action set, defined');
isa_ok($lsmb, 'LedgerSMB', 'new: action set, correct type');
ok(defined $lsmb->{action}, 'new: action set, action defined');
is($lsmb->{action}, 'apple_sauce', 'new: action set, action processed');
ok(defined $lsmb->{dbversion}, 'new: action set, dbversion defined');
ok(defined $lsmb->{path}, 'new: action set, path defined');
ok(defined $lsmb->{version}, 'new: action set, version defined');

my $lsmb = LedgerSMB->new();
ok(defined $lsmb, 'new: lynx, defined');
isa_ok($lsmb, 'LedgerSMB', 'new: lynx, correct type');
ok(defined $lsmb->{action}, 'new: lynx, action defined');
ok(defined $lsmb->{dbversion}, 'new: lynx, dbversion defined');
ok(defined $lsmb->{path}, 'new: lynx, path defined');
is($lsmb->{path}, 'bin/lynx', 'new: lynx, path carried through');
ok(defined $lsmb->{lynx}, 'new: lynx, lynx defined');
is($lsmb->{lynx}, 1, 'new: lynx, lynx enabled');
ok(defined $lsmb->{menubar}, 'new: lynx, menubar defined (deprecated)');
is($lsmb->{menubar}, 1, 'new: lynx, menubar enabled (deprecated)');
ok(defined $lsmb->{version}, 'new: lynx, version defined');

@r = trap {$lsmb = LedgerSMB->new()};
is($trap->die, "Error: Access Denied\n",
	'new: directory traversal 1 caught');
@r = trap {$lsmb = LedgerSMB->new()};
is($trap->die, "Error: Access Denied\n",
	'new: directory traversal 2 caught');
@r = trap {$lsmb = LedgerSMB->new()};
is($trap->die, "Error: Access Denied\n",
	'new: directory traversal 3 caught');

# $lsmb->redirect checks
my $lsmb = LedgerSMB->new();
ok(!defined $lsmb->{callback}, 'redirect: No callback set');
@r = trap{$lsmb->redirect};
is($trap->stdout, "redirected\n", 'redirect: No message or callback redirect');
TODO: {
	local $TODO = '$lsmb->info for LedgerSMB';
	@r = trap{$lsmb->redirect('msg' => 'hello world')};
	is($trap->stdout, "hello world\n", 
		'redirect: message, no callback redirect');
}
$lsmb->{callback} = 1;
@r = trap{$lsmb->redirect};
is($trap->stdout, "redirected\n", 'redirect: callback, no message redirect');
@r = trap{$lsmb->redirect('msg' => "hello world\n")};
is($trap->stdout, "redirected\n", 'redirect: callback and message redirect');

# $lsmb->call_procedure checks
my $lsmb = LedgerSMB->new();
$lsmb->{dbh} = ${LedgerSMB::Sysconfig::GLOBALDBH};
@r = $lsmb->call_procedure('procname' => 'character_length', 
	'args' => ['month']);
is($#r, 0, 'call_procedure: correct return length (one row)');
is($r[0]->{'character_length'}, 5, 
	'call_procedure: single arg, non-numeric return');

@r = $lsmb->call_procedure('procname' => 'trunc', 'args' => [57.1, 0]);
is($r[0]->{'trunc'}, Math::BigFloat->new('57'), 
	'call_procedure: two args, numeric return');

@r = $lsmb->call_procedure('procname' => 'pi', 'args' => []);
like($r[0]->{'pi'}, qr/^3.14/, 
	'call_procedure: empty arg list, non-numeric return');

# These tests are ugly and shouldn't work
@r = $lsmb->call_procedure(
	'procname' => 'power(2, 2) UNION ALL SELECT * FROM pi', 
	'args' => [], 'order_by' => 'power DESC');
is($#r, 1, 'call_procedure: correct return length (two rows)');
is($r[0]->{'power'}, 4, 'call_procedure: DESC ordering');
@r = $lsmb->call_procedure(
	'procname' => 'power(2, 2) UNION ALL SELECT * FROM pi', 
	'args' => [], 'order_by' => 'power ASC');
is($r[1]->{'power'}, 4, 'call_procedure: ASC ordering');

##
##TODO: {
##	local $TODO = 'Breaks when no arglist given';
##	@r = $lsmb->call_procedure('procname' => 'pi');
##	like($r[0]->{'pi'}, qr/^3.14/, 
##		'call_procedure: no args, non-numeric return');
##}

# $lsmb->merge checks
my $lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'keys' => ['apple', 'pear']);
ok(!defined $lsmb->{peach}, 'merge: Did not add unselected key');
is($lsmb->{apple}, 1, 'merge: Added unselected key apple');
is($lsmb->{pear}, 2, 'merge: Added unselected key pear');
like($lsmb->{path}, qr#bin/(lynx|mozilla)#, 'merge: left existing key');

my $lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3});
is($lsmb->{apple}, 1, 'merge: No key, added apple');
is($lsmb->{pear}, 2, 'merge: No key, added pear');
is($lsmb->{peach}, 3, 'merge: No key, added peach');
like($lsmb->{path}, qr#bin/(lynx|mozilla)#, 'merge: No key, left existing key');

my $lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'index' => 1);
is($lsmb->{apple_1}, 1, 'merge: Index 1, added apple as apple_1');
is($lsmb->{pear_1}, 2, 'merge: Index 1, added pear as pear_1');
is($lsmb->{peach_1}, 3, 'merge: Index 1, added peach as peach_1');
like($lsmb->{path}, qr#bin/(lynx|mozilla)#, 'merge: Index 1, left existing key');

# $lsmb->is_allowed_role checks
my $lsmb = LedgerSMB->new();
$lsmb->{_roles} = ('apple', 'pear');
is($lsmb->is_allowed_role('allowed_roles' => ['pear']), 1, 
	'is_allowed_role: allowed role');

TODO: {
	local $TODO = 'role system unimplemented';
	$lsmb->{_roles} = ['apple', 'pear'];
	is($lsmb->is_allowed_role('allowed_roles' => ['peach']), 0, 
		'is_allowed_role: disallowed role');
	is($lsmb->is_allowed_role('allowed_roles' => []), 0, 
		'is_allowed_role: no allowable roles');
	delete $lsmb->{_roles};
	is($lsmb->is_allowed_role('allowed_roles' => ['apple']), 0, 
		'is_allowed_role: no roles for user');
}
