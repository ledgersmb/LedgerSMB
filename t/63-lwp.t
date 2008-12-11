use Test::More;
use LWP;
use LedgerSMB::Sysconfig;
use HTTP::Cookies;

if (!$ENV{'LSMB_TEST_LWP'}){
	plan 'skip_all' => 'LWP Test not enabled!';
} else {
	plan 'no_plan';
}

my $host = $ENV{LSMB_BASE_URL} || 'http://localhost/ledger-smb/';
if ($host !~ /\/$/){
	$host .= "/";
};
$host =~ /https?:\/\/([^\/]+)\//;
$hostname = $1;
my $db = $ENV{LSMB_TEST_NEW_DB} || $ENV{PGDATABASE};
do 't/data/62-request-data'; # Import test case oashes
my $browser = LWP::UserAgent->new( );
if ($host !~ /https?:.+:/){
	if ($host =~ /http:/){
		$hport = 80;
	} elsif ($host =~ /https:/){
		$hport = 443;
	}
	$hostport = "$hostname:$hport";
} else {
	$hostport = "$hostname";
}
$browser->credentials("$hostport", 'LedgerSMB', $ENV{LSMB_USER} => $ENV{LSMB_PASS});

# cookie setup
my $cookie = HTTP::Cookies->new(
	"$LedgerSMB::Sysconfig::cookie_name" => "1:1:$db"
);
$browser->cookie_jar($cookie);

for my $test (@$test_request_data){
	next if $test->{_skip_lwp};
	my $argstr = "";
        my $module = "";
	for $key (keys %$test){
		if ($key eq 'module'){
			$module = $test->{"$key"}
		}
		elsif ($key !~ /^\_/){
			$argstr .= "&" . "$key=".$test->{"$key"};
		}
	}
	$argstr =~ s/^&//;
	my $url="$host$module?$argstr&company=$db";
	my $response = $browser->get($url);
	ok($response->is_success(), "$test->{_test_id} RESPONSE 200")
		|| print STDERR "# " .$response->status_line() . ":$url\n";
	if ($test->{format} eq 'PDF'){
		cmp_ok($response->header('content-type'), 'eq', 
			'application/pdf', "$test->{_test_id} PDF sent");
	} else {
		like($response->header('content-type'), qr/^text\/html/,
			"$test->{_test_id} HTML sent");
	}
	if (ref($lwp_tests->{"$test->{_test_id}"}) eq 'CODE'){
		&$lwp_tests->{"$test->{_test_id}"};
	}
}
