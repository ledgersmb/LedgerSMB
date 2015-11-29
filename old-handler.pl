#!/usr/bin/perl
#
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
# this script is the frontend called from bin/$terminal/$script
# all the accounting modules are linked to this script which in
# turn execute the same script in bin/$terminal/
#
#######################################################################

our $logger=Log::Log4perl->get_logger('old-handler-chain');#make logger available to other old programs
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);

# Clearing all namespaces for persistant code use
for my $nsp (qw(lsmb_legacy Form GL AA IS IR OE PE IC AM)) {
   for my $k (keys %{"${nsp}::"}){
        next if $k =~ /[A-Z]+/;
        next if $k eq 'try' or $k eq 'catch';
        next if *{"${nsp}::{$k}"}{CODE};
        if (*{"${nsp}::{$k}"}{ARRAY}) {
            @{"${nsp}::{$k}"} = () unless /^(?:INC|ISA|EXPORT|EXPORT_OK|ARGV|_|\W)$/;
        }
        if (*{"${nsp}::{$k}"}{HASH}) {
            %{"${nsp}::{$k}"} = ();
        }
        if (*{"${nsp}::{$k}"}{SCALAR}){
           ${"${nsp}::{$k}"} = undef;
        }
    }
}
package lsmb_legacy;
use Digest::MD5;
use Try::Tiny;
use LedgerSMB::App_State;

$| = 1;

binmode (STDIN, ':utf8');
binmode (STDOUT, ':utf8');
use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::Auth;
use LedgerSMB::Request::Error;
use LedgerSMB::Session;
use LedgerSMB::App_State;
use Data::Dumper;

use Data::Dumper;


$form = new Form;
use Data::Dumper;
use LedgerSMB::Sysconfig;

# name of this script
my $script;
if ($ENV{GATEWAY_INTERFACE} =~ /^CGI/){
    $uri = $ENV{REQUEST_URI};
    $uri =~ s/\?.*//;
    $ENV{SCRIPT_NAME} = $uri;
    $ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
    $script = $1;
} else {
    $0 =~ tr/\\/\//;
    $pos = rindex $0, '/';
    $script = substr( $0, $pos + 1 );
}


$locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} )
  or $form->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );

$form->{action} = $form->{nextsub} if (!$form->{action} and $form->{nextsub});

# we use $script for the language module
$form->{script} = $script;

# strip .pl for translation files
$script =~ s/\.pl//;

# pull in DBI
use DBI qw(:sql_types);

# locale messages
#$form->{charset} = $locale->encoding;
$form->{charset} = 'UTF-8';
$locale->encoding('UTF-8');

if ($@) {
    $form->{callback} = "";
    $msg1             = $locale->text('You are logged out!');
    $msg2             = $locale->text('Login');
    $form->redirect(
        "$msg1 <p><a href=\"login.pl\" target=\"_top\">$msg2</a></p>");
}

try {
    $form->db_init( \%myconfig );

    # we get rid of myconfig and use User as a real object
    %myconfig = %{ LedgerSMB::User->fetch_config( $form ) };
    $LedgerSMB::App_State::User = \%myconfig;
    map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout)
        unless ( $form->{type} eq 'preferences' );

    if ($myconfig{language}){
        $locale   = LedgerSMB::Locale->get_handle( $myconfig{language} )
            or &_error($form, __FILE__ . ':' . __LINE__
                       . ": Locale not loaded: $!\n" );
    }

    $LedgerSMB::App_State::Locale = $locale;
    # pull in the main code
    $logger->trace("requiring bin/$form->{script}");
    require "bin/$form->{script}";

    # customized scripts
    if ( -f "bin/custom/$form->{script}" ) {
        eval { require "bin/custom/$form->{script}"; };
    }

    # customized scripts for login
    if ( -f "bin/custom/$form->{login}_$form->{script}" ) {
        eval { require "bin/custom/$form->{login}_$form->{script}"; };
    }

    if ( $form->{action} ) {
        $logger->trace("action $form->{action}");

        binmode STDOUT, ':utf8';
        binmode STDERR, ':utf8';
        # window title bar, user info
        $form->{titlebar} =
            "LedgerSMB "
            . $locale->text('Version')
            . " $form->{version} - $myconfig{name} - $myconfig{dbname}";

        &{ $form->{action} };
        LedgerSMB::App_State::cleanup();

    }
    else {
        $form->error( __FILE__ . ':' . __LINE__ . ': '
                      . $locale->text('action not defined!'));
    }
}catch  {
  # We have an exception here because otherwise we always get an exception
  # when output terminates.  A mere 'die' will no longer trigger an automatic
  # error, but die 'foo' will map to $form->error('foo')
  # -- CT
    $form->{_error} = 1;
    $LedgerSMB::App_State::DBH = undef;
    _error($form, "'$_'") unless $_ =~ /^Died/i or $_ =~ /^exit at Ledger/;
};

$logger->trace("leaving after script=bin/$form->{script} action=$form->{action}");#trace flow

1;

$form->{dbh}->commit if defined $form->{dbh};

$form->{dbh}->disconnect()
    if defined $form->{dbh};

# end


sub _error {

    my ( $self, $msg ) = @_;
    my $error;
    if (eval { $msg->isa('LedgerSMB::Request::Error') }){
        $error = $msg;
    } else {
        $error = LedgerSMB::Request::Error->new(msg => "$msg");
    }

    if ( $ENV{GATEWAY_INTERFACE} ) {

        delete $self->{pre};
        print $error->http_response("<p>dbversion: $self->{dbversion}, company: $self->{company}</p>");

    }
    else {

        if ( $ENV{error_function} ) {
            &{ $ENV{error_function} }($msg);
        }
    }
}

