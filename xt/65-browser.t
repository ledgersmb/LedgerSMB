#!perl

use Test::More;

#if (@missing) {
#    plan skip_all => join (' and ', @missing) . ' not set';
#    ok(1);
#} else {
    plan tests => 2;
    require Selenium::Remote::Driver;

    my $browser = $self->{caps}{browser_name} =~ /\$\{([^\}]+)\}/;
    my $base = $self->base_url =~ /\$\{([a-zA-Z0-9_]+)\}/
             ? $ENV{$1} // "http://localhost:5000"
             : $self->base_url;
    my $driver = new Selenium::Remote::Driver(
                          'port' => 4422,
                          'browser_name' => $browser || 'phantomjs',
                          )
    || die "Unable to connect to PhantomJS";
    $driver->set_implicit_wait_timeout(30000); # 30s
    $driver->get($base . '/login.pl');

    ok($driver->find_element_by_name('password'), 'got a password');

    $driver->get($base . '/setup.pl');

    ok($driver->find_element_by_name('s_password'), 'got a user');
#}
