#!perl

use Test2::V0;
use Test2::Tools::Spec;
no warnings 'once';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

use LedgerSMB::Sysconfig;
use LedgerSMB::Magic qw( SCRIPT_NEWSCRIPTS SCRIPT_OLDSCRIPTS );

LedgerSMB::Sysconfig->initialize( 't/data/ledgersmb.conf' );

is LedgerSMB::Sysconfig::language(), 'en2', 'language set correctly';

like $ENV{PATH}, qr/foo$/, 'appends config path correctly';

for my $script (SCRIPT_OLDSCRIPTS->@*) {
    ok(-f 'old/bin/' . $script, "Whitelisted oldcode script $script exists");
}

for my $script (SCRIPT_NEWSCRIPTS->@*) {
    $script =~ s/\.pl$/.pm/;
    ok(-f 'lib/LedgerSMB/Scripts/' . $script,
       "Whitelisted script $script exists");
}


done_testing;
