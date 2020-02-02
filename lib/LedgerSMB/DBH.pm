
package LedgerSMB::DBH;

=head1 NAME

LedgerSMB::DBH - Database Connection Routines for LedgerSMB

=head1 SYNPOSIS

  my $dbh = LedgerSMB::DBH->connect($company, $username, $password);

=cut

use strict;
use warnings;

use LedgerSMB::Sysconfig;
use LedgerSMB::Setting;
use Carp;
use DBI;

=head1 DESCRIPTION

Sets up and manages the db connection.  This returns a DBI database handle.

=head1 METHODS

This module doesn't specify any (public) methods.

=head1 FUNCTIONS

=head2 connect ($username, $password)

Returns a connection authenticated with $username and $password.
Returns undef on connection failure or lack of credentials.

=cut

sub connect {
    my ($package, $company, $username, $password) = @_;

    return undef unless $username && $password;
    return undef if $username eq 'logout';

    my $dbh = DBI->connect("dbi:Pg:dbname=$company", $username, $password,
                           { PrintError => 0, AutoCommit => 0,
                             # From the DBI docs:
                             #   It is strongly recommended that
                             #   AutoInactiveDestroy is enabled on all new code
                             AutoInactiveDestroy => 1,
                             pg_enable_utf8 => 1, pg_server_prepare => 0 })
        or return undef;

    $dbh->do(q{set client_min_messages = 'warning'});

    my $dbi_trace=$LedgerSMB::Sysconfig::DBI_TRACE;
    if ($dbi_trace) {
        # See http://search.cpan.org/~timb/DBI-1.616/DBI.pm#TRACING
        $dbh->trace(split /=/,$dbi_trace,2);
    }

    return $dbh;
}

=head2 require_version($version)

Checks for a setting called 'ignore_version' and returns immediately if this is
set and true.

Otherwise, requires a specific version (exactly).  Dies if doesn't match.

The ignore_version setting is intended to be temporarily set during
zero-downtime upgrades.

=cut

sub require_version {
    my ($self, $dbh, $expected_version) = @_;
    $expected_version ||= $self; # handling ::require_version($version) syntax

    my $ignore_version =
        LedgerSMB::Setting->new(dbh => $dbh)->get('ignore_version');
    return if $ignore_version;

    my $version = LedgerSMB::Setting->new(dbh => $dbh)->get('version');

    if ($expected_version eq $version) {
        return '';
    }
    else {
        return $version;
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014-2017 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
