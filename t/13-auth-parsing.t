#!/usr/bin/perl

use Test::More (tests => 7);
use MIME::Base64;
use strict;
use warnings;

BEGIN{
use_ok('LedgerSMB::Auth');
};
my $colonpasswd = 'Test:Test2';
my $pluspasswd = 'Test+Test2';
my $excpasswd = 'Test!Test2';

my $username = 'Foo';
my $auth_token;
my $got_creds;


# Colons
$auth_token = MIME::Base64::encode("$username:$colonpasswd");
$got_creds = LedgerSMB::Auth::factory(
    { HTTP_AUTHORIZATION => 'Basic ' . $auth_token }
    )->get_credentials;
is($got_creds->{login}, $username, 'username returned');
is($got_creds->{password}, $colonpasswd, 'username returned');

# Plus sign
$auth_token = MIME::Base64::encode("$username:$pluspasswd");
$got_creds = LedgerSMB::Auth::factory(
    { HTTP_AUTHORIZATION => 'Basic ' . $auth_token }
    )->get_credentials;
is($got_creds->{login}, $username, 'username returned');
is($got_creds->{password}, $pluspasswd, 'username returned');

# Exclamation point
$auth_token = MIME::Base64::encode("$username:$excpasswd");
$got_creds = LedgerSMB::Auth::factory(
    { HTTP_AUTHORIZATION => 'Basic ' . $auth_token }
    )->get_credentials;
is($got_creds->{login}, $username, 'username returned');
is($got_creds->{password}, $excpasswd, 'username returned');
