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
use LedgerSMB::Legacy_Util;
use LedgerSMB::Template;
use LedgerSMB::Template::Elements;
use LedgerSMB::Template::CSV;
use LedgerSMB::Template::HTML;
use LedgerSMB::Template::TXT;
use LedgerSMB::App_State;
use Log::Log4perl;
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);


my $temp = $LedgerSMB::Sysconfig::tempdir;
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
$template = undef;
$template = LedgerSMB::Template->new(
    'language' => 'de',
    'path'     => 't/data',
    'format'   => 'HTML'
);
ok(defined $template,
        'Template, new: Object creation with valid language and path');
isa_ok($template, 'LedgerSMB::Template',
        'Template, new: Object creation with valid language and path');
is($template->{include_path}, 't/data',
        'Template, new: Object creation with valid path overrides language');

$template = undef;
$template = LedgerSMB::Template->new(
    'format'   => 'HTML',
    'path'     => 't/data',
    'template' => '04-template',
    'locale' => $locale
);
ok(defined $template,
        'Template, new: Object creation with locale');
isa_ok($template, 'LedgerSMB::Template',
        'Template, new: Object creation with locale');

$template = undef;
$template = LedgerSMB::Template->new(
    'format'   => 'HTML',
    'path'     => 't/data',
    'template' => '04-template-2'
);
ok(defined $template,
        'Template, new: Object creation with non-existent template');
throws_ok{$template->render({'login' => 'foo'})} qr/not found/,
        'Template, render: File not found caught';

#####################
## Rendering tests ##
#####################

SKIP: {
    #skip "LATEX_TESTING not set", 7 unless $ENV{LATEX_TESTING};
    $template = undef;
    $template = LedgerSMB::Template->new(
        'format'   => 'PDF',
        'path'     => 't/data',
        'template' => '04-template'
    );
    ok(defined $template,
        'Template, new (PDF): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (PDF): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (PDF): Object creation with format and template');
    isa_ok($template->render({'login' => 'foo&bar'}),
        'LedgerSMB::Template',
        'Template, render (PDF): Simple PDF template, default filename');
    like($template->{output}, qr/^%PDF/, 'Template, render (PDF): output is PDF');

    $template = undef;
    $template = LedgerSMB::Template->new(
        'format'   => 'postscript',
        'path'     => 't/data',
        'template' => '04-template'
    );
    ok(defined $template,
        'Template, new (PS): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (PS): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (PS): Object creation with format and template');
    isa_ok($template->render({'login' => 'foo\&bar'}),
        'LedgerSMB::Template',
        'Template, render (PS): Simple Postscript template, default filename');
    like($template->{output}, qr/^%!PS/, 'Template, render (PS): output is Postscript');

    $template = undef;
    $template = LedgerSMB::Template->new(
        'format'   => 'XLS',
        'path'     => 't/data',
        'template' => '04-template'
    );
    ok(defined $template,
        'Template, new (XLS): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (XLS): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (XLS): Object creation with format and template');
    isa_ok($template->render({'login' => 'foo\&bar'}),
        'LedgerSMB::Template',
        'Template, render (XLS): Simple Postscript template, default filename');
    # xls is a Microsoft BIFF format file.
    # make sure it looks like one by checking the first few header bytes.
    like($template->{output}, qr/^\xD0\xCF\x11\xE0/, 'Template, render (XLS): output is XLS');

    $template = undef;
    $template = LedgerSMB::Template->new(
        'format'   => 'XLSX',
        'path'     => 't/data',
        'template' => '04-template'
    );
    ok(defined $template,
        'Template, new (XLSX): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (XLSX): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (XLSX): Object creation with format and template');
    isa_ok($template->render({'login' => 'foo\&bar'}),
        'LedgerSMB::Template',
        'Template, render (XLSX): Simple Postscript template, default filename');
    # xlsx is actualy a zip file.
    like($template->{output}, qr/^PK/, 'Template, render (XLSX): output is XLSX');

    $template = undef;
    $template = LedgerSMB::Template->new(
        'format'   => 'ODS',
        'path'     => 't/data',
        'template' => '04-template'
    );
    ok(defined $template,
        'Template, new (ODS): Object creation with format and template');
    isa_ok($template, 'LedgerSMB::Template',
        'Template, new (ODS): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (ODS): Object creation with format and template');
    isa_ok($template->render({'login' => 'foo\&bar'}),
        'LedgerSMB::Template',
        'Template, render (ODS): Simple Postscript template, default filename');
    # xlsx is actualy a zip file.
    like($template->{output}, qr/^PK/, 'Template, render (ODS): output is ODS');
}

$template = undef;
$template = LedgerSMB::Template->new(
    'format'   => 'TXT',
    'path'     => 't/data',
    'template' => '04-template'
);
ok(defined $template,
        'Template, new (TXT): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template',
       'Template, new (TXT): Object creation with format and template');
$template->render({'login' => 'foo&bar'});
is($template->{output}, "I am a template.\nLook at me foo&bar.",
        'Template, render (TXT): Simple TXT template, correct output');

$template = undef;
$template = LedgerSMB::Template->new(
    'format'   => 'HTML',
    'path'     => 't/data',
    'template' => '04-template'
);
ok(defined $template,
        'Template, new (HTML): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template',
       'Template, new (HTML): Object creation with format and template');
$template->render({'login' => 'foo&bar'});
is($template->{output}, "I am a template.\nLook at me foo&amp;bar.",
        'Template, render (HTML): Simple HTML template, correct output');

#########################################
## LedgerSMB::Template private methods ##
#########################################

use Math::BigFloat;
$template = undef;
$template = LedgerSMB::Template->new(
    'user'     => {numberformat => '1.000,00'},
    'format'   => 'HTML',
    'template' => '04-template'
);
ok(defined $template,
        'Template, private (preprocess): Object creation with format and template');
isa_ok($template, 'LedgerSMB::Template',
        'Template, private (preprocess): Object creation with format and template');

###################################
## LedgerSMB::Template::Elements ##
###################################

$template = undef;

my $lsmb = LedgerSMB->new();
$locale = LedgerSMB::Locale->get_handle( LedgerSMB::Sysconfig::language() )
  or $lsmb->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );


$template = LedgerSMB::Template->new(
    'user'     => {numberformat => '1.000,00'},
    'format'   => 'HTML',
    'path'     => 't/data',
    'locale'   => $locale,
    'template' => '04-complex_template'
);

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
);

$payment_template->render({ request => { script => '' },
                            payment => $payment });
my @output =  split /\n/, $payment_template->{output};
is(grep(/name="payment_101"/, @output), 0, 'Invoice locked');
is(grep(/Locked by/, @output), 1, 'Invoice locked label shown');


# LPR PRinting Tests
SKIP: {
    #skip 'LATEX_TESTING is not set', 2 unless $ENV{LATEX_TESTING};
    use LedgerSMB::Sysconfig;
    %LedgerSMB::Sysconfig::printer = ('test' => 'cat > t/var/04-lpr-test');

    $template = LedgerSMB::Template->new(
        'format'   => 'PDF',
        'template' => '04-template',
        'locale'   => $locale,
        'path'     => 't/data',
    );
    LedgerSMB::Legacy_Util::render_template(
        $template,
        {},
        'test',
    );

    my $LPR_TEST;
    ok(open ($LPR_TEST, '<', "t/var/04-lpr-test"), 'LedgerSMB::Template::_output_lpr output file opened successfully');

    my $line1 = <$LPR_TEST>;

    like($line1, qr/^%PDF/, 'output file is pdf');
}
