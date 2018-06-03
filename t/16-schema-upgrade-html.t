# Database schema upgrade pre-checks

use strict;
use warnings;

use Data::Dumper;
use DBI;
use Digest::MD5 qw( md5_hex );
use File::Temp qw( :seekable );
use IO::Scalar;
use Log::Log4perl qw( :easy );
use MIME::Base64;

use Test::More 'no_plan';
use Test::Exception;


use LedgerSMB;
use LedgerSMB::Database::ChangeChecks qw( run_checks load_checks );
use LedgerSMB::Setup::SchemaChecks qw( html_formatter_context );


Log::Log4perl->easy_init($OFF);


sub test_request {
    my $req = LedgerSMB->new();

    $req->{script} = 'script.pl';
    $req->{query_string} = 'action=rebuild';

    return $req;
}


sub filter_js_src {

    # Given an array ref of rendered html lines,
    # perform in-place substitution of javascript paths
    # so that differences between built and unbuilt dojo
    # installations are ignored.
    my $lines = shift;
    foreach my $line(@{$lines}) {
        $line =~ s|"js-src/|"js/|g;
    }
}


###############################################
#
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

is_deeply( LedgerSMB::Setup::SchemaChecks::_unpack_grid_data(
               {
                   rowcount_pfx => 2,
                   'pfx_--pk_1' => '1 2 3',
                   'pfx_a_1' => 1,
                   'pfx_b_1' => 2,
                   'pfx_c_1' => 3,
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
                '--pk' => '1 2 3',
            },
            {
                a => 4,
                b => 5,
                c => 6,
                __pk => '4 5 6',
                '--pk' => '4 5 6',
            }
           ], '');



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
lives_and(sub { @checks = load_checks($fh); is scalar @checks, 1 },
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
is join("\n", @$out), q{<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
        <title></title>
        <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
        
        
        <link rel="stylesheet" href="js/dojo/resources/dojo.css" type="text/css" />
        <link rel="stylesheet" href="js/dijit/themes/claro/claro.css" type="text/css" />

        
            <link rel="stylesheet" href="css/ledgersmb.css" type="text/css" />
        
        
            <link rel="stylesheet" href="css/setup/stylesheet.css" type="text/css" />
        
        
        <script type="text/javascript">
            var dojoConfig = {
                async: 1,
                locale: '',
                packages: [{"name":"lsmb","location":"../lsmb"}]
            };
            var lsmbConfig = {
                
            };
       </script>
        <script type="text/javascript" src="js/dojo/dojo.js"></script>
        <script type="text/javascript" src="js/lsmb/main.js"></script>
        
        <meta name="robots" content="noindex,nofollow" />
</head>
<body>
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
</body>}, 'print a description on failure';


###############################################
#
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
lives_and(sub { @checks = load_checks($fh); is scalar @checks, 1 },
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
is join("\n", @$out), q{<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
        <title></title>
        <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
        
        
        <link rel="stylesheet" href="js/dojo/resources/dojo.css" type="text/css" />
        <link rel="stylesheet" href="js/dijit/themes/claro/claro.css" type="text/css" />

        
            <link rel="stylesheet" href="css/ledgersmb.css" type="text/css" />
        
        
            <link rel="stylesheet" href="css/setup/stylesheet.css" type="text/css" />
        
        
        <script type="text/javascript">
            var dojoConfig = {
                async: 1,
                locale: '',
                packages: [{"name":"lsmb","location":"../lsmb"}]
            };
            var lsmbConfig = {
                
            };
       </script>
        <script type="text/javascript" src="js/dojo/dojo.js"></script>
        <script type="text/javascript" src="js/lsmb/main.js"></script>
        
        <meta name="robots" content="noindex,nofollow" />
</head>
<body>
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
</body>}, 'print the custom description on failure';


###############################################
#
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
lives_and(sub { @checks = load_checks($fh); is scalar @checks, 1 },
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
is join("\n", @$out), q{<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
        <title></title>
        <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
        
        
        <link rel="stylesheet" href="js/dojo/resources/dojo.css" type="text/css" />
        <link rel="stylesheet" href="js/dijit/themes/claro/claro.css" type="text/css" />

        
            <link rel="stylesheet" href="css/ledgersmb.css" type="text/css" />
        
        
            <link rel="stylesheet" href="css/setup/stylesheet.css" type="text/css" />
        
        
        <script type="text/javascript">
            var dojoConfig = {
                async: 1,
                locale: '',
                packages: [{"name":"lsmb","location":"../lsmb"}]
            };
            var lsmbConfig = {
                
            };
       </script>
        <script type="text/javascript" src="js/dojo/dojo.js"></script>
        <script type="text/javascript" src="js/lsmb/main.js"></script>
        
        <meta name="robots" content="noindex,nofollow" />
</head>
<body>
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
</body>}, 'print the button/confirmation on failure';

###############################################
#
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
lives_and(sub { @checks = load_checks($fh); is scalar @checks, 1 },
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
is join("\n", @$out), q{<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
        <title></title>
        <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
        
        
        <link rel="stylesheet" href="js/dojo/resources/dojo.css" type="text/css" />
        <link rel="stylesheet" href="js/dijit/themes/claro/claro.css" type="text/css" />

        
            <link rel="stylesheet" href="css/ledgersmb.css" type="text/css" />
        
        
            <link rel="stylesheet" href="css/setup/stylesheet.css" type="text/css" />
        
        
        <script type="text/javascript">
            var dojoConfig = {
                async: 1,
                locale: '',
                packages: [{"name":"lsmb","location":"../lsmb"}]
            };
            var lsmbConfig = {
                
            };
       </script>
        <script type="text/javascript" src="js/dojo/dojo.js"></script>
        <script type="text/javascript" src="js/lsmb/main.js"></script>
        
        <meta name="robots" content="noindex,nofollow" />
</head>
<body>
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
</body>}, 'print the buttons/confirmations on failure';

###############################################
#
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
lives_and(sub { @checks = load_checks($fh); is scalar @checks, 1 },
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
is join("\n", @$out), q{<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
        <title></title>
        <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
        
        
        <link rel="stylesheet" href="js/dojo/resources/dojo.css" type="text/css" />
        <link rel="stylesheet" href="js/dijit/themes/claro/claro.css" type="text/css" />

        
            <link rel="stylesheet" href="css/ledgersmb.css" type="text/css" />
        
        
            <link rel="stylesheet" href="css/setup/stylesheet.css" type="text/css" />
        
        
        <script type="text/javascript">
            var dojoConfig = {
                async: 1,
                locale: '',
                packages: [{"name":"lsmb","location":"../lsmb"}]
            };
            var lsmbConfig = {
                
            };
       </script>
        <script type="text/javascript" src="js/dojo/dojo.js"></script>
        <script type="text/javascript" src="js/lsmb/main.js"></script>
        
        <meta name="robots" content="noindex,nofollow" />
</head>
<body>
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
      <input id="row-1" type="hidden" name="row_1" value="0" />
      <input id="grid--pk-0" type="hidden" name="grid--pk_0" value="Y29sMQ== Y29sMg==" />      <td class="a  text">            col1      </td>      <td class="b  text">            col2      </td>      <td class="c  input_text">          <input id="c-1" type="text" name="gridc_0" size="60" value="col3" data-dojo-type="dijit/form/ValidationTextBox" maxlength="255" />      </td>   </tr>
</tbody><input id="rowcount-grid" type="hidden" name="rowcount_grid" value="1" />
</table>
</form>
</body>}, 'print the grid on failure';





done_testing;
