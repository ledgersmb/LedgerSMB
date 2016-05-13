package LedgerSMB::PSGI;

=head1 NAME

PSGI wrapper functionality for LedgerSMB

=head1 SYNOPSIS

 use LedgerSMB::PSGI;
 my $app = LedgerSMB::PSGI->get_app();

=cut

use strict;
use warnings;
our $VERSION = '1.5';

# Preloads
use LedgerSMB;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;
use LedgerSMB::Template::HTML;
use LedgerSMB::Locale;
use LedgerSMB::File;
use LedgerSMB::Scripts::login;
use LedgerSMB::PGObject;
use Try::Tiny;

use CGI::Emulate::PSGI;

local $@; # localizes just for initial load.
eval { require LedgerSMB::Template::LaTeX; };
$ENV{GATEWAY_INTERFACE}="cgi/1.1";

sub rest_app {
    return CGI::Emulate::PSGI->handler(
        sub {
            do 'bin/rest-handler.pl';
        });
};

sub old_app {
    return CGI::Emulate::PSGI->handler(
        sub {
            my $uri = $ENV{REQUEST_URI};
            $uri =~ s/\?.*//;
            $ENV{SCRIPT_NAME} = $uri;

            _run_old();
        });
};

sub new_app {
    return CGI::Emulate::PSGI->handler(
        sub {
            my $uri = $ENV{REQUEST_URI};
            $ENV{SCRIPT_NAME} = $uri;
            my $script = $uri;
            $ENV{SCRIPT_NAME} =~ s/\?.*//;
            $script =~ s/.*[\\\/]([^\\\/\?=]+\.pl).*/$1/;

            _run_new($script);
         });
}

sub _run_old {
    if (my $cpid = fork()){
       wait;
    } else {
       do 'bin/old-handler.pl';
       exit;
    }
}

sub _run_new {
    my ($script) = @_;
    if (-f 'bin/lsmb-request.pl'){
        try {
            do 'bin/lsmb-request.pl';
        }
        catch {
            # simple 'die' statements are request terminations
            # so we don't want to cause a 500 ISE to be returned
            die $_
                unless $_ =~ /^Died at/;
        }
    } else {
        die 'something is wrong, cannot find lsmb-request.pl';
    }
}

1;
