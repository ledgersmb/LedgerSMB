package TestsFor::COATest;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::ParameterizedInstances';

use lib 'xt/41-coaload';
use COATest;

use File::Find::Rule;

# sort, run everything in parallel but the ones for the same country, for they need the same database
sub _constructor_parameter_sets {
    my $class = shift;
    my $rule = File::Find::Rule->new;
    $rule->or($rule->new
                   ->directory
                   ->name(qr(gifi|sic))
                   ->prune
                   ->discard,
              $rule->new);
    my @files = sort $rule->name("*.sql")->file->in("sql/coa");
    my %tests = (); my $i = 1;

    # This should be instance_name => { new parameters },
    # but I failed to get the sqlfile installed in the structure
    for my $sqlfile (@files) {
        $tests{$i++} = { sqlfile => $sqlfile };
    }
    return %tests;
}

has 'test_data' => (
    is => 'rw',
    isa => 'COATest',
);

sub BUILD {
    my $test = shift;
    $test->test_data(COATest->new( @_ ));
}

# Runs at the start of each test class
#sub test_startup {
#    warn p @_;
#    my $test = shift;
#    $test->next::method; # optional to call parent test_startup
#    # more startup
#}

# Runs at the start of each test method.
#sub test_setup {
#    my $test = shift;
#    $test->next::method; # optional to call parent test_setup
#    # more setup
#}

sub test_constructor {
    my $test = shift;

    local $!;

    my $coatest = $test->{test_data};
    ok($coatest, "Cannot set new COATest");
    my $sqlfile = $coatest->sqlfile;

    my $db = $coatest->test_db;
    $! = undef; # reset if drop failed

    system("dropdb '$db' 2>/dev/null");
    system("createdb '$db' -T '$ENV{LSMB_NEW_DB}'");
    ok(! $!, "DB created for $sqlfile testing");

    system("psql $db -f $sqlfile");
    ok(! $!, "psql run file succeeded");

    my $returnstring = `psql '$db' -c "SELECT COUNT(*), 'TESTRESULT' from account"`;
    my $testval;
    if ( $returnstring ) {
        $testval = grep { /TESTRESULT/ } split("\n", $returnstring);
        $testval =~ s/\D//g;
    }
    ok($testval, "Got rows back for account, for $sqlfile");
    system("dropdb '$db'");
}

# teardown methods are run after every test method.
#sub test_teardown {
#    my $test = shift;
#    # more teardown
#    $test->next::method; # optional to call parent test_teardown
#}

# Runs at the end of each test class.
#sub test_shutdown {
#     my $test = shift;
#     # more teardown
#     $test->next::method; # # optional to call parent test_shutdown
#}

1;
