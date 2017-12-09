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

use English qw(-no_match_vars);
if ($EUID == 0) {
    die join("\n",
        'Running a Web Service as root is a security problem',
        'If you are starting LedgerSMB as a system service',
        'please make sure that you drop privlidges as per README.md',
        'and the example files in conf/',
        'This makes it difficult to run on a privlidged port (<1024)',
        'In theory you can pass the --user argument to starman,',
        'However starman drops privlidges too late, starting us as root.'
        );
}


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
            local ($!, $@);
            my $do_ = 'bin/rest-handler.pl';
            unless ( do $do_ ) {
                if ($! or $@) {
                    print "Status: 500 Internal server error (PSGI.pm (rest_app))\n\n";
                    warn "Failed to execute $do_ ($!): $@\n";
                }
            }
        }
    );
}

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
}


=item new_app

Returns a 'PSGI app' which handles requests for the 'new code' entry points
in LedgerSMB::Scripts::*

=cut


sub new_app {
   return CGI::Emulate::PSGI->handler(
        sub {
           my $uri = $ENV{REQUEST_URI};
           local $ENV{SCRIPT_NAME} = $uri;
           my $script = $uri;
           $ENV{SCRIPT_NAME} =~ s/\?.*//;
           $script =~ s/.*[\\\/]([^\\\/\?=]+\.pl).*/$1/;

           _run_new($script);
       });
}

sub _run_old {
    if (my $cpid = fork()){
       waitpid $cpid, 0;
    } else {
        # We need a 'try' block here to prevent errors being thrown in
        # the inner block from escaping out of the block and missing
        # the 'exit' below.
        try {
            local ($!, $@);
            my $do_ = 'bin/old-handler.pl';
            unless ( do $do_ ) {
                if ($! or $@) {
                    print "Status: 500 Internal server error (PSGI.pm)\n\n";
                    warn "Failed to execute $do_ ($!): $@\n";
                }
            }
        };
        exit;
    }
}

sub _run_new {
    my ($script) = @_;
    if (-f 'bin/lsmb-request.pl'){ ###FIXME: we probably don't need to explicitly test for the file to exist here as the wrapper around do $do_ will handle it for us
        try {
            local ($!, $@);
            my $do_ = 'bin/lsmb-request.pl';
            unless ( do $do_ ) {
                if ($! or $@) {
                    print "Status: 500 Internal server error (PSGI.pm run_new)\n\n";
                    warn "Failed to execute $do_ ($!): $@\n";
                }
            }
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

=back

=cut

1;
