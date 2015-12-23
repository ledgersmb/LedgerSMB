
=head1 NAME

LedgerSMB::Locale - Locale handling class for LedgerSMB

=head1 SYNOPSIS

Locale support module for LedgerSMB.  Uses Locale::Maketext::Lexicon as a base.

=head1 METHODS

=over

=item get_handle ($language_code)

Returns a locale handle for accessing the other methods.  Inherited from
Locale::Maketext.

=item text ($string, @params)

Returns the translation for the given string.  Use this method with a litteral
string argument to make sure it's included in the translation lexicon.

To request translation of a non-litteral string (e.g. function return value),
call the maketext() method.

=item maketext ($string, @params)

Returns the translation for the given string.  The string position argument
won't be included in the translation lexicon.  Use this function to translate
a string held in a variable, or returned from a function.

=item date ($myconfig, $date, $longformat)

Returns the given date after formatting it.  $longformat is a ternary flag that
determines how the date is formatted.  If $longformat is true, the date will be
given in the form of "_('September') 23 2007".  If $longformat is false but
defined, the date will be in the form of "_('Sep') 23 2007" unless the date is
given in the form 'yyyy.mm.dd', in which case it is returned as-is.  If
$longformat is not defined, the date will be output in the format specified by
$myconfig->{dateformat}.

=back

=head1 Copyright (C) 2006, The LedgerSMB core team.

 #====================================================================
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
 # This work contains copyrighted information from a number of sources
 # all used with permission.  It is released under the GNU General
 # Public License Version 2 or, at your option, any later version.
 # See COPYRIGHT file for details.
 #
 # This file contains source code included with or based on SQL-Ledger
 # which is Copyright Dieter Simader and DWS Systems Inc. 2000-2005
 # and licensed under the GNU General Public License version 2 or, at
 # your option, any later version.  For a full list including contact
 # information of contributors, maintainers, and copyright holders,
 # see the CONTRIBUTORS file.
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
 #
 #====================================================================
=cut

package LedgerSMB::Locale;

use strict;
use warnings;

use base 'Locale::Maketext';
use LedgerSMB::Sysconfig;
use Locale::Maketext::Lexicon;
use Encode;

Locale::Maketext::Lexicon->import(
    {
        '*'     => [ Gettext => "${LedgerSMB::Sysconfig::localepath}/*.po", ],
        _auto   => 1,
        _decode => 1,
    }
);

sub text {
    my ( $self, $text, @params ) = @_;
    return $self->maketext( $text, @params );
}

##sub date {
##    my ($self, $myconfig, $date, $longformat) = @_;
##    return $date;
##}
sub date {
    my ( $self, $myconfig, $date, $longformat ) = @_;
    my @longmonth = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec));
    @longmonth = (
        "January",   "February", "March",    "April",
        "May ",      "June",     "July",     "August",
        "September", "October",  "November", "December"
    ) if $longformat;
    my $longdate = '';

    return '' if not $date;

    my $spc = '';
    my $yy  = '';
    my $mm  = '';
    my $dd  = '';

    # get separator
    $spc = $myconfig->{dateformat};
    $spc =~ s/\w//g;
    $spc = substr( $spc, 0, 1 );

    if ( !$longformat && $date =~ /^\d{4}\D/ ) {  # reparsing date at this point
                                                  # causes problems!
        return $date;
    }
    if ( $date =~ /\D/ ) {
        if ($date  =~ /^\d{4}/){ # db date in
            ( $yy, $mm, $dd ) = split /\D/, $date;
        }
        elsif ( $myconfig->{dateformat} =~ /^yy/ ) {
            ( $yy, $mm, $dd ) = split /\D/, $date;
        }
        elsif ( $myconfig->{dateformat} =~ /^mm/ ) {
            ( $mm, $dd, $yy ) = split /\D/, $date;
        }
        elsif ( $myconfig->{dateformat} =~ /^dd/ ) {
            ( $dd, $mm, $yy ) = split /\D/, $date;
        }

    }
    else {
        $date = substr( $date, 2 );
        ( $yy, $mm, $dd ) = ( $date =~ /(..)(..)(..)/ );
    }

    $dd *= 1;
    $yy += 2000 if length $yy == 2;
    $dd = substr( "0$dd", -2 );
    $mm = substr( "0$mm", -2 );

    if ( $myconfig->{dateformat} =~ /^dd/ ) {
        $longdate = "$dd$spc$mm$spc$yy";
    }
    elsif ( $myconfig->{dateformat} =~ /^yy/ ) {
        $longdate = "$yy$spc$mm$spc$dd";
    }
    else {
        $longdate = "$mm$spc$dd$spc$yy";
    }

    if ( defined $longformat ) {
        $longdate = $self->maketext( $longmonth[ --$mm ] ) . " $dd $yy";
    }
    $longdate;
}

1;

