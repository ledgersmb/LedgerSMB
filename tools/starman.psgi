#!/usr/bin/plackup 

package LedgerSMB::FCGI;

use CGI::Emulate::PSGI;
use LedgerSMB::PSGI;
use Plack::Builder;
use Plack::Middleware::Static;


my $app = LedgerSMB::PSGI::app();

builder {
   enable "Plack::Middleware::Static",
       path => qr{(^/?(images|doc|UI|css)/|favicon\.ico)}, root => '.';
   mount '/stop.pl' => sub { exit; }
	if $ENV{COVERAGE};
   mount '/' => $app;
};

