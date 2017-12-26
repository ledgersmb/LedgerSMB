#!perl

use strict;
use warnings;

use Test::More;
use YAML::Syck;

# If we choose to depend on environment variables,
# uncomment the next lines and initialize reqenv with their names
#my @reqenv = qw();
#my @missing = grep { ! $ENV{$_} } @reqenv;
#
#plan skip_all => join (' and ', @missing) . ' not set'
#    if @missing;

plan tests => 2;
require Selenium::Remote::Driver;

my $config_data_whole = LoadFile('t/.pherkin.yaml');
my $selenium = $config_data_whole->{default}->{extensions}->{"Pherkin::Extension::Weasel"}->{sessions}->{selenium};

my $browser = $selenium->{driver}->{caps}->{browser_name} =~ /\$\{([^\}]+)\}/
          ? $ENV{$1} // "phantomjs"
          : $selenium->{driver}->{caps}->{browser_name};

my $remote_server_addr = $selenium->{driver}->{caps}->{remote_server_addr} =~ /\$\{([a-zA-Z0-9_]+)\}/
          ? $ENV{$1} // "localhost"
          : $selenium->{driver}->{caps}->{remote_server_addr};

my $base_url = $selenium->{base_url} =~ /\$\{([a-zA-Z0-9_]+)\}/
          ? $ENV{$1} // "http://localhost:5000"
          : $selenium->{base_url};

my %caps = (
          port => $selenium->{driver}->{caps}->{port},
          browser_name => $browser,
          remote_server_addr => $remote_server_addr
);

my $driver = Selenium::Remote::Driver->new(%caps)
          || die "Unable to connect to remote browser";

$driver->set_implicit_wait_timeout(30000); # 30s
$driver->get($base_url . '/login.pl');

ok($driver->find_element_by_name('password'), 'got a password');

$driver->get($base_url . '/setup.pl');

ok($driver->find_element_by_name('s_password'), 'got a user');

