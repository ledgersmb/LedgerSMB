#!perl

use Test::More;

#if (@missing) {
#    plan skip_all => join (' and ', @missing) . ' not set';
#    ok(1);
#} else {
    plan tests => 2;
    require Selenium::Remote::Driver;

    my $driver = new Selenium::Remote::Driver(
                          'port' => 4422,
                          'browser_name' => 'phantomjs',
                          )
    || die "Unable to connect to PhantomJS";
    $driver->set_implicit_wait_timeout(30000); # 30s
    $driver->get('http://localhost:5000/login.pl');

    ok($driver->find_element_by_name('password'), 'got a password');

    $driver->get('http://localhost:5000/setup.pl');

    ok($driver->find_element_by_name('s_password'), 'got a user');
#}
