#!perl

=head1 UNIT TESTS FOR

LedgerSMB::Database::Upgrade

=cut

use Test2::V0;
use Test2::Tools::Compare qw{bag item end};
use Carp::Always;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

use LedgerSMB::Database::Upgrade;
use LedgerSMB::Sysconfig;

use DBI;
use DBD::Mock::Session;

LedgerSMB::Sysconfig->initialize();

package LedgerSMB::Test::Database {
    use Carp;
    use DBI;

    use LedgerSMB::Database;
    use Moose;
    use namespace::autoclean;
    extends 'LedgerSMB::Database';

    has sessions => (is => 'ro', default => sub { [] });

    sub connect {
        my $self = shift;
        my $mock_args = shift;
        my $dbh = DBI->connect('dbi:Mock:','','');
        for my $key (keys $mock_args->%*) {
            $dbh->{$key} = $mock_args->{$key};
        }
        my $session = shift $self->sessions->@*;
        croak "Too few sessions provided" unless $session;
        $dbh->{mock_session} = $session;
        return $dbh;
    }

    sub run_file {}
    sub load_base_schema {}

    __PACKAGE__->meta->make_immutable();
}


my $upgrade =
    LedgerSMB::Database::Upgrade->new(
        type     => 'ledgersmb/1.2',
        database => LedgerSMB::Test::Database->new(
            sessions => [
                DBD::Mock::Session->new(
                    main => (
                        {
                            statement => q{select id, accno, description
                               from chart where link = 'AR'
                                and charttype = 'A'},
                            results   => [[]],
                        },
                        {
                            statement => q{select id, accno, description
                               from chart where link = 'AP'
                                and charttype = 'A'},
                            results   => [[]],
                        },
                    ),
                ),
                DBD::Mock::Session->new(
                    getinfo => (
                        {
                            statement => q{SHOW SERVER_ENCODING;},
                            results   => [['encoding'], ['utf8']],
                        },
                        {
                            statement => q{SHOW CLIENT_ENCODING;},
                            results   => [['encoding'], ['utf8']],
                        },
                        {
                            statement => q{SELECT SESSION_USER},
                            results   => [['SESSION_USER'], ['postgres']],
                        },
                        {
                            statement => q{select count(*)=1
            from pg_attribute attr
            join pg_class cls
              on cls.oid = attr.attrelid
            join pg_namespace nsp
              on nsp.oid = cls.relnamespace
           where cls.relname = 'defaults'
             and attr.attname='version'
                 and nsp.nspname = 'public'
             },
                            results   => [['column'], [0]],
                        },
                        {
                            statement => q{SELECT value FROM defaults WHERE setting_key = ?},
                            results   => [['value'], ['1.2.0']],
                        },
                    ),
                ),
                DBD::Mock::Session->new(
                    getinfo => (
                        {
                            statement => q{SHOW SERVER_ENCODING;},
                            results   => [['encoding'], ['utf8']],
                        },
                        {
                            statement => q{SHOW CLIENT_ENCODING;},
                            results   => [['encoding'], ['utf8']],
                        },
                        {
                            statement => q{SELECT SESSION_USER},
                            results   => [['SESSION_USER'], ['postgres']],
                        },
                        {
                            statement => q{select count(*)=1
            from pg_attribute attr
            join pg_class cls
              on cls.oid = attr.attrelid
            join pg_namespace nsp
              on nsp.oid = cls.relnamespace
           where cls.relname = 'defaults'
             and attr.attname='version'
                 and nsp.nspname = 'public'
             },
                            results   => [['column'], [0]],
                        },
                        {
                            statement => q{SELECT value FROM defaults WHERE setting_key = ?},
                            results   => [['value'], ['1.2.0']],
                        },
                    ),
                ),
                DBD::Mock::Session->new(
                    upgrade => (
                        {
                            statement => q{ALTER SCHEMA public RENAME TO lsmb12;
              CREATE SCHEMA public;
              GRANT ALL ON SCHEMA public TO PUBLIC},
                            results   => [[]],
                        },
                        {
                            statement => q{select value='yes'
                                 from defaults
                                where setting_key='migration_ok'},
                            results   => [['column'], [1]],
                        },
                    ),
                ),
            ],
        ),
    );

my $expected_keys = bag {
    item 'default_ar';
    item 'default_ap';
    item 'default_country';
    end();
};
my $required_vars;
ok lives { $required_vars = $upgrade->required_vars };
is [keys $required_vars->%*], $expected_keys;


my @applicable_tests = $upgrade->applicable_tests;
is scalar(@applicable_tests), 11;

is $upgrade->applicable_test_by_name($applicable_tests[0]->name),
    $applicable_tests[0];


ok lives { $upgrade->run_upgrade_script( {} ) } or diag $@;



done_testing;
