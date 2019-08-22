#!perl

use Test2::V0;
use Test2::Tools::Spec;
no warnings 'once';

use English qw(-no_match_vars); # required to 'require Sysconfig'


chdir 't/data';

require LedgerSMB::Sysconfig;


is $LedgerSMB::Sysconfig::auth, 'DB2', 'Auth set correctly';
is $LedgerSMB::Sysconfig::cache_templates, 5, 'template caching working';
is $LedgerSMB::Sysconfig::language, 'en2', 'language set correctly';
is $LedgerSMB::Sysconfig::check_max_invoices, '52',
   'max invoices set correctly';
is $LedgerSMB::Sysconfig::max_post_size, 4194304333,
   'max post size set correctly';
is $LedgerSMB::Sysconfig::cookie_name, 'LedgerSMB-1.32', 'cookie set correctly';
ok(!$LedgerSMB::Sysconfig::template_xls, 'template_xls is false');

tests xlsx_detection => sub {
    use Test2::Require::Module 'LedgerSMB::Template::XLSX';

    ok($LedgerSMB::Sysconfig::template_xlsx, 'template_xlsx is true');
};

tests ods_detection => sub {
    use Test2::Require::Module 'LedgerSMB::Template::ODS';

    ok($LedgerSMB::Sysconfig::template_ods, 'template_ods is true');
};

tests latex_detection => sub {
    use Test2::Require::Module 'LedgerSMB::Template::LaTeX';

    ok($LedgerSMB::Sysconfig::template_latex, 'template_latex is true');
};

like $ENV{PATH}, qr/foo$/, 'appends config path correctly';

for my $script (@LedgerSMB::Sysconfig::scripts) {
    ok(-f '../../old/bin/' . $script, "Whitelisted oldcode script $script exists");
}

for my $script (@LedgerSMB::Sysconfig::newscripts) {
    $script =~ s/\.pl$/.pm/;
    ok(-f '../../lib/LedgerSMB/Scripts/' . $script,
       "Whitelisted script $script exists");
}


done_testing;
