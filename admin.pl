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
#     Web: http://www.ledgersmb.org/
#
#  Contributors:
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
# this script sets up the terminal and runs the scripts
# in bin/$terminal directory
# admin.pl is linked to this script
#
#######################################################################

use LedgerSMB::Sysconfig;
require "common.pl";

$| = 1;

if ($ENV{CONTENT_LENGTH}) {
	read(STDIN, $_, $ENV{CONTENT_LENGTH});
}

if ($ENV{QUERY_STRING}) {
	$_ = $ENV{QUERY_STRING};
}

if ($ARGV[0]) {
	$_ = $ARGV[0];
}


%form = split /[&=]/;

# fix for apache 2.0 bug
map { $form{$_} =~ s/\\$// } keys %form;

# name of this script
$0 =~ tr/\\/\//;
$pos = rindex $0, '/';
$script = substr($0, $pos + 1);

#this needs to be a db based function
#if (-e "${LedgerSMB::Sysconfig::userspath}/nologin" && $script ne 'admin.pl') {
#	print "Content-Type: text/html\n\n<html><body><strong>";
#	print "\nLogin disabled!\n";
#	print "\n</strong></body></html>";
#	exit;
#}


if ($form{path}) {

	if ($form{path} ne 'bin/lynx'){ $form{path} = 'bin/mozilla';}	

	$ARGV[0] = "$_&script=$script";
	require "bin/$script";

} else {

	$form{terminal} = "lynx";

	if ($ENV{HTTP_USER_AGENT} !~ /lynx/i) {
		$form{terminal} = "mozilla";
	}

	$ARGV[0] = "path=bin/$form{terminal}&script=$script";
	map { $ARGV[0] .= "&${_}=$form{$_}" } keys %form;

	require "bin/$script";

}

# end of main

