
=head1 NAME

LedgerSMB::User

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

=item LedgerSMB::User->new($login);

Create a LedgerSMB::User object.  If the user $login exists, set the fields
with values retrieved from the database.

=cut

sub new {

    my ( $type, $login ) = @_;
    my $self = {};

    if ( $login ne "" ) {

        # use central db
        my $dbh = ${LedgerSMB::Sysconfig::GLOBALDBH};

        # for now, this is querying the table directly... ugly
        my $fetchUserPrefs = $dbh->prepare(
            "SELECT acs, address, businessnumber,
                   company, countrycode, currency,
                   dateformat, dbdriver, dbhost, dbname, 
                   dboptions, dbpasswd, dbport, dbuser, 
                   email, fax, menuwidth, name, numberformat, 
                   password, print, printer, role, sid, 
                   signature, stylesheet, tel, templates, 
                   timeout, vclimit, u.username
              FROM users_conf as uc, users as u
             WHERE u.username =  ?
               AND u.id = uc.id;"
        );

        $fetchUserPrefs->execute($login);

        my $userHashRef = $fetchUserPrefs->fetchrow_hashref;

        while ( my ( $key, $value ) = each( %{$userHashRef} ) ) {
            $self->{$key} = $value;
        }

        chomp( $self->{dbport} );
        chomp( $self->{dbname} );
        chomp( $self->{dbhost} );

        $self->{dbconnect} =
            'dbi:Pg:dbname='
          . $self->{dbname}
          . ';host='
          . $self->{dbhost}
          . ';port='
          . $self->{dbport};

        if ( $self->{username} ) {
            $self->{login} = $login;
        }
    }

    bless $self, $type;
}

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

    my $login = $lsmb->{login};
    my $dbh = $lsmb->{dbh};

    if ( !$login ) {
        &error( $self, "Access Denied" );
    }

    $query = qq|
		SELECT * FROM user_preference 
		 WHERE id = (SELECT id FROM users WHERE username = ?)|;
    my $sth = $dbh->prepare($query);
    $sth->execute($lsmb->{login});
    $myconfig = $sth->fetchrow_hashref(NAME_lc);

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

=item LedgerSMB::User::dbconnect_vars($form, $db);

Converts individual $form values into $form->{dboptions} and $form->{dbconnect}.

=cut

sub dbconnect_vars {
    my ( $form, $db ) = @_;

    my %dboptions = (
        'Pg' => {
            'yy-mm-dd' => 'set DateStyle to \'ISO\'',
            'mm/dd/yy' => 'set DateStyle to \'SQL, US\'',
            'mm-dd-yy' => 'set DateStyle to \'POSTGRES, US\'',
            'dd/mm/yy' => 'set DateStyle to \'SQL, EUROPEAN\'',
            'dd-mm-yy' => 'set DateStyle to \'POSTGRES, EUROPEAN\'',
            'dd.mm.yy' => 'set DateStyle to \'GERMAN\''
        }
    );

    $form->{dboptions} = $dboptions{ $form->{dbdriver} }{ $form->{dateformat} };

    $form->{dbconnect} = "dbi:$form->{dbdriver}:dbname=$db";
    $form->{dbconnect} .= ";host=$form->{dbhost}";
    $form->{dbconnect} .= ";port=$form->{dbport}";

}

=item LedgerSMB::User->dbdrivers();

Returns a list of all drivers set up with DBI whose names end in 'Pg'.

=cut

sub dbdrivers {

    my @drivers = DBI->available_drivers();

    #  return (grep { /(Pg|Oracle|DB2)/ } @drivers);
    return ( grep { /Pg$/ } @drivers );

}

=item LedgerSMB::User->dbsources($form);

Returns a list of all databases in the same cluster as the database that $form
is set to.  If $form->{only_acc_db} is set, only non-template databases that
have a defaults table owned by $form->{dbuser} are returned.

=cut

sub dbsources {
    my ( $self, $form ) = @_;

    my @dbsources = ();
    my ( $sth, $query );

    $form->{dbdefault} = $form->{dbuser} unless $form->{dbdefault};
    $form->{sid} = $form->{dbdefault};
    &dbconnect_vars( $form, $form->{dbdefault} );

    my $dbh =
      DBI->connect( $form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd} )
      or $form->dberror( __FILE__ . ':' . __LINE__ );
    $dbh->{pg_enable_utf8} = 1;

    if ( $form->{dbdriver} eq 'Pg' ) {

        $query = qq|SELECT datname FROM pg_database|;
        $sth   = $dbh->prepare($query);
        $sth->execute || $form->dberror( __FILE__ . ':' . __LINE__ . $query );

        while ( my ($db) = $sth->fetchrow_array ) {

            if ( $form->{only_acc_db} ) {

                next if ( $db =~ /^template/ );

                &dbconnect_vars( $form, $db );
                my $dbh =
                  DBI->connect( $form->{dbconnect}, $form->{dbuser},
                    $form->{dbpasswd} )
                  or $form->dberror( __FILE__ . ':' . __LINE__ );
                $dbh->{pg_enable_utf8} = 1;

                $query = qq|
                    SELECT tablename FROM pg_tables
                     WHERE tablename = 'defaults'
                       AND tableowner = ?|;
                my $sth = $dbh->prepare($query);
                $sth->execute( $form->{dbuser} )
                  || $form->dberror( __FILE__ . ':' . __LINE__ . $query );

                if ( $sth->fetchrow_array ) {
                    push @dbsources, $db;
                }
                $sth->finish;
                $dbh->disconnect;
                next;
            }
            push @dbsources, $db;
        }
    }

    $sth->finish;
    $dbh->disconnect;

    return @dbsources;

}

=item LedgerSMB::User->dbcreate($form);

Create the database indicated by $form->{db} and load Pg-database.sql, the chart
indicated by $form->{chart} and custom tables and functions
(Pg-custom_tables.sql and Pg-custom_functions).

=cut

sub dbcreate {
    my ( $self, $form ) = @_;

    my %dbcreate =
      ( 'Pg' => qq|CREATE DATABASE "$form->{db}" WITH ENCODING = 'UNICODE'| );

    $form->{sid} = $form->{dbdefault};
    &dbconnect_vars( $form, $form->{dbdefault} );

    # The below line connects to Template1 or another template file in order
    # to create the db.  One must disconnect and reconnect later.
    if ( $form->{dbsuperuser} ) {
        my $superdbh =
          DBI->connect( $form->{dbconnect}, $form->{dbsuperuser},
            $form->{dbsuperpasswd} )
          or $form->dberror( __FILE__ . ':' . __LINE__ );
        $superdbh->{pg_enable_utf8} = 1;
        my $query = qq|$dbcreate{$form->{dbdriver}}|;
        $superdbh->do($query)
          || $form->dberror( __FILE__ . ':' . __LINE__ . $query );

        $superdbh->disconnect;
    }

    #Reassign for the work below

    &dbconnect_vars( $form, $form->{db} );

    my $dbh =
      DBI->connect( $form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd} )
      or $form->dberror( __FILE__ . ':' . __LINE__ );
    $dbh->{pg_enable_utf8} = 1;
    if ( $form->{dbsuperuser} ) {
        my $superdbh =
          DBI->connect( $form->{dbconnect}, $form->{dbsuperuser},
            $form->{dbsuperpasswd} )
          or $form->dberror( __FILE__ . ':' . __LINE__ );
        $superdbh->{pg_enable_utf8} = 1;

        # JD: We need to check for plpgsql,
        # if it isn't there create it, if we can't error
        # Good chance I will have to do this twice as I get
        # used to the way the code is structured

        my %langcreate = ( 'Pg' => qq|CREATE LANGUAGE plpgsql| );
        my $query = qq|$langcreate{$form->{dbdriver}}|;
        $superdbh->do($query);
        $superdbh->disconnect;
    }

    # create the tables
    my $dbdriver =
      ( $form->{dbdriver} =~ /Pg/ )
      ? 'Pg'
      : $form->{dbdriver};

    my $filename = qq|sql/Pg-database.sql|;
    $self->process_query( $form, $dbh, $filename );

    # load gifi
    ($filename) = split /_/, $form->{chart};
    $filename =~ s/_//;
    $self->process_query( $form, $dbh, "sql/${filename}-gifi.sql" );

    # load chart of accounts
    $filename = qq|sql/$form->{chart}-chart.sql|;
    $self->process_query( $form, $dbh, $filename );

    # create custom tables and functions
    my $item;
    foreach $item (qw(tables functions)) {
        $filename = "sql/${dbdriver}-custom_${item}.sql";
        if ( -f "$filename" ) {
            $self->process_query( $form, $dbh, $filename );
        }
    }

    $dbh->disconnect;

}

=item LedgerSMB::User->process_query($form, $dbh, $filename);

Load the file $filename into the database indicated through form using psql.
$dbh is ignored.

=cut

sub process_query {
    my ( $self, $form, $dbh, $filename ) = @_;

    return unless ( -f $filename );

    $ENV{PGPASSWORD} = $form->{dbpasswd};
    $ENV{PGUSER}     = $form->{dbuser};
    $ENV{PGDATABASE} = $form->{db};
    $ENV{PGHOST}     = $form->{dbhost};
    $ENV{PGPORT}     = $form->{dbport};

    $results = system('psql -f $filename 2>&1');
    if ($?) {
        $form->error($!);
    }
    elsif ( $results =~ /error/i ) {
        $form->error($results);
    }
}

=item LedgerSMB::User->dbdelete($form);

Disused function to drop the database $form->{db}.

=cut

sub dbdelete {
    my ( $self, $form ) = @_;

    $form->{sid} = $form->{dbdefault};
    &dbconnect_vars( $form, $form->{dbdefault} );
    my $dbh =
      DBI->connect( $form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd} )
      or $form->dberror( __FILE__ . ':' . __LINE__ );
    $dbh->{pg_enable_utf8} = 1;
    my $query = qq|DROP DATABASE "$form->{db}"|;
    $dbh->do($query) || $form->dberror( __FILE__ . ':' . __LINE__ . $query );

    $dbh->disconnect;

}

=item LedgerSMB::User->dbsources_unused($form, $memfile);

Disused function to identify all databases in a cluster with a defaults table
that are not mentioned in the memberfile $memfile.

=cut

sub dbsources_unused {
    my ( $self, $form, $memfile ) = @_;

    my @dbexcl    = ();
    my @dbsources = ();

    $form->error( __FILE__ . ':' . __LINE__ . ": $memfile locked!" )
      if ( -f "${memfile}.LCK" );

    # open members file
    open( FH, '<', "$memfile" )
      or $form->error( __FILE__ . ':' . __LINE__ . ": $memfile : $!" );

    while (<FH>) {
        if (/^dbname=/) {
            my ( $null, $item ) = split /=/;
            push @dbexcl, $item;
        }
    }

    close FH;

    $form->{only_acc_db} = 1;
    my @db = &dbsources( "", $form );

    push @dbexcl, $form->{dbdefault};

    foreach $item (@db) {
        unless ( grep /$item$/, @dbexcl ) {
            push @dbsources, $item;
        }
    }

    return @dbsources;

}

=item LedgerSMB::User->dbneedsupdate($form);

Disused function to locate all databases owned by $form->{dbuser} that are not
a template* database which have a defaults table with a version entry.

=cut

sub dbneedsupdate {
    my ( $self, $form ) = @_;

    my %dbsources = ();
    my $query;

    $form->{sid} = $form->{dbdefault};
    &dbconnect_vars( $form, $form->{dbdefault} );

    my $dbh =
      DBI->connect( $form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd} )
      or $form->dberror( __FILE__ . ':' . __LINE__ );
    $dbh->{pg_enable_utf8} = 1;

    if ( $form->{dbdriver} =~ /Pg/ ) {

        $query = qq|
            SELECT d.datname 
              FROM pg_database d, pg_user u
             WHERE d.datdba = u.usesysid
                   AND u.usename = ?|;
        my $sth = $dbh->prepare($query);
        $sth->execute( $form->{dbuser} )
          || $form->dberror( __FILE__ . ':' . __LINE__ . $query );

        while ( my ($db) = $sth->fetchrow_array ) {

            next if ( $db =~ /^template/ );

            &dbconnect_vars( $form, $db );

            my $dbh =
              DBI->connect( $form->{dbconnect}, $form->{dbuser},
                $form->{dbpasswd} )
              or $form->dberror( __FILE__ . ':' . __LINE__ );
            $dbh->{pg_enable_utf8};

            $query = qq|
                SELECT tablename 
                  FROM pg_tables
                 WHERE tablename = 'defaults'|;
            my $sth = $dbh->prepare($query);
            $sth->execute
              || $form->dberror( __FILE__ . ':' . __LINE__ . $query );

            if ( $sth->fetchrow_array ) {
                $query = qq|
                    SELECT value FROM defaults
                     WHERE setting_key = 'version'|;
                my $sth = $dbh->prepare($query);
                $sth->execute;

                if ( my ($version) = $sth->fetchrow_array ) {
                    $dbsources{$db} = $version;
                }
                $sth->finish;
            }
            $sth->finish;
            $dbh->disconnect;
        }
        $sth->finish;
    }

    $dbh->disconnect;

    %dbsources;

}

=item LedgerSMB::User->dbupdate($form);

Applies database upgrade scripts to upgrade the database to the current level.

=cut

sub dbupdate {
    my ( $self, $form ) = @_;

    $form->{sid} = $form->{dbdefault};

    my @upgradescripts = ();
    my $query;
    my $rc = -2;

    if ( $form->{dbupdate} ) {

        # read update scripts into memory
        opendir SQLDIR, "sql/."
          or $form->error( __FILE__ . ':' . __LINE__ . ': ' . $! );
        @upgradescripts =
          sort script_version grep /$form->{dbdriver}-upgrade-.*?\.sql$/,
          readdir SQLDIR;
        closedir SQLDIR;
    }

    foreach my $db ( split / /, $form->{dbupdate} ) {

        next unless $form->{$db};

        # strip db from dataset
        $db =~ s/^db//;
        &dbconnect_vars( $form, $db );

        my $dbh = DBI->connect(
            $form->{dbconnect}, $form->{dbuser},
            $form->{dbpasswd}, { AutoCommit => 0 }
        ) or $form->dberror( __FILE__ . ':' . __LINE__ );
        $dbh->{pg_enable_utf8} = 1;

        # check version
        $query = qq|
            SELECT value FROM defaults
             WHERE setting_key = 'version'|;
        my $sth = $dbh->prepare($query);

        # no error check, let it fall through
        $sth->execute;

        my $version = $sth->fetchrow_array;
        $sth->finish;

        next unless $version;

        $version = calc_version($version);
        my $dbversion = calc_version( $form->{dbversion} );

        foreach my $upgradescript (@upgradescripts) {
            my $a = $upgradescript;
            $a =~ s/(^$form->{dbdriver}-upgrade-|\.sql$)//g;

            my ( $mindb, $maxdb ) = split /-/, $a;
            $mindb = calc_version($mindb);
            $maxdb = calc_version($maxdb);

            next if ( $version >= $maxdb );

            # exit if there is no upgrade script or version == mindb
            last if ( $version < $mindb || $version >= $dbversion );

            # apply upgrade
            $self->process_query( $form, $dbh, "sql/$upgradescript" );
            $dbh->commit;
            $version = $maxdb;

        }

        $rc = 0;
        $dbh->disconnect;

    }

    $rc;

}

=item calc_version($version);

Returns a numeric form for the version passed in.  The numeric form is derived
by converting each dotted portion of the version to a three-digit number and
appending them.

 +----------+------------+
 | $version |   returned |
 +----------+------------+
 |   1.0.0  |    1000000 |
 |   1.2.33 |    1002033 |
 | 189.2.33 |  189002033 |
 |  1.2.3.4 | 1002003004 |
 +----------+------------+

=cut

sub calc_version {

    my @v = split /\./, $_[0];
    my $version = 0;
    my $i;

    for ( $i = 0 ; $i <= $#v ; $i++ ) {
        $version *= 1000;
        $version += $v[$i];
    }

    return $version;

}

=item script_version

Sorting function for database upgrade scripts.

=cut

sub script_version {
    my ( $my_a, $my_b ) = ( $a, $b );

    my ( $a_from, $a_to, $b_from, $b_to );
    my ( $res_a, $res_b, $i );

    $my_a =~ s/.*-upgrade-//;
    $my_a =~ s/.sql$//;
    $my_b =~ s/.*-upgrade-//;
    $my_b =~ s/.sql$//;
    ( $a_from, $a_to ) = split( /-/, $my_a );
    ( $b_from, $b_to ) = split( /-/, $my_b );

    $res_a = calc_version($a_from);
    $res_b = calc_version($b_from);

    if ( $res_a == $res_b ) {
        $res_a = calc_version($a_to);
        $res_b = calc_version($b_to);
    }

    return $res_a <=> $res_b;

}

=item $user->save_member();

Updates the user config in the database for the user $user.  If no config for
the user exists, the user to the database.

=cut

sub save_member {

    my ($self) = @_;

    # replace \r\n with \n
    for (qw(address signature)) { $self->{$_} =~ s/\r?\n/\\n/g }

    # use central db
    my $dbh = ${LedgerSMB::Sysconfig::GLOBALDBH};

    #check to see if the user exists already
    my $userCheck = $dbh->prepare("SELECT id FROM users WHERE username = ?");
    $userCheck->execute( $self->{login} );
    my ($userID) = $userCheck->fetchrow_array;

    if ( !$self->{dbhost} ) {
        $self->{dbhost} = 'localhost';
    }
    if ( !$self->{dbport} ) {
        $self->{dbport} = '5432';
    }

    my $userConfExists = 0;

    if ($userID) {

        #got an id, check to see if it's in the users_conf table
        my $userConfCheck =
          $dbh->prepare("SELECT password, 1 FROM users_conf WHERE id = ?");
        $userConfCheck->execute($userID);

        ( $oldPassword, $userConfExists ) = $userConfCheck->fetchrow_array;
    }
    else {
        my $userConfAdd = $dbh->prepare("SELECT create_user(?);");
        $userConfAdd->execute( $self->{login} );
        ($userID) = $userConfAdd->fetchrow_array;
    }

    if ($userConfExists) {

        # for now, this is updating the table directly... ugly
        my $userConfUpdate = $dbh->prepare(
            "UPDATE users_conf
                                               SET acs = ?, address = ?, businessnumber = ?,
                                                   company = ?, countrycode = ?, currency = ?,
                                                   dateformat = ?, dbdriver = ?,
                                                   dbhost = ?, dbname = ?, dboptions = ?, 
                                                   dbpasswd = ?, dbport = ?, dbuser = ?,
                                                   email = ?, fax = ?, menuwidth = ?,
                                                   name = ?, numberformat = ?,
                                                   print = ?, printer = ?, role = ?,
                                                   sid = ?, signature = ?, stylesheet = ?,
                                                   tel = ?, templates = ?, timeout = ?,
                                                   vclimit = ?
                                             WHERE id = ?;"
        );

        $userConfUpdate->execute(
            $self->{acs},            $self->{address},
            $self->{businessnumber}, $self->{company},
            $self->{countrycode},    $self->{currency},
            $self->{dateformat},     $self->{dbdriver},
            $self->{dbhost},         $self->{dbname},
            $self->{dboptions},      $self->{dbpasswd},
            $self->{dbport},         $self->{dbuser},
            $self->{email},          $self->{fax},
            $self->{menuwidth},      $self->{name},
            $self->{numberformat},   $self->{print},
            $self->{printer},        $self->{role},
            $self->{sid},            $self->{signature},
            $self->{stylesheet},     $self->{tel},
            $self->{templates},      $self->{timeout},
            $self->{vclimit},        $userID
        );

        if ( $oldPassword ne $self->{password} ) {

       # if they're supplying a 32 char password that matches their old password
       # assume they don't want to change passwords

            $userConfUpdate = $dbh->prepare(
                "UPDATE users_conf
                                                SET password = md5(?)
                                              WHERE id = ?"
            );

            $userConfUpdate->execute( $self->{password}, $userID );

        }

    }
    else {

        my $userConfInsert = $dbh->prepare(
            "INSERT INTO users_conf(acs, address, businessnumber,
                                                                   company, countrycode, currency,
                                                                   dateformat, dbdriver,
                                                                   dbhost, dbname, dboptions, dbpasswd,
                                                                   dbport, dbuser, email, fax, menuwidth,
                                                                   name, numberformat, print, printer, role, 
                                                                   sid, signature, stylesheet, tel, templates, 
                                                                   timeout, vclimit, id, password)
                                            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                                                   ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                                                   ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, md5(?));"
        );

        $userConfInsert->execute(
            $self->{acs},            $self->{address},
            $self->{businessnumber}, $self->{company},
            $self->{countrycode},    $self->{currency},
            $self->{dateformat},     $self->{dbdriver},
            $self->{dbhost},         $self->{dbname},
            $self->{dboptions},      $self->{dbpasswd},
            $self->{dbport},         $self->{dbuser},
            $self->{email},          $self->{fax},
            $self->{menuwidth},      $self->{name},
            $self->{numberformat},   $self->{print},
            $self->{printer},        $self->{role},
            $self->{sid},            $self->{signature},
            $self->{stylesheet},     $self->{tel},
            $self->{templates},      $self->{timeout},
            $self->{vclimit},        $userID,
            $self->{password}
        );

    }

    if ( !$self->{'admin'} ) {

        $self->{dbpasswd} =~ s/\\'/'/g;
        $self->{dbpasswd} =~ s/\\\\/\\/g;

        # format dbconnect and dboptions string
        &dbconnect_vars( $self, $self->{dbname} );

        # check if login is in database
        my $dbh = DBI->connect(
            $self->{dbconnect}, $self->{dbuser},
            $self->{dbpasswd}, { AutoCommit => 0 }
        ) or $self->error($DBI::errstr);
        $dbh->{pg_enable_utf8} = 1;

        # add login to employees table if it does not exist
        my $login = $self->{login};
        $login =~ s/@.*//;
        my $sth = $dbh->prepare("SELECT entity_id FROM employee WHERE login = ?;");
        $sth->execute($login);

        my ($id) = $sth->fetchrow_array;
        $sth->finish;
        my $employeenumber;
        my @values;
        if ($id) {

            $query = qq|UPDATE employee SET
            role = ?,
            email = ?, 
            name = ?
            WHERE login = ?|;

            @values = ( $self->{role}, $self->{email}, $self->{name}, $login );

        }
        else {

            my ($employeenumber) =
              Form::update_defaults( "", \%$self, "employeenumber", $dbh );
            $query = qq|
                INSERT INTO employee 
                            (login, employeenumber, name, 
                            workphone, role, email, sales)
                    VALUES (?, ?, ?, ?, ?, ?, '1')|;

            @values = (
                $login,       $employeenumber, $self->{name},
                $self->{tel}, $self->{role},   $self->{email}
            );
        }

        $sth = $dbh->prepare($query);
        $sth->execute(@values);
        $dbh->commit;
        $dbh->disconnect;

    }
}

=item LedgerSMB::User->delete_login($form);

Disused function to delete the user $form->{login}.

=cut

sub delete_login {
    my ( $self, $form ) = @_;

    my $dbh = DBI->connect(
        $form->{dbconnect}, $form->{dbuser},
        $form->{dbpasswd}, { AutoCommit => 0 }
    ) or $form->dberror( __FILE__ . ':' . __LINE__ );
    $dbh->{pg_enable_utf8} = 1;

    my $login = $form->{login};
    $login =~ s/@.*//;
    my $query = qq|SELECT entity_id FROM employee WHERE login = ?|;
    my $sth   = $dbh->prepare($query);
    $sth->execute($login)
      || $form->dberror( __FILE__ . ':' . __LINE__ . ': ' . $query );

    my ($id) = $sth->fetchrow_array;
    $sth->finish;

    my $query = qq|
        UPDATE employee 
           SET login = NULL,
               enddate = current_date
         WHERE login = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute($login);
    $dbh->commit;
    $dbh->disconnect;

}

=item LedgerSMB::User->config_vars();

Disused function that returns a list of user config variable names.

=cut

sub config_vars {

    my @conf = qw(acs address businessnumber company countrycode
      currency dateformat dbconnect dbdriver dbhost dbname dboptions
      dbpasswd dbport dbuser email fax menuwidth name numberformat
      password printer role sid signature stylesheet tel templates
      timeout vclimit);

    @conf;

}

=item $self->error($msg);

Privately used error function.  Used in places where the more typically used
$form->error cannot be used.  Always dies.

=cut

sub error {
    my ( $self, $msg ) = @_;

    if ( $ENV{GATEWAY_INTERFACE} ) {
        print qq|Content-Type: text/html\n\n|
          . qq|<body bgcolor=ffffff>\n\n|
          . qq|<h2><font color=red>Error!</font></h2>\n|
          . qq|<p><b>$msg</b>|;

    }

    die "Error: $msg\n";

}

1;

=back

