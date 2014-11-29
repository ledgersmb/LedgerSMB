package LedgerSMB::PSGI;

=head1 NAME

PSGI wrapper functionality for LedgerSMB

=head1 SYNOPSIS

 use LedgerSMB::PSGI;
 my $app = LedgerSMB::PSGI->get_app();

=cut
 
# Preloads
use LedgerSMB;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;
use LedgerSMB::Template::HTML;
use LedgerSMB::Locale;
use LedgerSMB::File;
use LedgerSMB::PGObject;
use Try::Tiny;

use CGI::Emulate::PSGI;

sub app {
   return CGI::Emulate::PSGI->handler(
     sub {
       my $uri = $ENV{REQUEST_URI};
       $ENV{SCRIPT_NAME} = $uri;
       my $script = $uri;
       $ENV{SCRIPT_NAME} =~ s/\?.*//; 
       $script =~ s/.*[\\\/]([^\\\/\?=]+\.pl).*/$1/;

       my $nscript = $script;
       $nscript =~ s/l$/m/;
       if ($uri =~ m|/rest/|){
         do 'rest-handler.pl';
       } elsif (-f "LedgerSMB/Scripts/$nscript"){
         do 'lsmb-request.pl'; 
       } else {
          _run_old($script);
       }
    }
  );
}

my $pre_dispatch = undef;
sub pre_dispatch {
    $pre_dispatch = shift;
}

my $post_dispatch = undef;
sub post_dispatch {
    $pre_dispatch = shift;
}

sub _run_old {
    if (my $cpid = fork()){
       wait;
    } else {
       &$pre_dispatch() if $pre_dispatch;
       do 'old-handler.pl';
       &$post_dispatch() if $post_dispatch;
       exit;
    }
}

sub _run_new {
    my ($script) = @_;
    &$pre_dispatch();
    $uri = $ENV{REQUEST_URI};
    $uri =~ s/\?.*//;

    do "./$script";
    &$post_dispatch();
}

1;
