=head1 NAME

LedgerSMB::DBH - Database Connection Routines for LedgerSMB

=head1 SYNPOSIS

  my $dbh = LedgerSMB::DBH->connect($company, $username, $password);

or

  my $dbh = LedgerSMB::DBH->connect($company)

to use credentials returned by LedgerSMB::Auth::get_credentials

=cut

package LedgerSMB::DBH;
use strict;
use warnings;

use LedgerSMB::Auth;
use LedgerSMB::Sysconfig;
use LedgerSMB::App_State;
use LedgerSMB::Setting;
use DBI;

=head1 DESCRIPTION

Sets up and manages the db connection.  This returns a DBI database handle.

=head1 FUNCTIONS

=head2 connect ($username, $password)

Returns a connection authenticated with $username and $password.  If $username
is not sent, then these are taken from LedgerSMB::Auth::get_credentials.

Note:  if get_credentials returns a username of 'logoud', then this will return
control there to prompt for credentials again.

=cut

sub connect {
    my ($package, $company, $username, $password) = @_;
    if (!$username){
        my $creds = LedgerSMB::Auth::get_credentials;
        LedgerSMB::Auth::credential_prompt()
            if $creds->{login} && $creds->{login} eq 'logout';
        $username = $creds->{login};
        $password = $creds->{password};
    }
    return undef unless $username;
    my $dbh = DBI->connect(qq|dbi:Pg:dbname="$company"|, $username, $password,
           { PrintError => 0, AutoCommit => 0,
             pg_enable_utf8 => 1, pg_server_prepare => 0 });
    my $dbi_trace=$LedgerSMB::Sysconfig::DBI_TRACE;
    $dbh->do("set client_min_messages = 'warning'");
    if($dbi_trace)
    {
     $dbh->trace(split /=/,$dbi_trace,2);#http://search.cpan.org/~timb/DBI-1.616/DBI.pm#TRACING
    }

    return $dbh;
}

=head2 set_datestyle

This is used for old code, to set the datetyle for input.  It is not needed
for new code because of PGDate support to/from the db.  For this reason, once
order entry is removed, we should probably remove support for it.

=cut

sub set_datestyle {
    my $dbh = LedgerSMB::App_State::DBH;
    my $datequery = 'select dateformat from user_preference join users using(id)
                      where username = CURRENT_USER';
    my $date_sth = $dbh->prepare($datequery);
    $date_sth->execute;
    my ($datestyle) = $date_sth->fetchrow_array;
    my %date_query = (
        'mm/dd/yyyy' => 'set DateStyle to \'SQL, US\'',
        'mm-dd-yyyy' => 'set DateStyle to \'POSTGRES, US\'',
        'dd/mm/yyyy' => 'set DateStyle to \'SQL, EUROPEAN\'',
        'dd-mm-yyyy' => 'set DateStyle to \'POSTGRES, EUROPEAN\'',
        'dd.mm.yyyy' => 'set DateStyle to \'GERMAN\''
    );
    $dbh->do( $date_query{ $datestyle } ) if $date_query{ $datestyle };
}

=head2 require_version($version)

Checks for a setting called 'ignore_version' and returns immediately if this is
set and true.

Otherwise, requires a specific version (exactly).  Dies if doesn't match.

The ignore_version setting is intended to be temporarily set during
zero-downtime upgrades.

=cut

sub require_version {
    my ($self, $expected_version) = @_;
    $expected_version ||= $self; # handling ::require_version($version) syntax

    my $ignore_version = LedgerSMB::Setting->get('ignore_version');
    return if $ignore_version;

    my $version = LedgerSMB::Setting->get('version');
    die LedgerSMB::App_State->Locale->text("Database is not the expected version.  Was [_1], expected [_2].  Please re-run setup.pl against this database to correct.<a href='setup.pl'>setup.pl</a>", $version, $expected_version)
       unless $version eq $expected_version;
    return 0;
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team.

This file may be reused under the terms of the GNU General Public License,
version 2 or at your option any later version.  Please see the included
LICENSE.txt for more information.

=cut

1;
