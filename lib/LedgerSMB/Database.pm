
package LedgerSMB::Database;

=head1 NAME

LedgerSMB::Database - APIs for database creation and management.

=head1 SYNOPSIS

This module wraps both DBI and the PostgreSQL commandline tools.

  my $db = LedgerSMB::Database->new(
       connect_data => {
          user     => 'foo',
          dbname   => 'mycompany',
          password => 'foospassword',
       },
       schema   => 'non_public',
  );

  $db->load_modules('LOADORDER');

=head1 DESCRIPTION

LedgerSMB::Database provides methods for database creation and management
as well as database version detection (for upgrades) and more.

For the lower level database management routines, it inherits from
C<PGObject::Util::DBAdmin>.

=cut


use strict;
use warnings;

use Carp;
use DateTime;
use DBD::Pg;
use DBI;
use File::Spec;
use File::Temp;
use JSON::PP;
use PGObject::Util::DBAdmin v1.6.2;
use Scope::Guard;
use XML::LibXML;
use XML::LibXML::XPathContext;

use Moose;
use namespace::autoclean;
extends 'PGObject::Util::DBAdmin';

use LedgerSMB::Database::Loadorder;


our $VERSION = '1.2';



around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    if ($args{schema} && $args{connect_data}) {
        $args{connect_data}->{options} //= '';

        my $enc_schema = ($args{schema} =~ s/['\\]/$1$1/gr);
        $args{connect_data}->{options} .= qq{-c search_path=$enc_schema};
    }
    elsif ($args{schema}) {
        die q{Missing 'connect_data' arg; expected to set default schema};
    }
    return $class->$orig( %args );
};

=head1 PROPERTIES

=head2 source_dir

Indicates the path to the directory which holds the 'Pg-database.sql' file
and the associated changes, charts and gifi files.

The default value is relative to the current directory, which is assumed
to be the root of the LedgerSMB source tree.

=cut

has source_dir => (is => 'ro', default => './sql');

=head2 data_dir

Indicates the path to the directory which holds the 'initial-data.xml' file
containing the reference and static data to be loaded into the base schema.

=cut

has data_dir => (is => 'ro', default => './locale');

=head2 default_connect_options

=cut

has default_connect_options => (is => 'rw',
                                default => sub {
                                    {
                                        PrintError          => 0,
                                        AutoCommit          => 0,
                                        AutoInactiveDestroy => 1,
                                        pg_enable_utf8      => 1,
                                        pg_server_prepare   => 0,
                                    }
                                });

=head2 schema

=cut

has schema => (is => 'ro', default => 'public');

=head2 upgrade_run_id

Contains the C<run_id> of the upgrade after invoking C<apply_changes>.

=cut

has upgrade_run_id => (is => 'rw');


=head1 METHODS

=head2 loader_log_filename

This creates a log file for the specific upgrade attempt.

=cut

sub loader_log_filename {
    my $dt = DateTime->now();
    $dt =~ s/://g; # strip out disallowed Windows characters
    return File::Spec->tmpdir . "/dblog_${dt}_$$";
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


sub _stringify_db_ver {
    my ($ver) = @_;
    $ver //= 0;
    return join('.',
                reverse
                map {
                    my $t = $ver;
                    $ver = int($ver/100);
                    ($t % 100); } 1..3);  ## no critic (ProhibitMagicNumbers) sniff
}

sub _set_system_info {
    my ($dbh, $rv) = @_;

    my ($server_encoding) =
        @{${$dbh->selectall_arrayref('SHOW SERVER_ENCODING;')}[0]};
    my ($client_encoding) =
        @{${$dbh->selectall_arrayref('SHOW CLIENT_ENCODING;')}[0]};

    my %utf8_mode_desc = (
        '-1' => 'Auto-detect',
        '0'  => 'Never',
        '1'  => 'Always',
        ''   => '<unspecified>', # happens when testing with DBD::Mock
        );
    $rv->{system_info} = {
        'PostgreSQL (client)' => _stringify_db_ver($dbh->{pg_lib_version}),
        'PostgreSQL (server)' => _stringify_db_ver($dbh->{pg_server_version}),
        'DBD::Pg (version)' => $DBD::Pg::VERSION->stringify,
        'DBI (version)' => $DBI::VERSION,
         'DBD::Pg UTF-8 mode' => $utf8_mode_desc{$dbh->{pg_enable_utf8} // ''},
        'PostgreSQL server encoding' => $server_encoding,
        'PostgreSQL client encoding' => $client_encoding,
    };

    return;
}


sub get_info {
    my $self = shift @_;
    my $authdb = shift @_;
    my $retval = { # defaults
         appname => undef,
         version => undef,
    full_version => undef,
          status => undef,
    };
    local $@ = undef;

    my $dbh = eval { $self->connect({PrintError => 0, AutoCommit => 0}) };
    if ( !$dbh ) {
        # Could not connect, try to validate existance by connecting
        # to postgres and checking

        $self->logger->debug(
            "Can't connect to database; falling through to $authdb"
            );
        $dbh = $self->new($self->export, (dbname => $authdb))
            ->connect({PrintError=>0});
        return $retval unless $dbh;
        _set_system_info($dbh, $retval);

        # don't assign to App_State::DBH, since we're a fallback connection,
        #  not one to the company database

        my $sth = $dbh->prepare(
            'select count(*) = 1 from pg_database where datname = ?'
            );
        $sth->execute($self->{dbname});
        my ($exists) = $sth->fetchrow_array();
        if ($exists){
            $retval->{status} = 'exists';
        } else {
            $retval->{status} = 'does not exist';
        }
        $sth = $dbh->prepare('SELECT SESSION_USER');
        $sth->execute;
        $retval->{username} = $sth->fetchrow_array();
        $sth->finish();
        $dbh->disconnect();

        return $retval;
    }
    else {
        # Got a db handle... try to find the version and app by a few
        # different means
       $retval->{status} = 'exists';
       _set_system_info($dbh, $retval);

       my $sth = $dbh->prepare('SELECT SESSION_USER');
       $sth->execute;
       $retval->{username} = $sth->fetchrow_array();
       $sth->finish();

       # Is there a chance this is an SL or LSMB legacy version?
       # (ie. is there a VERSION column to query in the DEFAULTS table?
       $sth = $dbh->prepare(
       q{select count(*)=1
            from pg_attribute attr
            join pg_class cls
              on cls.oid = attr.attrelid
            join pg_namespace nsp
              on nsp.oid = cls.relnamespace
           where cls.relname = 'defaults'
             and attr.attname='version'
                 and nsp.nspname = 'public'
             }
       );
       $sth->execute();
       my ($have_version_column) = $sth->fetchrow_array();
       $sth->finish();

       if ($have_version_column) {
           # Legacy SL and LSMB
           $self->logger->trace( 'Legacy SL or LSMB database' );
           $sth = $dbh->prepare(
               'SELECT version FROM defaults'
               );
           #avoid DBD::Pg::st fetchrow_hashref failed: no statement executing
           my $rv=$sth->execute();
           if (defined($rv)) {
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
                $retval->{version} = '1.4';
           } elsif ($ref->{value} =~ /^(1\.\d+)/){
                $retval->{version} = $1;
           }
           $dbh->rollback();
           return $retval;
       }
       $dbh->rollback;
       # SQL-Ledger 2.7-2.8 (fldname, fldvalue)
       $sth = $dbh->prepare('SELECT fldvalue FROM defaults WHERE fldname = ?');
       $sth->execute('version');
       if (my $ref = $sth->fetchrow_hashref('NAME_lc')){
            $self->logger->trace( 'SL' );
            $retval->{appname} = 'sql-ledger';
            $retval->{full_version} = $ref->{fldvalue};
            $retval->{version} = $ref->{fldvalue};
            $retval->{version} =~ s/(\d+\.\d+).*/$1/g;
       } else {
            my $schema = $self->schema;
            $self->logger->debug( "SL; possibly no version set; $schema" );
            $retval->{appname} = 'unknown';
       }
       $dbh->rollback;
   }
    return $retval;
}

=head2 connect($options)

Calls C<PGObject::Util::DBAdmin>'s C<connect> method with C<$options>,
merged with C<default_options> attribute's value.

Upon succesfull return, sets the connection's C<client_min_messages>
to C<warning>.

This routine claims the C<private_LedgerSMB> slot in the database handle
for storage of LedgerSMB internal data.

=cut

sub connect {
    my $self    = shift;
    my $options = shift // {};

    my $dbh = $self->SUPER::connect(
        {
            ( %{ $self->default_connect_options }, %{ $options }, )
        })
        or return undef;

    $dbh->{private_LedgerSMB} = {
        schema    =>  $self->schema,
    };
    $dbh->do(q{set client_min_messages = 'warning'});

    return $dbh;
}

=head2 require_version($dbh, $version)

Checks for a setting called 'ignore_version' and returns immediately if this is
set and true.

Otherwise, requires a specific version (exactly).  Dies if doesn't match.

The ignore_version setting is intended to be temporarily set during
zero-downtime upgrades.

=cut

sub require_version {
    my ($self, $dbh, $expected_version) = @_;


    my $settings = $dbh->selectall_hashref(
        q{SELECT * FROM defaults
           WHERE setting_key IN ('ignore_version', 'version')},
        'setting_key')
        or die $dbh->errstr;

    return if ($settings->{ignore_version}
               and $settings->{ignore_version}->{value});

    if ($expected_version eq $settings->{version}->{value}) {
        return '';
    }
    else {
        return $settings->{version}->{value};
    }
}

=head2 $db->copy('new_name')

Copies the existing database to a new name.

=cut

sub copy {
    my ($self, $new_name) = @_;
    my $new_db = $self->new($self->export, (dbname => $new_name));
    my $rc = $new_db->create(copy_of => $self->dbname);

    $new_db->connect({ AutoCommit => 1 })->do(
        q|SELECT setting__set('role_prefix',
                              coalesce((setting_get('role_prefix')).value,?))|,
        undef, 'lsmb_' . $self->dbname . '__');

    return $rc;
}

=head2 $db->load_base_schema([ upto_tag => $tag, log => $path, errlog => $path ])

Loads the base schema definition file Pg-database.sql and the
database schema upgrade scripts.

When an C<upto_tag> argument is provided, only schema changes upto a specific
tag in the LOADORDER file will be applied (the main use-case being migrations).

=cut

sub _load_contact_classes {
    my ($self, $dbh, $xpc) = @_;
    my @nodes = $xpc->findnodes( './x:contact-classes/x:class' );
    return unless @nodes;

    my $sth = $dbh->prepare(
        q|INSERT INTO contact_class (class) VALUES (?)|
        ) or die $dbh->errstr;
    for my $node (@nodes) {
        my $atts = $node->attributes;
        my @vals = (
            $atts->getNamedItem( 'name' )->nodeValue,
            );
        $self->logger->tracef( 'Inserting contact class "%s"', @vals );
        $sth->execute( @vals )
            or die $sth->errstr;
    }
}

sub _load_countries {
    my ($self, $dbh, $xpc) = @_;
    my @nodes = $xpc->findnodes( './x:countries/x:country' );
    return unless @nodes;

    my $sth = $dbh->prepare(
        q|INSERT INTO country (short_name, name) VALUES (?, ?)|
        ) or die $dbh->errstr;
    for my $node (@nodes) {
        my $atts = $node->attributes;
        my @vals = (
            $atts->getNamedItem( 'code' )->nodeValue,
            $atts->getNamedItem( 'description' )->nodeValue
            );
        $self->logger->tracef( 'Inserting country code "%s"/"%s"', @vals );
        $sth->execute( @vals )
            or die $sth->errstr;
    }
}

sub _load_languages {
    my ($self, $dbh, $xpc) = @_;
    my @nodes = $xpc->findnodes( './x:languages/x:language' );
    return unless @nodes;

    my $sth = $dbh->prepare(
        q|INSERT INTO language (code, description) VALUES (?, ?)|
        ) or die $dbh->errstr;
    for my $node (@nodes) {
        my $atts = $node->attributes;
        my @vals = (
            $atts->getNamedItem( 'code' )->nodeValue,
            $atts->getNamedItem( 'description' )->nodeValue
            );
        $self->logger->tracef( 'Inserting language code "%s"/"%s"', @vals );
        $sth->execute( @vals )
            or die $sth->errstr;
    }
}

sub _load_salutations {
    my ($self, $dbh, $xpc) = @_;
    my @nodes = $xpc->findnodes( './x:salutations/x:salutation' );
    return unless @nodes;

    my $sth = $dbh->prepare(
        q|INSERT INTO salutation (salutation) VALUES (?)|
        ) or die $dbh->errstr;
    for my $node (@nodes) {
        my $atts = $node->attributes;
        my @vals = (
            $atts->getNamedItem( 'text' )->nodeValue,
            );
        $self->logger->tracef( 'Inserting salutation "%s"', @vals );
        $sth->execute( @vals )
            or die $sth->errstr;
    }
}

sub load_base_schema {
    my ($self, %args) = @_;

    my $dbh = $self->connect({ AutoCommit => 1 });
    $dbh->do(
        q|CREATE SCHEMA IF NOT EXISTS | . $dbh->quote_identifier($self->schema)
        )
        or die $dbh->errstr;
    $self->logger->infof('Created schema "%s"', $self->schema);
    $self->run_file(
        file       => "$self->{source_dir}/Pg-database.sql",
        vars       => {
            lsmb_schema => $self->schema,
        },
    );
    my $sth = $dbh->prepare(
        q|select true
            from pg_class cls
            join pg_namespace nsp
                 on nsp.oid = cls.relnamespace
           where cls.relname = 'defaults'
                 and nsp.nspname = ?
             |);
    $sth->execute($self->schema);
    my ($success) = $sth->fetchrow_array();
    $sth->finish();

    die 'Base schema failed to load'
        if ! $success;

    $dbh->disconnect;
    $dbh = $self->connect();
    my $guard = Scope::Guard->new(sub { $dbh->disconnect if $dbh; });
    my $initial = File::Spec->catfile( $self->data_dir, 'initial-data.xml' );
    open( my $fh, '<:bytes', $initial )
        or croak "Failed to open schema seed data file ($initial): $!";
    my $doc = XML::LibXML->load_xml( IO => $fh );
    my $xpc = XML::LibXML::XPathContext->new( $doc->documentElement );
    $xpc->registerNs( 'x', 'http://ledgersmb.org/xml-schemas/initial-data' );
    close( $fh ) or carp "Failed to close seed data file ($initial): $!";
    $self->_load_contact_classes( $dbh, $xpc );
    $self->_load_countries( $dbh, $xpc );
    $self->_load_languages( $dbh, $xpc );
    $self->_load_salutations( $dbh, $xpc );
    $dbh->commit;
    $dbh->disconnect;
    $dbh = undef;

    if (opendir(LOADDIR, "$self->{source_dir}/on_load")) {
        while (my $fname = readdir(LOADDIR)) {
            $self->run_file(
                file       => "$self->{source_dir}/on_load/$fname",
                ) if -f "$self->{source_dir}/on_load/$fname";
        }
        closedir(LOADDIR);
    }
    $self->apply_changes(upto_tag => $args{upto_tag});
    return 1;
}


=head2 $db->load_modules($loadorder)

Loads or reloads sql modules from $loadorder

Returns true when successful, dies upon error.

=cut

sub _load_module {
    my ($self, $dbh, $module) = @_;

    $dbh->do(q{delete from defaults where setting_key = 'module_load_ok'})
        or die $dbh->errstr;
    $dbh->do(q{insert into defaults (setting_key, value)
             values ('module_load_ok', 'no') })
        or die $dbh->errstr;

    my ($success, $stdout, $stderr) = $self->run_file_with_logs(
        file => "$self->{source_dir}/modules/$module",
        vars => {
            lsmb_schema => $self->schema,
        },
        );
    $success or die $stderr;

    my $sth = $dbh->prepare(q{select value from defaults
                            where setting_key = 'module_load_ok'});
    $sth->execute;
    my ($value) = $sth->fetchrow_array();
    $sth->finish;
    die "Module $module failed to load"
        if not $value or $value ne 'yes';
}


sub load_modules {
    my ($self, $loadorder, $args) = @_;

    my $filename = "$self->{source_dir}/modules/$loadorder";
    open my $fh, '<', $filename
        or die "Failed to open $filename : $!";

    my $dbh = $self->connect({ AutoCommit => 1 });
    for my $mod (<$fh>) {
        chomp($mod);
        $mod =~ s/(\s+|#.*)//g;
        next unless $mod;

        $self->_load_module($dbh, $mod);
    }
    close $fh or die "Cannot close $filename";
    return 1;
}

=head2 $db->load_sic({ country => '2-char-country-code',
                       sic => 'name-of-sic' })

Loads the SIC table as specified in the chart of accounts file name given
for the given 2-char (iso) country code.

=cut

sub load_sic {
    my ($self, $args) = @_;

    if (defined $args->{sic}
        && -f "$self->{source_dir}/coa/$args->{country}/sic/$args->{sic}"){
        $self->run_file(
            file => "$self->{source_dir}/coa/$args->{country}/sic/$args->{sic}",
            );
    }
    return;
}


=head2 $db->create_and_load();

Creates a database and then loads it.

Returns true when successful, dies on error.

=cut

sub create_and_load {
    my ($self, $args) = @_;
    $self->logger->info('Creating database');
    $self->create;
    $self->logger->info('Loading schema into ' . $self->schema);
    $self->load_base_schema(
        log_stdout     => $args->{log},
        errlog  => $args->{errlog},
        );
    $self->logger->info('Applying schema changes');
    $self->apply_changes();
    $self->logger->info('Loading LedgerSMB application database modules');
    return $self->load_modules('LOADORDER', {
    log     => $args->{log},
    errlog  => $args->{errlog},
            });
}


=head2 $db->upgrade_modules($loadorder, $version)

This routine upgrades modules as required with a patch release upgrade.

Be sure to run C<apply_changes> before this method to ensure the
schema the modules are upgraded into is in the correct state.

=cut

sub upgrade_modules {
    my ($self, $loadorder, $version) = @_;

    my $temp = $self->loader_log_filename();

    $self->load_modules($loadorder, {
    log     => $temp . '_stdout',
    errlog  => $temp . '_stderr'
                })
        or die 'Modules failed to be loaded.';

    my $dbh = $self->connect({PrintError=>0, AutoCommit=>1});
    my $sth = $dbh->prepare(
          q{UPDATE defaults SET value = ? WHERE setting_key = 'version'}
    );
    $sth->execute($version)
        or die 'Version not updated.';
    $dbh->disconnect;

    return 1;
}

=head2 apply_changes( [upto_tag => $tag], [checks => $boolean], $run_id => $uuid_str )

Runs fixes if they have not been applied, optionally up to
a specific tagged point in the LOADORDER file; supply C<$run_id> if
this is a continued invocation of a prior, failed upgrade run. In case
no C<run_id> is provided, a new UUID will be generated and assigned to
C<upgrade_run_id>.

Runs schema upgrade checks when the value of C<checks> is true.

Returns the return status of C<LedgerSMB::Database::Loadorder->apply_changes>.

=cut

sub apply_changes {
    my ($self, %args) = @_;
    my $dbh = $self->connect({
        PrintError=>0,
        AutoCommit => 0,
        pg_server_prepare => 0});
    $dbh->do(q{set client_min_messages = 'warning'});
    my $loadorder =
        LedgerSMB::Database::Loadorder->new(
            "$self->{source_dir}/changes/LOADORDER",
            upto_tag => $args{upto_tag},
            run_id => $args{run_id});
    if ($loadorder->init_if_needed($dbh)) {
        $dbh->commit;
    }
    $self->logger->debug('Applying database schema upgrades');
    my $rv = $loadorder->apply_all($dbh, checks => $args{checks});
    $self->upgrade_run_id( $loadorder->run_id );
    $dbh->disconnect;

    return $rv;
}

=head2 list_changes( [run_id => $uuid] );

List all applied database schema patches as triggered by C<apply_changes>.

Returns an arrayref of hashes with the following keys:

=over

=item * run_id

=item * sha

=item * path

=item * last_updated

=item * messages

=back

=cut

my $json = JSON::PP->new;

sub list_changes {
    my ($self, %args) = @_;
    my $run_id = $args{run_id};

    my $dbh = $self->connect({
        PrintError => 0,
        AutoCommit => 0,
        pg_server_prepare => 0});
    my $changes;
    if ($run_id) {
        $changes = $dbh->selectall_arrayref(
            q{select * from db_patches where run_id = ? order by last_updated},
            { Slice => {} },
            $run_id);
    }
    else {
        $changes = $dbh->selectall_arrayref(
            q{select * from db_patches order by last_updated},
            { Slice => {} });
    }
    $self->logger->info($dbh->errstr) if $dbh->err;
    return undef if $dbh->err;

    $_->{messages} = $json->decode( $_->{messages} )
        for (grep { $_->{messages} } ($changes // [])->@*);
    return $changes;
}

=head2 stats

Returns a hashref of table names to rows.  The following tables are counted:

=over

=item ar

=item ap

=item gl

=item oe

=item acc_trans

=item users

=item entity_credit_account

=item entity

=back

=cut

my @tables = qw(ar ap gl users entity_credit_account entity acc_trans oe parts orderitems invoice);

sub stats {
    my ($self) = @_;
    my $dbh = $self->connect;
    my $results;

    $results->{$_->{table}} = $_->{count}
    for map {
       my $sth = $dbh->prepare($_->{query});
       $sth->execute;
       my ($count) = $sth->fetchrow_array;
       { table => $_->{table}, count => $count };
    } map {
       my $qt = 'SELECT COUNT(*) FROM __TABLE__';
       my $id = $dbh->quote_identifier($_);
       $qt =~ s/__TABLE__/$id/;
       { table => $_, query => $qt };
    } @tables;

    $dbh->disconnect;
    return $results;
}

=head2 run_file_with_logs(file => $file) 

Wrapper around run_file() method, which does not die on error and returns
the captured stdout and stderr output.

Returns an array of three elements comprising:

   * success, false if an error occurred, true otherwise
   * stdout output log
   * stderr output log

=cut

sub run_file_with_logs {

    my $self = shift;
    my @args = @_;
    my $stdout_fh = File::Temp->new;
    my $stderr_fh = File::Temp->new;

    # ->run_file croaks on error, but we trap that condition
    # so that we can carry on and do something useful with
    # its output logs.
    local ($!, $@) = (undef, undef);
    my $success = eval {
        $self->run_file(
            @args,
            stdout_log => $stdout_fh->filename,
            errlog => $stderr_fh->filename,
        ) and return 1;
    };

    # Slurp contents of log files
    local $/ = undef;
    my $stdout = <$stdout_fh>;
    my $stderr = <$stderr_fh>;

    return ($success, $stdout, $stderr);
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
