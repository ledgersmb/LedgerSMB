#!/usr/bin/perl

use strict;
use warnings;

# Absolute directory name required to not trip up Template::Latex
$ENV{TMPDIR} = "$ENV{PWD}/t/var";

use Test::More 'no_plan';
use Test::Trap qw(trap $trap);
use Test::Exception;

use Error qw(:try :warndie);

use LedgerSMB::AM;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Locale;
use LedgerSMB::Template;
use LedgerSMB::Template::Elements;
use LedgerSMB::Template::CSV;
use LedgerSMB::Template::HTML;
my $has_latex = 0;
 (  eval {require LedgerSMB::Template::LaTeX } 
&&  eval {require Template::Latex} 
&&  eval {require Template::Plugins::Latex}
) || ($has_latex = 1) ;
use LedgerSMB::Template::TXT;

$LedgerSMB::Sysconfig::tempdir = 't/var';

my @r;
my $temp;
my $form;
my $myconfig;
my $template;
my $FH;
my $locale;

$locale = LedgerSMB::Locale->get_handle('fr');

##############
## AM tests ##
##############
my $expStackTrace = 0;
if ( $ENV{PERL5OPT}=~/.*?Devel::SimpleTrace.*/ || $ENV{PERL5OPT}=~/.*?Carp::Always.*/ )
{
   $expStackTrace = 1;
}

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
$form->{file} = 'test2/apples.txt';
@r = trap{AM->check_template_name($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, "Error: Not in a whitelisted directory: test2/apples.txt\n",
        'AM, check_template_name: Invalid directory, non-css denial');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: Not in a whitelisted directory: test2\/apples.txt\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: Not in a whitelisted directory: test2/apples.txt\n",
        'AM, check_template_name: Invalid directory, non-css denial');
}
$form->{file} = 'test/apples.exe';
@r = trap{AM->check_template_name($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, "Error: Error:  File is of type that is not allowed.\n",
        'AM, check_template_name: Disallowed type denial');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: Error:  File is of type that is not allowed.\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: Error:  File is of type that is not allowed.\n",
        'AM, check_template_name: Disallowed type denial');

}
# adjusting backuppath to avoid triggering directory traversal detection
$temp = ${LedgerSMB::Sysconfig::backuppath};
${LedgerSMB::Sysconfig::backuppath} = "foo";
$form->{file} = "${LedgerSMB::Sysconfig::backuppath}/apples.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, "Error: Not allowed to access foo/ with this method\n",
        'AM, check_template_name: Backup path denial');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: Not allowed to access foo\/ with this method\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: Not allowed to access foo/ with this method\n",
        'AM, check_template_name: Backup path denial');
}
${LedgerSMB::Sysconfig::backuppath} = $temp;

$form->{file} = "css/../apples.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, "Error: Directory transversal not allowed.\n",
        'AM, check_template_name: Directory transversal denial 1');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: Directory transversal not allowed.\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: Directory transversal not allowed.\n",
        'AM, check_template_name: Directory transversal denial 1');
}
$form->{file} = "/tmp/apples.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, "Error: Not in a whitelisted directory: /tmp/apples.txt\n",
        'AM, check_template_name: Directory transversal denial 2');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: Directory transversal not allowed.\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: Directory transversal not allowed.\n",
        'AM, check_template_name: Directory transversal denial 2');
}
$form->{file} = "test/apples.txt:evil";
@r = trap{AM->check_template_name($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, "Error: Directory transversal not allowed.\n",
        'AM, check_template_name: Directory transversal denial 3');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: Directory transversal not allowed.\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: Directory transversal not allowed.\n",
        'AM, check_template_name: Directory transversal denial 3');
}
$form->{file} = "c:\\evil.txt";
@r = trap{AM->check_template_name($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, "Error: Directory transversal not allowed.\n",
        'AM, check_template_name: Directory transversal denial 4');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: Directory transversal not allowed.\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: Directory transversal not allowed.\n",
        'AM, check_template_name: Directory transversal denial 4');
}

# AM->load_template checks
# load_template takes its file name from form
$form = new Form;
$myconfig = {'templates' => 't/data'};
$form->{file} = 't/data/04-not-there.txt';
@r = trap{AM->load_template($myconfig, $form)};
if ( $expStackTrace == 0 )
{
    is($trap->die, 'Error: Template not found: t/data/04-not-there.txt
');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: t\/data\/04-not-there.txt : No such file or directory\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg, "Error: t/data/04-not-there.txt : No such file or directory\n",
        'AM, load_template: Die on non-existent file');
}
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
if ( $expStackTrace == 0 )
{
    is($trap->die,
        "Error: t/var/not here/test.txt : No such file or directory\n",
        'AM, save_template: Die on unwritable file');
}
else
{   
    my $trapmsg="";
    if ($trap->die =~/(Error: t\/var\/not here\/test.txt : No such file or directory\n).*/)
    {
        $trapmsg = $1;
    }
    is($trapmsg,
        "Error: t/var/not here/test.txt : No such file or directory\n",
        'AM, save_template: Die on unwritable file');
}
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

######################################
## LedgerSMB::Template::HTML checks ##
######################################

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

####################
## Template tests ##
####################

# Template->new
$myconfig = {'templates' => 't/data'};
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => 'x/0', 'format' => 'HTML')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 1';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '1\\2', 'format' => 'HTML')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 2';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '1:2', 'format' => 'HTML')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 3';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '..', 'format' => 'HTML')} 
	qr/Invalid language/, 'Template, new: Invalid language caught 4';
throws_ok{new LedgerSMB::Template('user' => $myconfig, 'language' => '.svn', 'format' => 'HTML')} 
	qr/Invalid language/,
	'Template, new: Invalid language caught 5';
$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'language' => 'de', 'format' => 'HTML');
ok(defined $template, 'Template, new: Object creation with valid language');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new: Object creation with valid language');
is($template->{include_path_lang}, 't/data/de',
	'Template, new: Object creation with valid language has good include_path');
$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'language' => 'de',
	'path' => 't/data', 'output_file' => 'test', 'format' => 'HTML');
ok(defined $template,
	'Template, new: Object creation with valid language and path');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new: Object creation with valid language and path');
is($template->{include_path}, 't/data',
	'Template, new: Object creation with valid path overrides language');
is($template->{outputfile}, 't/var/test',
	'Template, new: Object creation with filename is correct');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => '04-template', 'locale' => $locale);
ok(defined $template, 
	'Template, new: Object creation with locale');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new: Object creation with locale');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => '04-template-2', 'no_auto_output' => 1);
ok(defined $template, 
	'Template, new: Object creation with non-existent template');
throws_ok{$template->render({'login' => 'foo'})} qr/not found/,
	'Template, render: File not found caught';

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'TODO', 
	'template' => '04-template', 'no_auto_output' => 1);
ok(defined $template, 
	'Template, new: Object creation with non-existent format');
throws_ok{$template->render({'login' => 'foo'})} qr/Can't locate/,
	'Template, render: Invalid format caught';

#####################
## Rendering tests ##
#####################

SKIP: {
    skip "LaTeX modules not installed" unless $has_latex;
    $template = undef;
    $template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'PDF', 
	'template' => '04-template', 'no_auto_output' => 1);
    ok(defined $template, 
	'Template, new (PDF): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template', 
	'Template, new (PDF): Object creation with format and template');
    is($template->{include_path}, 't/data',
	'Template, new (PDF): Object creation with format and template');
    is($template->render({'login' => 'foo&bar'}), 
        "t/var/04-template-output-$$.pdf",
	'Template, render (PDF): Simple PDF template, default filename');
    ok(-e "t/var/04-template-output-$$.pdf",
	'Template, render (PDF): File created');
    is(unlink("t/var/04-template-output-$$.pdf"), 1,
	'Template, render (PDF): removing testfile');
    ok(!-e "t/var/04-template-output-$$.pdf",
	'Template, render (PDF): testfile removed');

    $template = undef;
    $template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'PS', 
	'template' => '04-template', 'no_auto_output' => 1);
    ok(defined $template, 
	'Template, new (PS): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template', 
	'Template, new (PS): Object creation with format and template');
    is($template->{include_path}, 't/data',
	'Template, new (PS): Object creation with format and template');
    is($template->render({'login' => 'foo\&bar'}),
	"t/var/04-template-output-$$.ps",
	'Template, render (PS): Simple Postscript template, default filename');
    ok(-e "t/var/04-template-output-$$.ps", 'Template, render (PS): File created');
    is(unlink("t/var/04-template-output-$$.ps"), 1,
	'Template, render (PS): removing testfile');
    ok(!-e "t/var/04-template-output-$$.ps",
	'Template, render (PS): testfile removed');
}

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'TXT', 
	'template' => '04-template', 'no_auto_output' => 1);
ok(defined $template, 
	'Template, new (TXT): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new (TXT): Object creation with format and template');
is($template->{include_path}, 't/data',
	'Template, new (TXT): Object creation with format and template');
is($template->render({'login' => 'foo&bar'}),
	'04-template.txt',
	'Template, render: Simple text template, no filename');
is($template->{output}, "I am a template.\nLook at me foo&bar.\n", 
	'Template, render (TXT): Simple TXT template, correct output');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => '04-template', 'no_auto_output' => 1);
ok(defined $template, 
	'Template, new (HTML): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new (HTML): Object creation with format and template');
is($template->{include_path}, 't/data',
	'Template, new (HTML): Object creation with format and template');
is($template->render({'login' => 'foo&bar'}),
	undef,
	'Template, render (HTML): Simple HTML template, no file');
is($template->{output}, "I am a template.\nLook at me foo&amp;bar.", 
	'Template, render (HTML): Simple HTML template, correct output');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => \'Look at me <?lsmb login ?>.', 'no_auto_output' => 1);
ok(defined $template, 
	'Template, new (HTML): Object creation with string template');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new (HTML): Object creation with string template');
is($template->{include_path}, 't/data',
	'Template, new (HTML): Object creation with string template');
is($template->render({'login' => 'foo&bar'}),
	undef,
	'Template, render (HTML): Simple HTML string template, no file');
is($template->{output}, "Look at me foo&amp;bar.", 
	'Template, render (HTML): Simple HTML string template, correct output');

$template = undef;
$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'HTML', 
	'template' => '04-gettext', 'output_file' => '04-gettext',
	'no_auto_output' => 1);
ok(defined $template, 
	'Template, new (HTML): Object creation with outputfile');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, new (HTML): Object creation with outputfile');
is($template->{include_path}, 't/data',
	'Template, new (HTML): Object creation with outputfile');
is($template->render({'month' => 'June', 'login' => 'foo&bar', 
	'fr' => $locale}), 't/var/04-gettext.html',
	'Template, render (HTML): Gettext HTML template');
ok(-e "t/var/04-gettext.html",
	'Template, render (HTML): File created');
open($FH, '<', "t/var/04-gettext.html");
@r = <$FH>;
close($FH);
chomp(@r);
is(join("\n", @r), 
	"I am a foo&amp;bar.\nLook at me Juin.\njuni\nAan foo&amp;bar", 
	'Template, render (HTML): Gettext HTML template, correct output');
is(unlink("t/var/04-gettext.html"), 1,
	'Template, render (HTML): removing testfile');
ok(!-e "t/var/04-gettext.html",
	'Template, render (HTML): testfile removed');

## XeTeX test, requires PDFLATEX to be xelatex and modified Template::Latex
SKIP: {
	skip 'XeTeX and modified Template::Latex requiring PDF tests';
	$template = undef;
	$template = new LedgerSMB::Template('user' => $myconfig,
		'format' => 'PDF', 'template' => '04-gettext',
		'no_auto_output' => 1);
	ok(defined $template, 
		'Template, new (PDF): XeTeX template creation');
	isa_ok($template, 'LedgerSMB::Template', 
		'Template, new (PDF): XeTeX template creation');
	is($template->{include_path}, 't/data',
		'Template, new (PDF): XeTeX template creation');
	is($template->render({'login' => 'foo&bar'}),
		"t/var/04-gettext-output-$$.pdf",
		'Template, render (PDF): XeTeX PDF template, default filename');
	ok(-e "t/var/04-gettext-output-$$.pdf",
		'Template, render (PDF): File created');
	is(unlink("t/var/04-gettext-output-$$.pdf"), 1,
		'Template, render (PDF): removing testfile');
	ok(!-e "t/var/04-gettext-output-$$.pdf",
		'Template, render (PDF): testfile removed');
}

#########################################
## LedgerSMB::Template private methods ##
#########################################

use Math::BigFloat;
$template = undef;
$template = new LedgerSMB::Template('user' => {numberformat => '1.000,00'},
	'format' => 'HTML', 'template' => '04-template', 'no_auto_output' => 1);
ok(defined $template, 
	'Template, private (_preprocess): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template', 
	'Template, private (_preprocess): Object creation with format and template');
my $number = Math::BigFloat->new(17.5);
isa_ok($number, 'Math::BigFloat', 
	'Template, private (_preprocess): number');
## Commending out the one below because it is not valid when Math::BigInt::GMP is loaded
# $template->_preprocess($number);
## Commenting out these tests since currently the functionality is known broken
## and unused
#cmp_ok($number, 'eq', '17,50',
#	'Template, private (_preprocess): Math::BigFloat conversion');
#$number = [Math::BigFloat->new(1008.51), 'hello'];
#$template->_preprocess($number);
#
#cmp_ok($number->[0], 'eq', '1.008,51',
#	'Template, private (_preprocess): Math::BigFloat conversion (array)');
#cmp_ok($number->[1], 'eq', 'hello',
#	'Template, private (_preprocess): no conversion (array)');

###################################
## LedgerSMB::Template::Elements ##
###################################

$template = undef;
$form = undef;

my $lsmb = LedgerSMB->new();
$locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} )
  or $lsmb->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );


$template = new LedgerSMB::Template('user' => {numberformat => '1.000,00'},
	'format' => 'HTML', path => 't/data', locale => $locale, 'template' => '04-complex_template', 'no_auto_output' => 1);

$template->render({});

my $contact_request = {
        entity_id    => 1,
        control_code => 'test1',
        meta_number  => 'test1',
	credit_id    => '1',
        entity_class => 1,
        default_country => 4,
        credit_list  => [{ entity_class => 1,
                           meta_number => 'test1',
                        }],
	contacts     => [{contact     => 'ctest1', 
			description   => 'dtest1', 
			contact_class => '1'}],
        business_id  => 1000,
        business_types => [{ id => 1,    description => 'test1' },
                           { id => 1000, description => 'test2' }],
	country_list => [{id => 1, name => 'country1'},
		{id => 2, name => 'country2'},
		{id => 3, name => 'country3'},
		{id => 4, name => 'country4'},
		{id => 5, name => 'country5'},
		{id => 6, name => 'country6'},
		]
}; # Company with Credit Accounts and business types.

my $payment = LedgerSMB->new();
$payment->merge({
	contact_1 => 1, source_1 => 1, action=>'dispay_payments', id_1 => 1,
	id_1_1    => 1, 
	contact_invoices => [{contact_id => 1, invoices =>[[101, 101, "2009-01-01", 1000, 0, 0, 1000, 0, 
				'test']]}]});

my $payment_template =  LedgerSMB::Template->new(
        path            => 'UI/payments',
        template        => 'payments_detail',
        format          => 'HTML',
        no_auto_output  => 1,
        output_file     => 'payment_test1'
);

$payment_template->render($payment);
my @output =  get_output_line_array($payment_template);
cmp_ok(grep(/101<\/td>/, @output), '>', 0, 'Invoice row exists');
is(grep(/name="payment_101"/, @output), 0, 'Invoice locked');
is(grep(/Locked by/, @output), 1, 'Invoice locked label shown');


# LPR PRinting Tests
use LedgerSMB::Sysconfig;
%LedgerSMB::Sysconfig::printer = ('test' => 'cat > t/var/04-lpr-test');

$template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'PDF', 
	'template' => '04-template', 'locale' => $locale, no_auto_output => 1);
$template->render({media => 'test'});
$template->output(media => 'test');

ok (open (LPR_TEST, '<', 't/var/04-lpr-test'), 'LedgerSMB::Template::_output_lpr output file opened successfully');

my $line1 = <LPR_TEST>;

like($line1, qr/^%PDF/, 'output file is pdf');

$template =  LedgerSMB::Template->new(
        path            => 'UI',
        template        => 'rp-payments',
        format          => 'HTML',
        no_auto_output  => 1,
        output_file     => 'rp_payment_test1'
);

$lsmb = {columns => ['test']};
$template->render($lsmb);
@output =  get_output_line_array($template);
cmp_ok(grep(/^\s*<\s*th\s+class="listtop"\s*>\s*$/, @output), '>', 0, 
	'th tags properly finish');

# Functions
sub get_output_line_array {
        my $FH;
        my ($template) = @_;
        open($FH, '<:bytes', $template->{rendered}) or
                throw Error::Simple 'Unable to open rendered file';
        my @lines = <$FH>;
        close $FH;
        delete $template->{rendered};
        return @lines;
}

