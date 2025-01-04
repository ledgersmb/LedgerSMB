#!perl

# Database schema upgrade pre-checks

use Test2::V0;

use Data::Dumper;
use DBI;
use Digest::MD5 qw( md5_hex );
use File::Temp qw( :seekable );
use MIME::Base64;
use Plack::Request;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($OFF);

use LedgerSMB;
use LedgerSMB::Database::ChangeChecks qw( run_checks load_checks );
use LedgerSMB::Database::SchemaChecks::JSON qw( json_formatter_context );


my $dir = File::Temp->newdir();
my $json_dir = $dir->dirname;

sub _slurp {
    my ($fn) = @_;

    open my $fh, '<:encoding(UTF-8)', $fn
        or die "Failed to open generated response file '$fn': $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh
        or warn "Failed to close generated response file '$fn': $!";


    return $content;
}

###############################################
#
#
#  Test helper routines
#
###############################################


# _check_hashid

is LedgerSMB::Database::SchemaChecks::JSON::_check_hashid(
    { title => 'a title' }
    ),
    md5_hex( 'a title' ), '_check_hashid with only a title';
is LedgerSMB::Database::SchemaChecks::JSON::_check_hashid(
    {
        title => 'a title',
        path => 'a path',
    } ),
    md5_hex( 'a path', 'a title' ), '_check_hashid with only a title';


my $tests;
my $dbh;
my $fh;
my @checks;
my $out;


###############################################
#
#
#  First test: Render the description && title
#
###############################################


$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'first title',
    description => q|a description|,
    query => q|something|,
    on_submit => sub { return 1; },
    on_failure => sub {
        describe;
    };

1;
HEREDOC

open $fh, '<', \$tests
    or die $!;
ok(lives { @checks = load_checks($fh); is scalar @checks, 1 },
          'Loading a single check from file-handle');

$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};

is $LedgerSMB::Database::SchemaChecks::JSON::cached_response, undef,
    'undef cached response';

$out = json_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} $json_dir;

is _slurp($out), q!{
   "failure" : {
      "description" : "a description",
      "title" : "first title"
   },
   "response" : {}
}
!, 'print a description on failure';


###############################################
#
#
#  Second test: Render a confirmation
#
###############################################

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'second title',
    description => q|a description|,
    query => q|something|,
    on_submit => sub { return 1; },
    on_failure => sub {
        confirm abc => 'Abc';
    };

1;
HEREDOC

open $fh, '<', \$tests
    or die $!;
ok( lives { @checks = load_checks($fh); is scalar @checks, 1 },
          'Loading a single check from file-handle');

$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};

$out = json_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} $json_dir;

is $LedgerSMB::Database::SchemaChecks::JSON::cached_response, undef,
    'undef cached response';

is _slurp($out), q!{
   "failure" : {
      "confirmations" : [
         {
            "abc" : "Abc"
         }
      ]
   },
   "response" : {}
}
!, 'print the button/confirmation on failure';

###############################################
#
#
#  Third test: Render multiple confirmations
#
###############################################

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'third title',
    description => q|a description|,
    query => q|something|,
    on_submit => sub { return 1; },
    on_failure => sub {
        confirm abc => 'Abc', def => 'Def';
    };

1;
HEREDOC

open $fh, '<', \$tests
    or die $!;
ok( lives { @checks = load_checks($fh); is scalar @checks, 1 },
          'Loading a single check from file-handle');

$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};

$out = json_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} $json_dir;

is $LedgerSMB::Database::SchemaChecks::JSON::cached_response, undef,
    'undef cached response';

is _slurp($out), q!{
   "failure" : {
      "confirmations" : [
         {
            "abc" : "Abc"
         },
         {
            "def" : "Def"
         }
      ]
   },
   "response" : {}
}
!, 'print the buttons/confirmations on failure';


###############################################
#
#
#  Fourth test: Re-running third test does not accumulate 'failure' section
#
###############################################

# Explicitly re-use third test's setup

$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};

$out = json_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} $json_dir;

is $LedgerSMB::Database::SchemaChecks::JSON::cached_response, undef,
    'undef cached response';

is _slurp($out), q!{
   "failure" : {
      "confirmations" : [
         {
            "abc" : "Abc"
         },
         {
            "def" : "Def"
         }
      ]
   },
   "response" : {}
}
!, 'print the buttons/confirmations on failure';




###############################################
#
#
#  Fifth test: Render a grid (2-column p-key)
#
###############################################

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'fifth title',
    description => q|a description|,
    query => q|something|,
    tables => {
        'abc' => { prim_key => ['a', 'b'] },
    },
    on_submit => sub { return 1; },
    on_failure => sub {
        my (\$dbh, \$rows) = \@_;

        grid \$rows,
        name => 'grid',
        id => 'grid',
        table => 'abc',
        columns => [ 'a', 'b', 'c' ],
        edit_columns => ['c'];
    };

1;
HEREDOC

open $fh, '<', \$tests
    or die $!;
ok( lives { @checks = load_checks($fh); is scalar @checks, 1 },
          'Loading a single check from file-handle');

$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'a', 'b', 'c' ],
        [ 'col1', 'col2', 'col3' ],
        ],
};

$out = json_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} $json_dir;


is _slurp($out), q!{
   "failure" : {
      "grids" : {
         "grid" : {
            "adjustment_fields" : [
               "c"
            ],
            "rows" : [
               {
                  "__pk" : "Y29sMQ== Y29sMg==",
                  "a" : "col1",
                  "b" : "col2",
                  "c" : "col3"
               }
            ]
         }
      }
   },
   "response" : {}
}
!, 'print the grid on failure';



done_testing;
