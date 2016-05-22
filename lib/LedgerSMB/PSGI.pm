package LedgerSMB::PSGI;

=head1 NAME

LedgerSMB::PSGI - PSGI application routines for LedgerSMB

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

=head1 FUNCTIONS

=over

=item rest_app

Returns a 'PSGI app' which handles GET/POST requests for the RESTful services

=cut

sub rest_app {
    return CGI::Emulate::PSGI->handler(
        sub {
            do 'bin/rest-handler.pl';
        });
};

=item old_app

Returns a 'PSGI app' which handles requests for the 'old-code' scripts in bin/

=cut

sub old_app {
    return CGI::Emulate::PSGI->handler(
        sub {
            my $uri = $ENV{REQUEST_URI};
            $uri =~ s/\?.*//;
            $ENV{SCRIPT_NAME} = $uri;

            _run_old();
        });
};

=item new_app

Returns a 'PSGI app' which handles requests for the 'new code' entry points
in LedgerSMB::Scripts::*

=cut


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
