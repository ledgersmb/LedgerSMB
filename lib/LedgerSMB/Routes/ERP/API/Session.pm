package LedgerSMB::Routes::ERP::API::Session;

=head1 NAME

LedgerSMB::Routes::ERP::API::Session - Webservice routes for the current session

=head1 DESCRIPTION

Webservice routes for the current session

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Session;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK );

use LedgerSMB::DBObject::Menu;
use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.session';


get '/session' => sub {
    my ($env) = @_;
    my $locale = locale($env);

    my $dbh = $env->{'lsmb.app'};
    my $result = {};
    my $sth = $dbh->prepare(
        q|SELECT * FROM admin__get_roles_for_user_by_entity(person__get_my_entity_id())|
        );
    $sth->execute;
    $result->{roles} = [ sort map { $_->[0] } @{$sth->fetchall_arrayref() // []} ];
    die $sth->errstr if $sth->err;

    $sth = $dbh->prepare(q|SELECT user__check_my_expiration()|);
    $sth->execute;
    if (my $expiration = $sth->fetchrow_arrayref()) {
        $result->{password_expiration} = $expiration->[0];
    }
    else {
        $result->{password_expiration} = '';
    }
    die $sth->errstr if $sth->err;

    $sth = $dbh->prepare(
        q|SELECT * FROM user__get_preferences((select id from employee__get_user(person__get_my_entity_id())))|
        ) or die $dbh->errstr;
    $sth->execute;
    $result->{preferences} = $sth->fetchrow_hashref('NAME_lc')
        or die $sth->errstr;
    $result->{preferences} //= {};

    $sth = $dbh->prepare(
        q|SELECT * FROM defaults WHERE setting_key = '__disableToaster'|
        );
    $sth->execute;
    if ($sth->fetchrow_arrayref) {
        $result->{preferences}->{__disableToaster} = 1;
    }

    return [ 200, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             [ json()->encode( $result ) ] ];
};


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
