#!perl

use Test::More;

chdir 't/data';

require '../../LedgerSMB/Sysconfig.pm';


plan tests => (11+scalar(@LedgerSMB::Sysconfig::scripts)
               +scalar(@LedgerSMB::Sysconfig::newscripts));

is $LedgerSMB::Sysconfig::auth, 'DB2', 'Auth set correctly';
is $LedgerSMB::Sysconfig::tempdir, 'test', 'tempdir set correctly';
is $LedgerSMB::Sysconfig::cssdir, 'css3/', 'css dir set correctly';
is $LedgerSMB::Sysconfig::fs_cssdir, 'css4', 'css fs dir set correctly';
is $LedgerSMB::Sysconfig::cache_templates, 5, 'template caching working';
is $LedgerSMB::Sysconfig::language, 'en2', 'language set correctly';
is $LedgerSMB::Sysconfig::check_max_invoices, '52',
   'max invoices set correctly';
is $LedgerSMB::Sysconfig::max_post_size, 4194304333,
   'max post size set correctly';
is $LedgerSMB::Sysconfig::cookie_name, 'LedgerSMB-1.32', 'cookie set correctly';
is $LedgerSMB::Sysconfig::no_db_str, 'database2',
   'missing db string set correctly';

like $ENV{PATH}, '/foo$/', 'appends config path correctly';

for my $script (@LedgerSMB::Sysconfig::scripts) {
    ok(-f '../../bin/' . $script, "Whitelisted oldcode script $script exists");
}

for my $script (@LedgerSMB::Sysconfig::newscripts) {
    $script =~ s/\.pl$/.pm/;
    ok(-f '../../LedgerSMB/Scripts/' . $script,
       "Whitelisted script $script exists");
}
