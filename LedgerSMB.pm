#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
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
# Copyright (C) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
# Contributors: Thomas Bayen <bayen@gmx.de>
#               Antti Kaihola <akaihola@siba.fi>
#               Moritz Bunkus (tex)
#               Jim Rawlings <jim@your-dba.com> (DB2)
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# main package
#
#======================================================================

use Math::BigFloat lib=>'GMP';
use LedgerSMB::Sysconfig;
use strict;

package LedgerSMB;


sub new {
	# This will probably be the last to be revised.

	my $type = shift;

	my $argstr = shift;

	read(STDIN, $_, $ENV{CONTENT_LENGTH});

	if ($argstr){
		 $_ = $argstr;
	}
	elsif ($ENV{QUERY_STRING}) {
		$_ = $ENV{QUERY_STRING};
	}

	elsif ($ARGV[0]) {
		$_ = $ARGV[0];
	}
	
	my $self = {};
	%$self = split /[&=]/;
	for (keys %$self) { $self->{$_} = unescape("", $self->{$_}) }

	if (substr($self->{action}, 0, 1) !~ /( |\.)/) {
		$self->{action} = lc $self->{action};
		$self->{action} =~ s/( |-|,|\#|\/|\.$)/_/g;
	}

	$self->{menubar} = 1 if $self->{path} =~ /lynx/i;
	#menubar will be deprecated, replaced with below
	$self->{lynx} = 1 if $self->{path} =~ /lynx/i;

	$self->{version} = "1.2.0 Beta 2";
	$self->{dbversion} = "1.2.0";

	bless $self, $type;

}


sub debug {
	# Use Data Dumper for this one.

	my ($self, $file) = @_;

	if ($file) {
		open(FH, '>', "$file") or die $!;
		for (sort keys %$self) { print FH "$_ = $self->{$_}\n" }
		close(FH);
	} else {
		print "\n";
		for (sort keys %$self) { print "$_ = $self->{$_}\n" }
	}

} 


sub escape {
	my ($self, $str) = @_;

	my $regex = qr/([^a-zA-Z0-9_.-])/;
	$str =~ s/$regex/sprintf("%%%02x", ord($1))/ge;
	# for Apache 2.0.x prior to 2.0.44 we escape strings twic;
	if ($ENV{SERVER_SIGNATURE} =~  /Apache\/2\.0\.(\d+)/ && $1 < 44) {
		$str =~ s/$regex/sprintf("%%%02x", ord($1))/ge;
	}
	$str;
}


sub unescape {
	my ($self, $str) = @_;

	$str =~ tr/+/ /;
	$str =~ s/\\$//;

	$str =~ s/%([0-9a-fA-Z]{2})/pack("c",hex($1))/eg;
	$str =~ s/\r?\n/\n/g;

	$str;

}


sub numtextrows {

	my ($self, $str, $cols, $maxrows) = @_;

	my $rows = 0;

	for (split /\n/, $str) { 
		$rows += int (((length) - 2)/$cols) + 1 
	}

	$maxrows = $rows unless defined $maxrows;

	return ($rows > $maxrows) ? $maxrows : $rows;

}


sub isblank {
	my ($self, $name, $msg) = @_;
	$self->error($msg) if $self->{$name} =~ /^\s*$/;
}



sub redirect {

	my ($self, $msg) = @_;
	use List::Util qw(first);

	if ($self->{callback} || !$msg) {

		main::redirect();
	} else {

		$self->info($msg);
	}
}

sub format_string {

	my ($self, @fields) = @_;

	my $format = $self->{format};

	if ($self->{format} =~ /(postscript|pdf)/) {
		$format = 'tex';
	}

	my %replace = ( 
		'order' => { 
			html => [ '<', '>', '\n', '\r' ],
			txt  => [ '\n', '\r' ],
			tex  => [ quotemeta('\\'), '&', '\n','\r', 
				'\$', '%', '_', '#',
				quotemeta('^'), '{', '}', '<', '>', '£' 
				] },
		html => { '<'  => '&lt;', '>' => '&gt;','\n' => '<br />', 
			'\r' => '<br />' },
		txt  => { '\n' => "\n", '\r' => "\r" },
		tex  => {'&' => '\&', '$' => '\$', '%' => '\%', '_' => '\_',
			'#' => '\#', quotemeta('^') => '\^\\', '{' => '\{', 
			'}' => '\}', '<' => '$<$', '>' => '$>$',
			'\n' => '\newline ', '\r' => '\newline ', 
			'£' => '\pounds ', quotemeta('\\') => '/'} 
	);

	my $key;

	foreach $key (@{ $replace{order}{$format} }) {
		for (@fields) { $self->{$_} =~ s/$key/$replace{$format}{$key}/g }
	}

}


sub format_amount {

	my ($self, $myconfig, $amount, $places, $dash) = @_;

	my $negative ;
	if ($amount){
		$amount = $self->parse_amount($myconfig, $amount);
		$negative = ($amount < 0);
		$amount =~ s/-//;
	}

	if ($places =~ /\d+/) {
		#$places = 4 if $places == 2;
		$amount = $self->round_amount($amount, $places);
	}

	# is the amount negative

	# Parse $myconfig->{numberformat}



	my ($ts, $ds) = ($1, $2);

	if ($amount) {

		if ($myconfig->{numberformat}) {

			my ($whole, $dec) = split /\./, "$amount";
			$amount = join '', reverse split //, $whole;

			if ($places) {
				$dec .= "0" x $places;
				$dec = substr($dec, 0, $places);
			}

			if ($myconfig->{numberformat} eq '1,000.00') {
				$amount =~ s/\d{3,}?/$&,/g;
				$amount =~ s/,$//;
				$amount = join '', reverse split //, $amount;
				$amount .= "\.$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1 000.00') {
				$amount =~ s/\d{3,}?/$& /g;
				$amount =~ s/\s$//;
				$amount = join '', reverse split //, $amount;
				$amount .= "\.$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq "1'000.00") {
				$amount =~ s/\d{3,}?/$&'/g;
				$amount =~ s/'$//;
				$amount = join '', reverse split //, $amount;
				$amount .= "\.$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1.000,00') {
				$amount =~ s/\d{3,}?/$&./g;
				$amount =~ s/\.$//;
				$amount = join '', reverse split //, $amount;
				$amount .= ",$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1000,00') {
				$amount = "$whole";
				$amount .= ",$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1000.00') {
				$amount = "$whole";
				$amount .= ".$dec" if ($dec ne "");
			}

			if ($dash =~ /-/) {
				$amount = ($negative) ? "($amount)" : "$amount";
			} elsif ($dash =~ /DRCR/) {
				$amount = ($negative) ? "$amount DR" : "$amount CR";
			} else {
				$amount = ($negative) ? "-$amount" : "$amount";
			}
		}

	} else {

		if ($dash eq "0" && $places) {

			if ($myconfig->{numberformat} eq '1.000,00') {
				$amount = "0".","."0" x $places;
			} else {
				$amount = "0"."."."0" x $places;
			}

		} else {
			$amount = ($dash ne "") ? "$dash" : "";
		}
	}

	$amount;
}


sub parse_amount {

	my ($self, $myconfig, $amount) = @_;

	if ($amount eq '' or $amount == undef){
		return 0;
	}

	if (UNIVERSAL::isa($amount, 'Math::BigFloat')){ # Amount may not be an object	
		return $amount;
	}
	my $numberformat = $myconfig->{numberformat};


	if (($numberformat eq '1.000,00') ||
		($numberformat eq '1000,00')) {

		$amount =~ s/\.//g;
		$amount =~ s/,/./;
	}
	if ($numberformat eq '1 000.00'){
		$amount =~ s/\s//g;
	}

	if ($numberformat eq "1'000.00") {
		$amount =~ s/'//g;
	}


	$amount =~ s/,//g;
	if ($amount =~ s/\((\d*\.?\d*)\)/$1/){
		$amount = $1 * -1;
	}
	if ($amount =~ s/(\d*\.?\d*)\s?DR/$1/){
		$amount = $1 * -1;
	}
	$amount =~ s/\s?CR//;
	$amount = new Math::BigFloat($amount);
	return ($amount * 1);
}


sub round_amount {

	my ($self, $amount, $places) = @_;

	# These rounding rules follow from the previous implementation.
	# They should be changed to allow different rules for different accounts.
	Math::BigFloat->round_mode('+inf') if $amount >= 0;
	Math::BigFloat->round_mode('-inf') if $amount < 0;

	$amount = Math::BigFloat->new($amount)->ffround(-$places) if $places >= 0;
	$amount = Math::BigFloat->new($amount)->ffround(-($places-1)) if $places < 0;

	return $amount;
}

sub callproc {
	my $self = shift @_;
	my $procname = shift @_;
	my $argstr = "";
	my @results;
	for (1 .. scalar @_){
		$argstr .= "?, ";
	}
	$argstr =~ s/\, $//;
	my $query = "SELECT * FROM $procname()";
	$query =~ s/\(\)/($argstr)/;
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute(@_);
	while (my $ref = $sth->fetchrow_hashref('NAME_lc')){
		push @results, $ref;
	}
	@results;
}

sub datetonum {

	my ($self, $myconfig, $date, $picture) = @_;

	my ($yy, $mm, $dd);
	if ($date && $date =~ /\D/) {

		if ($myconfig->{dateformat} =~ /^yy/) {
			($yy, $mm, $dd) = split /\D/, $date;
		}

		if ($myconfig->{dateformat} =~ /^mm/) {
			($mm, $dd, $yy) = split /\D/, $date;
		}

		if ($myconfig->{dateformat} =~ /^dd/) {
			($dd, $mm, $yy) = split /\D/, $date;
		}

		$dd *= 1;
		$mm *= 1;
		$yy += 2000 if length $yy == 2;

		$dd = substr("0$dd", -2);
		$mm = substr("0$mm", -2);

		$date = "$yy$mm$dd";
	}

	$date;
}


# Database routines used throughout

sub db_init {
	my ($self, $myconfig) = @_;
	$self->{dbh} = $self->dbconnect_noauto($myconfig) || $self->dberror();

	my $query = 
		"SELECT t.extends, 
			coalesce (t.table_name, 'custom_' || extends) 
			|| ':' || f.field_name as field_def
		FROM custom_table_catalog t
		JOIN custom_field_catalog f USING (table_id)";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute;
	my $ref;
	while ($ref = $sth->fetchrow_hashref('NAME_lc')){
		push @{$self->{custom_db_fields}{$ref->{extends}}},
			$ref->{field_def};
	}
}

sub dbconnect_noauto {

	my ($self, $myconfig) = @_;

	# connect to database
	my $dbh = DBI->connect($myconfig->{dbconnect}, $myconfig->{dbuser}, $myconfig->{dbpasswd}, {AutoCommit => 0}) or $self->dberror;

	# set db options
	if ($myconfig->{dboptions}) {
		$dbh->do($myconfig->{dboptions});
	}

	$dbh;
}


sub redo_rows {

	my ($self, $flds, $new, $count, $numrows) = @_;

	my @ndx = ();

	for (1 .. $count) { 
		push @ndx, { num => $new->[$_-1]->{runningnumber}, ndx => $_ } 
	}

	my $i = 0;
	my $j;
	# fill rows
	foreach my $item (sort { $a->{num} <=> $b->{num} } @ndx) {
		$i++;
		$j = $item->{ndx} - 1;
		for (@{$flds}) { $self->{"${_}_$i"} = $new->[$j]->{$_} }
	}

	# delete empty rows
	for $i ($count + 1 .. $numrows) {
		for (@{$flds}) { delete $self->{"${_}_$i"} }
	}
}


sub merge {
	my ($self, $src) = @_;
	for my $arg ($self, $src){
		shift;
	}
	my @keys;
	if (scalar @keys){
		@keys = @_;
		print "Keys: ". scalar @keys . "\n";
	}
	else {
		@keys = keys %{$src};
		print "Keys: ". scalar @keys . "\n";
	}
	for my $arg (keys %$src){
		$self->{$arg} = $src->{$arg};
	}
}

1;
