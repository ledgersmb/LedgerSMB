#!/usr/bin/perl
#
# t/10-form.t
#
# Tests various functions in LedgerSMB::Form that aren't tested elsewhere.
#

# format_amount in 02-number-handling.t
# parse_amount  in 02-number-handling.t
# round_amount  in 02-number-handling.t
# current_date  in 03-date-handling.t
# split_date    in 03-date-handling.t
# format_date   in 03-date-handling.t
# from_to       in 03-date-handling.t
# datetonum     in 03-date-handling.t
# add_date      in 03-date-handling.t

# encode_all    empty
# decode_all    empty

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
##sub get_recurring {
##sub save_recurring {
##sub save_intnotes {
##sub update_defaults {
##sub db_prepare_vars {
##sub audittrail {

use strict;
use warnings;

use Test2::V0;
use Math::BigFloat;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

use LedgerSMB::Form;



sub capture_stdout (&) { ## no critic (ProhibitSubroutinePrototypes)
    my $block = shift;
    local *STDOUT;
    my $output = '';

    open STDOUT, '>', \$output
        or die "Unable to redirect STDOUT: $!";
    $block->();
    return $output;
}



my $form = Form->new;
my %myconfig;
my $utfstr;
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
$form = Form->new;

$form->{header} = 1;
capture_stdout { $form->hide_form('path'); }; # suppress printed output
ok($form->{header}, 'hide_form: header flag not cleared');

## $form->info checks
$form = Form->new;
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{header} = 'Blah';

like(capture_stdout { $form->info('hello world'); }, qr|<b>hello world</b>|,
     'info: CGI, pre-set header content');

delete $form->{header};
$ENV{LSMB_NOHEAD} = 0;

## $form->isblank checks
$form = Form->new;
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{header} = 'yes';
$form->{blank} = '    ';
ok(!$form->isblank('version'), 'isblank: Not blank');

## $form->header checks
$form = Form->new;
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
$form = Form->new;
@ary = ('projectnumber', 'description', 'name', 'startdate');
$form->{sort} = 'name';
is([$form->sort_columns(@ary)],
        ['name', 'projectnumber', 'description', 'startdate'],
        'sort_column: sort name');
$form->{sort} = 'apple';
is([$form->sort_columns(@ary)], ['apple', @ary],
        'sort_column: sort non-existent');
is($form->sort_columns, 0,
        'sort_column: sort, no columns');
delete $form->{sort};
is([$form->sort_columns(@ary)], \@ary,
        'sort_column: sort unset');

## $form->sort_order checks
## Note that $ordinal is intended to be a hashref mapping column names to
##  position
$form = Form->new;
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
$form = Form->new;
is(capture_stdout {$form->print_button({'pear' => {'key' => 'P', 'value' => 'Pears'}}, 'pear');},
   "<button data-dojo-type=\"dijit/form/Button\" class=\"submit\" type=\"submit\" name=\"__action\" value=\"pear\" id=\"action-pear-1\" title=\"Pears\"  >Pears</button>\n", 'print_button');

## $form->like checks
$form = Form->new;
is($form->like('hello world'), '%hello world%', 'like');

## $form->redirect checks
$form = Form->new;
ok(!defined $form->{callback}, 'redirect: No callback set');
is(capture_stdout { eval { $form->redirect;}; },
   "Location: login.pl\nContent-type: text/html\n\n", 'redirect: No message or callback redirect');
$form->{callback} = 1;


done_testing;
