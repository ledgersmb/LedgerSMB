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
    my $query = 'SELECT preference__set(?, ?)';
    my $sth = $dbh->prepare($query);
    for my $setting ($data->@*) {
        $sth->execute($setting->{setting}, $setting->{value})
            or die $sth->errstr;
    }
};



1;
