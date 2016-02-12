#!/usr/bin/perl
=head1 NAME

LedgerSMB::Database - Provides the APIs for database creation and management.

=head1 SYNOPSIS

This module wraps both DBI and the PostgreSQL commandline tools.

  my $db = LedgerSMB::Database->new({
       company_name => 'mycompany',
       username => 'foo',
       password => 'foospassword'
  });

  $db->load_modules('LOADORDER');


=head1 COPYRIGHT

This module is copyright (C) 2007, the LedgerSMB Core Team and subject to
the GNU General Public License (GPL) version 2, or at your option, any later
version.  See the COPYRIGHT and LICENSE files for more information.

=cut

# Methods are documented inline.

package LedgerSMB::Database;

use strict;
use warnings;

use LedgerSMB::Auth;
use DBI;
use base qw(App::LedgerSMB::Admin::Database);

use LedgerSMB::Sysconfig;
use base('LedgerSMB');
use DateTime;
use Log::Log4perl;

Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);

our $VERSION = '1.1';

my $logger = Log::Log4perl->get_logger('LedgerSMB::Database');

my $temp = $LedgerSMB::Sysconfig::tempdir;

=head1 METHODS

=head2 loader_log_filename

This creates a log file for the specific upgrade attempt.

=cut

sub loader_log_filename {
    my $dt = DateTime->now();
    $dt =~ s/://g; # strip out disallowed Windows characters
    return $temp . "/dblog_${dt}_$$";
}


=head2 get_info()

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
    local $@;

    my $creds = LedgerSMB::Auth->get_credentials();
    $logger->trace("\$creds=".Data::Dumper::Dumper(\$creds));
    my $dbh = eval { $self->connect({PrintError => 0, AutoCommit => 0}) };
    if (!$dbh){ # Could not connect, try to validate existance by connecting
                # to postgres and checking
           $dbh = $self->new($self->export, (dbname => 'postgres'))
               ->connect({PrintError=>0});
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
       if (defined $sth && $sth->execute('version')) {
           my $ref = $sth->fetchrow_hashref('NAME_lc');
           $retval->{full_version} = $ref->{value};
           $retval->{appname} = 'ledgersmb';
           if ($ref->{value} eq '1.2.0') {
                $retval->{version} = '1.2';
           } elsif ($ref->{value} eq '1.2.99'){
                $retval->{version} = '1.3dev';
           } elsif ($ref->{value} =~ /^1\.3\.999/ or $ref->{value} =~ /^1.4/){
                $retval->{version} = "1.4";
           } elsif ($ref->{value} =~ /^1\.3/){
                $retval->{version} = '1.3';
           } elsif ($ref->{value} =~ /^1\.5\./){
                $retval->{version} = '1.5';
           }
           $dbh->rollback();
           return $retval;
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

=head2 $db->copy('new_name')

Copies the existing database to a new name.

=cut

sub copy {
    my ($self, $new_name) = @_;
    $self->new($self->export, (dbname => $new_name)
              )->create(copy_of => $self->dbname);
}

=head2 $db->load_base_schema()

Loads the base schema definition file Pg-database.sql.

=cut

sub load_base_schema {
    my ($self, $args) = @_;
    my $success;
    my $log = loader_log_filename();

    $self->{source_dir} = './'
        unless $self->{source_dir};

    $self->run_file(

        file       => "$self->{source_dir}sql/Pg-database.sql",
        log_stdout => ($args->{log} || "${log}_stdout"),
        log_stderr => ($args->{errlog} || "${log}_stderr")
    );

    if (opendir(LOADDIR, 'sql/on_load')) {
        while (my $fname = readdir(LOADDIR)) {
            $self->run_file(
                file       => "$self->{source_dir}sql/on_load/$fname",
                log_stdout => ($args->{log} || "${log}_stdout"),
                log_stderr => ($args->{errlog} || "${log}_stderr")
                ) if -f "sql/on_load/$fname";
        }
        closedir(LOADDIR);
    }
    return 1;

}


=head2 $db->load_modules($loadorder)

Loads or reloads sql modules from $loadorder

=cut

sub load_modules {
    my ($self, $loadorder, $args) = @_;
    my $log = loader_log_filename();

    $self->{source_dir} ||= '';
    open (LOADORDER, '<', "$self->{source_dir}sql/modules/$loadorder");
    for my $mod (<LOADORDER>) {
        chomp($mod);
        $mod =~ s/(\s+|#.*)//g;
        next unless $mod;
        no warnings 'uninitialized';
        $self->run_file(
                       file       => "$self->{source_dir}sql/modules/$mod",
                       log_stdout  => $args->{log} || "${log}_stdout",
               log_stderr  => $args->{errlog} || "${log}_stderr"
        );

    }
    close (LOADORDER); ### return failure to execute the script?
    return 1;
}

=head2 $db->load_coa({country => '2-char-country-code',
                     chart => 'name-of-chart' })

Loads the chart of accounts (and possibly GIFI) as specified in
the chart of accounts file name given for the given 2-char (iso) country code.

=cut

sub load_coa {
    my ($self, $args) = @_;
    my $log = loader_log_filename();

    $self->run_file (
        file         => "sql/coa/$args->{country}/chart/$args->{chart}",
        log_stdout   => $log,
        log_stderr   => $log,
        );
    if (defined $args->{coa_lc}
        && -f "sql/coa/$args->{coa_lc}/gifi/$args->{chart}"){
        $self->run_file(
            file        => "sql/coa/$args->{coa_lc}/gifi/$args->{chart}",
            log_stdout  => $log,
            log_stderr  => $log,
            );
    }
}


=head2 $db->create_and_load();

Creates a database and then loads it.

=cut

sub create_and_load(){
    my ($self, $args) = @_;
    $self->create;
    $self->load_base_schema({
    log_stdout     => $args->{log},
    errlog  => $args->{errlog},
          });
    $self->load_modules('LOADORDER', {
    log     => $args->{log},
    errlog  => $args->{errlog},
            });
}


=head2 $db->upgrade_modules($loadorder, $version)

This routine upgrades modules as required with a patch release upgrade.

=cut

sub upgrade_modules {
    my ($self, $loadorder, $version) = @_;

    my $temp = $self->loader_log_filename();

    $self->load_modules($loadorder, {
    log     => $temp . "_stdout",
    errlog  => $temp . "_stderr"
                })
        or die "Modules failed to be loaded.";

    my $dbh = $self->connect({PrintError=>0});
    my $sth = $dbh->prepare(
          "UPDATE defaults SET value = ? WHERE setting_key = 'version'"
    );
    $sth->execute($LedgerSMB::VERSION)
        or die "Version not updated.";

    return 1;
}

1;
