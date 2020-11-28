#!perl


use lib 'xt/lib';
use strict;
use warnings;


use Test::More;
use Test::BDD::Cucumber::StepFile;



###############
#
# Setup steps
#
###############


Given qr/these preferences for the (admin|user)(?: "([^"]+)")?:/, sub {
    my $reference_user = $1;
    my $user_name = $2 // S->{"the $reference_user"};
    my $data = C->data;

    my $dbh = S->{ext_lsmb}->admin_dbh;
    my $query = 'UPDATE user_preference SET ' . join(' ', map { "$_->{setting} = ?" } $data->@*)
        . ' WHERE id = (select id from users where username = ?)';
    $dbh->do($query, {}, (map { $_->{value} } $data->@*), $user_name )
        or die $dbh->errstr;
};



1;
