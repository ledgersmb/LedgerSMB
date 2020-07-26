# Database schema upgrade pre-checks

use Test2::V0;
use Text::Diff;

use Data::Dumper;
use DBI;
use Digest::MD5 qw( md5_hex );
use File::Temp qw( :seekable );
use IO::Scalar;
use MIME::Base64;
use Plack::Request;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($OFF);

use LedgerSMB;
use LedgerSMB::Database::ChangeChecks qw( run_checks load_checks );
use LedgerSMB::Setup::SchemaChecks qw( html_formatter_context );


sub test_request {
    my $plack_req = Plack::Request->new({});
    my $req = LedgerSMB->new($plack_req);

    $req->{script}          = 'script.pl';
    $req->{query_string}    = 'action=rebuild';
    $req->{resubmit_action} = 'rebuild_modules';

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
    @{$lines} = split(/\n/, $line);
}


sub find_application_mode {
    my $lines = shift;
    my $pattern = qr/^\bmode:\s*"(production|development)"$/;
    my @mode = grep {/$pattern/} @$lines;
    return if @mode != 1; # We need only a single line
    return ($mode[0] =~ /$pattern/)[0];
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

$fh = IO::Scalar->new(\$tests);
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

filter_js_src($out);
my $mode = find_application_mode($out);

my $check = qq{<!-- prettier-disable -->
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title></title>
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link href="js/dojo/resources/dojo.css" rel="stylesheet">
    <link href="js/css/claro.css" rel="stylesheet">
    <link href="js/css/ledgersmb.css" rel="stylesheet">
    <link href="js/css/setup.css" rel="stylesheet">
    <script>
        var dojoConfig = {
            async: 1,
            locale: "",
            packages: [{"name":"lsmb","location":"../lsmb"}],
            mode: "$mode"
        };
        var lsmbConfig = {
        };
    </script>
    <script src="js/_scripts/manifest.js"></script>
    } .
    ($mode eq "production"
        ? q{<script src="js/_scripts/npm.dojo.js"></script>
            <script src="js/_scripts/npm.dijit.js"></script>
            <script src="js/_scripts/npm.dojo-webpack-plugin.js"></script>
            <script src="js/_scripts/bootstrap~gnome~gnome2~ledgersmb~ledgersmb-blue~ledgersmb-brown~ledgersmb-common~ledgersmb-purple~le.js"></script>}
        : ''
    ) . qq{
    <script src="js/_scripts/main.js"></script>
    <script src="js/_scripts/bootstrap.js"></script>
    <meta name="robots" content="noindex,nofollow" />
</head>
<body class="claro">
  <form method="POST"
        enctype="multipart/form-data"
        action="script.pl?action=rebuild">
    <input type="hidden" name="action" value="rebuild_modules">
    <input type="hidden" name="database" value="">
    <input type="hidden" name="check_id" value="d5d3db1765287eef77d7927cc956f50a">
<div class="description">
  <h1>title</h1>
  <p>
    <p>a description</p>
  </p>
</div>
</form>
</body>
</html>};

$check =~ s|\n+\s*|\n|g;
my @expected = split (/\n/, $check);

is $out,\@expected, 'Render the description && title',
    diff $out,\@expected,{ STYLE => 'Table', CONTEXT => 1 };


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

$fh = IO::Scalar->new(\$tests);
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

filter_js_src($out);
$check = qq{<!-- prettier-disable -->
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title></title>
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link href="js/dojo/resources/dojo.css" rel="stylesheet">
    <link href="js/css/claro.css" rel="stylesheet">
    <link href="js/css/ledgersmb.css" rel="stylesheet">
    <link href="js/css/setup.css" rel="stylesheet">
    <script>
        var dojoConfig = {
            async: 1,
            locale: "",
            packages: [{"name":"lsmb","location":"../lsmb"}],
            mode: "$mode"
        };
        var lsmbConfig = {
        };
    </script>
    <script src="js/_scripts/manifest.js"></script>
    } .
    ($mode eq "production"
        ? q{<script src="js/_scripts/npm.dojo.js"></script>
            <script src="js/_scripts/npm.dijit.js"></script>
            <script src="js/_scripts/npm.dojo-webpack-plugin.js"></script>
            <script src="js/_scripts/bootstrap~gnome~gnome2~ledgersmb~ledgersmb-blue~ledgersmb-brown~ledgersmb-common~ledgersmb-purple~le.js"></script>}
        : ''
    ) . qq{
    <script src="js/_scripts/main.js"></script>
    <script src="js/_scripts/bootstrap.js"></script>
    <meta name="robots" content="noindex,nofollow" />
</head>
<body class="claro">
  <form method="POST"
        enctype="multipart/form-data"
        action="script.pl?action=rebuild">
    <input type="hidden" name="action" value="rebuild_modules">
    <input type="hidden" name="database" value="">
    <input type="hidden" name="check_id" value="d5d3db1765287eef77d7927cc956f50a">
<div class="description">
  <h1>title</h1>
  <p>
    <p>another description</p>
  </p>
</div>
</form>
</body>
</html>};

$check =~ s|\n+\s*|\n|g;
@expected = split (/\n/, $check);

is $out, \@expected, 'Render a custom description',
    diff $out,\@expected,{ STYLE => 'Table', CONTEXT => 2 };


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

$fh = IO::Scalar->new(\$tests);
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

filter_js_src($out);
$check = qq{<!-- prettier-disable -->
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title></title>
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link href="js/dojo/resources/dojo.css" rel="stylesheet">
    <link href="js/css/claro.css" rel="stylesheet">
    <link href="js/css/ledgersmb.css" rel="stylesheet">
    <link href="js/css/setup.css" rel="stylesheet">
    <script>
        var dojoConfig = {
            async: 1,
            locale: "",
            packages: [{"name":"lsmb","location":"../lsmb"}],
            mode: "$mode"
        };
        var lsmbConfig = {
        };
    </script>
    <script src="js/_scripts/manifest.js"></script>
    } .
    ($mode eq "production"
        ? q{<script src="js/_scripts/npm.dojo.js"></script>
            <script src="js/_scripts/npm.dijit.js"></script>
            <script src="js/_scripts/npm.dojo-webpack-plugin.js"></script>
            <script src="js/_scripts/bootstrap~gnome~gnome2~ledgersmb~ledgersmb-blue~ledgersmb-brown~ledgersmb-common~ledgersmb-purple~le.js"></script>}
        : ''
    ) . qq{
    <script src="js/_scripts/main.js"></script>
    <script src="js/_scripts/bootstrap.js"></script>
    <meta name="robots" content="noindex,nofollow" />
</head>
<body class="claro">
  <form method="POST"
        enctype="multipart/form-data"
        action="script.pl?action=rebuild">
    <input type="hidden" name="action" value="rebuild_modules">
    <input type="hidden" name="database" value="">
    <input type="hidden" name="check_id" value="d5d3db1765287eef77d7927cc956f50a">
<button
   type="submit"
   id="confirm-0"
   name="confirm"
   value="abc"
   data-dojo-type="dijit/form/Button"
   >Abc</button>
</form>
</body>
</html>};

$check =~ s|\n+\s*|\n|g;
@expected = split (/\n/, $check);

is $out, \@expected, 'Render a confirmation',
    diff $out,\@expected,{ STYLE => 'Table', CONTEXT => 2 };


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

$fh = IO::Scalar->new(\$tests);
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

filter_js_src($out);
$check = qq{<!-- prettier-disable -->
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title></title>
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link href="js/dojo/resources/dojo.css" rel="stylesheet">
    <link href="js/css/claro.css" rel="stylesheet">
    <link href="js/css/ledgersmb.css" rel="stylesheet">
    <link href="js/css/setup.css" rel="stylesheet">
    <script>
        var dojoConfig = {
            async: 1,
            locale: "",
            packages: [{"name":"lsmb","location":"../lsmb"}],
            mode: "$mode"
        };
        var lsmbConfig = {
        };
    </script>
    <script src="js/_scripts/manifest.js"></script>
    } .
    ($mode eq "production"
        ? q{<script src="js/_scripts/npm.dojo.js"></script>
            <script src="js/_scripts/npm.dijit.js"></script>
            <script src="js/_scripts/npm.dojo-webpack-plugin.js"></script>
            <script src="js/_scripts/bootstrap~gnome~gnome2~ledgersmb~ledgersmb-blue~ledgersmb-brown~ledgersmb-common~ledgersmb-purple~le.js"></script>}
        : ''
    ) . qq{
    <script src="js/_scripts/main.js"></script>
    <script src="js/_scripts/bootstrap.js"></script>
    <meta name="robots" content="noindex,nofollow" />
</head>
<body class="claro">
  <form method="POST"
        enctype="multipart/form-data"
        action="script.pl?action=rebuild">
    <input type="hidden" name="action" value="rebuild_modules">
    <input type="hidden" name="database" value="">
    <input type="hidden" name="check_id" value="d5d3db1765287eef77d7927cc956f50a">
<button
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
   >Def</button>
</form>
</body>
</html>};

$check =~ s|\s*\n+\s*|\n|g;
@expected = split (/\n/, $check);

is $out, \@expected, 'Render multiple confirmations',
    diff $out,\@expected,{ STYLE => 'Table', CONTEXT => 2 };


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

$fh = IO::Scalar->new(\$tests);
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

filter_js_src($out);
$check = qq{<!-- prettier-disable -->
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title></title>
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link href="js/dojo/resources/dojo.css" rel="stylesheet">
    <link href="js/css/claro.css" rel="stylesheet">
    <link href="js/css/ledgersmb.css" rel="stylesheet">
    <link href="js/css/setup.css" rel="stylesheet">
    <script>
        var dojoConfig = {
            async: 1,
            locale: "",
            packages: [{"name":"lsmb","location":"../lsmb"}],
            mode: "$mode"
        };
        var lsmbConfig = {
        };
    </script>
    <script src="js/_scripts/manifest.js"></script>
    } .
    ($mode eq "production"
        ? q{<script src="js/_scripts/npm.dojo.js"></script>
            <script src="js/_scripts/npm.dijit.js"></script>
            <script src="js/_scripts/npm.dojo-webpack-plugin.js"></script>
            <script src="js/_scripts/bootstrap~gnome~gnome2~ledgersmb~ledgersmb-blue~ledgersmb-brown~ledgersmb-common~ledgersmb-purple~le.js"></script>}
        : ''
    ) . qq{
    <script src="js/_scripts/main.js"></script>
    <script src="js/_scripts/bootstrap.js"></script>
    <meta name="robots" content="noindex,nofollow" />
</head>
<body class="claro">
  <form method="POST"
        enctype="multipart/form-data"
        action="script.pl?action=rebuild">
    <input type="hidden" name="action" value="rebuild_modules">
    <input type="hidden" name="database" value="">
    <input type="hidden" name="check_id" value="d5d3db1765287eef77d7927cc956f50a">
<table id="grid"
       class="dynatable "
       width=""><thead>
   <tr>   <th class="a  text">a
   </th>   <th class="b  text">b
   </th>   <th class="c  input_text">c
   </th>   </tr>
</thead><tbody>   <tr class=" 0">
      <input id="grid-row-1" type="hidden" name="grid_row_1" value="0" />
      <input id="grid---pk-0" type="hidden" name="grid_--pk_0" value="Y29sMQ== Y29sMg==" />      <td class="a  text">            col1      </td>      <td class="b  text">            col2      </td>      <td class="c  input_text">          <input id="grid_c-1" type="text" name="grid_c_0" size="60" value="col3" data-dojo-type="dijit/form/ValidationTextBox" maxlength="255" />      </td>   </tr>
</tbody><input id="rowcount-grid" type="hidden" name="rowcount_grid" value="1" />
</table>
</form>
</body>
</html>};

$check =~ s|\n+\s*|\n|g;
@expected = split (/\n/, $check);

is $out, \@expected, 'Render a grid (2-column p-key)',
    diff $out,\@expected,{ STYLE => 'Table', CONTEXT => 2 };

done_testing;
