#!/usr/bin/perl

use strict;
use warnings;

# Absolute directory name required to not trip up Template::Latex
$ENV{TMPDIR} = "$ENV{PWD}/t/var";
$ENV{LANG} = 'LANG=en_US.UTF8';

$ENV{REQUEST_METHOD} = 'GET';
     # Suppress warnings from LedgerSMB::_process_cookies


use Test::More 'no_plan';
use Test::Trap qw(trap $trap);
use Test::Exception;

use LedgerSMB::AM;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Locale;
use LedgerSMB::Template;
use LedgerSMB::Template::Elements;
use LedgerSMB::Template::CSV;
use LedgerSMB::Template::HTML;
use LedgerSMB::Template::TXT;
use LedgerSMB::App_State;
use Log::Log4perl;
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);



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
if ( defined $ENV{PERL5OPT}
     && ($ENV{PERL5OPT}=~/.*?Devel::SimpleTrace.*/ ||
         $ENV{PERL5OPT}=~/.*?Carp::Always.*/ ))
{
   $expStackTrace = 1;
}


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
    skip "LATEX_TESTING not set", 7 unless $ENV{LATEX_TESTING};
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
	'template' => \ 'Look at me <?lsmb login ?>.', 'no_auto_output' => 1);
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
	"I am a foo&amp;bar.\nLook at me Juin.\njuni\nTo foo&amp;bar",
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

$payment_template->render({ request => { script => '' },
                            payment => $payment });
my @output =  get_output_line_array($payment_template);
#cmp_ok(grep(/101<\/td>/, @output), '>', 0, 'Invoice row exists');
is(grep(/name="payment_101"/, @output), 0, 'Invoice locked');
is(grep(/Locked by/, @output), 1, 'Invoice locked label shown');


# LPR PRinting Tests
SKIP: {
    skip 'LATEX_TESTING is not set', 2 unless $ENV{LATEX_TESTING};
    use LedgerSMB::Sysconfig;
    %LedgerSMB::Sysconfig::printer = ('test' => 'cat > t/var/04-lpr-test');

    $template = new LedgerSMB::Template('user' => $myconfig, 'format' => 'PDF',
	'template' => '04-template', 'locale' => $locale, no_auto_output => 1);
    $template->render({media => 'test'});
    $template->output(media => 'test');

    ok (open (LPR_TEST, '<', 't/var/04-lpr-test'), 'LedgerSMB::Template::_output_lpr output file opened successfully');

    my $line1 = <LPR_TEST>;

    like($line1, qr/^%PDF/, 'output file is pdf');
}
# Functions
sub get_output_line_array {
        my $FH;
        my ($template) = @_;
        open($FH, '<:bytes', $template->{rendered}) or
                die 'Unable to open rendered file';
        my @lines = <$FH>;
        close $FH;
        unlink $template->{rendered};
        return @lines;
}

