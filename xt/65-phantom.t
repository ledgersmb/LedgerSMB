#!perl

use Test::More;

#if (@missing) {
#    plan skip_all => join (' and ', @missing) . ' not set';
#    ok(1);
#} else {
    plan tests => 2;
    require Selenium::Remote::Driver;

    my $base_url = $ENV{LSMB_BASE_URL} // 'http://localhost:5000';

    my $driver = new Selenium::Remote::Driver(
        port => 4422,
        remote_server_addr => $ENV{REMOTE_SERVER_ADDR} // 'localhost'
                          )
    || die "Unable to connect to PhantomJS";
    $driver->set_implicit_wait_timeout(30000); # 30s
    $driver->get("$base_url/login.pl");

    ok($driver->find_element_by_name('password'), 'got a password');

    $driver->get("$base_url/setup.pl");

    ok($driver->find_element_by_name('s_password'), 'got a user');
#}
