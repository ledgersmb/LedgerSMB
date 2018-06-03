#!perl

use Test::More;

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

SKIP: {
    eval {require LedgerSMB::Template::XLSX} ||
        skip 'LedgerSMB::Template::XLSX not available', 1;
    ok($LedgerSMB::Sysconfig::template_xlsx, 'template_xlsx is true');
}

SKIP: {
    eval {require LedgerSMB::Template::ODS} ||
        skip 'LedgerSMB::Template::ODS not available', 1;
    ok($LedgerSMB::Sysconfig::template_ods, 'template_ods is true');
}

SKIP: {
    eval {require LedgerSMB::Template::LaTeX} ||
        skip 'LedgerSMB::Template::LaTeX not available', 1;
    ok($LedgerSMB::Sysconfig::template_latex, 'template_latex is true');
}

like $ENV{PATH}, '/foo$/', 'appends config path correctly';

for my $script (@LedgerSMB::Sysconfig::scripts) {
    ok(-f '../../old/bin/' . $script, "Whitelisted oldcode script $script exists");
}

for my $script (@LedgerSMB::Sysconfig::newscripts) {
    $script =~ s/\.pl$/.pm/;
    ok(-f '../../lib/LedgerSMB/Scripts/' . $script,
       "Whitelisted script $script exists");
}


done_testing;
