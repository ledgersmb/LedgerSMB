#!/usr/bin/perl
=head1 NAME

LedgerSMB::Database - Provides the APIs for database creation and management.

=head1 SYNOPSIS

This module provides the APIs for database creation and management

=head1 COPYRIGHT

This module is copyright (C) 2007, the LedgerSMB Core Team and subject to 
the GNU General Public License (GPL) version 2, or at your option, any later
version.  See the COPYRIGHT and LICENSE files for more information.

=head1 METHODS

=over

=cut

# Methods are documented inline.  

package LedgerSMB::Database;
use LedgerSMB::Auth;
use DBI;

our $VERSION = '1';

use LedgerSMB::Sysconfig;
use base('LedgerSMB');
use strict;
use DateTime;
use Log::Log4perl;
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);
my $logger = Log::Log4perl->get_logger('LedgerSMB::Database');

my $dbversions = {
    '1.2' => '1.2.0',
    '1.3dev' => '1.2.99',
    '1.3' => '1.3.0',
    '1.4' => '1.4'
};

my $temp = $LedgerSMB::Sysconfig::tempdir;

=item loader_log_filename

This creates a log file for the specific upgrade attempt.

=cut

sub loader_log_filename {
    my $dt = DateTime->now();
    $dt =~ s/://g; # strip out disallowed Windows characters
    return $temp . "/dblog_${dt}_$$";
}


=item LedgerSMB::Database->new({dbname = $dbname, countrycode = $cc, chart_name = $name, company_name = $company, username = $username, password = $password})

This function creates a new database management object with the specified
characteristics.  The $dbname is the name of the database. the countrycode
is the two-letter ISO code.  The company name is the friendly name for 
dropdown boxes on the Login screen.

As some countries may have multiple available charts, you can also specify
a chart name as well.

Note that the arguments can be any hashref. If it is a LedgerSMB object,
however, it will attempt to copy all attributes beginning with _ into the 
current object (_user, _locale, etc).

=cut

sub new {
    my ($class, $args) = @_;

    my $self = {};
    for (qw(countrycode chart_name chart_gifi company_name username password
            contrib_dir source_dir)){
        $self->{$_} = $args->{$_};
    }
    if ($self->{source_dir}){
        $self->{source_dir} =~ s/\/*$/\//;
    } else {
        $self->{source_dir} = '';
    }

    bless $self, $class;
    return $self;
}

=item dbh

This routine returns a DBI database handle

=cut

sub dbh {
    my ($self) = @_;

    return $LedgerSMB::App_State::DBH
	if defined $LedgerSMB::App_State::DBH;

    my $creds = LedgerSMB::Auth::get_credentials();
    $LedgerSMB::App_State::DBH = DBI->connect(
        qq|dbi:Pg:dbname="$self->{company_name}"|,
	"$creds->{login}", "$creds->{password}",
	{ AutoCommit => 0, PrintError => $logger->is_warn(), }
    );
    return $LedgerSMB::App_State::DBH;
}

=item base_backup

This routine connects to the database using pg_dumpall and returns a plain text,
roles-only dump of the current database cluster.  This is left uncompressed for
readability and ease of troubleshooting.  Base backups are advised to be taken
frequently and in conjunction with single database backups.  The single database
backups will backup all data but no roles.  Restoring a new database onto a new
server post-crash with only the single-database backup thus means recreating all
users.

The file is named roles_[date].sql by default where the date is in
yyyy-mm-dd format.

It returns the full path of the resulting backup file on success, or undef on 
failure.

=cut

sub base_backup {
    my $self = shift @_;

    local %ENV; # Make sure that - when leaving the scope - %ENV is restored
    $ENV{PGUSER} = $self->{username};
    $ENV{PGPASSWORD} = $self->{password};
    $ENV{PGDATABASE} = $self->{company_name};
    $ENV{PGHOST} = $LedgerSMB::Sysconfig::db_host;
    $ENV{PGPORT} = $LedgerSMB::Sysconfig::db_port;

    my @t = localtime(time);
    $t[4]++;
    $t[5] += 1900;
    $t[3] = substr( "0$t[3]", -2 );
    $t[4] = substr( "0$t[4]", -2 );
    my $date = "$t[5]-$t[4]-$t[3]";

    my $backupfile = $LedgerSMB::Sysconfig::backuppath .
                     "/roles_${date}.sql";

    my $exit_code = system("pg_dumpall -r -f $backupfile");

    if($exit_code != 0) {
        $backupfile = undef;
        $logger->error("backup failed: non-zero exit code from pg_dumpall");
    }

    return $backupfile;
}

=item db_backup()

This routine connects to the database using pg_dump and creates a Pg-native 
database backup of the selected db only.  There is some redundancy with the base
backup but the overlap is minimal.  You can restore your database and data with
the db_bakup, but not the users and roles.  You can restore the users and roles
with the base_backup but not your database.

The resulting file is named backup_[dbname]_[date].bak with the date in
yyyy-mm-dd format.

It returns the full path of the resulting backup file on success, or undef on 
failure.

=cut

sub db_backup {
    my $self = shift @_;

    local %ENV; # Make sure that - when leaving the scope - %ENV is restored
    $ENV{PGUSER} = $self->{username};
    $ENV{PGPASSWORD} = $self->{password};
    $ENV{PGDATABASE} = $self->{company_name};
    $ENV{PGHOST} = $LedgerSMB::Sysconfig::db_host;
    $ENV{PGPORT} = $LedgerSMB::Sysconfig::db_port;

    my @t = localtime(time);
    $t[4]++;
    $t[5] += 1900;
    $t[3] = substr( "0$t[3]", -2 );
    $t[4] = substr( "0$t[4]", -2 );
    my $date = "$t[5]-$t[4]-$t[3]";

    my $backupfile = $LedgerSMB::Sysconfig::backuppath .
                     "/backup_$self->{company_name}_${date}.bak";

    my $exit_code = system("pg_dump  -F c -f '$backupfile' '$self->{company_name}'");

    if($exit_code != 0) {
        $backupfile = undef;
        $logger->error("backup failed: non-zero exit code from pg_dump");
    }

    return $backupfile;
}

=item get_info()

This routine connects to the database using DBI and attempts to determine if a 
related application is running in that database and if so what version.  
It returns a hashref with the following keys set:

=over

=item username
Set to the user of the current connection

=item appname
Set to the current application name, one of:

=over

=item ledgersmb

=item sql-ledger

=item undef

=back

=item version
The current version of the application.  One of:

=over

=item legacy
SQL-Ledger 2.6 and below, and LedgerSMB 1.1 and below

=item 1.2 (LedgerSMB only)

=item 1.3 (LedgerSMB only)

=item 1.3dev (LedgerSMB only)

=item 2.7 (SQL-Ledger only)

=item 2.8 (SQL-Ledger only)

=back

=over

=item full_version
The full version number of the database version

=item status
Current status of the db.  One of:

=item exists
The database was confirmed to exist

=item does not exist
The database was confirmed to not exist

=item undef
The database could not be confirmed to exist, or not

=back

=back

It is worth noting that this is designed to be informative and helpful in 
determining whether automatic upgrades can in fact occur or other 
administrative tasks can be run.  Sample output might be:

{    appname => undef, 
     version => undef, 
full_version => undef,
      status => 'does not exist'}

or

{    appname => 'sql-ledger',
     version => '2.8',
full_version => '2.8.33',
      status => 'exists'}

or

{   appname => 'ledgersmb',
    version => '1.2'
fullversion => '1.2.0',
     status => 'exists' }

It goes without saying that status will always equal 'exists' if appname is set.
However the converse is not true.  If the status is 'exists' and appname is not
set, this merely means that the database exists but is not used by a recognized
application.  So administrative functions are advised to check both the appname
and status values.

Finally, it is important to note that LedgerSMB 1.1 and prior, and SQL-Ledger 
2.6.x and prior are lumped under appname => 'ledgersmb' and version => 'legacy',
though the fullversion may give you an idea of what the actual version is run.

=cut 

sub get_info {
    my $self = shift @_;
    my $retval = { # defaults
         appname => undef,
         version => undef,
    full_version => undef,
          status => undef,
    };

    my $creds = LedgerSMB::Auth->get_credentials();
    $logger->trace("\$creds=".Data::Dumper::Dumper(\$creds));
    my $dbh = $self->dbh();
    if (!$dbh){ # Could not connect, try to validate existance by connecting
                # to postgres and checking
           $dbh = DBI->connect(
                   "dbi:Pg:dbname=postgres", 
                   "$creds->{login}", "$creds->{password}", { AutoCommit => 0 }
            );
           return $retval unless $dbh;
           $logger->debug("DBI->connect dbh=$dbh");
	   # don't assign to App_State::DBH, since we're a fallback connection,
	   #  not one to the company database

           my $sth = $dbh->prepare(
                 "select count(*) = 1 from pg_database where datname = ?"
           );
           $sth->execute($self->{company_name});
           my ($exists) = $sth->fetchrow_array();
           if ($exists){
                $retval->{status} = 'exists';
           } else {
                $retval->{status} = 'does not exist';
           }
           $sth = $dbh->prepare("SELECT SESSION_USER");
           $sth->execute;
           $retval->{username} = $sth->fetchrow_array();
	   $sth->finish();
	   $dbh->disconnect();

           return $retval;
   } else { # Got a db handle... try to find the version and app by a few
            # different means
       $logger->debug("DBI->connect dbh=$dbh");

       my $sth;
       $sth = $dbh->prepare("SELECT SESSION_USER");
       $sth->execute;
       $retval->{username} = $sth->fetchrow_array();
       $sth->finish();

       # Is there a chance this is an SL or LSMB legacy version?
       # (ie. is there a VERSION column to query in the DEFAULTS table?
       $sth = $dbh->prepare(
	   qq|select count(*)=1
	        from pg_attribute attr
	        join pg_class cls
	          on cls.oid = attr.attrelid
	        join pg_namespace nsp
	          on nsp.oid = cls.relnamespace
	       where cls.relname = 'defaults'
	         and attr.attname='version'
                 and nsp.nspname = 'public'
             |
	   );
       $sth->execute();
       my ($have_version_column) =
	   $sth->fetchrow_array();
       $sth->finish();

       if ($have_version_column) {
	   # Legacy SL and LSMB
	   $sth = $dbh->prepare(
	       'SELECT version FROM defaults'
	       );
	   #avoid DBD::Pg::st fetchrow_hashref failed: no statement executing
	   my $rv=$sth->execute();     
	   if(defined($rv))
	   {
	       if (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
		   if ($ref->{version}){
		       $retval->{appname} = 'ledgersmb';
		       $retval->{version} = 'legacy';
		       $retval->{full_version} = $ref->{version};

		       $dbh->rollback();
		       return $retval;
		   }
	       }
	   }
       }
       $dbh->rollback;
       # LedgerSMB 1.2 and above
       $sth = $dbh->prepare('SELECT value FROM defaults WHERE setting_key = ?');
       $sth->execute('version');
       if (my $ref = $sth->fetchrow_hashref('NAME_lc')){
           $retval->{full_version} = $ref->{value};
           $retval->{appname} = 'ledgersmb';
           if ($ref->{value} eq '1.2.0') {
                $retval->{version} = '1.2';
           } elsif ($ref->{value} eq '1.2.99'){
                $retval->{version} = '1.3dev';
           } elsif ($ref->{value} =~ /^1.3.999/ or $ref->{value} =~ /^1.4/){
                $retval->{version} = "1.4";
           } elsif ($ref->{value} =~ /^1.3/){
                $retval->{version} = '1.3';
           }
           if ($retval->{version}){

	       $dbh->rollback();
              return $retval;
           }
       }
       $dbh->rollback;
       # SQL-Ledger 2.7-2.8 (fldname, fldvalue)
       $sth = $dbh->prepare('SELECT fldvalue FROM defaults WHERE fldname = ?');
       $sth->execute('version');
       if (my $ref = $sth->fetchrow_hashref('NAME_lc')){
            $retval->{appname} = 'sql-ledger';
            $retval->{full_version} = $ref->{fldvalue};
            $retval->{version} = $ref->{fldvalue};
            $retval->{version} =~ s/(\d+\.\d+).*/$1/g;
       } else {
            $retval->{appname} = 'unknown';
            $retval->{exists} = 'exists';
       } 
       $dbh->rollback;
   }
   #$logger->debug("DBI->disconnect dbh=$dbh");
   #$dbh->disconnect;#leave disconnect to upper level
   return $retval;
}

=item $db->server_version();

Connects to the server and returns the version number in x.y.z format.

=cut

sub server_version {
    my $self = shift @_;
    $logger->trace("\$self=".Data::Dumper::Dumper(\$self));
    my $dbName=$self->{company_name}||'postgres';
    my $creds = LedgerSMB::Auth->get_credentials();
    $logger->trace("\$creds=".Data::Dumper::Dumper(\$creds));
    my $dbh = DBI->connect(
        "dbi:Pg:dbname=$dbName", 
         "$creds->{login}", "$creds->{password}", { AutoCommit => 0 }
    ) or return undef;
    my ($version) = $dbh->selectrow_array('SELECT version()');
    $version =~ /(\d+\.\d+\.\d+)/;
    my $retval = $1;
    $dbh->disconnect;
    return $retval;
}

=item $db->list()

Lists available databases except for those named "postgres" or starting with
"template"

Returns a list of strings of db names.

=cut

sub list {
    my ($self) = @_;
    my $creds = LedgerSMB::Auth->get_credentials();
    my $dbh = DBI->connect(
        "dbi:Pg:dbname=postgres", 
         "$creds->{login}", "$creds->{password}", { AutoCommit => 0 }
    ) or LedgerSMB::Auth::credential_prompt;
    my $resultref = $dbh->selectall_arrayref(
        "SELECT datname FROM pg_database 
          WHERE datname <> 'postgres' AND datname NOT LIKE 'template%'
       ORDER BY datname"
    );
    my @results;
    for my $r (@$resultref){
        push @results, @$r;
    }

    $dbh->disconnect;
    return @results;
}


    
=item $db->create();

Creates a database and loads the contrib files.  This is done from template0, 
meaning nothing added to postgres will be found in this database.  This was 
necessary as a workaround for issues on some Debian systems.

Returns true if successful, false of not.  Creates a log called dblog in the 
temporary directory with all the output from the psql files.  

In DEBUG mode, will show all lines to STDERR.  In ERROR logging mode, will 
display only those lines containing the word ERROR.

=cut

sub create {
    my ($self, $args) = @_;
    # We have to use template0 because of issues that Debian has with database 
    # encoding.  Apparently that causes problems for us, so template0 must be
    # used. Hat tip:  irc user nwnw on #ledgersmb
    #
    # Also moved away from createdb here because at least for some versions of
    # PostgreSQL, it connects to the postgres db in order to issue the 
    # CREATE DATABASE command.  This makes it harder to adequately secure the 
    # platform via pg_hba.conf.  Long run we should specify a locale.
    # 
    # Hat tip:  irc user RhodiumToad on #postgresql -- CT

    my $dbh = DBI->connect('dbi:Pg:dbname=postgres',
			   $self->{username}, $self->{password});

    $dbh->{RaiseError} = 1;
    $dbh->{AutoCommit} = 1;
    my $dbn = $dbh->quote_identifier($self->{company_name});
    my $rc = $dbh->do("CREATE DATABASE $dbn WITH TEMPLATE template0 ENCODING 'UTF8'");
    $dbh->disconnect();

    $logger->trace("after create db \$rc=$rc");
    die "Failed to create database named $dbn"
	if ! $rc;

    $self->load_base_schema({
	log => $args->{log},
	errlog => $args->{errlog}
			    });

    return 1;
}

=item $db->copy('new_name')

Copies the existing database to a new name.

=cut

sub copy {
    my ($self, $new_name) = @_;
    my $dbh = DBI->connect('dbi:Pg:dbname=postgres', 
         $self->{username}, $self->{password},
         { AutoCommit => 1, PrintError => 1, }
    );
    my $dbname = $dbh->quote_identifier($self->{company_name});
    $new_name = $dbh->quote_identifier($new_name);
    my $rc = $dbh->do("CREATE DATABASE $new_name WITH TEMPLATE $dbname");
    $dbh->disconnect;
    return $rc;
}        

=item $db->load_base_schema()

Loads the base schema definition file Pg-database.sql.

=cut

sub load_base_schema {
    my ($self, $args) = @_;
    my $success;
    my $log = loader_log_filename();
    
    # The statement below is likely to fail, because
    # the language already exists. Unfortunately, it's an error.
    # If it had been a notice, 
    $self->dbh->do("CREATE LANGUAGE plpgsql");
    $self->dbh->commit;
    $self->exec_script(
	{
	    script => "$self->{source_dir}sql/Pg-database.sql",
	    log => ($args->{log} || "${log}_stdout"),
	    errlog => ($args->{errlog} || "${log}_stderr")
	});

    opendir(LOADDIR, 'sql/on_load');
    while (my $fname = readdir(LOADDIR)){
        $self->exec_script({
            script => "$self->{source_dir}sql/on_load/$fname",
	    log => ($args->{log} || "${log}_stdout"),
	    errlog => ($args->{errlog} || "${log}_stderr")
        }) if -f "sql/on_load/$fname";
    }

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(
	qq|select true
	        from pg_class cls
	        join pg_namespace nsp
	          on nsp.oid = cls.relnamespace
	       where cls.relname = 'defaults'
                 and nsp.nspname = 'public'
             |);
    $sth->execute();
    ($success) = $sth->fetchrow_array();
    $sth->finish();

    die "Base schema failed to load"
	if ! $success;
}


=item $db->load_modules($loadorder)

Loads or reloads sql modules from $loadorder

=cut

sub load_modules {
    my ($self, $loadorder, $args) = @_;
    my $log = loader_log_filename();

    my $dbh = $self->dbh;
    open (LOADORDER, '<', "$self->{source_dir}sql/modules/$loadorder");
    for my $mod (<LOADORDER>) {
        chomp($mod);
        $mod =~ s/#.*//;
        $mod =~ s/^\s*//;
        $mod =~ s/\s*$//;
        next if $mod eq '';

	$dbh->do("delete from defaults where setting_key='module_load_ok'");
	$dbh->do("insert into defaults (setting_key, value)" .
		 " values ('module_load_ok','no')");
	$dbh->commit;
        $self->exec_script({script => "$self->{source_dir}sql/modules/$mod",
                            log    => $args->{log} || "${log}_stdout",
			    errlog => $args->{errlog} || "${log}_stderr"
			   });
	my $sth = $dbh->prepare("select value='yes' from defaults" .
				" where setting_key='module_load_ok'");
	$sth->execute();
	my ($is_success) = $sth->fetchrow_array();
	$sth->finish();
	die "Module $mod failed to load"
	    if ! $is_success;
    }
    close (LOADORDER); ### return failure to execute the script?
}

=item $db->load_coa({country => '2-char-country-code',
                     chart => 'name-of-chart' })

Loads the chart of accounts (and possibly GIFI) as specified in
the chart of accounts file name given for the given 2-char (iso) country code.

=cut

sub load_coa {
    my ($self, $args) = @_;
    my $log = loader_log_filename();

    $self->exec_script(
        {script => "sql/coa/$args->{country}/chart/$args->{chart}", 
         logfile => $log });
    if (-f "sql/coa/$args->{coa_lc}/gifi/$args->{chart}"){
        $self->exec_script(
            {script => "sql/coa/$args->{coa_lc}/gifi/$args->{chart}",
             logfile => $log });
    }
}


=item $db->exec_script({script => 'path/to/file', log => 'path/to/log',
    errlog => 'path/to/stderr_output' })

Executes the script.  Returns 0 if successful, 1 if there are errors suggesting
that types are already created, and 2 if there are other errors.

=cut

sub exec_script {
    my ($self, $args) = @_;


    local %ENV;

    $ENV{PGUSER} = $self->{username};
    $ENV{PGPASSWORD} = $self->{password};
    $ENV{PGDATABASE} = $self->{company_name};
    $ENV{PGHOST} = $LedgerSMB::Sysconfig::db_host;
    $ENV{PGPORT} = $LedgerSMB::Sysconfig::db_port;

    open (LOG, '>>', $args->{log});
    if ($args->{errlog}) {
	open (PSQL, '-|', "psql -f $args->{script} 2>>$args->{errlog}");
    } else {
	open (PSQL, '-|', "psql -f $args->{script} 2>&1");
    }
    my $test = 0;
    while (my $line = <PSQL>){
        if ($line =~ /ERROR/){
            if (($test < 2) and ($line =~ /relation .* exists/)){
                $test = 1;
            } else {
                $test  =2;
            }
        }
        print LOG $line;
    }
    close(PSQL);
    if ($? != 0) {  # command return value non-zero indicates 'other error'
	$test = 2;
    }

    close(LOG);
    return $test;
}

=item $db->create_and_load();

Creates a database and then loads it.

=cut

sub create_and_load(){
    my ($self, $args) = @_;
    $self->create({
	log     => $args->{log},
	errlog  => $args->{errlog},
		  });
    $self->load_modules('LOADORDER', {
	log     => $args->{log},
	errlog  => $args->{errlog},
			});
}


=item $db->lsmb_info()

This routine retrieves general stats about the database and returns the output
as a hashref with the following key/value pairs:

=over

=item ar_rows 

=item ap_rows

=item gl_rows

=item acc_trans_rows

=item eca_rows

=item oe_rows

=item transactions_rows

=item users_rows

=back

=cut

sub lsmb_info {
    my ($self) = @_;
    my @tables = qw(ar ap gl acc_trans entity_credit_account oe transactions 
                    users);
    my $retval = {};
    my $qtemp = 'SELECT count(*) FROM TABLE';
    my $dbh = DBI->connect(
        qq|dbi:Pg:dbname="$self->{company_name}"|,  
         $self->{username}, $self->{password},
         { AutoCommit => 0, PrintError => $logger->is_warn(), }
    );
    for my $t (@tables) {
        my $query = $qtemp;
        $query =~ s/TABLE/$t/;
        my ($count) = $dbh->selectrow_array($query);
        my $key = $t;
        $key = 'eca' if $t eq 'entity_credit_account';
        $retval->{"${key}_count"} = $count;
    }
    $dbh->disconnect();
    return $retval;
}
    

=item $db->db_tests()

This routine runs general db tests.

TODO

=cut

#TODO
#
1;
