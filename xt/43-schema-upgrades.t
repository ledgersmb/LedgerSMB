#!perl

=head1 UNIT TESTS FOR

LedgerSMB::Database::ChangeChecks

=cut

#
#
##############################################
#
#
#  See also t/16-schema-upgrade-precheck.t
#
##############################################



use Test2::V0;

use LedgerSMB;
use LedgerSMB::Database;
use LedgerSMB::Database::ChangeChecks qw/load_checks run_checks run_with_formatters/;

use DBI;
use Carp::Always;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

my $fh;


####### Create test run conditions

my $dbh = DBI->connect("dbi:Pg:dbname=$ENV{LSMB_NEW_DB}", undef, undef,
                       { AutoCommit => 1, PrintError => 0 })
    or die "Can't connect to template database: " . DBI->errstr;;

$dbh->do(q{set client_min_messages = 'warning'});
$dbh->do(qq{DROP DATABASE IF EXISTS $ENV{LSMB_NEW_DB}_43_upgrades})
    or die "Can't drop old test database: " . DBI->errstr;
$dbh->disconnect;

LedgerSMB::Database->new(
    connect_data => {
        dbname => "$ENV{LSMB_NEW_DB}_43_upgrades",
    },
    schema => 'xyz',
    )
    ->create_and_load;

$dbh = DBI->connect(qq{dbi:Pg:dbname=$ENV{LSMB_NEW_DB}_43_upgrades},
              undef, undef, { AutoCommit => 0, PrintError => 0 })
    or die "Can't connect to test database";
$dbh->{private_LedgerSMB} = { schema => 'xyz' };
####### End: Create test run conditions


#######################################################
#
#
# First check: run a successful check (no failures)
#
#######################################################


my $check_def = qq|

package checks1;

use Test::More;
use LedgerSMB::Database::ChangeChecks;

check 'test_success',
   query => q{SELECT * FROM defaults WHERE value = 'test'},
   description => 'test',
   tables => {
      'defaults' => { prim_key => [ 'setting_key' ] },
   },
   columns => [ 'setting_key', 'value' ],
   edit_columns => [ 'value' ],
   on_failure => sub { ok(0, 'on_failure not to be called!'); },
   on_submit => sub { ok(0, 'on_submit not to be called!'); };

1;
|;

open $fh, '<', \$check_def
    or die $!;
my @checks = load_checks($fh);

ok(run_checks($dbh, checks => \@checks),
   'Checks successfully completed');


#######################################################
#
#
# Second check: run a failing check
#
#######################################################


$check_def = qq|

package checks1;

use Test::More;
use LedgerSMB::Database::ChangeChecks;

check 'test_failure',
   query => q{SELECT * FROM defaults WHERE setting_key = 'version'},
   description => 'test',
   tables => {
      'defaults' => { prim_key => [ 'setting_key' ] },
   },
   columns => [ 'setting_key', 'value' ],
   edit_columns => [ 'value' ],
   on_failure => sub { ok(1, 'on_failure correctly called!'); },
   on_submit => sub { ok(0, 'on_submit not to be called!'); };

1;
|;

open $fh, '<', \$check_def
    or die $!;
@checks = load_checks($fh);

run_with_formatters {
    ok(! run_checks($dbh, checks => \@checks),
       'Checks successfully failed');
} {
    provided => sub { return 0; },
};



#######################################################
#
#
# Third check: run multiple succeeding checks
#
#######################################################


$check_def = qq|

package checks1;

use Test::More;
use LedgerSMB::Database::ChangeChecks;

check 'test_success_1',
   query => q{SELECT * FROM defaults WHERE value = 'zzzzzzz'},
   description => 'test',
   tables => {
      'defaults' => { prim_key => [ 'setting_key' ] },
   },
   columns => [ 'setting_key', 'value' ],
   edit_columns => [ 'value' ],
   on_failure => sub { ok(0, 'on_failure not to be called!'); },
   on_submit => sub { ok(0, 'on_submit not to be called!'); };


check 'test_success_2',
   query => q{SELECT * FROM entity_class WHERE id < 0},
   description => 'test',
   tables => {
      'defaults' => { prim_key => [ 'id' ] },
   },
   columns => [ 'id', 'class' ],
   edit_columns => [ 'id' ],
   on_failure => sub { ok(0, 'on_failure not to be called!'); },
   on_submit => sub { ok(0, 'on_submit not to be called!'); };

1;
|;

open $fh, '<', \$check_def
    or die $!;
@checks = load_checks($fh);

run_with_formatters {
    ok(run_checks($dbh, checks => \@checks),
       'Checks successfully completed');
} {
    provided => sub { return 0; },
};

#######################################################
#
#
# Fourth check: run failing check with corrective action
#
#######################################################


$check_def = qq|

package checks1;

use Test::More;
use LedgerSMB::Database::ChangeChecks;

check 'test_failure',
   query => q{SELECT * FROM defaults WHERE value = '$LedgerSMB::VERSION'},
   description => 'test',
   tables => {
      'defaults' => { prim_key => [ 'setting_key' ] },
   },
   on_failure => sub {
       my (\$dbh, \$rows) = \@_;
       grid \$rows,
         name => 'defaults',
         columns => [ 'setting_key', 'value' ],
         edit_columns => [ 'value' ];
   },
   on_submit => sub { save_grid \$_[0], \$_[1], name=>'defaults'; };

1;
|;

open $fh, '<', \$check_def
    or die $!;
@checks = load_checks($fh);

my $grid_rows;
run_with_formatters {
    # We first have checks fail
    ok(! run_checks($dbh, checks => \@checks),
       'Checks failed');

    # and then issue the same request (presumably with 'response content')
    # to apply the
    ok(run_checks($dbh, checks => \@checks),
       'Checks succeeded');
} {
    grid => sub {
        my ($dbh, $rows) = @_;
        $grid_rows = $rows;
    },
    provided => sub {
        my ($check, $name) = @_;
        return defined $grid_rows
            unless defined $name;

        $grid_rows->[0]->{value} = 'the-latest-version';

        return $grid_rows;
    },
};

my $sth = $dbh->prepare(
    q{select count(*) from defaults where value = 'the-latest-version'});

$sth->execute;
my ($count) = @{$sth->fetchrow_arrayref};

is($count, 1, 'The table was correctly updated');
$sth->finish;

$dbh->disconnect;



$dbh = DBI->connect("dbi:Pg:dbname=$ENV{LSMB_NEW_DB}", undef, undef,
                       { AutoCommit => 1, PrintError => 0 })
    or die "Can't connect to template database: " . DBI->errstr;;

$dbh->do(q{set client_min_messages = 'warning'});
$dbh->do(qq{DROP DATABASE IF EXISTS $ENV{LSMB_NEW_DB}_43_upgrades})
    or die "Can't drop old test database: " . DBI->errstr;
$dbh->disconnect;


done_testing;
