# Database schema upgrade pre-checks                         -*- mode: perl; -*-

use Test2::V0;
use Test2::Mock;
use Text::Diff;

use Beam::Wire;
use Data::Dumper;
use DBI;
use Digest::MD5 qw( md5_hex );
use File::Temp qw( :seekable );
use MIME::Base64;
use Plack::Request;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($OFF);

use LedgerSMB;
use LedgerSMB::Locale;
use LedgerSMB::Database;
use LedgerSMB::Database::ChangeChecks qw( run_checks load_checks );
use LedgerSMB::Setup::SchemaChecks qw( html_formatter_context );

my $wire = Beam::Wire->new(file => 't/ledgersmb.yaml');
LedgerSMB::Locale->initialize($wire);


my $db_mock = Test2::Mock->new(
    class => 'LedgerSMB::Database',
    override => [
        upgrade_run_id => sub { 'a3730c7e-58f1-11ef-995a-3ffe22c8da96' }
    ]);

sub test_request {
    my $plack_req = Plack::Request->new({});
    my $wire = Beam::Wire->new(
        config => {
            printers => {
                class => 'LedgerSMB::Printers',
                args => [],
            },
            default_locale => {
                class => 'LedgerSMB::LanguageResolver',
                args => {
                    directory => './locale/po/',
                }
            },
            paths => {
                class => 'Beam::Wire',
                args => {
                    config => {
                        UI => './UI/'
                    }
                }
            },
            ui => {
                class => 'LedgerSMB::Template::UI',
                method => 'new_UI',
                args => {
                    root => { '$ref' => 'paths/UI' }
                }
            }
        });
    $plack_req->env->{'lsmb.script'}   = 'script.pl';
    my $req = LedgerSMB->new($plack_req, $wire);

    $req->{script}          = 'script.pl';
    $req->{query_string}    = 'action=rebuild';
    $req->{resubmit_action} = 'rebuild_modules';
    $req->{database}        = bless {}, 'LedgerSMB::Database';
    return $req;
}


sub filter_js_src {

    # Given an array ref of rendered html lines,
    # perform in-place substitution of javascript paths
    # so that differences between built and unbuilt dojo
    # installations are ignored.
    # Also make sure that we don't abort on whitespace differences
    my $lines = shift;
    my $line = join("\n",@{$lines});
    $line =~ s|</script><script|</script>\n<script|g;
    $line =~ s|"js-src/|"js/|g;
    $line =~ s|\s*\n+\s*|\n|g;
    # Filter out chunks hashes
    $line =~ s|[~\.]([0-9a-f]{8}\.)?[0-9a-f]{20}\.js|.js|g;
    # Split in lines
    return $line;
}



###############################################
#
#  Test helper routines
#
###############################################


# _check_hashid

is LedgerSMB::Setup::SchemaChecks::_check_hashid( { title => 'a title' } ),
    md5_hex( 'a title' ), '_check_hashid with only a title';
is LedgerSMB::Setup::SchemaChecks::_check_hashid(
    {
        title => 'a title',
        path => 'a path',
    } ),
    md5_hex( 'a path', 'a title' ), '_check_hashid with only a title';


# _unpack_grid_data

is( LedgerSMB::Setup::SchemaChecks::_unpack_grid_data(
               {
                   rowcount_pfx => 2,
                   'pfx_row_1' => 1,
                   'pfx_--pk_1' => '1 2 3',
                   'pfx_a_1' => 1,
                   'pfx_b_1' => 2,
                   'pfx_c_1' => 3,
                   'pfx_row_2' => 2,
                   'pfx_--pk_2' => '4 5 6',
                   'pfx_a_2' => 4,
                   'pfx_b_2' => 5,
                   'pfx_c_2' => 6,
               }, 'pfx', [ 'a', 'b', 'c' ]),
           [
            {
                a => 1,
                b => 2,
                c => 3,
                __pk => '1 2 3',
            },
            {
                a => 4,
                b => 5,
                c => 6,
                __pk => '4 5 6',
            }
           ], '');



my $tests;
my $dbh;
my $fh;
my @checks;
my $out;


###############################################
#
#  First test: Render the description && title
#
###############################################


$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
    description => q|a description|,
    query => q|something|,
    on_submit => sub { return 1; },
    on_failure => sub {
        describe;
    };

1;
HEREDOC

open $fh, '<', \$tests
    or die "$!";
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

$out = html_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} test_request();

$out = filter_js_src($out);

my $check = qq{
<h1>title</h1>

<div class="description">
  <p>
    <p>a description</p>
  </p>
</div>};

$check =~ s|\n+\s*|\n|g;

ok( (index($out,$check)>0), 'Render the description && title')
    or diag diff([ split /\n/, $out ], [ split /\n/, $check ],{ STYLE => 'Table', CONTEXT => 1 });


###############################################
#
#  Second test: Render a custom description
#
###############################################

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
    description => q|a description|,
    query => q|something|,
    on_submit => sub { return 1; },
    on_failure => sub {
        describe 'another description';
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

$out = html_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} test_request();

$out = filter_js_src($out);
$check = qq{
  <h1>title</h1>
<div class="description">
  <p>
    <p>another description</p>
  </p>
</div>};

$check =~ s|\n+\s*|\n|g;

ok( (index($out,$check)>0), 'Render a custom description')
    or diff([ split /\n/, $out ], [ split /\n/, $check ], { STYLE => 'Table', CONTEXT => 2 });


###############################################
#
#  Third test: Render a confirmation
#
###############################################

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
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

$out = html_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} test_request();

$out = filter_js_src($out);
$check = qq{<button
   type="submit"
   id="confirm-0"
   name="confirm"
   value="abc"
   data-dojo-type="dijit/form/Button"
   >Abc</button>};

$check =~ s|\n+\s*|\n|g;

ok( index($out, $check)>0, 'Render a confirmation')
    or diff([ split /\n/, $out ],[ split /\n/, $check ],{ STYLE => 'Table', CONTEXT => 2 });


###############################################
#
#  Fourth test: Render multiple confirmations
#
###############################################

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
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

$out = html_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} test_request();

$out = filter_js_src($out);
$check = qq{<button
   type="submit"
   id="confirm-0"
   name="confirm"
   value="abc"
   data-dojo-type="dijit/form/Button"
   >Abc</button>
<button
   type="submit"
   id="confirm-1"
   name="confirm"
   value="def"
   data-dojo-type="dijit/form/Button"
   >Def</button>};

$check =~ s|\s*\n+\s*|\n|g;


ok( index($out,$check)>0, 'Render multiple confirmations')
    or diag diff([ split /\n/, $out ],[ split /\n/, $check ],{ STYLE => 'Table', CONTEXT => 2 });


###############################################
#
#  Fifth test: Render a grid (2-column p-key)
#
###############################################

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
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
ok(lives { @checks = load_checks($fh); is scalar @checks, 1 },
          'Loading a single check from file-handle');

$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'a', 'b', 'c' ],
        [ 'col1', 'col2', 'col3' ],
        ],
};

$out = html_formatter_context {
    return ! run_checks($dbh, checks => \@checks);
} test_request();

$out = filter_js_src($out);
$check = qq{<table id="grid"
        class="dynatable "
        width="">
  <thead>
   <tr><th style="display:none"></th>
   <th style="display:none"></th>
    <th class="a  text">a</th>
    <th class="b  text">b</th>
    <th class="c  input_text">c</th>
   </tr>
  </thead>
  <tbody>
   <tr class=" 0">
      <td style="display:none">
        <span><input id="grid-row-1" type="hidden" name="grid_row_1" value="0" /></span></td>
      <td style="display:none"><span><input id="grid---pk-0" type="hidden" name="grid_--pk_0" value="Y29sMQ== Y29sMg==" /></span></td>
      <td class="a  text">col1</td>
      <td class="b  text">col2</td>
      <td class="c  input_text"><span><input id="grid_c-1" type="text" name="grid_c_0" size="60" value="col3" data-dojo-type="dijit/form/ValidationTextBox" maxlength="255" /></span></td>
   </tr>
  </tbody>
 </table>
<span><input id="rowcount-grid" type="hidden" name="rowcount_grid" value="1" /></span>
};

$check =~ s|\n+\s*|\n|g;

ok( index($out,$check)>0, 'Render a grid (2-column p-key)')
    or diag diff( [ split /\n/, $out ],[ split /\n/, $check ],{ STYLE => 'Table', CONTEXT => 2 });

done_testing;
