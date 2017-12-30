package TestsFor::COATest;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::ParameterizedInstances';

use lib 'xt/41-coaload';
use COATest;

use File::Find::Rule;

my $rule = File::Find::Rule->new;
$rule->or($rule->new
               ->directory
               ->name(qr(gifi|sic))
               ->prune
               ->discard,
          $rule->new);
my @files = sort $rule->name("*.sql")->file->in("sql/coa"); # "sql/coa/ar/chart/General.sql"

my %tests;

for my $sqlfile (@files) {
    my ($_1,$dir,$type,$name) = $sqlfile =~ qr(sql\/coa\/(([a-z]{2})\/)?(.+\/)?([^\/\.]+)\.sql$);
    $dir //= '';
    $tests{"x$dir"} = [] if (!defined($tests{"x$dir"}));
    push @{$tests{"x$dir"}}, $sqlfile;
}

# sort, run everything in parallel but the ones for the same country, for they need the same database
sub _constructor_parameter_sets {
    my $class = shift;
    my ($_1,$dir) = $class =~ qr(TestsFor::COATest(::([a-z]{2}))?);
    $dir //= '';
    my %testcases = ();
    my $i = 1;

    for my $sqlfile (@{$tests{"x$dir"}}) {
        $testcases{$i++} = { sqlfile => $sqlfile };
    }
    return %testcases;
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
sub test_startup {
    my $test = shift;
    $test->next::method; # optional to call parent test_startup

    my $db = $test->{test_data}->test_db;
    system("dropdb '$db' 2>/dev/null");
    system("createdb '$db' -T '$ENV{LSMB_NEW_DB}'");
}

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
    my $sqlfile = $coatest->sqlfile;
    my $db = $coatest->test_db;

    my $returnstring = `psql '$db' -c "SELECT 1 FROM pg_database WHERE datname='$db'"`;
    my $testval = grep { /^ +1$/ } split /\n/, $returnstring;
    ok($testval, "DB created for $sqlfile testing");

    $! = undef; # reset if system failed
    system("psql $db -f $sqlfile");
    ok(! $!, "psql run file succeeded");

    $returnstring = `psql '$db' -c "SELECT COUNT(*), 'TESTRESULT' from account"`;
    if ( $returnstring ) {
        $testval = grep { /TESTRESULT/ } split /\n/, $returnstring;
        $testval =~ s/\D//g;
    }
    ok($testval, "Got rows back for account, for $sqlfile");
}

# teardown methods are run after every test method.
#sub test_teardown {
#    my $test = shift;
#    # more teardown
#    $test->next::method; # optional to call parent test_teardown
#}

# Runs at the end of each test class.
sub test_shutdown {
    my $test = shift;
    my $db = $test->{test_data}->test_db;
    system("dropdb '$db'");
    $test->next::method; # # optional to call parent test_shutdown
}

1;
