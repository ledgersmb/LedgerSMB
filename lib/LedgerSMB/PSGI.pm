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
use LedgerSMB::PSGI::Util;
use LedgerSMB::Router keywords => [ qw( router ) ];
use LedgerSMB::Routes::ERP::API::Accounts;
use LedgerSMB::Routes::ERP::API::Goods;
use LedgerSMB::Routes::ERP::API::MenuNodes;
use LedgerSMB::Routes::ERP::API::Templates;
use LedgerSMB::Setting;
use LedgerSMB::Sysconfig;

use CGI::Emulate::PSGI;
use HTTP::Status qw( HTTP_FOUND );
use Try::Tiny;
use List::Util qw{  none };
use Log::Log4perl;
use Scalar::Util qw{ reftype };

# To build the URL space
use Plack;
use Plack::Builder;
use Plack::Request::WithEncoding;
use Plack::App::File;
use Plack::Middleware::ConditionalGET;
use Plack::Middleware::ReverseProxy;
use Plack::Builder::Conditionals;
use Plack::Util;


# After Perl 5.20 is the minimum required version,
# we can drop the restriction on the match vars
# because 5.20 doesn't copy the data (but uses
# string slices)
use English qw(-no_match_vars);
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

our $psgi_env;

sub old_app {
    my $script = shift;
    my $handler = CGI::Emulate::PSGI->handler(
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
                    unless ( lsmb_legacy->handle($script, $psgi_env) ) { ## no critic (RequireExplicitInclusion)
                        if ($! or $@) {
                            print "Status: 500 Internal server error (PSGI.pm)\n\n";
                            warn "Failed to execute old request ($!): $@\n";
                        }
                    }
                };

                exit;
            }
            return;
        });

    # marshall the psgi environment into the cgi environment
    # so we can re-use state from the various middlewares
    return sub {
        my $env = shift;
        local $psgi_env = $env;

        return $handler->($env);
    }
}


=item psgi_app

Implements a PSGI application for the purpose of calling the entry-points
in LedgerSMB::Scripts::*.

=cut


sub psgi_app {
    my $env = shift;
    my $psgi_req = Plack::Request::WithEncoding->new($env);
    my $request = LedgerSMB->new($psgi_req);

    $request->{action} = $env->{'lsmb.action_name'};
    my $res;
    try {
        LedgerSMB::App_State::run_with_state sub {

            $request->initialize_with_db if $request->{dbh};
            $res = $env->{'lsmb.action'}->($request);
        }, DBH     => $env->{'lsmb.db'};

        $request->{dbh}->commit if defined $request->{dbh};
    }
    catch {
        my $error = $_;

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
    };

    return $res;
}

=item setup_url_space(development => $boolean, coverage => $boolean)

Sets up the URL space for the PSGI app, pointing various URLs at the
appropriate PSGI handlers/apps.

=cut

sub _hook_psgi_logger {
    my ($env, $settings, $router) = @_;
    my $logger_name = $settings->{logger} ? ".$settings->{logger}" : '';
    my $logger = Log::Log4perl->get_logger("LedgerSMB$logger_name");

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
    my %args = @_;
    my $development = $args{development};
    my $psgi_app = \&psgi_app;

    return builder {
        enable match_if addr([qw{ 127.0.0.0/8 ::1 ::ffff:127.0.0.0/108 }]),
            'ReverseProxy';
        enable match_if path(qr!.+\.(css|js|png|ico|jp(e)?g|gif)$!),
            'ConditionalGET';

        enable 'Plack::Middleware::Pod',
             path => qr{^/pod/},
             root => './',
             pod_view => 'Pod::POM::View::HTMl' # the default
                 if $development;

        # not using @LedgerSMB::Sysconfig::scripts: it has not only entry-points
        mount "/$_.pl" => builder {
            my $script = $_;
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog', format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::ClearDownloadCookie';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain          => 'main',
                cookie          => LedgerSMB::Sysconfig::cookie_name,
                duration        => 60*60*24*90,
                # can marshall state in, but not back out (due to forking)
                # so have the inner scope handle serialization itself
                inner_serialize => 1;
            enable '+LedgerSMB::Middleware::Log4perl',
                script          => $script;
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'closed',
                default_company    => LedgerSMB::Sysconfig::default_db(),
                schema             => LedgerSMB::Sysconfig::db_namespace();
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'closed',
                require_version    => $LedgerSMB::VERSION;
            old_app($script)
        }
        for ('aa', 'am', 'ap', 'ar', 'gl', 'ic', 'ir', 'is', 'oe', 'pe');

        mount "/$_" => builder {
            my $script = $_;
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain   => 'main',
                cookie   => LedgerSMB::Sysconfig::cookie_name,
                duration => 60*60*24*90;
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow',
                script   => $script;
            enable '+LedgerSMB::Middleware::Log4perl',
                script   => $script;
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'open',
                default_company => LedgerSMB::Sysconfig::default_db(),
                schema          => LedgerSMB::Sysconfig::db_namespace();
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'open',
                require_version => $LedgerSMB::VERSION;
            enable '+LedgerSMB::Middleware::DisableBackButton';
            enable '+LedgerSMB::Middleware::ClearDownloadCookie';
            $psgi_app;
        }
        for  (grep { $_ !~ m/^(login|setup)[.]pl$/ } @LedgerSMB::Sysconfig::newscripts);

        mount '/login.pl' => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain   => 'main',
                cookie   => LedgerSMB::Sysconfig::cookie_name,
                duration => 60*60*24*90;
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow',
                script   => 'login.pl';
            enable '+LedgerSMB::Middleware::Log4perl',
                script   => 'login.pl';
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'none',
                default_company => LedgerSMB::Sysconfig::default_db(),
                schema          => LedgerSMB::Sysconfig::db_namespace();
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'none',
                require_version => $LedgerSMB::VERSION;
            enable '+LedgerSMB::Middleware::DisableBackButton';
            enable '+LedgerSMB::Middleware::ClearDownloadCookie';
            $psgi_app;
        };

        mount '/erp/api/v0' => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::SessionStorage',
                domain      => 'main',
                cookie      => LedgerSMB::Sysconfig::cookie_name,
                cookie_path => '/',
                duration    => 60*60*24*90;
            enable '+LedgerSMB::Middleware::Authenticate::Company',
                provide_connection => 'open',
                default_company => LedgerSMB::Sysconfig::default_db(),
                schema          => LedgerSMB::Sysconfig::db_namespace();
            enable '+LedgerSMB::Middleware::MainAppConnect',
                provide_connection => 'open',
                require_version => $LedgerSMB::VERSION;
            my $router = router 'erp/api';
            $router->hooks('before' => \&_hook_psgi_logger);
            sub { return $router->dispatch(@_); };
        };

        mount '/setup.pl' => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog',
                format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow',
                script => 'setup.pl';
            enable '+LedgerSMB::Middleware::Log4perl',
                script => 'setup.pl';
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

        if (! $LedgerSMB::Sysconfig::dojo_built) {
            mount '/js/' => Plack::App::File->new(root => 'UI/js-src')->to_app
        }

        mount '/' => Plack::App::File->new( root => 'UI' )->to_app;
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
