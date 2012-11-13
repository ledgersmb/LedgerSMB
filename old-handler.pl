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

# Clearing all namespaces for persistant code use
for my $nsp (qw(lsmb_legacy Form GL AA IS IR OE RP JC PE IC AM BP CP PE User)) {    
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
use LedgerSMB::Session;
use LedgerSMB::App_State;
use Data::Dumper;

our $logger=Log::Log4perl->get_logger('old-handler-chain');#make logger available to other old programs

#sleep 10000;

use Data::Dumper;
require "common.pl";

# for custom preprocessing logic
eval { require "custom.pl"; };

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


# we use $script for the language module
$form->{script} = $script;

# strip .pl for translation files
$script =~ s/\.pl//;

# pull in DBI
use DBI qw(:sql_types);

# send warnings to browser
# $SIG{__WARN__} = sub { $form->info( $_[0] ) };

# send errors to browser
#$SIG{__DIE__} =
#  sub { print STDERR  __FILE__ . ':' . __LINE__ . ': ' . $_[0]; };

## did sysadmin lock us out
#if (-f "${LedgerSMB::Sysconfig::userspath}/nologin") {
#	$locale = LedgerSMB::Locale->get_handle(${LedgerSMB::Sysconfig::language}) or
#		$form->error(__FILE__.':'.__LINE__.": Locale not loaded: $!\n");
#	$form->{charset} = 'UTF-8';
#	$locale->encoding('UTF-8');
#
#	$form->{callback} = "";
#	$form->error(__FILE__.':'.__LINE__.': '.$locale->text('System currently down for maintenance!'));
#}


# grab user config. This is ugly and unecessary if/when

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

$form->db_init( \%myconfig );
&check_password;

# we get rid of myconfig and use User as a real object
%myconfig = %{ LedgerSMB::User->fetch_config( $form ) };
map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout)
  unless ( $form->{type} eq 'preferences' );

if ($myconfig{language}){
    $locale   = LedgerSMB::Locale->get_handle( $myconfig{language} )
      or $form->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );
}

$LedgerSMB::App_State::Locale = $locale;
# pull in the main code
try {
#eval {
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
#  1;
#} ||
 }catch  {
  # We have an exception here because otherwise we always get an exception
  # when output terminates.  A mere 'die' will no longer trigger an automatic
  # error, but die 'foo' will map to $form->error('foo')
  # -- CT
  $form->error($_)  unless $_ eq 'Died'; 
} 
;

$logger->trace("leaving after script=bin/$form->{script} action=$form->{action}");#trace flow

1;

$form->{dbh}->disconnect()
    if defined $form->{dbh};

# end

sub check_password {

    require "bin/pw.pl";
    if ( $ENV{GATEWAY_INTERFACE} ) {
        $ENV{HTTP_COOKIE} =~ s/;\s*/;/g;
        @cookies = split /;/, $ENV{HTTP_COOKIE};
        foreach (@cookies) {
            ( $name, $value ) = split /=/, $_, 2;
            $cookie{$name} = $value;
        }

        #check for valid session
        if ( !LedgerSMB::Session::check( $cookie{${LedgerSMB::Sysconfig::cookie_name}}, $form ) ) {
            &getpassword(1);
            exit;
        }
    }
    else {
        exit;
    }
}

