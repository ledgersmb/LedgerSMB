use Test::More (tests => 3);
use MIME::Base64;
use strict;
use warnings;

BEGIN{
use_ok('LedgerSMB::Auth');
};
my $colonpasswd = 'Test:Test2';

my $username = 'Foo';

my $auth_token = MIME::Base64::encode("$username:$colonpasswd");
$ENV{'HTTP_AUTHORIZATION'} = $auth_token;

my $got_creds = LedgerSMB::Auth::get_credentials;

is($got_creds->{login}, $username, 'username returned');
is($got_creds->{password}, $colonpasswd, 'username returned');
