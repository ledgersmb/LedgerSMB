#!perl

use strict;
use warnings;

use Test::More;
use YAML qw(LoadFile);

# If we choose to depend on environment variables,
# uncomment the next lines and initialize reqenv with their names
#my @reqenv = qw();
#my @missing = grep { ! $ENV{$_} } @reqenv;
#
#plan skip_all => join (' and ', @missing) . ' not set'
#    if @missing;

plan tests => 2;
require Selenium::Client;

my $config_data_whole = LoadFile('t/.pherkin.yaml');
my $selenium = $config_data_whole->{default}->{extensions}->{"Pherkin::Extension::Weasel"}->{sessions}->{selenium};

my $browser = $selenium->{driver}->{caps}->{browser} =~ /\$\{([^\}]+)\}/
          ? $ENV{$1} // "phantomjs"
          : $selenium->{driver}->{caps}->{browser};

my $remote_server_addr = $selenium->{driver}->{caps}->{host} =~ /\$\{([a-zA-Z0-9_]+)\}/
          ? $ENV{$1} // "localhost"
          : $selenium->{driver}->{caps}->{host};

my $base_url = $selenium->{base_url} =~ /\$\{([a-zA-Z0-9_]+)\}/
          ? $ENV{$1} // "http://localhost:5000"
          : $selenium->{base_url};

my %caps = (
          port => $selenium->{driver}->{caps}->{port},
          browser => $browser,
    host => $remote_server_addr
);

my $driver = Selenium::Client->new(%caps)
          || die "Unable to connect to remote browser";

my ($sess_caps, $sess) = $driver->NewSession();

$sess->SetTimeouts(implicit => 30000); # 30s
$sess->NavigateTo(url => $base_url . '/login.pl');

ok($sess->FindElement(using => 'css selector', value => '[name="password"]'), 'got a password');

$sess->NavigateTo(url => $base_url . '/setup.pl');

ok($sess->FindElement(using => 'css selector', value => '[name="s_password"]'), 'got a user');

