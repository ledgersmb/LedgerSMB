#!/usr/bin/perl
=head1 NAME

LedgerSMB::Database

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

our $VERSION = '1';

use LedgerSMB::Sysconfig;
use base('LedgerSMB');
use strict;

my $dbversions = {
    '1.2' => '1.2.0',
    '1.3dev' => '1.2.99',
    '1.3' => '1.3.0'
};

my $temp = $LedgerSMB::Sysconfig::tempdir;

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

=item get_info()

This routine connects to the database using DBI and attempts to determine if a 
related application is running in that database and if so what version.  
It returns a hashref with the following keys set:

=over

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
    use DBI;
    use LedgerSMB::Auth;
    my $self = shift @_;
    my $retval = { # defaults
         appname => undef,
         version => undef,
    full_version => undef,
          status => undef,
    };
    my $creds = LedgerSMB::Auth->get_credentials();
    my $dbh = DBI->connect(
        "dbi:Pg:dbname=$self->{company_name}", 
         "$creds->{login}", "$creds->{password}", { AutoCommit => 0 }
    );
    if (!$dbh){ # Could not connect, try to validate existance by connecting
                # to template1 and checking
           $dbh = DBI->connect(
                   "dbi:Pg:dbname=template1", 
                   "$creds->{login}", "$creds->{password}", { AutoCommit => 0 }
            );
           return $retval unless $dbh;
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
           return $retval;
   } else { # Got a db handle... try to find the version and app by a few
            # different means
       my $sth;
       # Legacy SL and LSMB
       $sth = $dbh->prepare('SELECT version FROM defaults');
       $sth->execute();
       if (my ($ref) = $sth->fetchrow_hashref('NAME_lc')){
           if ($ref->{version}){
               $retval->{appname} = 'ledgersmb';
               $retval->{version} = 'legacy';
               $retval->{full_version} = $ref->{version};
               return $retval;
           }
       }
       $dbh->rollback;
       # LedgerSMB 1.2 and above
       $sth = $dbh->prepare('SELECT value FROM defaults WHERE setting_key = ?');
       $sth->execute('version');
       if (my ($ref) = $sth->fetchrow_hashref('NAME_lc')){
           $retval->{full_version} = $ref->{value};
           $retval->{appname} = 'ledgersmb';
           if ($ref->{value} eq '1.2.0') {
                $retval->{version} = '1.2';
           } elsif ($ref->{value} eq '1.2.99'){
                $retval->{version} = '1.3dev';
           } elsif ($ref->{value} =~ /^1.3/){
                $retval->{version} = '1.3';
           }
           if ($retval->{version}){
              return $retval;
           }
       }
       $dbh->rollback;
       # SQL-Ledger 2.7-2.8 (fldname, fldvalue)
       $sth = $dbh->prepare('SELECT fldvalue FROM defaults WHERE fldname = ?');
       $sth->execute('version');
       if (my ($ref) = $sth->fetchrow_hashref('NAME_lc')){
            $retval->{appname} = 'sql-ledger';
            $retval->{full_version} = $ref->{fldname};
            $retval->{version} = $ref->{fldname};
            $retval->{version} =~ s/(\d+\.\d+).*/$1/g;
       }
       $dbh->rollback;
   }
   $dbh->disconnect;
   return $retval;
}

=item $db->create();

Creates a database and loads the contrib files.  This is done from template0, 
meaning nothing added to template1 will be found in this database.  This was 
necessary as a workaround for issues on some Debian systems.

Returns true if successful, false of not.  Creates a log called dblog in the 
temporary directory with all the output from the psql files.  

In DEBUG mode, will show all lines to STDERR.  In ERROR logging mode, will 
display only those lines containing the word ERROR.

=cut

sub create {
    my ($self) = @_;
    
    # We have to use template0 because of issues that Debian has with database 
    # encoding.  Apparently that causes problems for us, so template0 must be
    # used.
    my $rc = system("createdb -t template0 -E UTF8 > $temp/dblog");
    if ($rc) {
        return $rc;
    }

     my @contrib_scripts = qw(pg_trgm tsearch2 tablefunc);

     for my $contrib (@contrib_scripts){
         my $rc2;
         $rc2=system("psql -f $ENV{PG_CONTRIB_DIR}/$contrib.sql >> $temp/dblog_stdout 2>>$temp/dblog_stderr");
         $rc ||= $rc2
     }
     my $rc2 = system("psql -f $self->{source_dir}sql/Pg-database.sql >> $temp/dblog_stdout 2>>$temp/dblog_stderr");
     
     $rc ||= $rc2;

     # TODO Add logging of errors/notices

     return $rc;
}

=item $db->load_modules($loadorder)

Loads or reloads sql modules from $loadorder

=cut

sub load_modules {
    my ($self, $loadorder) = @_;
    open (LOADORDER, '<', "$self->{source_dir}sql/modules/$loadorder");
    for my $mod (<LOADORDER>){
        chomp($mod);
        $mod =~ s/#.*//;
        $mod =~ s/^\s*//;
        $mod =~ s/\s*$//;
        next if $mod eq '';
        $self->exec_script({script => "$self->{source_dir}sql/modules/$mod",
                            log    => "$temp/dblog"});

    }
    close (LOADORDER);
}

=item $db->exec_script({script => 'path/to/file', logfile => 'path/to/log'})

Executes the script.  Returns 0 if successful, 1 if there are errors suggesting
that types are already created, and 2 if there are other errors.

=cut

sub exec_script {
    my ($self, $args) = @_;
    open (LOG, '>>', $args->{log});
    open (PSQL, '-|', "psql -f $args->{script} 2>&1");
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
    close(LOG);
    return $test;
}

=item $db->create_and_load();

Creates a database and then loads it.

=cut

sub create_and_load(){
    my ($self) = @_;
    $self->create();
    $self->load_modules('LOADORDER');
}


=item $db->process_roles($rolefile);

Loads database Roles templates.

=cut

sub process_roles {
    my ($self, $rolefile) = @_;

    open (ROLES, '<', "sql/modules/$rolefile");
    open (TROLES, '>', "$temp/lsmb_roles.sql");

    for my $line (<ROLES>){
        $line =~ s/<\?lsmb dbname \?>/$self->{company_name}/;
        print TROLES $line;
    }

    close ROLES;
    close TROLES;

    $self->exec_script({script => "$temp/lsmb_roles.sql", 
                        log    => "$temp/dblog"});
}

=item $db->log_from_logfile();

Process log file and log relevant pieces via the log classes.

=cut

#TODO
#
1;
