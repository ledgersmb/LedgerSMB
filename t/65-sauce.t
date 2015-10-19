use Test::More;

my @reqenv = qw(TEST_SAUCE SAUCE_USERNAME SAUCE_ACCESS_KEY);
my @missing = grep { ! $ENV{$_} } @reqenv;
if (@missing) {
    plan skip_all => 'not a told to: ' . join (' and ', @missing) . ' not set';
    ok(1);
} else {
    plan tests => 2;
    require Selenium::Remote::Driver;
    my $host = "$ENV{SAUCE_USERNAME}:$ENV{SAUCE_ACCESS_KEY}\@ondemand.saucelabs.com";

    my $driver = new Selenium::Remote::Driver(
                          'remote_server_addr' => $host,
                          'port' => "80",
                          'browser_name' => "chrome",
                          'version' => "46",
                          'platform' => "Linux",
                          );
    $driver->get('http://saucelabs.com:5000/login.pl');

    ok($driver->find_element_by_name('password'), 'got a password');

    $driver->get('http://saucelabs.com:5000/setup.pl');

    ok($driver->find_element_by_name('s_passwd'), 'got a password');
}
