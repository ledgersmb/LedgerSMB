#!/usr/bin/perl

use strict;
use warnings;

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


my $temp = $LedgerSMB::Sysconfig::tempdir;
my $form;
my $myconfig;
my $template;
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

###############################################
## LedgerSMB::Template::preprocess checks ##
###############################################

for my $value ([], {}) {
    my $rv = LedgerSMB::Template::preprocess($value, sub { return shift; });
    is(ref $rv, ref $value,
       "return value type equals input value type");
}


######################################
## LedgerSMB::Template::HTML checks ##
######################################

my $escape = LedgerSMB::Template::HTML->can('escape');
is(LedgerSMB::Template::preprocess('04-template', $escape), '04-template',
        'HTML, preprocess: Returned simple string unchanged');
is(LedgerSMB::Template::preprocess('14 > 12', $escape), '14 &gt; 12',
        'HTML, preprocess: Returned properly escaped string');
is_deeply(LedgerSMB::Template::preprocess([0, 'apple', 'mango&durian'],
                                          $escape),
        [0, 'apple', 'mango&amp;durian'],
        'HTML, preprocess: Returned properly escaped array ref contents');
is_deeply(LedgerSMB::Template::preprocess({'fruit' => '&veggies',
                'test' => 1}, $escape),
        {'fruit' => '&amp;veggies', 'test' => 1},
        'HTML, preprocess: Returned properly escaped hash ref contents');
is_deeply(LedgerSMB::Template::preprocess({'fruit' => '&veggies',
                'test' => ['nest', 'bird', '0 < 15', 1]}, $escape),
        {'fruit' => '&amp;veggies', 'test' => ['nest', 'bird', '0 &lt; 15', 1]},
        'HTML, preprocess: Returned properly escaped nested contents');

####################
## Template tests ##
####################

# Template->new
$myconfig = {'templates' => 't/data'};
$template = undef;
$template = LedgerSMB::Template->new('user' => $myconfig, 'language' => 'de',
        'path' => 't/data', 'format' => 'HTML');
ok(defined $template,
        'Template, new: Object creation with valid language and path');
isa_ok($template, 'LedgerSMB::Template',
        'Template, new: Object creation with valid language and path');
is($template->{include_path}, 't/data',
        'Template, new: Object creation with valid path overrides language');

$template = undef;
$template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'HTML',
        path => 't/data', 'template' => '04-template', 'locale' => $locale);
ok(defined $template,
        'Template, new: Object creation with locale');
isa_ok($template, 'LedgerSMB::Template',
        'Template, new: Object creation with locale');

$template = undef;
$template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'HTML',
        path => 't/data', 'template' => '04-template-2');
ok(defined $template,
        'Template, new: Object creation with non-existent template');
throws_ok{$template->render({'login' => 'foo'})} qr/not found/,
        'Template, render: File not found caught';

#####################
## Rendering tests ##
#####################

SKIP: {
    skip "LATEX_TESTING not set", 7 unless $ENV{LATEX_TESTING};
    $template = undef;
    $template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'PDF',
        path => 't/data', 'template' => '04-template');
    ok(defined $template,
        'Template, new (PDF): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (PDF): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (PDF): Object creation with format and template');
    is($template->render({'login' => 'foo&bar'}),
        "$temp/04-template-output-$$.pdf",
        'Template, render (PDF): Simple PDF template, default filename');
    ok(-e "$temp/04-template-output-$$.pdf",
        'Template, render (PDF): File created');
    is(unlink("$temp/04-template-output-$$.pdf"), 1,
        'Template, render (PDF): removing testfile');
    ok(!-e "$temp/04-template-output-$$.pdf",
        'Template, render (PDF): testfile removed');

    $template = undef;
    $template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'PS',
        path => 't/data', 'template' => '04-template');
    ok(defined $template,
        'Template, new (PS): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (PS): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (PS): Object creation with format and template');
    is($template->render({'login' => 'foo\&bar'}),
        "$temp/04-template-output-$$.ps",
        'Template, render (PS): Simple Postscript template, default filename');
    ok(-e "$temp/04-template-output-$$.ps", 'Template, render (PS): File created');
    is(unlink("$temp/04-template-output-$$.ps"), 1,
        'Template, render (PS): removing testfile');
    ok(!-e "$temp/04-template-output-$$.ps",
        'Template, render (PS): testfile removed');

    $template = undef;
    $template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'XLS',
        path => 't/data', 'template' => '04-template');
    ok(defined $template,
        'Template, new (XLS): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (XLS): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (XLS): Object creation with format and template');
    is($template->render({'login' => 'foo\&bar'}),
        "$temp/04-template-output-$$.xls",
        'Template, render (XLS): Simple Postscript template, default filename');
    ok(-e "$temp/04-template-output-$$.xls", 'Template, render (XLS): File created');
    is(unlink("$temp/04-template-output-$$.xls"), 1,
        'Template, render (XLS): removing testfile');
    ok(!-e "$temp/04-template-output-$$.xls",
        'Template, render (XLS): testfile removed');

    $template = undef;
    $template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'XLSX',
        path => 't/data', 'template' => '04-template');
    ok(defined $template,
        'Template, new (XLSX): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (XLSX): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (XLSX): Object creation with format and template');
    is($template->render({'login' => 'foo\&bar'}),
        "$temp/04-template-output-$$.xlsx",
        'Template, render (XLSX): Simple Postscript template, default filename');
    ok(-e "$temp/04-template-output-$$.xlsx", 'Template, render (XLSX): File created');
    is(unlink("$temp/04-template-output-$$.xlsx"), 1,
        'Template, render (XLSX): removing testfile');
    ok(!-e "$temp/04-template-output-$$.xlsx",
        'Template, render (XLSX): testfile removed');

}

$template = undef;
$template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'TXT',
        path => 't/data', 'template' => '04-template');
ok(defined $template,
        'Template, new (TXT): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template',
       'Template, new (TXT): Object creation with format and template');
$template->render;
is($template->{output}, "I am a template.\nLook at me foo&bar.",
        'Template, render (TXT): Simple TXT template, correct output');

$template = undef;
$template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'HTML',
        path => 't/data', 'template' => '04-template');
ok(defined $template,
        'Template, new (HTML): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template',
       'Template, new (HTML): Object creation with format and template');
$template->render;
is($template->{output}, "I am a template.\nLook at me foo&amp;bar.",
        'Template, render (HTML): Simple HTML template, correct output');

#########################################
## LedgerSMB::Template private methods ##
#########################################

use Math::BigFloat;
$template = undef;
$template = LedgerSMB::Template->new('user' => {numberformat => '1.000,00'},
        'format' => 'HTML', 'template' => '04-template');
ok(defined $template,
        'Template, private (preprocess): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template',
        'Template, private (preprocess): Object creation with format and template');
my $number = Math::BigFloat->new(17.5);
isa_ok($number, 'Math::BigFloat',
        'Template, private (preprocess): number');
## Commending out the one below because it is not valid when Math::BigInt::GMP is loaded
# $template->_preprocess($number);
## Commenting out these tests since currently the functionality is known broken
## and unused
#cmp_ok($number, 'eq', '17,50',
#       'Template, private (_preprocess): Math::BigFloat conversion');
#$number = [Math::BigFloat->new(1008.51), 'hello'];
#$template->_preprocess($number);
#
#cmp_ok($number->[0], 'eq', '1.008,51',
#       'Template, private (_preprocess): Math::BigFloat conversion (array)');
#cmp_ok($number->[1], 'eq', 'hello',
#       'Template, private (_preprocess): no conversion (array)');

###################################
## LedgerSMB::Template::Elements ##
###################################

$template = undef;
$form = undef;

my $lsmb = LedgerSMB->new();
$locale = LedgerSMB::Locale->get_handle( LedgerSMB::Sysconfig::language() )
  or $lsmb->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );


$template = LedgerSMB::Template->new('user' => {numberformat => '1.000,00'},
        'format' => 'HTML', path => 't/data', locale => $locale, 'template' => '04-complex_template');

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
);

$payment_template->render({ request => { script => '' },
                            payment => $payment });
my @output =  split /\n/, $payment_template->{output};
is(grep(/name="payment_101"/, @output), 0, 'Invoice locked');
is(grep(/Locked by/, @output), 1, 'Invoice locked label shown');


# LPR PRinting Tests
SKIP: {
    skip 'LATEX_TESTING is not set', 2 unless $ENV{LATEX_TESTING};
    use LedgerSMB::Sysconfig;
    %LedgerSMB::Sysconfig::printer = ('test' => 'cat > t/var/04-lpr-test');

    $template = LedgerSMB::Template->new('user' => $myconfig, 'format' => 'PDF',
        'template' => '04-template', 'locale' => $locale, no_auto_output => 1);
    $template->render({media => 'test'});
    $template->output(media => 'test');
    my $LPR_TEST;
    ok(open ($LPR_TEST, '<', "$temp/04-lpr-test"), 'LedgerSMB::Template::_output_lpr output file opened successfully');

    my $line1 = <$LPR_TEST>;

    like($line1, qr/^%PDF/, 'output file is pdf');
}
