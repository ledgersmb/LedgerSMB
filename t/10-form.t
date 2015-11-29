#!/usr/bin/perl
#
# t/10-form.t
#
# Tests various functions in LedgerSMB::Form that aren't tested elsewhere.
#

# format_amount	in 02-number-handling.t
# parse_amount	in 02-number-handling.t
# round_amount	in 02-number-handling.t
# current_date	in 03-date-handling.t
# split_date	in 03-date-handling.t
# format_date	in 03-date-handling.t
# from_to	in 03-date-handling.t
# datetonum	in 03-date-handling.t
# add_date	in 03-date-handling.t

# encode_all	empty
# decode_all	empty

##sub new {
##sub dberror {
##sub db_parse_numeric {
##sub callproc {
##sub get_my_emp_num {
##sub format_string {
##sub db_init {
##sub run_custom_queries {
##sub dbconnect {
##sub dbconnect_noauto {
##sub dbquote {
##sub update_balance {
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

use Test::More 'no_plan';
use Test::Trap qw(trap $trap);
use Math::BigFloat;
#use IO::String;

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

my $expStackTrace = 0;
if ( defined $ENV{PERL5OPT} &&
     ($ENV{PERL5OPT}=~/.*?Devel::SimpleTrace.*/ ||
      $ENV{PERL5OPT}=~/.*?Carp::Always.*/ ))
{
   $expStackTrace = 1;
}

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
cmp_ok(unpack("U", $form->unescape('%d8%ad')), 'eq',
	unpack("U", $utfstr), 'unescape: %d8%ad');
cmp_ok(unpack("U", $form->unescape($form->unescape('%d8%ad'))), 'eq',
	unpack("U", $utfstr), '(2x) unescape: %d8%ad');

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

## $form->hide_form checks
$form = new Form;

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
like($trap->stdout, qr|<b>hello world</b>|,
	'info: CGI, pre-set header content');
ok(!$form->{pre}, 'info: CGI, removed $self->{pre}');

delete $form->{header};
$ENV{LSMB_NOHEAD} = 0;

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


## $form->isblank checks
$form = new Form;
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{header} = 'yes';
$form->{blank} = '    ';
ok(!$form->isblank('version'), 'isblank: Not blank');
is($trap->exit, undef,
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
$ENV{LSMB_NOHEAD} = 0;
delete $ENV{GATEWAY_INTERFACE};
delete $form->{header};
$ENV{LSMB_NOHEAD} = 0;

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
is($trap->stdout, "<button data-dojo-type=\"dijit/form/Button\" class=\"submit\" type=\"submit\" name=\"action\" value=\"pear\" accesskey=\"P\" title=\"Pears [Alt-P]\">Pears</button>\n", 'print_button');

## $form->like checks
$form = new Form;
is($form->like('hello world'), '%hello world%', 'like');

## $form->redirect checks
$form = new Form;
ok(!defined $form->{callback}, 'redirect: No callback set');
@r = trap{$form->redirect};
is($trap->stdout, "Location: login.pl\nContent-type: text/html\n\n", 'redirect: No message or callback redirect');
@r = trap{$form->redirect('hello world')};
is($trap->stdout, "hello world\n",
	'redirect: message, no callback redirect');
$form->{callback} = 1;
@r = trap{$form->redirect};
is($trap->stdout, "", 'redirect: callback, no message redirect');
@r = trap{$form->redirect("hello world\n")};
is($trap->stdout, "", 'redirect: callback and message redirect');
