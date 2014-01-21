
=head1 NAME

LedgerSMB::User - Provides user support and database management functions.

=head1 SYNOPSIS

This module provides user support and database management functions.

=head1 STATUS

Deprecated

=head1 COPYRIGHT

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006
 # This work contains copyrighted information from a number of sources
 # all used with permission.
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
 #  Contributors: Jim Rawlings <jim@your-dba.com>
 #
 #====================================================================
 #
 # This file has undergone whitespace cleanup.
 #
 #====================================================================
 #
 # user related functions
 #
 #====================================================================

=head1 METHODS

=over

=cut

# inline documentation

package LedgerSMB::User;
use LedgerSMB::Sysconfig;
use LedgerSMB::Auth;
use Data::Dumper;
use Log::Log4perl;

my $logger = Log::Log4perl->get_logger('LedgerSMB::User');


=item LedgerSMB::User->country_codes();

Returns a hash where the keys are registered locales and the values are the
textual representation of the locale name.

=cut

sub country_codes {
    use Locale::Country;
    use Locale::Language;

    my %cc = ();

    # scan the locale directory and read in the LANGUAGE files
    opendir DIR, "${LedgerSMB::Sysconfig::localepath}";

    my @dir = grep !/^\..*$/, readdir DIR;

    foreach my $dir (@dir) {
        $dir = substr( $dir, 0, -3 );
        $cc{$dir} = code2language( substr( $dir, 0, 2 ) );
        $cc{$dir} .= ( "/" . code2country( substr( $dir, 3, 2 ) ) )
          if length($dir) > 2;
        $cc{$dir} .= ( " " . substr( $dir, 6 ) ) if length($dir) > 5;
    }

    closedir(DIR);

    %cc;

}

=item LedgerSMB::User->fetch_config($login);

Returns a reference to a hash that contains the user config for the user $login.
If that user does not exist, output 'Access denied' if in CGI and die in all
cases.

=cut

sub fetch_config {

    #I'm hoping that this function will go and is a temporary bridge
    #until we get rid of %myconfig elsewhere in the code

    my ( $self, $lsmb ) = @_;

    my $login;
    my $creds = LedgerSMB::Auth::get_credentials;
    $login = $creds->{login};
     
    my $dbh = $lsmb->{dbh};

    if ( !$login ) { # Assume this is for current connected user
        my $sth = $dbh->prepare('SELECT SESSION_USER');
        $sth->execute();
        ($login) = $sth->fetchrow_array();
    }

    $query = qq|
		SELECT * FROM user_preference 
		 WHERE id = (SELECT id FROM users WHERE username = ?)|;
    my $sth = $dbh->prepare($query);
    $sth->execute($login);
    $myconfig = $sth->fetchrow_hashref(NAME_lc);
    $myconfig->{templates} = "DB";
    bless $myconfig, __PACKAGE__;
    return $myconfig;
}


=item LedgerSMB::User->check_recurring($form);

Disused function to return the number of current recurring events.

=cut

sub check_recurring {
    my ( $self, $form ) = @_;

    my $dbh = $form->{dbh};
    $dbh->{pg_encode_utf8} = 1;

    my $query = qq|
        SELECT count(*) FROM recurring
         WHERE enddate >= current_date AND nextdate <= current_date|;
    ($_) = $dbh->selectrow_array($query);

    $dbh->disconnect;

    $_;

}



1;

=back

