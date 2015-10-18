use Test::More;
BEGIN: {
    if ($ENV{TRAVIS_PULL_REQUEST} and $ENV{TEST_SAUCE}){
        plan tests => 2;
    } else {
        plan skipall => 'not a pull request' unless $ENV{TRAVIS_PULL_REQUEST};
        exit 0;
    }
}

use Selenium::Remote::Driver;

my $host = "$ENV{SAUCE_USER_NAME}:$ENV{SAUCE_API_KEY}\@ondemand.saucelabs.com";

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
