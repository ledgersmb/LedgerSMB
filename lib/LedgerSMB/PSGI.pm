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
use LedgerSMB::Auth;
use LedgerSMB::PSGI::Util;
use LedgerSMB::Setting;
use LedgerSMB::Sysconfig;

use CGI::Emulate::PSGI;
use HTTP::Status qw( HTTP_FOUND );
use Try::Tiny;
use List::Util qw{  none };
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

sub old_app {
    return CGI::Emulate::PSGI->handler(
        sub {
            my $uri = $ENV{REQUEST_URI};
            $uri =~ s/\?.*//;
            local $ENV{SCRIPT_NAME} = $uri;

            _run_old();
        });
}


=item psgi_app

Implements a PSGI application for the purpose of calling the entry-points
in LedgerSMB::Scripts::*.

=cut


sub psgi_app {
    my $env = shift;

    my $auth = LedgerSMB::Auth::factory($env);

    my $psgi_req = Plack::Request::WithEncoding->new($env);
    my $request = LedgerSMB->new(
        $psgi_req->parameters, $env->{'lsmb.script'}, $env->{QUERY_STRING},
        $psgi_req->uploads, $psgi_req->cookies, $auth, $env->{'lsmb.db'},
        $env->{'lsmb.company'},
        $env->{'lsmb.session_id'}, $env->{'lsmb.create_session_cb'},
        $env->{'lsmb.invalidate_session_cb'});

    $request->{action} = $env->{'lsmb.action_name'};
    my $res;
    try {
        LedgerSMB::App_State::run_with_state sub {
            if ($env->{'lsmb.want_db'} && !$env->{'lsmb.dbonly'}) {
                $request->initialize_with_db();
            }
            else {
                # Some default settings as we run without a user
                $request->{_user} = {
                    dateformat => LedgerSMB::Sysconfig::date_format(),
                };
            }

            $res = $env->{'lsmb.action'}->($request);

            if (ref $res && ref $res eq 'LedgerSMB::Template') {
                # We got an evaluated template instead of a PSGI triplet...
                $res = LedgerSMB::PSGI::Util::template_to_psgi($res);
            }
        }, DBH     => $env->{'lsmb.db'},
           DBName  => $env->{'lsmb.company'},
           Locale  => $request->{_locale};

        $request->{dbh}->commit if defined $request->{dbh};
    }
    catch {
        # The database setup middleware will roll back before disconnecting
        my $error = $_;
        if ($error !~ /^Died at/) {
            $env->{'psgix.logger'}->({
                level => 'error',
                message => $_ });
            $res = LedgerSMB::PSGI::Util::internal_server_error(
                $_, 'Error!',
                $request->{dbversion}, $request->{company});
        }
    };

    return $res;
}

sub _run_old {
    if (my $cpid = fork()){
       waitpid $cpid, 0;
    } else {
        # make 100% sure any "die"-s don't bubble up higher than this point in
        # the stack: we're a fork()ed process and should under no circumstance
        # end up acting like another worker. When we are done, we need to
        # exit() below.
        try {
            local ($!, $@) = (undef, undef);
            my $do_ = 'old/bin/old-handler.pl';
            unless ( do $do_ ) {
                if ($! or $@) {
                    print "Status: 500 Internal server error (PSGI.pm)\n\n";
                    warn "Failed to execute $do_ ($!): $@\n";
                }
            }
        };

        exit;
    }
    return;
}

=item setup_url_space(development => $boolean, coverage => $boolean)

Sets up the URL space for the PSGI app, pointing various URLs at the
appropriate PSGI handlers/apps.

=cut

sub setup_url_space {
    my %args = @_;
    my $coverage = $args{coverage};
    my $development = $args{development};
    my $old_app = old_app();
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
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog', format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            $old_app
        }
        for ('aa', 'am', 'ap', 'ar', 'gl', 'ic', 'ir', 'is', 'oe', 'pe');

        mount "/$_" => builder {
            enable '+LedgerSMB::Middleware::RequestID';
            enable 'AccessLog', format => 'Req:%{Request-Id}i %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
            enable '+LedgerSMB::Middleware::DynamicLoadWorkflow';
            enable '+LedgerSMB::Middleware::Log4perl';
            enable '+LedgerSMB::Middleware::AuthenticateSession';
            enable '+LedgerSMB::Middleware::DisableBackButton';
            enable '+LedgerSMB::Middleware::ClearDownloadCookie';
            $psgi_app;
        }
        for  (@LedgerSMB::Sysconfig::newscripts);

        mount '/stop.pl' => sub { exit; }
            if $coverage;

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

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
