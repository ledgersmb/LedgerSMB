#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;

use Beam::Wire;
use File::Temp;

use LedgerSMB;
use LedgerSMB::Locale;
use LedgerSMB::Legacy_Util;
use LedgerSMB::Template;
use LedgerSMB::Template::Plugin::HTML;
use Plack::Request;

use Log::Log4perl qw(:easy);

my $wire = Beam::Wire->new(file => 't/ledgersmb.yaml');
LedgerSMB::Locale->initialize($wire);
Log::Log4perl->easy_init($OFF);


my $template;
my $locale;
my $plugin = LedgerSMB::Template::Plugin::HTML->new;

$locale = LedgerSMB::Locale->get_handle('fr');

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

my $escape = sub { $plugin->escape(@_) };
is(LedgerSMB::Template::preprocess('04-template', $escape), '04-template',
        'HTML, preprocess: Returned simple string unchanged');
is(LedgerSMB::Template::preprocess('14 > 12', $escape), '14 &gt; 12',
        'HTML, preprocess: Returned properly escaped string');
is(LedgerSMB::Template::preprocess([0, 'apple', 'mango&durian'], $escape),
   [0, 'apple', 'mango&amp;durian'],
   'HTML, preprocess: Returned properly escaped array ref contents');
is(LedgerSMB::Template::preprocess({'fruit' => '&veggies', 'test' => 1}, $escape),
   {'fruit' => '&amp;veggies', 'test' => 1},
   'HTML, preprocess: Returned properly escaped hash ref contents');
is(LedgerSMB::Template::preprocess({'fruit' => '&veggies',
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
    'format_plugin' => $plugin
);
ok(defined $template,
        'Template, new: Object creation with valid language and path');
isa_ok($template, ['LedgerSMB::Template'],
        'Template, new: Object creation with valid language and path');
is($template->{include_path}, 't/data',
        'Template, new: Object creation with valid path overrides language');

$template = undef;
$template = LedgerSMB::Template->new(
    'path'     => 't/data',
    'template' => '04-template',
    'locale' => $locale,
    'format_plugin'   => $plugin
);
ok(defined $template,
        'Template, new: Object creation with locale');
isa_ok($template, ['LedgerSMB::Template'],
        'Template, new: Object creation with locale');

$template = undef;
$template = LedgerSMB::Template->new(
    'path'     => 't/data',
    'template' => '04-template-2',
    'format_plugin'   => $plugin
);
ok(defined $template,
        'Template, new: Object creation with non-existent template');
like( dies {$template->render({'login' => 'foo'})},
      qr/not found/,
      'Template, render: File not found caught');

##############################
## Rendering tests -- LaTeX ##
##############################

SKIP: {
    eval {require Template::Plugin::Latex} ||
        skip 'Template::Plugin::Latex not installed', 12;
    eval {require Template::Latex} ||
        skip 'Template::Latex not installed', 12;
    eval { require LedgerSMB::Template::Plugin::LaTeX } or
        skip q{Can't require LedgerSMB::Template::Plugin::LaTeX}, 12;

    $template = undef;
    my $p = LedgerSMB::Template::Plugin::LaTeX->new( format => 'PDF' );
    $template = LedgerSMB::Template->new(
        'path'     => 't/data',
        'template' => '04-template',
        'format_plugin'   => $p
    );
    ok(defined $template,
        'Template, new (PDF): Object creation with format and template');
    isa_ok($template, ['LedgerSMB::Template'],
        'Template, new (PDF): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (PDF): Object creation with format and template');
    isa_ok($template->render({'login' => 'foo&bar'}),
        ['LedgerSMB::Template'],
        'Template, render (PDF): Simple PDF template, default filename');
    like($template->{output}, qr/^%PDF/, 'Template, render (PDF): output is PDF');
    is(
        $template->{mimetype},
        'application/pdf',
        'Template, render (PDF): correct mimetype'
    );

    $template = undef;
    $p = LedgerSMB::Template::Plugin::LaTeX->new( format => 'PS' );
    $template = LedgerSMB::Template->new(
        'path'     => 't/data',
        'template' => '04-template',
        'format_plugin'   => $p
    );
    ok(defined $template,
        'Template, new (PS): Object creation with format and template');
    isa_ok($template, ['LedgerSMB::Template'],
        'Template, new (PS): Object creation with format and template');
    is($template->{include_path}, 't/data',
        'Template, new (PS): Object creation with format and template');
    isa_ok($template->render({'login' => 'foo\&bar'}),
        ['LedgerSMB::Template'],
        'Template, render (PS): Simple Postscript template, default filename');
    like($template->{output}, qr/^%!PS/, 'Template, render (PS): output is Postscript');
    is($template->{mimetype}, 'application/postscript', 'Template, render (PS): correct mimetype');
}


###############################
## Rendering tests -- XLS(X) ##
###############################

SKIP: {
    eval {require Excel::Writer::XLSX} ||
        skip 'Excel::Writer::XLSX not installed', 12;
    eval {require Spreadsheet::WriteExcel} ||
        skip 'Spreadsheet::WriteExcel not installed', 12;
    eval { require LedgerSMB::Template::Plugin::XLSX } or
        skip q{Can't require LedgerSMB::Template::Plugin::XLSX}, 12;

    $template = undef;
    my $p = LedgerSMB::Template::Plugin::XLSX->new( format => 'XLS' );
    $template = LedgerSMB::Template->new(
        'path'     => 'templates/demo',
        'template' => 'display_report',
        'format_plugin'   => $p
    );
    ok(defined $template,
        'Template, new (XLS): Object creation with format and template');
    isa_ok($template, ['LedgerSMB::Template'],
        'Template, new (XLS): Object creation with format and template');
    is($template->{include_path}, 'templates/demo',
        'Template, new (XLS): Object creation with format and template');
    isa_ok($template->render({'name' => 'foo&bar',
                              'rows' => [],
                              'columns' => [] }),
        ['LedgerSMB::Template'],
        'Template, render (XLS): Simple XLS template, default filename');
    # xls is a Microsoft BIFF format file.
    # make sure it looks like one by checking the first few header bytes.
    like($template->{output}, qr/^\xD0\xCF\x11\xE0/, 'Template, render (XLS): output is XLS');
    is(
        $template->{mimetype},
        'application/vnd.ms-excel',
        'Template, render (XLS): correct mimetype'
    );

    $template = undef;
    $p = LedgerSMB::Template::Plugin::XLSX->new( format => 'XLSX' );
    $template = LedgerSMB::Template->new(
        'path'     => 'templates/demo',
        'template' => 'display_report',
        'format_plugin'   => $p
    );
    ok(defined $template,
        'Template, new (XLSX): Object creation with format and template');
    isa_ok($template, ['LedgerSMB::Template'],
        'Template, new (XLSX): Object creation with format and template');
    is($template->{include_path}, 'templates/demo',
        'Template, new (XLSX): Object creation with format and template');
    isa_ok($template->render({'name' => 'foo&bar',
                              'rows' => [],
                              'columns' => []}),
        ['LedgerSMB::Template'],
        'Template, render (XLSX): Simple XLSX template, default filename');
    # xlsx is actualy a zip file.
    like($template->{output}, qr/^PK/, 'Template, render (XLSX): output is XLSX');
    is(
        $template->{mimetype},
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Template, render (XLSX): correct mimetype'
    );
}

############################
## Rendering tests -- ODS ##
############################

SKIP: {
    eval {require XML::Twig } ||
        skip 'XML::Twig not installed', 5;
    eval {require OpenOffice::OODoc} ||
        skip 'OpenOffice::OODoc not installed', 5;
    eval { require LedgerSMB::Template::Plugin::ODS } or
        skip q{Can't require LedgerSMB::Template::Plugin::ODS}, 12;

    $template = undef;
    my $p = LedgerSMB::Template::Plugin::ODS->new( format => 'ODS' );
    $template = LedgerSMB::Template->new(
        'path'     => 'templates/demo',
        'template' => 'display_report',
        'format_plugin'   => $p
    );
    ok(defined $template,
        'Template, new (ODS): Object creation with format and template');
    isa_ok($template, ['LedgerSMB::Template'],
        'Template, new (ODS): Object creation with format and template');
    is($template->{include_path}, 'templates/demo',
        'Template, new (ODS): Object creation with format and template');
    isa_ok($template->render({'name' => 'foo&bar', rows => [], columns => []}),
        ['LedgerSMB::Template'],
        'Template, render (ODS): Simple ODS template, default filename');
    # ods is actualy a zip file.
    like($template->{output}, qr/^PK/, 'Template, render (ODS): output is ODS');
    is(
        $template->{mimetype},
        'application/vnd.oasis.opendocument.spreadsheet',
        'Template, render (ODS): correct mimetype'
    );
}


############################
## Rendering tests -- TXT ##
############################

$template = undef;
ok(require LedgerSMB::Template::Plugin::TXT);
$plugin = LedgerSMB::Template::Plugin::TXT->new;
$template = LedgerSMB::Template->new(
    'path'     => 't/data',
    'template' => '04-template',
    'format_plugin'   => $plugin
);
ok(defined $template,
        'Template, new (TXT): Object creation with format and template');
isa_ok($template, ['LedgerSMB::Template'],
       'Template, new (TXT): Object creation with format and template');
$template->render({'login' => 'foo&bar'});
is($template->{output}, "I am a template.\nLook at me foo&bar.",
        'Template, render (TXT): Simple TXT template, correct output');
is($template->{mimetype}, 'text/plain', 'Template, new (HTML): correct mimetype');


############################
## Rendering tests -- CSV ##
############################

$template = undef;
ok(require LedgerSMB::Template::Plugin::CSV);
$plugin = LedgerSMB::Template::Plugin::CSV->new;
$template = LedgerSMB::Template->new(
    'path'     => 't/data',
    'template' => '04-template',
    'format_plugin'   => $plugin
);
ok(defined $template,
        'Template, new (CSV): Object creation with format and template');
isa_ok($template, ['LedgerSMB::Template'],
       'Template, new (CSV): Object creation with format and template');
$template->render({'login' => 'foo&bar'});
is($template->{output}, "account,amount,description,project",
        'Template, render (CSV): Simple TXT template, correct output');
is($template->{mimetype}, 'text/csv', 'Template, new (CSV): correct mimetype');


#############################
## Rendering tests -- HTML ##
#############################

$template = undef;
$plugin = LedgerSMB::Template::Plugin::HTML->new;
$template = LedgerSMB::Template->new(
    'path'     => 't/data',
    'template' => '04-template',
    'format_plugin'   => $plugin
);
ok(defined $template,
        'Template, new (HTML): Object creation with format and template');
isa_ok($template, ['LedgerSMB::Template'],
       'Template, new (HTML): Object creation with format and template');
$template->render({'login' => 'foo&bar'});
is($template->{output}, "I am a template.\nLook at me foo&amp;bar.",
        'Template, render (HTML): Simple HTML template, correct output');
is($template->{mimetype}, 'text/html', 'Template, new (HTML): correct mimetype');


#################################
## Rendering tests -- External ##
#################################

ok(require LedgerSMB::Template::Plugin::External);

$template = undef;
$plugin   = LedgerSMB::Template::Plugin::External->new(
    command   => 'utils/test/template-renderer %d %f %o',
    mime_type => 'application/binary',
    format    => 'bin',
    formats   => [ 'bin', 'null' ],
    input_extension => 'html'
);
$template = LedgerSMB::Template->new(
    'path'          => 't/data',
    'template'      => '04-template',
    'format_plugin' => $plugin
);
ok(defined $template);
isa_ok($template, ['LedgerSMB::Template']);
$template->render({'login' => 'foo&bar'});
is($template->{output}, "I am a template.\nLook at me foo&bar.\n");
is($template->{mimetype}, 'application/binary');


#########################################
## LedgerSMB::Template private methods ##
#########################################

use Math::BigFloat;
$template = undef;
$template = LedgerSMB::Template->new(
    'user'     => {numberformat => '1.000,00'},
    'template' => '04-template',
    'format_plugin'   => $plugin # HTML
);
ok(defined $template,
        'Template, private (preprocess): Object creation with format and template');
isa_ok($template, ['LedgerSMB::Template'],
        'Template, private (preprocess): Object creation with format and template');




# LPR Printing Tests
SKIP: {
    eval {require Template::Plugin::Latex} ||
        skip 'Template::Plugin::Latex not installed', 2;
    eval {require Template::Latex} ||
        skip 'Template::Latex not installed', 2;
    eval { require LedgerSMB::Template::Plugin::LaTeX } or
        skip q{Can't require LedgerSMB::Template::Plugin::LaTeX}, 12;

    my $temp = File::Temp->new();
    my $wire = Beam::Wire->new(
        config => {
            printers => {
                class => 'LedgerSMB::Printers',
                args => {
                    printers => {
                        test => "cat > $temp"
                    }
                },
            }
        } );
    my $p = LedgerSMB::Template::Plugin::LaTeX->new( format => 'PDF' );
    $template = LedgerSMB::Template->new(
        'template' => '04-template',
        'locale'   => $locale,
        'path'     => 't/data',
        'format_plugin'   => $p,
        );
    $template->render({});
    LedgerSMB::Legacy_Util::output_template(
        $template,
        { _wire => $wire }, # $form
        method => 'test',
    );

    my $LPR_TEST;
    ok(open ($LPR_TEST, '<', $temp), 'LedgerSMB::Template::_output_lpr output file opened successfully');
    like(<$LPR_TEST>, qr/^%PDF/, 'output file is pdf');
}


done_testing;
