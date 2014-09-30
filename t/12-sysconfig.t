use Test::More tests => 11;

chdir 't/data';

require '../../LedgerSMB/Sysconfig.pm';

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

