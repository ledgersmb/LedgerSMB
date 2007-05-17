#!/usr/bin/perl

use strict;
use warnings;

$ENV{TMPDIR} = 't/var';

use Test::More tests => 42;
use Test::Trap qw(trap $trap);

use LedgerSMB::Form;
use LedgerSMB::Menufile;

my $ini;
my @r;
my $form;
my $myconfig;

# general new and add_file checks
$ini = new LedgerSMB::Menufile;
ok(defined $ini, 'new: File not provided');
isa_ok($ini, 'LedgerSMB::Menufile', 'new: File not provided gives correct type');
$ini->add_file('t/data/12-menu1.ini');
is_deeply($ini->{'AR--Add Transaction'}, 
	{'action' => 'add', 'module' => 'ar.pl'},
	'add_file: First file added, leaf correct');
is_deeply($ini->{'ORDER'}, 
	['AR', 'AR--Add Transaction'],
	'add_file: First file added, order correct');

$ini->add_file('t/data/12-menu2.ini');
is_deeply($ini->{'AR--Add Transaction'}, 
	{'action' => 'add', 'module' => 'ar.pl'},
	'add_file: Second file added, old leaf correct');
is_deeply($ini->{'AR--foo'},
	{'module' => 'am.pl'},
	'add_file: Second file added, new leaf correct');
is_deeply($ini->{'ORDER'}, 
	['AR', 'AR--Add Transaction', 'section', 'AR--foo'],
	'add_file: Second file added, order correct');

$ini = LedgerSMB::Menufile->new('t/data/12-menu2.ini');
ok(defined $ini, 'new: File provided');
isa_ok($ini, 'LedgerSMB::Menufile', 'new: File provided gives correct type');
is_deeply($ini->{'AR--foo'},
	{'module' => 'am.pl'},
	'new: File provided, leaf correct');
is_deeply($ini->{'ORDER'}, 
	['section', 'AR--foo'],
	'new: File provided, order correct');

$ini->add_file('t/data/12-menu3.ini');
is_deeply($ini->{'AR--foo'},
	{'module' => 'ax.pl'},
	'add_file: Data re-added, leaf correct, not duplicated');
is_deeply($ini->{'ORDER'}, 
	['section', 'AR--foo'],
	'add_file: Data re-added, order correct, not duplicated');

# menuitem checks
$form = new Form;
$form->{script} = 'tt.pl';
$form->{tag} = '1';
$myconfig = {'login' => 'testuser', 'numberformat' => '1000.00'};
$ini = new LedgerSMB::Menufile('t/data/12-menu4.ini');
is_deeply($ini->{'AR--foo'},
	{'module' => 'ax.pl', 'action' => 'add', 'type' => 'foo'},
	'new: Data for menu item test 1 correct');
is_deeply($ini->{'New Window'}, {'target' => '_blank'},
	'new: Data for menu item test 2 correct');
is_deeply($ini->{'Website'}, {'href' => 'ledgersmb.org'},
	'new: Data for menu item test 3 correct');
is_deeply($ini->{'AR--test'},
	{'module' => 'test', 'apples' => 'login=', 'pears' => 'numberformat=2'},
	'new: Data for menu item test 4 correct');
is_deeply($ini->{'AR'}, {'target' => 'acc_menu', 'type' => 'test'},
	'new: Data for menu item test 5 correct');

is($ini->menuitem($myconfig, $form, 'AR--foo'), '<a style="display:block;"href="ax.pl?path=bin/mozilla&amp;action=add&amp;level=AR--foo&amp;login=&amp;timeout=&amp;sessionid=&amp;js=&amp;type=foo">',
	'menuitem: Menu item test 1, base');
ok(!defined $ini->{'AR--foo'}->{'module'}, 'menuitem: Deleted module');
ok(!defined $ini->{'AR--foo'}->{'action'}, 'menuitem: Deleted action');
is($ini->menuitem($myconfig, $form, 'New Window'), '<a style="display:block;"href="tt.pl?path=bin/mozilla&amp;action=section_menu&amp;level=New%20Window&amp;login=&amp;timeout=&amp;sessionid=&amp;js=" target="_blank">',
	'menuitem: Menu item test 2, target');
is($ini->menuitem($myconfig, $form, 'Website'), '<a href="ledgersmb.org">',
	'menuitem: Menu item test 3, href');
ok(!defined $ini->{'Website'}->{'href'}, 'menuitem: Deleted href');
$form->{menubar} = 1;
is($ini->menuitem($myconfig, $form, 'AR--test'), '<a style=""href="test?path=bin/mozilla&amp;action=section_menu&amp;level=AR--test&amp;login=&amp;timeout=&amp;sessionid=&amp;js=&amp;apples=testuser&amp;pears=1000.002">',
	'menuitem: Menu item test 4, myconfig substitutions');
is($ini->menuitem($myconfig, $form, 'AR'), '<a style=""href="tt.pl?path=bin/mozilla&amp;action=section_menu&amp;level=AR&amp;login=&amp;timeout=&amp;sessionid=&amp;js=&amp;type=test#id1" target="acc_menu">',
	'menuitem: Menu item test 5, acc_menu');
ok(!defined $ini->{'AR'}->{'target'}, 'menuitem: Deleted target');

# access_control check
$myconfig = {'acs' => 'AR--test'};
$ini = new LedgerSMB::Menufile('t/data/12-menu4.ini');
is_deeply([$ini->access_control($myconfig)], ['AR', 'New Window', 'Website'],
	'access_control: Single item, not top exclusion, top');
is_deeply([$ini->access_control($myconfig, 'AR')], ['AR--foo'],
	'access_control: Single item, not top exclusion, submenu');
$myconfig = {'acs' => 'Website'};
is_deeply([$ini->access_control($myconfig)], ['AR', 'New Window'],
	'access_control: Single item, top exclusion, top');
is_deeply([$ini->access_control($myconfig, 'AR')], ['AR--foo', 'AR--test'],
	'access_control: Single item, top exclusion, sub menu');
$myconfig = {'acs' => 'AR--test;AR--foo;New Window'};
is_deeply([$ini->access_control($myconfig)], ['AR', 'Website'],
	'access_control: Multiple items, top');
is_deeply([$ini->access_control($myconfig, 'AR')], [],
	'access_control: Multiple items, sub menu');
$myconfig = {'acs' => 'AR'};
is_deeply([$ini->access_control($myconfig)], ['New Window', 'Website'],
	'access_control: Top menu exclusion, top');
is_deeply([$ini->access_control($myconfig, 'AR')], ['AR--foo', 'AR--test'],
	'access_control: Top menu exclusion, sub menu');

# file not found check
$ini = new LedgerSMB::Menufile;
@r = trap{$ini->add_file('t/data/12-not-a-file')};
is_deeply($ini->{'ORDER'}, [],
	'add_file: Non-existent file added, order correct');
like($trap->die, qr|12-not-a-file :|, 
	'add_file: Non-existent file causes error display');

# Gratuitous testing to increase coverage rating
$ini = undef;
@r = trap{$ini = LedgerSMB::Menufile::new};
isa_ok($ini, 'main', 'new: No type passed gives main type');

my $pkg = 'foo';
$ini = undef;
@r = trap{$ini = LedgerSMB::Menufile::new(\$pkg)};
like($trap->{warn}[0], qr|has no copy constructor! creating a new object|,
	'new: Type passed scalar reference');
isa_ok($ini, 'SCALAR', 'new: Type passed scalar reference gives SCALAR type');
LedgerSMB::Menufile::add_file($ini, 't/data/12-menu1.ini');
is_deeply($ini->{'AR--Add Transaction'}, 
	{'action' => 'add', 'module' => 'ar.pl'},
	'add_file: File added to SCALAR, leaf correct');
is_deeply($ini->{'ORDER'}, 
	['AR', 'AR--Add Transaction'],
	'add_file: File added to SCALAR, order correct');
