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

# setup defaults, DO NOT CHANGE
$userspath = "users";
$spool = "spool";
$templates = "templates";
$memberfile = "users/members";
$sendmail = "| /usr/sbin/sendmail -t";
$latex = 0;
%printer = ();
########## end ###########################################


$| = 1;

use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::Session;

eval { require "ledger-smb.conf"; };

# for custom preprocessing logic
eval { require "custom.pl"; };

$form = new Form;

  
# name of this script
$0 =~ tr/\\/\//;
$pos = rindex $0, '/';
$script = substr($0, $pos + 1);

# we use $script for the language module
$form->{script} = $script;
# strip .pl for translation files
$script =~ s/\.pl//;

# pull in DBI
use DBI qw(:sql_types);

# check for user config file, could be missing or ???
eval { require("$userspath/$form->{login}.conf"); };
if ($@) {
	$locale = LedgerSMB::Locale->get_handle("fr_CA");
	$form->{charset} = $locale->encoding;
	$form->{charset} = 'UTF-8';
	$locale->encoding('UTF-8');

	$form->{callback} = "";
	$msg1 = $locale->text('You are logged out!');
	$msg2 = $locale->text('Login');
	$form->redirect("$msg1 <p><a href=\"login.pl\" target=\"_top\">$msg2</a></p>");
}

# locale messages
$locale = LedgerSMB::Locale->get_handle($myconfig{countrycode});
#$form->{charset} = $locale->encoding;
$form->{charset} = 'UTF-8';
$locale->encoding('UTF-8');

# send warnings to browser
$SIG{__WARN__} = sub { $form->info($_[0]) };

# send errors to browser
$SIG{__DIE__} = sub { $form->error($_[0]) };

$myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd};
map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout) unless ($form->{type} eq 'preferences');
$form->db_init(\%myconfig);

if ($form->{path} ne 'bin/lynx'){ $form->{path} = 'bin/mozilla';}	

# did sysadmin lock us out
if (-f "$userspath/nologin") {
	$form->error($locale->text('System currently down for maintenance!'));
}

# pull in the main code
require "bin/$form->{script}";

# customized scripts
if (-f "bin/custom/$form->{script}") {
	eval { require "bin/custom/$form->{script}"; };
}

# customized scripts for login
if (-f "bin/custom/$form->{login}_$form->{script}") {
	eval { require "bin/custom/$form->{login}_$form->{script}"; };
}

  
if ($form->{action}) {
	# window title bar, user info
	$form->{titlebar} = "LedgerSMB ".$locale->text('Version'). " $form->{version} - $myconfig{name} - $myconfig{dbname}";

	&check_password;

	if (substr($form->{action}, 0, 1) =~ /( |\.)/) {
		&{ $form->{nextsub} };
	} else {
		&{ $form->{action} };
	}

} else {
	$form->error($locale->text('action= not defined!'));
}

1;
# end


sub check_password {
  
	if ($myconfig{password}) {

		require "bin/pw.pl";

		if ($form->{password}) {
			if ((crypt $form->{password}, substr($form->{login}, 0, 2)) ne $myconfig{password}) {
				if ($ENV{HTTP_USER_AGENT}) {
					&getpassword;
				} else {
					$form->error($locale->text('Access Denied!'));
				}
				exit;
			} else {
				Session::session_create($form, %myconfig);
			}
			
		} else {
			if ($ENV{HTTP_USER_AGENT}) {
				$ENV{HTTP_COOKIE} =~ s/;\s*/;/g;
				@cookies = split /;/, $ENV{HTTP_COOKIE};
				foreach (@cookies) {
					($name,$value) = split /=/, $_, 2;
					$cookie{$name} = $value;
				}

				if ($form->{action} ne 'display') {
					if ((! $cookie{"LedgerSMB-$form->{login}"}) || $cookie{"LedgerSMB-$form->{login}"} ne $form->{sessionid}) {
						&getpassword(1);
						exit;
					}
				}
				#check for valid session
				if(!Session::session_check($cookie{"LedgerSMB"}, $form, %myconfig)){
					&getpassword(1);
					exit;
				}
			} else {
				exit;
			}
		}
	}
}


