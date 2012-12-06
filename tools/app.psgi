#!/usr/bin/plackup -s FCGI ledgersmb.fcgi

package LedgerSMB::FCGI;

use CGI::Emulate::PSGI;
use FCGI::ProcManager;
use FindBin;
# Preloads
use LedgerSMB;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;
use LedgerSMB::Template::LaTeX;
use LedgerSMB::Template::HTML;
use LedgerSMB::Locale;
use LedgerSMB::DBObject;
use LedgerSMB::File;

BEGIN {
  lib->import($FindBin::Bin) unless $ENV{mod_perl}
}

# Process Manager
my $proc_manager = FCGI::ProcManager->new({ n_processes => 10 });


my $app = CGI::Emulate::PSGI->handler(
   sub {
       if (my $cpid = fork()){
          wait
       } else {
          $proc_manager->pm_pre_dispatch();
          $uri = $ENV{REQUEST_URI};
          $uri =~ s/\?.*//;
          $ENV{SCRIPT_NAME} = $uri;
          $ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;

          my $script = $1;
          warn $script;
          do "./$script";
          $proc_manager->pm_post_dispatch();
       }
   }
);

