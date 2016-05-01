#!/usr/bin/plackup 

package LedgerSMB::FCGI;

use CGI::Emulate::PSGI;
use LedgerSMB::PSGI;
use Plack::Builder;
use Plack::Middleware::Static;

die 'Cannot verify version of libraries, may be including out of date modules?' unless $LedgerSMB::PSGI::VERSION == '1.5';


my $app = LedgerSMB::PSGI::app();

builder {
   enable "Plack::Middleware::Static",
       path => qr{(^/?(images|doc|UI|css)/|favicon\.ico)}, root => '.';
   mount '/stop.pl' => sub { exit; }
	if $ENV{COVERAGE};
   mount '/' => $app;
};

