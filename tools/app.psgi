#!/usr/bin/plackup

  my $path = "/usr/local/ledgersmb_trunk";

  use Plack::App::CGIBin;
  use Plack::Builder;
  use LedgerSMB;
  use LedgerSMB::Form;
  use Moose;
  use CGI::Simple;
  $CGI::Simple::DISABLE_UPLOADS = 0;
  use LedgerSMB::PGNumber;
  use LedgerSMB::PGDate;
  use Data::Dumper;
  use LedgerSMB::Auth;
  use LedgerSMB::Session;
  use LedgerSMB::Template;
  use LedgerSMB::Locale;
  use LedgerSMB::User;
  use LedgerSMB::Locale;
  use Try::Tiny;
  use Devel::Trace;
  use Plack::Middleware::Static;
  use Log::Log4perl;

  my $app = Plack::App::CGIBin->new(root => "$path")->to_app;
  builder {
       enable "Plack::Middleware::Static",
        path => qr!ledgersmb_trunk/(css|images|favicon|UI)/!,
        root => "../";
      mount '/ledgersmb_trunk' => $app;
  }
