#!/usr/bin/perl

use strict;
use warnings;

$ENV{TMPDIR} = 't/var';
$ENV{LANG} = 'LANG=en_US.UTF8';
$ENV{REQUEST_METHOD} = 'GET';
     # Suppress warnings from LedgerSMB::_process_cookies

use Test::More;
use Test::Exception;
use Test::Trap qw(trap $trap);
use Math::BigFloat;

use LedgerSMB::Sysconfig;
use LedgerSMB;
use LedgerSMB::App_State;
use Log::Log4perl;
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);


my $lsmb;
plan tests => 61;




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


$lsmb = LedgerSMB->new();
my %myconfig;
my $utfstr;
my @r;

ok(defined $lsmb);
isa_ok($lsmb, 'LedgerSMB');

# $lsmb->escape checks
$lsmb = LedgerSMB->new();
$utfstr = "\xd8\xad";
utf8::decode($utfstr);


# $lsmb->is_run_mode checks
$lsmb = LedgerSMB->new();
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


# $lsmb->new checks
$lsmb = LedgerSMB->new();
ok(defined $lsmb, 'new: blank, defined');
isa_ok($lsmb, 'LedgerSMB', 'new: blank, correct type');
ok(defined $lsmb->{action}, 'new: blank, action defined');
ok(defined $lsmb->{dbversion}, 'new: blank, dbversion defined');
ok(defined $lsmb->{path}, 'new: blank, path defined');
ok(defined $lsmb->{version}, 'new: blank, version defined');

$lsmb = LedgerSMB->new('path=bin/lynx');
#$lsmb = LedgerSMB->new();
#$lsmb->{path} = "bin/lynx";
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


# $lsmb->call_procedure checks
SKIP: {
	skip 'Skipping call_procedure tests, no db specified', 5
		if !defined $ENV{PGDATABASE};
	$lsmb = LedgerSMB->new();
	$lsmb->{dbh} = DBI->connect("dbi:Pg:dbname=$ENV{PGDATABASE}",
		undef, undef, {AutoCommit => 0 });
        LedgerSMB::App_State::set_DBH($lsmb->{dbh});
	@r = $lsmb->call_procedure('procname' => 'character_length',
		'args' => ['month'], 'schema'=>"pg_catalog");
	is($#r, 0, 'call_procedure: correct return length (one row)');
	is($r[0]->{'character_length'}, 5,
		'call_procedure: single arg, non-numeric return');

	@r = $lsmb->call_procedure('procname' => 'trunc', 'args' => [57.1, 0], 'schema' => 'pg_catalog');
	is($r[0]->{'trunc'}, Math::BigFloat->new('57'),
		'call_procedure: two args, numeric return');

	@r = $lsmb->call_procedure('procname' => 'pi', 'args' => [], 'schema'=>'pg_catalog');
	like($r[0]->{'pi'}, qr/^3.14/,
		'call_procedure: empty arg list, non-numeric return');
	@r = $lsmb->call_procedure('procname' => 'pi', 'schema'=>'pg_catalog');
	like($r[0]->{'pi'}, qr/^3.14/,
		'call_procedure: no args, non-numeric return');
    $lsmb->{dbh}->rollback();
    $lsmb->{dbh}->disconnect;
}

# $lsmb->merge checks
$lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'keys' => ['apple', 'pear']);
ok(!defined $lsmb->{peach}, 'merge: Did not add unselected key');
is($lsmb->{apple}, 1, 'merge: Added unselected key apple');
is($lsmb->{pear}, 2, 'merge: Added unselected key pear');
like($lsmb->{path}, qr#bin/(lynx|mozilla)#, 'merge: left existing key');

$lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3});
is($lsmb->{apple}, 1, 'merge: No key, added apple');
is($lsmb->{pear}, 2, 'merge: No key, added pear');
is($lsmb->{peach}, 3, 'merge: No key, added peach');
like($lsmb->{path}, qr#bin/(lynx|mozilla)#, 'merge: No key, left existing key');

$lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'index' => 1);
is($lsmb->{apple_1}, 1, 'merge: Index 1, added apple as apple_1');
is($lsmb->{pear_1}, 2, 'merge: Index 1, added pear as pear_1');
is($lsmb->{peach_1}, 3, 'merge: Index 1, added peach as peach_1');
like($lsmb->{path}, qr#bin/(lynx|mozilla)#, 'merge: Index 1, left existing key');

# $lsmb->is_allowed_role checks, no prefix
$lsmb = LedgerSMB->new();
$lsmb->{_role_prefix} = '1_';
$lsmb->{_roles} = ['1_apple', '1_pear'];
is($lsmb->is_allowed_role({allowed_roles => ['pear']}), 1,
	'is_allowed_role: allowed role');

$lsmb->{_roles} = ['apple', 'pear'];
is($lsmb->is_allowed_role({allowed_roles => ['peach']}), 0,
	'is_allowed_role: disallowed role');
is($lsmb->is_allowed_role({'allowed_roles' => []}), 0,
	'is_allowed_role: no allowable roles');
delete $lsmb->{_roles};
is($lsmb->is_allowed_role({'allowed_roles' => ['apple']}), 0,
		'is_allowed_role: no roles for user');

# $lsmb->is_allowed_role checks, prefix
$lsmb = LedgerSMB->new();
$lsmb->{_role_prefix} = 'test__';

$lsmb->{_roles} = ['test__apple', 'test__pear'];
is($lsmb->is_allowed_role({allowed_roles => ['pear']}), 1,
	'is_allowed_role: allowed role with prefix');
