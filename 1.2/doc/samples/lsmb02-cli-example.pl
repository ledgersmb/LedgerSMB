#!/usr/bin/perl -w
#
#  File:         lsmb02-cli-example.pl
#  Environment:  Ledger-SMB 1.2.0+
#  Author:       Louis B. Moore
#
#  Copyright (C)   2006  Louis B. Moore
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#  Revision:
#       $Id$
#
#

use File::chdir;
use HTML::Entities;


print "\n\nLedger-SMB login: ";
my $login = <STDIN>;
chomp($login);


print "\nLedger-SMB password: ";
system("stty -echo");
my $pwd = <STDIN>;
system("stty echo");
chomp($pwd);
print "\n\n";

$cmd = "login=" . $login . '&password=' . $pwd . '&path=bin&action=login';

$signin = runLScmd("./login.pl",$cmd);

if ( $signin =~ m/Error:/ ) {

	print "\nLogin error\n";
	exit;

}


while (<main::DATA>) {

	chomp;
	@rec = split(/\|/);

	$arg = 'path=bin/mozilla&login=' . $login . '&password=' . $pwd .
		'&action='       . escape(substr($rec[0],0,35)) .
		'&db='           . $rec[1] .
		'&name='         . escape(substr($rec[2],0,35)) .
		'&vendornumber=' . $rec[3] .
		'&address1='     . escape(substr($rec[4],0,35)) .
		'&address2='     . escape(substr($rec[5],0,35)) .
		'&city='         . escape(substr($rec[6],0,35)) .
		'&state='        . escape(substr($rec[7],0,35)) .
		'&zipcode='      . escape(substr($rec[8],0,35)) .
		'&country='      . escape(substr($rec[9],0,35)) .
		'&phone='        . escape(substr($rec[10],0,20)) .
		'&tax_2150=1' .
		'&taxaccounts=2150' .
		'&taxincluded=0' .
		'&terms=0';

	$rc=runLScmd("./ct.pl",$arg);

	if ($rc =~ m/Vendor saved!/) {

		print "$rec[2] SAVED\n";

	} else {

		print "$rec[2] ERROR\n";

	}

}


$cmd = "login=" . $login . '&password=' . $pwd . '&path=bin&action=logout';

$signin = runLScmd("./login.pl",$cmd);

if ( $signin =~ m/Error:/ ) {

    print "\nLogout error\n";

}

exit;


#*******************************************************
# Subroutines
#*******************************************************


sub runLScmd {

    my $cmd  = shift;
    my $args = shift;
    my $i    = 0;
    my $results;

    local $CWD = "/usr/local/ledger-smb/";

    $cmd = $cmd . " \"" . $args . "\"";

    $results = `$cmd 2>&1`;

    return $results;

}

sub escape {

    my $str = shift;

    if ($str) {

	decode_entities($str);
	$str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02x", ord($1))/ge;
    }

    return $str;

}


#*******************************************************
# Record Format
#*******************************************************
#
# action | db | name | vendornumber | address1 | address2 | city | state | zipcode | country | phone
#

__END__
save|vendor|Parts are Us|1377|238 Riverview|Suite 11|Cheese Head|WI|56743|USA|555-123-3322|
save|vendor|Widget Heaven|1378|41 S. Riparian Way||Show Me|MO|39793|USA|555-231-3309|
save|vendor|Consolidated Spackle|1379|1010 Binary Lane|Dept 1101|Beverly Hills|CA|90210|USA|555-330-7639 x772|

 	  	 
