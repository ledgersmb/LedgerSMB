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

use experimental 'try';

package lsmb_legacy;

use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::App_State;
use LedgerSMB::Middleware::SessionStorage;
use LedgerSMB::Middleware::RequestID;
use LedgerSMB::PSGI::Util;

use HTML::Escape;
use Log::Any;

our $logger;


sub handle {
    # WARNING !!
    #
    # This function *must* be called in a forked process
    #
    # because it changes global state without clean-up
    #
    #
    # Note that this function can receive a PSGI environment, but
    # modifications aren't marshalled back to the fork()ing process!
    my ($class, $script_module, $psgi_env, $wire) = @_;
    my $script = $script_module . '.pl';


    binmode(STDIN,  ':utf8');
    binmode(STDOUT, ':utf8');
    binmode(STDERR, ':utf8');

    my $params;
    if ($ENV{CONTENT_LENGTH}!= 0) {
        read( STDIN, $params, $ENV{CONTENT_LENGTH} );
    }
    elsif ( $ENV{QUERY_STRING} ) {
        $params = $ENV{QUERY_STRING};
    }

    $form = Form->new($params);
    my $session = $psgi_env->{'lsmb.session'};
    $form->{_session} = $session;
    $form->{_wire} = $wire;
    @{$form}{qw/ session_id company /} =
        @{$session}{qw/ session_id company /};

    #make logger available to other old programs
    $logger = Log::Any->get_logger(category => "lsmb.$script_module.$form->{__action}");

    local $SIG{__WARN__} = sub {
        my $msg = shift;

        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
        $msg =~ s/\n/\\n/g;
        $logger->warn($msg);
    };


    $locale = LedgerSMB::Locale
        ->get_handle($wire->get( 'default_locale' )
                     ->from_header( $ENV{HTTP_ACCEPT_LANGUAGE} )
        )
        or $form->error( __FILE__ . ':' . __LINE__ .
                         ": Locale not loaded: $!\n" );


    # we use $script for the language module
    $form->{script} = $script;

    # locale messages
    #$form->{charset} = $locale->encoding;
    $form->{charset} = 'UTF-8';
    $locale->encoding('UTF-8');

    try {
        $psgi_env->{'lsmb.app_cb'}->($psgi_env);
        LedgerSMB::App_State::set_DBH($psgi_env->{'lsmb.app'});

        $form->{session_id} = $psgi_env->{'lsmb.session'}->{session_id};
        $form->db_init( $psgi_env->{'lsmb.app'},  \%myconfig );

        # we get rid of myconfig and use User as a real object
        %myconfig = %{ LedgerSMB::User->fetch_config( $form ) };
        $form->{_user} = \%myconfig;
        $form->{_req} = Plack::Request::WithEncoding->new($psgi_env);
        map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout)
            unless ( $form->{type} and $form->{type} eq 'preferences' );

        if ($myconfig{language}){
            $locale   = LedgerSMB::Locale->get_handle( $myconfig{language} )
                or _error($form, __FILE__ . ':' . __LINE__
                          . ": Locale not loaded: $!\n" );
        }

        $form->{_locale} = $locale;
        # pull in the main code
        $logger->trace("requiring old/bin/$script");
        require "old/bin/$script";

        if ( $form->{__action}
             && $form->{__action} ne 'redirect'
             && "lsmb_legacy"->can($form->{__action}) ) {
            $logger->trace("__action $form->{__action}");

            &{ $form->{__action} }();
            $form->{dbh}->commit;
        }
        else {
            $form->error( __FILE__ . ':' . __LINE__ . ': '
                          . $locale->text('__action not defined!'));
        }
    }
    catch  ($err) {
        # We have an exception here because otherwise we always get an exception
        # when output terminates.  A mere 'die' will no longer trigger an automatic
        # error, but die 'foo' will map to $form->error('foo')
        # -- CT
        $form->{_error} = 1;
        if ($err =~ /^Died/i or $err =~ /^exit at /) {
            $form->{dbh}->commit if defined $form->{dbh};
        }
        else {
            $form->{dbh}->rollback if defined $form->{dbh};
            _error($form, "'$err'");
        }
    }

    $logger->trace("leaving after script=old/bin/$form->{script} __action=$form->{__action}");#trace flow

    $form->{dbh}->disconnect() if defined $form->{dbh};
    return 1; # PSGI.pm expects a 'true' response
}


sub _error {
    my ($form, $msg, $status) = @_;
    $msg = "? _error" if !defined $msg;
    my $html_msg = escape_html($msg);
    my $html_dbversion = escape_html($form->{dbversion});
    my $html_company   = escape_html($form->{company});
    $status = 500 if ! defined $status;

    print qq|Status: $status ISE
Content-Type: text/html; charset=utf-8

<html>
<body><h2 class="error">Error!</h2> <p><b>$html_msg</b></p>
<p>dbversion: $html_dbversion, company: $html_company</p>
</body>
</html>
|;

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $msg =~ s/\n/\\n/g;
    $logger->error($msg);
}


1;
