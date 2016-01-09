use Test::More;

my @reqenv = qw(TEST_SAUCE SAUCE_USERNAME SAUCE_ACCESS_KEY);
my @missing = grep { ! $ENV{$_} } @reqenv;
if (@missing) {
    plan skip_all => join (' and ', @missing) . ' not set';
    ok(1);
} else {
    plan tests => 2;
    require Selenium::Remote::Driver;
    my $user = $ENV{SAUCE_USERNAME};
    my $passwd = $ENV{SAUCE_ACCESS_KEY};
    my $host = "$user:$passwd\@localhost";

    my $driver = new Selenium::Remote::Driver(
                          'remote_server_addr' => $host,
                          'port' => 4445,
                          'browser_name' => "chrome",
                          'version' => "46",
                          'platform' => "Linux",
                          'extra_capabilities' => {
                            'tunnel-identifier' => $ENV{TRAVIS_JOB_NUMBER},
                          },
                          );
    $driver->get('http://localhost:5000/login.pl');

    ok($driver->find_element_by_name('password'), 'got a password');

    $driver->get('http://localhost:5000/setup.pl');

    ok($driver->find_element_by_name('s_passwd'), 'got a password');
}
