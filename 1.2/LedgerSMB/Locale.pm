#=====================================================================
#
# Locale support module for LedgerSMB
# LedgerSMB::Locale
#
# LedgerSMB 
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# 
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License 
# Version 2 or, at your option, any later version.  See COPYRIGHT file for 
# details.
#
#
#======================================================================
# This package contains locale related functions:
#`
# get_handle - gets a locale handle
# text - outputs HTML escaped translation for input text
# date - formats date for the locale
#
#====================================================================

package LedgerSMB::Locale;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon;
use HTML::Entities;
use Encode;

Locale::Maketext::Lexicon->import({
	'*' => [
		Gettext => "${LedgerSMB::Sysconfig::localepath}/*.po",
	],
	_auto => 1,
	_decode => 1,
});

sub text {
	my ($self, $text, @params) = @_;
	return encode_entities($self->maketext($text, @params));
}

##sub date {
##	my ($self, $myconfig, $date, $longformat) = @_;
##	return $date;
##}
sub date {
	my ($self, $myconfig, $date, $longformat) = @_;

	my @longmonth =  (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec));
	@longmonth = ("January", "February", "March", "April", "May ", "June", 
		"July", "August", "September", "October", "November", 
		"December") if $longformat;
	my $longdate = '';

	return '' if not $date;

	my $spc = '';
	my $yy = '';
	my $mm = '';
	my $dd = '';

	# get separator
	$spc = $myconfig->{dateformat};
	$spc =~ s/\w//g;
	$spc = substr($spc, 0, 1);

	if (!$longformat && $date =~ /^\d{4}\D/){ # reparsing date at this point
	                                          # causes problems!
		return $date;
	}
	if ($date =~ /\D/) {

		if ($myconfig->{dateformat} =~ /^yy/) {
			($yy, $mm, $dd) = split /\D/, $date;
		}

		if ($myconfig->{dateformat} =~ /^mm/) {
			($mm, $dd, $yy) = split /\D/, $date;
		}

		if ($myconfig->{dateformat} =~ /^dd/) {
			($dd, $mm, $yy) = split /\D/, $date;
		}

	} else {

		$date = substr($date, 2);
		($yy, $mm, $dd) = ($date =~ /(..)(..)(..)/);
	}

	$dd *= 1;
	$mm--;
	$yy += 2000 if length $yy == 2;

	if ($myconfig->{dateformat} =~ /^dd/) {

		$mm++;
		$dd = substr("0$dd", -2);
		$mm = substr("0$mm", -2);
		$longdate = "$dd$spc$mm$spc$yy";

		if (defined $longformat) {
			$longdate = "$dd";
			$longdate .= ($spc eq '.') ? ". " : " ";
			$longdate .= &text($self, $longmonth[--$mm])." $yy";
		}

	} elsif ($myconfig->{dateformat} =~ /^yy/) {

		$mm++;
		$dd = substr("0$dd", -2);
		$mm = substr("0$mm", -2);
		$longdate = "$yy$spc$mm$spc$dd"; 


	} else {

		$mm++;
		$dd = substr("0$dd", -2);
		$mm = substr("0$mm", -2);
		$longdate = "$mm$spc$dd$spc$yy"; 

	}
	if (defined $longformat) {
		$longdate = &text($self, $longmonth[--$mm])." $dd $yy";
	}
	$longdate;
}

1;

