######################################################################
# LedgerSMB Accounting and ERP

# http://www.ledgersmb.org/
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (C) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#######################################################################
#
# this script is the frontend called from old/bin/$terminal/$script
# all the accounting modules are linked to this script which in
# turn execute the same script in old/bin/$terminal/
#
#######################################################################

package lsmb_legacy;

use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::App_State;
use LedgerSMB::Middleware::RequestID;
use LedgerSMB::PSGI::Util;
use LedgerSMB::Sysconfig;

use Cookie::Baker;
use Digest::MD5;
use Log::Log4perl;
use Try::Tiny;

our $logger;


sub handle {
    # WARNING !!
    #
    # This function *must* be called in a forked process
    #
    # because it changes global state without clean-up
    my $class = shift;

    binmode (STDIN, ':utf8');
    binmode (STDOUT, ':utf8');
    binmode STDERR, ':utf8';

    my $params;
    if ($ENV{CONTENT_LENGTH}!= 0) {
        read( STDIN, $params, $ENV{CONTENT_LENGTH} );
    }
    elsif ( $ENV{QUERY_STRING} ) {
        $params = $ENV{QUERY_STRING};
    }

    $form = Form->new($params);
    # name of this script
    $ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
    my $script = $1;
    $script =~ m/(.*)\.pl/;
    my $script_module = $1;

    #make logger available to other old programs
    $logger = Log::Log4perl->get_logger("lsmb.$script_module.$form->{action}");

    local $SIG{__WARN__} = sub {
        my $msg = shift;

        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
        $msg =~ s/\n/\\n/g;
        $logger->warn($msg);
    };


    $locale = LedgerSMB::Locale->get_handle( LedgerSMB::Sysconfig::language() )
        or $form->error( __FILE__ . ':' . __LINE__ .
                         ": Locale not loaded: $!\n" );


    # we use $script for the language module
    $form->{script} = $script;

    # strip .pl for translation files
    $script =~ s/\.pl//;

    # locale messages
    #$form->{charset} = $locale->encoding;
    $form->{charset} = 'UTF-8';
    $locale->encoding('UTF-8');

    try {
        $form->db_init( \%myconfig );
        my $path = LedgerSMB::PSGI::Util::cookie_path($ENV{SCRIPT_NAME});
        if ($form->{_new_session_cookie_value}) {
            my $value = {
                company       => $env->{'lsmb.company'},
                %{$form->{_session}},
            };

            print 'Set-Cookie: '
                . bake_cookie(LedgerSMB::Sysconfig::cookie_name,
                              {
                                  value    => $LedgerSMB::Middleware::AuthenticateSession::store->encode($value),
                                  samesite => 'strict',
                                  httponly => 1,
                                  path     => $path,
                                  secure   => (lc($ENV{HTTPS}) eq 'on'),
                              });
        }

        # we get rid of myconfig and use User as a real object
        %myconfig = %{ LedgerSMB::User->fetch_config( $form ) };
        $LedgerSMB::App_State::User = \%myconfig;
        map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout)
            unless ( $form->{type} eq 'preferences' );

        if ($myconfig{language}){
            $locale   = LedgerSMB::Locale->get_handle( $myconfig{language} )
                or _error($form, __FILE__ . ':' . __LINE__
                          . ": Locale not loaded: $!\n" );
        }

        $form->{_locale} = $locale;
        # pull in the main code
        $logger->trace("requiring old/bin/$form->{script}");
        require "old/bin/$form->{script}";

        if ( $form->{action}
             && $form->{action} ne 'redirect'
             && "lsmb_legacy"->can($form->{action}) ) {
            $logger->trace("action $form->{action}");

            &{ $form->{action} };
            $form->{dbh}->commit;
        }
        else {
            $form->error( __FILE__ . ':' . __LINE__ . ': '
                          . $locale->text('action not defined!'));
        }
    }
    catch  {
        # We have an exception here because otherwise we always get an exception
        # when output terminates.  A mere 'die' will no longer trigger an automatic
        # error, but die 'foo' will map to $form->error('foo')
        # -- CT
        my $err = $_;
        $form->{_error} = 1;
        if ($err =~ /^Died/i or $err =~ /^exit at /) {
            $form->{dbh}->commit if defined $form->{dbh};
        }
        else {
            $form->{dbh}->rollback if defined $form->{dbh};
            _error($form, "'$err'");
        }
    };

    $logger->trace("leaving after script=old/bin/$form->{script} action=$form->{action}");#trace flow

    $form->{dbh}->disconnect() if defined $form->{dbh};
}


sub _error {
    my ($form, $msg, $status) = @_;
    $msg = "? _error" if !defined $msg;
    $status = 500 if ! defined $status;

    print qq|Status: $status ISE
Content-Type: text/html; charset=utf-8

<html>
<body><h2 class="error">Error!</h2> <p><b>$msg</b></p>
<p>dbversion: $form->{dbversion}, company: $form->{company}</p>
</body>
</html>
|;

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $msg =~ s/\n/\\n/g;
    $logger->error($msg);
}


1;
