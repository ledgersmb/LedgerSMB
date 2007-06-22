#!/usr/bin/perl
##format_amount	in 02-number-handling.t
##parse_amount	in 02-number-handling.t
##round_amount	in 02-number-handling.t
##current_date	in 03-date-handling.t
##split_date	in 03-date-handling.t
##format_date	in 03-date-handling.t
##from_to	in 03-date-handling.t
##datetonum	in 03-date-handling.t
##add_date	in 03-date-handling.t

##escape	in 10-form.t
##unescape	in 10-form.t
##quote		in 10-form.t
##unquote	in 10-form.t
##numtextrows	in 10-form.t
##debug		in 10-form.t
##hide_form	in 10-form.t
##info		in 10-form.t
##error		in 10-form.t
##isblank	in 10-form.t
##header	in 10-form.t
##sort_columns	in 10-form.t
##sort_order	in 10-form.t
##print_button	in 10-form.t

##encode_all	null
##decode_all	null

##sub new {
##sub dberror {
##sub redirect {
##sub db_parse_numeric {
##sub callproc {
##sub get_my_emp_num {
##sub parse_template {
##sub format_line {
##sub cleanup {
##sub rerun_latex {
##sub format_string {
##sub db_init {
##sub run_custom_queries {
##sub dbconnect {
##sub dbconnect_noauto {
##sub dbquote {
##sub update_balance {
##sub update_exchangerate {
##sub save_exchangerate {
##sub get_exchangerate {
##sub check_exchangerate {
##sub add_shipto {
##sub get_employee {
##sub get_name {
##sub all_vc {
##sub all_taxaccounts {
##sub all_employees {
##sub all_projects {
##sub all_departments {
##sub all_years {
##sub create_links {
##sub lastname_used {
##sub like {
##sub redo_rows {
##sub get_partsgroup {
##sub update_status {
##sub save_status {
##sub get_recurring {
##sub save_recurring {
##sub save_intnotes {
##sub update_defaults {
##sub db_prepare_vars {
##sub audittrail {

use strict;
use warnings;

$ENV{TMPDIR} = 't/var';

use Test::More;
plan skip_all => 'Trap tests could crash Perl on Windows' if $^O eq 'MSWin32';
eval "use Test::Trap";
plan skip_all => 'Test::Trap required for testing Form functions' if $@;
use Test::Trap qw(trap $trap);
plan 'no_plan';

use Math::BigFloat;
use IO::String;

use LedgerSMB::Form;

sub form_info_func {
	return $_[0];
}

sub form_error_func {
	print $_[0];
}

sub redirect {
	print "redirected\n";
}

my $form = new Form;
my %myconfig;
my $utfstr;
my @r;
my @ary;
my $aryref;
ok(defined $form);
isa_ok($form, 'Form');

## $form->escape checks
$utfstr = "\xd8\xad";
utf8::decode($utfstr);
for my $sig ('1.3.37', '2.2.4', '2.0.59') {
	$ENV{SERVER_SIGNATURE} = 'Apache/'.$sig;
	cmp_ok($form->escape('foo'), 'eq', 'foo', 
		"($sig) escape: foo");
	cmp_ok($form->escape('foo bar'), 'eq', 'foo%20bar', 
		"($sig) escape: foo bar");
	cmp_ok($form->escape($utfstr), 'eq', '%d8%ad', 
		"($sig) escape: U+D8AD");
}
$ENV{SERVER_SIGNATURE} = 'Apache/2.0.22';
cmp_ok($form->escape('foo'), 'eq', 'foo', 
	'(2.0.22) escape: foo');
cmp_ok($form->escape('foo bar'), 'eq', 'foo%2520bar', 
	'(2.0.22) escape: foo bar');
cmp_ok($form->escape($utfstr), 'eq', '%25d8%25ad', 
	'(2.0.22) escape: U+D8AD');
cmp_ok($form->escape('foo%20bar', 1), 'eq', 'foo%2520bar', 
	'(2.0.22, been) escape: foo bar');

## $form->unescape checks
$utfstr = "\xd8\xad";
utf8::decode($utfstr);
cmp_ok($form->unescape('+'), 'eq', ' ', 'unescape: +');
cmp_ok($form->unescape('\\'), 'eq', '', 'unescape: \\');
cmp_ok($form->unescape('%20'), 'eq', ' ', 'unescape: %20');
cmp_ok($form->unescape("foo\r\n"), 'eq', "foo\n", 'unescape: foo\r\n');
ok(utf8::is_utf8($form->unescape('foo%d8%ad')), 'unescape: (utf8 output)');
cmp_ok(unpack("H*", $form->unescape('%d8%ad')), 'eq', 
	unpack("H*", $utfstr), 'unescape: %d8%ad');
cmp_ok(unpack("H*", $form->unescape($form->unescape('%d8%ad'))), 'eq', 
	unpack("H*", $utfstr), '(2x) unescape: %d8%ad');

## $form->quote checks
ok(!defined $form->quote(), 'quote: (undef)');
cmp_ok($form->quote(\%myconfig), '==', \%myconfig, 'quote: (reference)');
cmp_ok($form->quote('hello'), 'eq', 'hello', 'quote: hello');
cmp_ok($form->quote('hello"world'), 'eq', 'hello&quot;world', 
	'quote: hello"world');

## $form->unquote checks
ok(!defined $form->unquote(), 'unquote: (undef)');
cmp_ok($form->unquote(\%myconfig), '==', \%myconfig, 'unquote: (reference)');
cmp_ok($form->unquote('hello'), 'eq', 'hello', 'unquote: hello');
cmp_ok($form->unquote('hello&quot;world'), 'eq', 'hello"world', 
	'unquote: hello&quot;world');

## $form->numtextrows checks
cmp_ok($form->numtextrows("hello world\n12345678901234567890\n", 20), '==', 2,
	'numtextrows: 2 rows');
cmp_ok($form->numtextrows("hello world12345678901234567890\n", 20), '==', 2,
	'numtextrows: 2 rows (no space)');
cmp_ok($form->numtextrows("hello world\n12345678901234567890\n", 20, 1), '==', 1,
	'numtextrows: 2 rows (1 max)');
cmp_ok($form->numtextrows("hello world\n12345678901234567890\n", 20, 3), '==', 2,
	'numtextrows: 2 rows (3 max)');

## $form->debug checks
$form = new Form;
@r = trap{$form->debug};
like($trap->stdout, qr/\naction = \ndbversion = \d+\.\d+\.\d+\nlogin = \nnextsub = \npath = bin\/mozilla\nversion = \d+\.\d+\.\d+\n/, 'debug: STDOUT');
SKIP: {
	skip 'Environment for file test not clean' if -f "t/lsmb-10.$$";
	$form->debug("t/lsmb-10.$$");
	ok(-f "t/lsmb-10.$$", "debug: output file t/lsmb-10.$$ created");
	open(my $FH, '<', "t/lsmb-10.$$");
	my @str = <$FH>;
	close($FH);
	chomp(@str);
	like(join("\n", @str), qr/action = \ndbversion = \d+\.\d+\.\d+\nlogin = \nnextsub = \npath = bin\/mozilla\nversion = \d+\.\d+\.\d+/, "debug: t/lsmb-10.$$ contents");
	is(unlink("t/lsmb-10.$$"), 1, "debug: removing t/lsmb-10.$$");
	ok(!-e "t/lsmb-10.$$", "debug: t/lsmb-10.$$ removed");
};

## $form->hide_form checks
$form = new Form;
$form->{header} = 1;
@r = trap{$form->hide_form};
like($trap->stdout, qr/<input type="hidden" name="action" value="" \/>\n<input type="hidden" name="dbversion" value="\d+\.\d+\.\d+" \/>\n<input type="hidden" name="login" value="" \/>\n<input type="hidden" name="nextsub" value="" \/>\n<input type="hidden" name="path" value="bin\/mozilla" \/>\n<input type="hidden" name="version" value="$form->{version}" \/>/, 
	'hide_form: base');
ok(!$form->{header}, 'hide_form: header flag cleared');

$form->{header} = 1;
@r = trap{$form->hide_form('path')};
is($trap->stdout, "<input type=\"hidden\" name=\"path\" value=\"bin/mozilla\" />\n", 
	'hide_form: path');
ok($form->{header}, 'hide_form: header flag not cleared');

## $form->info checks
$form = new Form;
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{pre} = 'Blah';
$form->{header} = 'Blah';

@r = trap{$form->info('hello world')};
is($trap->stdout, '<b>hello world</b>',
	'info: CGI, pre-set header content');
ok(!$form->{pre}, 'info: CGI, removed $self->{pre}');

delete $form->{header};
@r = trap{$form->info('hello world')};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+<body><b>hello world</b>|, 
	'info: CGI, header content');

delete $ENV{GATEWAY_INTERFACE};
delete $ENV{info_function};
$form->{pre} = 'Blah';
$form->{header} = 'Blah';
@r = trap{$form->info('hello world')};
is($trap->stdout, "hello world\n",
	'info: CLI, content');
ok($form->{pre}, 'info: CLI, ignored $self->{pre}');

$ENV{info_function} = 'main::form_info_func';
SKIP: {
	skip 'Environment variable info_function could not be set' unless
		$ENV{info_function} eq 'main::form_info_func';
	is($form->info('hello world'), 'hello world', 
		'info: CLI, function call');
};
delete $ENV{info_function};

## $form->error checks
$form = new Form;
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{pre} = 'Blah';
$form->{header} = 'Blah';
@r = trap{$form->error('hello world')};
is($trap->exit, 0, 
	'error: CGI, normal termination');
is($trap->stdout, '<body><h2 class="error">Error!</h2> <p><b>hello world</b></body>',
	'error: CGI, pre-set header content');
ok(!$form->{pre}, 'error: CGI, removed $self->{pre}');
delete $form->{header};
@r = trap{$form->error('hello world')};
is($trap->exit, 0, 
	'error: CGI, normal termination');
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+<body><h2 class="error">Error!</h2> <p><b>hello world</b></body>|, 
	'error: CGI, header content');

delete $ENV{GATEWAY_INTERFACE};
delete $ENV{error_function};
$form->{pre} = 'Blah';
$form->{header} = 'Blah';
@r = trap{$form->error('hello world')};
is($trap->die, "Error: hello world\n",
	'error: CLI, content, terminated');
ok($form->{pre}, 'error: CLI, ignored $self->{pre}');

$ENV{error_function} = 'main::form_error_func';
SKIP: {
	skip 'Environment variable error_function could not be set' unless
		$ENV{error_function} eq 'main::form_error_func';
	@r = trap{$form->error('hello world')};
	is($trap->stdout, 'hello world', 
		'error: CLI, function call called');
	is($trap->die, "Error: hello world\n",
		'error: CLI, function call termination');
};

## $form->isblank checks
$form = new Form;
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{header} = 'yes';
$form->{blank} = '    ';
ok(!$form->isblank('version'), 'isblank: Not blank');
@r = trap{$form->isblank('blank', 'hello world')};
is($trap->stdout, '<body><h2 class="error">Error!</h2> <p><b>hello world</b></body>',
	'isblank: Blank');
is($trap->exit, 0, 
	'isblank: Blank, termination');

## $form->header checks
$form = new Form;
$form->{header} = 'yes';
ok(!$form->header, 'header: preset');

$ENV{GATEWAY_INTERFACE} = 'yes';
delete $form->{header};
delete $form->{stylesheet};
delete $form->{charset};
delete $form->{titlebar};
delete $form->{title};
delete $form->{pre};
@r = trap{$form->header};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+|, 
	'header: unset');

delete $form->{header};
@r = trap{$form->header(1, 'hello world')};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+hello world[\n\s]+</head>[\n\s]+|, 
	'header: headeradd');

delete $form->{header};
$form->{pre} = 'hello world';
@r = trap{$form->header};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+hello world \n|, 
	'header: pre => \'hello world\'');
delete $form->{pre};

delete $form->{header};
$form->{titlebar} = 'hello';
@r = trap{$form->header};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title>hello</title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+|, 
	'header: titlebar => \'hello\'');

delete $form->{header};
$form->{title} = 'world';
@r = trap{$form->header};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title>world - hello</title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+|, 
	'header: titlebar => \'hello\', title => \'world\'');
delete $form->{title};
delete $form->{titlebar};

delete $form->{header};
$form->{charset} = 'UTF-8';
@r = trap{$form->header};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=UTF-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+|, 
	'header: charset => \'UTF-8\'');
delete $form->{charset};

delete $form->{header};
$form->{stylesheet} = "not a real file.$$";
@r = trap{$form->header};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+|, 
	"header: stylesheet => 'not a real file.$$'");

delete $form->{header};
$form->{stylesheet} = 'ledger-smb.css';
@r = trap{$form->header};
like($trap->stdout, qr|Content-Type: text/html; charset=utf-8\n\n+<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" \n\s+"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n\s+<title></title>\n\s+<meta http-equiv="Pragma" content="no-cache" />\n\s+<meta http-equiv="Expires" content="-1" />\n\s+<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />[\n\s]+<link rel="stylesheet" href="css/ledger-smb.css" type="text/css" title="LedgerSMB stylesheet" />[\n\s]+<meta http-equiv="content-type" content="text/html; charset=utf-8" />[\n\s]+<meta name="robots" content="noindex,nofollow" />[\n\s]+</head>[\n\s]+|, 
	'header: stylesheet => \'ledgersmb.css\'');

delete $ENV{GATEWAY_INTERFACE};
delete $form->{header};
is($form->header, 1, 'header: non-CGI');
is($form->{header}, 1, 'header: non-CGI header flag set');

## $form->sort_column checks
## Note that sort_column merely sorts the value of $form->{sort} to being the
##  first element of the list, adding it if needed
$form = new Form;
@ary = ('projectnumber', 'description', 'name', 'startdate');
$form->{sort} = 'name';
is_deeply([$form->sort_columns(@ary)], 
	['name', 'projectnumber', 'description', 'startdate'],
	'sort_column: sort name');
$form->{sort} = 'apple';
is_deeply([$form->sort_columns(@ary)], ['apple', @ary],
	'sort_column: sort non-existent');
is($form->sort_columns, 0,
	'sort_column: sort, no columns');
delete $form->{sort};
is_deeply([$form->sort_columns(@ary)], \@ary,
	'sort_column: sort unset');

## $form->sort_order checks
## Note that $ordinal is intended to be a hashref mapping column names to
##  position
$form = new Form;
$aryref = ['projectnumber', 'description', 'name', 'startdate'];
delete $form->{direction};
delete $form->{sort};
delete $form->{oldsort};
is($form->sort_order($aryref),
	'projectnumber ASC,description,name,startdate',
	'sort_order: unset, no ordinal');
is($form->{direction}, 'ASC', 'sort_order: unset direction ASC');

$form->{direction} = 'ASC';
delete $form->{sort};
delete $form->{oldsort};
is($form->sort_order($aryref),
	'projectnumber DESC,description,name,startdate',
	'sort_order: direction => \'ASC\', no ordinal');
is($form->{direction}, 'DESC', 'sort_order: ASC -> DESC, sort unset');

$form->{direction} = 'DESC';
delete $form->{sort};
delete $form->{oldsort};
is($form->sort_order($aryref),
	'projectnumber ASC,description,name,startdate',
	'sort_order: direction => \'DESC\', no ordinal');
is($form->{direction}, 'ASC', 'sort_order: DESC -> ASC, sort unset');

$form->{direction} = 'DESC';
$form->{sort} = 'name';
$form->{oldsort} = 'startdate';
is($form->sort_order($aryref),
	'name DESC,projectnumber,description,startdate',
	'sort_order: direction => \'DESC\', sort => \'name\', no ordinal');
is($form->{direction}, 'DESC', 'sort_order: DESC -/-> ASC, sort != oldsort');

$form->{direction} = 'DESC';
$form->{sort} = 'name';
$form->{oldsort} = 'startdate';
is($form->sort_order($aryref, {name => 2, projectnumber => 3, startdate => 1}),
	'2 DESC,3,description,1',
	'sort_order: direction => \'DESC\', sort => \'name\', ordinal');
$form->{direction} = 'DESC';
$form->{sort} = 'name';
$form->{oldsort} = 'startdate';
is($form->sort_order($aryref, {name => 0, projectnumber => 3, startdate => 1}),
	'name DESC,3,description,1',
	'sort_order: direction => \'DESC\', sort => \'name\', ordinal b');

## $form->print_button checks
$form = new Form;
@r = trap{$form->print_button({'pear' => {'key' => 'P', 'value' => 'Pears'}}, 'pear')};
is($trap->stdout, "<button class=\"submit\" type=\"submit\" name=\"action\" value=\"pear\" accesskey=\"P\" title=\"Pears [Alt-P]\">Pears</button>\n", 'print_button');

## $form->like checks
$form = new Form;
is($form->like('hello world'), '%hello world%', 'like');

## $form->redirect checks
$form = new Form;
ok(!defined $form->{callback}, 'redirect: No callback set');
@r = trap{$form->redirect};
is($trap->stdout, "redirected\n", 'redirect: No message or callback redirect');
@r = trap{$form->redirect('hello world')};
is($trap->stdout, "hello world\n", 
	'redirect: message, no callback redirect');
$form->{callback} = 1;
@r = trap{$form->redirect};
is($trap->stdout, "redirected\n", 'redirect: callback, no message redirect');
@r = trap{$form->redirect("hello world\n")};
is($trap->stdout, "redirected\n", 'redirect: callback and message redirect');
