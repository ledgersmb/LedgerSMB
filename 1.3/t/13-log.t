#!/usr/bin/perl

use strict;
use warnings;

$ENV{TMPDIR} = 't/var';

#use Test::More tests => 13;
use Test::More;
plan skip_all => 'Disabled because we have moved to Log4perl and the predefined
methods in the LedgerSMB::Log package nto currently recommended';
use Test::Trap qw(trap $trap);

use Data::Dumper;

use LedgerSMB::Sysconfig;
use LedgerSMB::Log;

my @r;

$LedgerSMB::Sysconfig::logging = 0;
@r = trap{LedgerSMB::Log->print('test', 'message')};
#is(LedgerSMB::Log->print('test', 'message'), 0);
ok(!$trap->stderr,
	'print: Unsetting LedgerSMB::Sysconfig::logging disables printing');
$LedgerSMB::Sysconfig::logging = 1;
@r = trap{LedgerSMB::Log->print('test', 'message')};
ok($trap->stderr,
	'print: Setting LedgerSMB::Sysconfig::logging enables printing');
like($trap->stderr, qr/^\[.*?\] \[test\] $$ message/,
	'print: Outputs correct message');
@r = trap{LedgerSMB::Log->emerg('test')};
like($trap->stderr, qr/^\[.*?\] \[emerg\] $$ test/,
	'emerg: Outputs correct grouping');
@r = trap{LedgerSMB::Log->alert('test')};
like($trap->stderr, qr/^\[.*?\] \[alert\] $$ test/,
	'alert: Outputs correct grouping');
@r = trap{LedgerSMB::Log->crit('test')};
like($trap->stderr, qr/^\[.*?\] \[crit\] $$ test/,
	'crit: Outputs correct grouping');
@r = trap{LedgerSMB::Log->error('test')};
like($trap->stderr, qr/^\[.*?\] \[error\] $$ test/,
	'error: Outputs correct grouping');
@r = trap{LedgerSMB::Log->warn('test')};
like($trap->stderr, qr/^\[.*?\] \[warn\] $$ test/,
	'warn: Outputs correct grouping');
@r = trap{LedgerSMB::Log->notice('test')};
like($trap->stderr, qr/^\[.*?\] \[notice\] $$ test/,
	'notice: Outputs correct grouping');
@r = trap{LedgerSMB::Log->info('test')};
like($trap->stderr, qr/^\[.*?\] \[info\] $$ test/,
	'info: Outputs correct grouping');
@r = trap{LedgerSMB::Log->debug('test')};
like($trap->stderr, qr/^\[.*?\] \[debug\] $$ test/,
	'debug: Outputs correct grouping');
@r = trap{LedgerSMB::Log->dump('test')};
like($trap->stderr, qr/^\[.*?\] \[debug\] $$ \$VAR1 = 'test'/,
	'dump: Simple dump correct');
@r = trap{LedgerSMB::Log->longmess('test')};
like($trap->stderr, qr/^\[.*?\] \[debug\] $$ test at /,
	'longmess: Outputs correct data');
