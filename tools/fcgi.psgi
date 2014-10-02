#!/usr/bin/plackup -s FCGI 

package LedgerSMB::FCGI;

use CGI::Emulate::PSGI;
use FCGI::ProcManager;
use FindBin;
use LedgerSMB::PSGI;

BEGIN {
  lib->import($FindBin::Bin) unless $ENV{mod_perl}
}

# Process Manager
my $proc_manager = FCGI::ProcManager->new({ n_processes => 10 });
LedgerSMB::PSGI::post_dispatch(sub {$proc_manager->pm_pre_dispatch()});
LedgerSMB::PSGI::post_dispatch(sub {$proc_manager->pm_post_dispatch()});


my $app = LedgerSMB::PSGI::app();

