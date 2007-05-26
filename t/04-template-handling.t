#!/usr/bin/perl

use strict;
use warnings;

$ENV{TMPDIR} = 't/var';

use Test::More 'no_plan';
use Test::Trap qw(trap $trap);
use Test::Exception;

use Error qw(:try);

use LedgerSMB::AM;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Locale;
use LedgerSMB::Template;
use LedgerSMB::Template::HTML;

$LedgerSMB::Sysconfig::tempdir = 't/var';

my @r;
my $temp;
my $form;
my $myconfig;
my $template;
my $FH;
my $locale;

$locale = LedgerSMB::Locale->get_handle('fr');

# AM->check_template_name checks
# check_template operates by calling $form->error if the checks fail
$form = new Form;
$myconfig = {'templates' => 'test'};
for my $ext ('css', 'tex', 'txt', 'html', 'xml') {
	$form->{file} = "test/apples.${ext}";
	@r = trap{AM->check_template_name($myconfig, $form)};
	ok(!defined $trap->die,
		"AM, check_template_name: Template directory, ${ext}");
}
$form->{file} = 'css/apples.txt';
@r = trap{AM->check_template_name($myconfig, $form)};
ok(!defined $trap->die,
	'AM, check_template_name: CSS directory, txt');
$form->{file} = 'test2/apples.txt';
@r = trap{AM->check_template_name($myconfig, $form)};
is($trap->die, "Error: Not in a whitelisted directory: test2/apples.txt\n",
	'AM, check_template_name: Invalid directory, non-css denial');
$form->{file} = 'test/apples.exe';
@r = trap{AM->check_template_name($myconfig, $form)};
is($trap->die, "Error: Error:  File is of type that is not allowed.\n",
	'AM, check_template_name: Disallowed type denial');

# adjusting backuppath to avoid triggering directory traversal detection
$temp = ${LedgerSMB::Sysconfig::backuppath};
${LedgerSMB::Sysconfig::backuppath} = "foo";
$form->{file} = "${LedgerSMB::Sysconfig::backuppath}/apples.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
is($trap->die, "Error: Not allowed to access foo/ with this method\n",
	'AM, check_template_name: Backup path denial');
${LedgerSMB::Sysconfig::backuppath} = $temp;

$form->{file} = "css/../apples.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
is($trap->die, "Error: Directory transversal not allowed.\n",
	'AM, check_template_name: Directory transversal denial 1');
$form->{file} = "/tmp/apples.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
is($trap->die, "Error: Directory transversal not allowed.\n",
	'AM, check_template_name: Directory transversal denial 2');
$form->{file} = "test/apples.txt:evil";
@r = trap{AM->check_template_name($myconfig, $form)};
is($trap->die, "Error: Directory transversal not allowed.\n",
	'AM, check_template_name: Directory transversal denial 3');
$form->{file} = "c:\\evil.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
is($trap->die, "Error: Directory transversal not allowed.\n",
	'AM, check_template_name: Directory transversal denial 4');

# AM->load_template checks
# load_template takes its file name from form
$form = new Form;
$myconfig = {'templates' => 't/data'};
$form->{file} = 't/data/04-not-there.txt';
@r = trap{AM->load_template($myconfig, $form)};
is($trap->die, "Error: t/data/04-not-there.txt : No such file or directory\n",
	'AM, load_template: Die on non-existent file');
$form->{file} = 't/data/04-template.html';
AM->load_template($myconfig, $form);
is($form->{body}, "I am a template.\nLook at me <?lsmb login ?>.\n",
	'AM, load_template: Read existing file');

# AM->save_template checks
$form = new Form;
$myconfig = {'templates' => 't/var/not here'};
$form->{body} = "I am a template.\nLook at me.\n";
$form->{file} = "$myconfig->{templates}/test.txt";
@r = trap{AM->save_template($myconfig, $form)};
is($trap->die,
	"Error: t/var/not here/test.txt : No such file or directory\n",
	'AM, save_template: Die on unwritable file');
$myconfig = {'templates' => 't/var'};
$form->{body} = "I am a template.\nLook at me.";
$form->{file} = "$myconfig->{templates}/04-template-save-test-$$.txt";
ok(!-e $form->{file}, 'AM, save_template: Environment clean');
AM->save_template($myconfig, $form);
ok(-e $form->{file}, 'AM, save_template: File created');
open($FH, '<', $form->{file});
@r = <$FH>;
close($FH);
chomp(@r);
is(join("\n", @r), $form->{body}, 'AM, save_template: Good save'); 
is(unlink($form->{file}), 1, 'AM, save_template: removing testfile');
ok(!-e $form->{file}, 'AM, save_template: testfile removed');

# LedgerSMB::Template::HTML checks
is(LedgerSMB::Template::HTML::get_template('04-template'), '04-template.html',
	'HTML, get_template: Returned correct template file name');
is(LedgerSMB::Template::HTML::preprocess('04-template'), '04-template',
	'HTML, preprocess: Returned simple string unchanged');
is(LedgerSMB::Template::HTML::preprocess('14 > 12'), '14 &gt; 12',
	'HTML, preprocess: Returned properly escaped string');
is_deeply(LedgerSMB::Template::HTML::preprocess([0, 'apple', 'mango&durian']), 
	[0, 'apple', 'mango&amp;durian'],
	'HTML, preprocess: Returned properly escaped array ref contents');
is_deeply(LedgerSMB::Template::HTML::preprocess({'fruit' => '&veggies', 
		'test' => 1}), 
	{'fruit' => '&amp;veggies', 'test' => 1},
	'HTML, preprocess: Returned properly escaped hash ref contents');
is_deeply(LedgerSMB::Template::HTML::preprocess({'fruit' => '&veggies', 
		'test' => ['nest', 'bird', '0 < 15', 1]}), 
	{'fruit' => '&amp;veggies', 'test' => ['nest', 'bird', '0 &lt; 15', 1]},
	'HTML, preprocess: Returned properly escaped nested contents');
is(LedgerSMB::Template::HTML::postprocess({outputfile => '04-template'}),
	'04-template.html', 'HTML, postprocess: Return output filename');

# Template->new
$myconfig = {'templates' => 't/data'};
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => 'x/0')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 1';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '1\\2')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 2';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '1:2')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 3';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '..')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 4';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '.svn')} 
	qr/Invalid language/,
	'Template, new: Invalid language caught 5';
$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'language' => 'de');
ok(defined $template, 'Template, new: Object creation with valid language');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new: Object creation with valid language');
is($template->{include_path}, 't/data/de;t/data',
	'Template, new: Object creation with valid language has good include_path');
$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'language' => 'de',
	'path' => 't/data');
ok(defined $template,
	'Template, new: Object creation with valid language and path');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new: Object creation with valid language and path');
is($template->{include_path}, 't/data',
	'Template, new: Object creation with valid path overrides language');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => '04-template');
ok(defined $template, 
	'Template, new: Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new: Object creation with format and template');
is($template->{include_path}, 't/data',
	'Template, new: Object creation with format and template');
is($template->render({'login' => 'foo&bar'}), 't/var/04-template-output.html',
	'Template, render: Simple HTML template, default filename');
ok(-e 't/var/04-template-output.html', 'Template, render (HTML): File created');
open($FH, '<', 't/var/04-template-output.html');
@r = <$FH>;
close($FH);
chomp(@r);
is(join("\n", @r), "I am a template.\nLook at me foo&amp;bar.", 
	'Template, render (HTML): Simple HTML template, correct output');
is(unlink('t/var/04-template-output.html'), 1,
	'Template, render: removing testfile');
ok(!-e 't/var/04-template-output.html',
	'Template, render (HTML): testfile removed');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => '04-template', 'locale' => $locale);
ok(defined $template, 
	'Template, new: Object creation with locale');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new: Object creation with locale');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => '04-template-2');
ok(defined $template, 
	'Template, new: Object creation with non-existent template');
throws_ok{$template->render({'login' => 'foo'})} qr/not found/,
	'Template, render: File not found caught';

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'TODO', 
	'template' => '04-template');
ok(defined $template, 
	'Template, new: Object creation with non-existent format');
throws_ok{$template->render({'login' => 'foo'})} qr/Can't locate/,
	'Template, render: Invalid format caught';
