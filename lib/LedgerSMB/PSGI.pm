package LedgerSMB::PSGI;

=head1 NAME

LedgerSMB::PSGI - PSGI application routines for LedgerSMB

=head1 DESCRIPTION

Maps the URL name space to the various entry points.

=head1 SYNOPSIS

 use LedgerSMB::PSGI;
 my $app = LedgerSMB::PSGI->get_app();

=head1 METHODS

This module doesn't specify any (public) methods.

=cut

use strict;
use warnings;

use LedgerSMB;
use LedgerSMB::App_State;
use LedgerSMB::oldHandler;
use LedgerSMB::Magic qw( SCRIPT_NEWSCRIPTS );
use LedgerSMB::PSGI::Util;
use LedgerSMB::Router keywords => [ qw( router ) ];
use LedgerSMB::Routes::ERP::API::Accounts;
use LedgerSMB::Routes::ERP::API::Contacts;
use LedgerSMB::Routes::ERP::API::Countries;
use LedgerSMB::Routes::ERP::API::Goods;
use LedgerSMB::Routes::ERP::API::GeneralLedger;
use LedgerSMB::Routes::ERP::API::Invoices;
use LedgerSMB::Routes::ERP::API::MenuNodes;
use LedgerSMB::Routes::ERP::API::Languages;
use LedgerSMB::Routes::ERP::API::Orders;
use LedgerSMB::Routes::ERP::API::Products;
use LedgerSMB::Routes::ERP::API::Session;
use LedgerSMB::Routes::ERP::API::Templates;
use LedgerSMB::Setting;

use CGI::Emulate::PSGI;
use HTTP::Status qw( HTTP_FOUND );
use List::Util qw{  none };
use Log::Any;
use Log::Log4perl;
use Scalar::Util qw{ reftype };
use String::Random;
use Feature::Compat::Try;

# To build the URL space
use Plack;
use Plack::Builder;
use Plack::Request::WithEncoding;
use Plack::App::File;
use Plack::Middleware::ConditionalGET;
use Plack::Middleware::ReverseProxy;
use Plack::Builder::Conditionals;
use Plack::Util;


use English;
if ($EUID == 0) {
    die join("\n",
        'Running a Web Service as root is a security problem.',
        'If you are starting LedgerSMB as a system service,',
        'please make sure that you drop privileges as per README.md',
        'and the example files in doc/conf/.',
        'The method of passing a --user argument to starman cannot',
        'be used as starman drops privileges too late, starting us as root.'
    );
}

local $@ = undef; # localizes just for initial load.
eval { require LedgerSMB::Template::LaTeX; };

=head1 FUNCTIONS

=over

=item old_app

Returns a 'PSGI app' which handles requests for the 'old-code' scripts in old/bin/

=cut

sub old_app {
    my $script = shift;
    my $wire = shift;

    # marshall the psgi environment into the cgi environment
    # so we can re-use state from the various middlewares
    return sub {
        my $env = shift;

        return Plack::Util::response_cb(
            CGI::Emulate::PSGI->handler(
                sub {
                    local $ENV{CONTENT_LENGTH} = $ENV{CONTENT_LENGTH} // 0;

                    if (my $cpid = fork()){
                        waitpid $cpid, 0;
                    } else {
                        # make 100% sure any "die"-s don't bubble up higher than
                        # this point in the stack: we're a fork()ed process and
                        # should under no circumstance end up acting like another
                        # worker. When we are done, we need to exit() below.
                        try {
                            local ($!, $@) = (undef, undef);
                            # the lsmb_legacy package is created by the
                            # oldHandler use statement
                            unless ( lsmb_legacy->handle($script, $env, $wire) ) { ## no critic (RequireExplicitInclusion)
                                if ($! or $@) {
                                    print "Status: 500 Internal server error (PSGI.pm)\n\n";
                                    warn "Failed to execute old request ($!): $@\n";
                                }
                            }
                        }
                        catch ($e) {
                        }
                        exit;
                    }
                    return;
                }
            )->($env),
            sub {
                Plack::Util::header_set($_[0]->[1],
                                        'Content-Security-Policy',
                                        q{frame-ancestors 'self'});
                if (not Plack::Util::header_exists($_[0]->[1],
                                                   'X-LedgerSMB-App-Content')) {
                    Plack::Util::header_push($_[0]->[1],
                                             'X-LedgerSMB-App-Content', 'yes');
                }
            });
    }
}


=item psgi_app

Implements a PSGI application for the purpose of calling the entry-points
in LedgerSMB::Scripts::*.

=cut


sub psgi_app {
    my $wire = shift;

    return sub {
        my $env = shift;
        my $psgi_req = Plack::Request::WithEncoding->new($env);
        my $request = LedgerSMB->new($psgi_req, $wire);

        $request->{__action} = $env->{'lsmb.action_name'};
        my $res;
        try {
            LedgerSMB::App_State::run_with_state sub {

                $request->initialize_with_db if $request->{dbh};
                $res = $env->{'lsmb.action'}->($request);
            }, DBH     => $env->{'lsmb.db'};

            $request->{dbh}->commit if defined $request->{dbh};
        }
        catch ($error) {
            # Explicitly roll back, because middleware may require the
            # database connection to be in a working state (e.g. DisableBackbutton)
            $request->{dbh}->rollback
                if $request->{dbh};
            if ($error !~ /^Died at/) {
                $env->{'psgix.logger'}->({
                    level => 'error',
                    message => $error });
                $res = LedgerSMB::PSGI::Util::internal_server_error(
                    $error,
                    'Error!',
                    $request->{company},
                    $request->{dbversion},
                    );
            }
            else {
                $res = [ '500', [ 'Content-Type' => 'text/plain' ], [ $error ]];
            }
        }

        return Plack::Util::response_cb(
            $res,
            sub {
                my $res = shift;
                Plack::Util::header_set($res->[1],
                                        'Content-Security-Policy',
                                        q{frame-ancestors 'self'});
            });
    };
}

=item setup_url_space(development => $boolean, coverage => $boolean)

Sets up the URL space for the PSGI app, pointing various URLs at the
appropriate PSGI handlers/apps.

=cut

sub _hook_psgi_logger {
    my ($env, $settings, $router) = @_;
    my $logger_name = $settings->{logger} ? ".$settings->{logger}" : '';
    my $logger = Log::Any->get_logger(category => "LedgerSMB$logger_name");

    $env->{'psgix.logger'} = sub {
        my ($level, $msg) = @{$_[0]}{qw/ level message /};

        return if not defined $msg;

        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
        $logger->$level( ($msg =~ s/\n/\\n/gr) );
        return;
    };

    return;
}

sub setup_url_space {
    my %args        = @_;
    my $wire        = $args{wire};
    my $psgi_app    = psgi_app($wire);

    my $cookie      = $wire->get( 'cookie' )->{name} // 'LedgerSMB';
    my $secret      = $wire->get( 'cookie' )->{secret} //
        String::Random->new->randpattern('.' x 50);

    return builder {
        if (my $proxy_ip = eval { $wire->get( 'miscellaneous/proxy_ip' ); }) {
            enable match_if addr([ split / /, $proxy_ip ]), 'ReverseProxy';
        }
        enable match_if path(qr!.+\.(css|js|png|ico|jp(e)?g|gif)$!),
            'ConditionalGET';

        # not using LedgerSMB::Magic::SCRIPT_OLDSCRIPTS:
        #   it has more than only entry-points
        mount "/$_.pl" => builder {
            my $script = $_;
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog', format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain          => 'main',
                cookie          => $cookie,
                duration        => 60*60*24*90,
                secret          => $secret,
                # can marshall state in, but not back out (due to forking)
                # so have the inner scope handle serialization itself
                inner_serialize => 1;
            enable '+LedgerSMB::Middleware::Log4perl',
                script          => $script;
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'closed',
                factory            => $wire->get( 'db' );
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'closed',
                require_version    => $LedgerSMB::VERSION;
            old_app($script, $wire)
        }
        for ('aa', 'am', 'ap', 'ar', 'gl', 'ic', 'ir', 'is', 'oe', 'pe');

        mount "/$_" => builder {
            my $script = $_;
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain   => 'main',
                cookie   => $cookie,
                secret   => $secret,
                duration => 60*60*24*90;
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow',
                max_post_size => $wire->get( 'miscellaneous/max_upload_size' ),
                script   => $script;
            enable '+LedgerSMB::Middleware::Log4perl',
                script   => $script;
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'open',
                factory         => $wire->get( 'db' );
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'open',
                require_version => $LedgerSMB::VERSION;
            enable '+LedgerSMB::Middleware::DisableBackButton';
            $psgi_app;
        }
        for  (grep { $_ !~ m/^(log(in|out)|setup)[.]pl$/ }
              (SCRIPT_NEWSCRIPTS)->@*);

        mount '/login.pl' => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain   => 'main',
                cookie   => $cookie,
                secret   => $secret,
                duration => 60*60*24*90,
                force_create => 'yes';
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow',
                max_post_size => $wire->get( 'miscellaneous/max_upload_size' ),
                script   => 'login.pl';
            enable '+LedgerSMB::Middleware::Log4perl',
                script   => 'login.pl';
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'none',
                factory         => $wire->get( 'db' );
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'none',
                require_version => $LedgerSMB::VERSION;
            enable '+LedgerSMB::Middleware::DisableBackButton';
            $psgi_app;
        };

        mount '/logout.pl' => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain   => 'main',
                cookie   => $cookie,
                secret   => $secret,
                duration => 60*60*24*90;
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow',
                max_post_size => $wire->get( 'miscellaneous/max_upload_size' ),
                script   => 'logout.pl';
            enable '+LedgerSMB::Middleware::Log4perl',
                script   => 'login.pl';
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'none',
                factory         => $wire->get( 'db' );
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'none',
                require_version => $LedgerSMB::VERSION;
            enable '+LedgerSMB::Middleware::DisableBackButton';
            $psgi_app;
        };

        mount '/erp/api/v0' => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain      => 'main',
                cookie      => $cookie,
                cookie_path => '/',
                secret      => $secret,
                duration    => 60*60*24*90;
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'open',
                factory         => $wire->get( 'db' );
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'open',
                require_version => $LedgerSMB::VERSION;

            my $router = router 'erp/api';
            $router->hooks('before' => \&_hook_psgi_logger);
            $router->hooks(
                'before' => sub {
                    my ($env) = @_;

                    $env->{wire} = $wire;
                    return;
                });
            sub { return $router->dispatch(@_); };
        };

        mount '/setup.pl' => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow',
                max_post_size => $wire->get( 'miscellaneous/max_upload_size' ),
                script => 'setup.pl';
            enable '+LedgerSMB::Middleware::Log4perl',
                script => 'setup.pl';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain      => 'setup',
                cookie      => "$cookie~setup",
                cookie_path => '/',
                secret      => $secret,
                duration    => 60*60*24*90;
            enable '+LedgerSMB::Middleware::SetupAuthentication';
            enable '+LedgerSMB::Middleware::DisableBackButton';
            $psgi_app;
        };

        enable sub {
            my $app = shift;

            return sub {
                my $env = shift;

                return [ HTTP_FOUND,
                         [ Location => 'login.pl' ],
                         [ '' ] ]
                             if $env->{PATH_INFO} eq '/';

                return $app->($env);
            }
        };

        mount '/' => Plack::App::File->new( root => $wire->get('paths/UI') )->to_app;
    };

}




=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
