
package LedgerSMB::Database::Upgrade;

=head1 NAME

LedgerSMB::Database::Upgrade - upgrade routines factored out of setup.pm

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use LedgerSMB::Upgrade_Tests;

use File::Temp;
use List::Util qw( first );
use Scope::Guard qw( guard );
use Template;
use Version::Compare;

use Moose;
use namespace::autoclean;

=head1 ATTRIBUTES

=head2 database

=cut

has database => (is => 'ro', required => 1);

=head2 type

=cut

has type => (is => 'ro', required => 1);

=head1 METHODS

=head2 applicable_tests

Returns all pre-upgrade tests that apply to the application and version
of the database being upgraded/migrated.

=cut

sub _upgrade_test_is_applicable {
    my ($dbinfo, $test) = @_;

    return (($test->min_version le $dbinfo->{version})
            && ($test->max_version ge $dbinfo->{version})
            && ($test->appname eq $dbinfo->{appname}));
}

sub applicable_tests {
    my $self = shift;
    my $dbinfo = $self->database->get_info;

    my @tests = (
        grep { _upgrade_test_is_applicable($dbinfo, $_) }
        LedgerSMB::Upgrade_Tests->get_tests
        );
    my %consistency = map { $_->name => 1 } @tests;

    if (scalar @tests != scalar keys %consistency) {
        die 'Inconsistent state fixing data: multiple applicable tests '
            . 'with the same name';
    }

    return @tests;
}

=head2 applicable_test_by_name($name)

Retrieves exactly one test from the set of applicable tests matching
C<$name>. When no matching test is found, C<undef> is returned.

=cut

sub applicable_test_by_name {
    my ($self, $name) = @_;

    return first { $_->name eq $name } ($self->applicable_tests);
}

=head2 run_tests($failure_cb)

Runs the applicable upgrade tests, until the first failing test,
calling C<$failure_cb> on that test.

Returns false-ish when a test failed; true-ish when all tests ran and
no conflicting data was identified (=failed).

=cut

sub run_tests {
    my ($self, $cb) = @_;

    my $dbh = $self->database->connect({ PrintError => 1, AutoCommit => 0});
    my $guard = guard {
        $dbh->rollback;
        $dbh->disconnect;
    };
    for my $test ($self->applicable_tests) {
        if (not $test->run($dbh, $cb)) {
            return 0;
        }
    }
    $dbh->commit;
    return 1;
}

=head2 run_upgrade_script($vars)

Runs the upgrade script from the C<sql/upgrade/> directory.

C<$vars> is a hashref to parameters required to run the upgrade script.

=cut

my %migration_schema = (
    'sql-ledger/2.8' => 'sl28',
    'sql-ledger/3.0' => 'sl30',
    'sql-ledger/3.2' => 'sl32',
    'ledgersmb/1.2'  => 'lsmb12',
    'ledgersmb/1.3'  => 'lsmb13',
    );

my %migration_script = (
    'sql-ledger/2.8' => 'sl2.8',
    'sql-ledger/3.0' => 'sl3.0',
    'sql-ledger/3.2' => undef,
    'ledgersmb/1.2'  => '1.2-1.5',
    'ledgersmb/1.3'  => '1.3-1.5',
    );

sub run_upgrade_script {
    my ($self, $vars) = @_;
    my $src_schema = $migration_schema{$self->type};
    my $template   = $migration_script{$self->type};

    my $dbh = $self->database->connect({ PrintError => 0, AutoCommit => 0 });
    my $temp = $self->database->loader_log_filename();

    my $guard = Scope::Guard->new(
        sub {
            $dbh->rollback;
            $dbh->do(
                qq{DROP SCHEMA $LedgerSMB::Sysconfig::db_namespace CASCADE;
                   ALTER SCHEMA $src_schema
                         RENAME TO $LedgerSMB::Sysconfig::db_namespace});
            $dbh->commit;
        });

    $dbh->do("ALTER SCHEMA  $LedgerSMB::Sysconfig::db_namespace
                    RENAME TO $src_schema;
              CREATE SCHEMA $LedgerSMB::Sysconfig::db_namespace")
    or die "Failed to create schema $LedgerSMB::Sysconfig::db_namespace (" . $dbh->errstr . ')';
    $dbh->commit;

    $self->database->load_base_schema(
        log     => $temp . '_stdout',
        errlog  => $temp . '_stderr',
        upto_tag=> 'migration-target'
        );

    $dbh->do(q(
       INSERT INTO defaults (setting_key, value)
                     VALUES ('migration_ok', 'no')
     ));
    $dbh->do(qq(
       INSERT INTO defaults (setting_key, value)
                     VALUES ('migration_src_schema', '$src_schema')
     ));
    $dbh->commit;


    my $engine = Template->new(
        INCLUDE_PATH => [ 'sql/upgrade' ],
        ENCODING     => 'utf8',
        TRIM         => 1,
        );

    my $tempfile = File::Temp->new();
    $engine->process("$template.sql",
                     {
                         VERSION_COMPARE => \&Version::Compare::version_compare,
                         %$vars
                     },
                     $tempfile)
       or die q{Failed to create upgrade instructions to be sent to 'psql': }
               . $engine->error;
    close $tempfile
       or warn 'Failed to close temporary file';

    $self->database->run_file(
        file => $tempfile->filename,
        stdout_log => $temp . '_stdout',
        errlog => $temp . '_stderr'
        );

    my $sth = $dbh->prepare(q(select value='yes'
                                 from defaults
                                where setting_key='migration_ok'));
    $sth->execute();

    my ($success) = $sth->fetchrow_array();
    $sth->finish();

    if (not $success) {
        die "Upgrade failed; logs can be found in
             ${temp}_stdout and ${temp}_stderr";
    }

    $dbh->do(q{delete from defaults where setting_key like 'migration_%'});
    $dbh->commit;

    $guard->dismiss;
    return;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
