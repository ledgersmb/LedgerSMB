package LedgerSMB::Routes::ERP::API::Accounts;

=head1 NAME

LedgerSMB::Routes::ERP::API::Accounts - Webservice routes for GL accounts

=head1 DESCRIPTION

Webservice routes for goods & services

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Accounts;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use LedgerSMB::DBObject::Account;
use LedgerSMB::Router appname => 'erp/api';

use HTTP::Status qw( HTTP_OK );
use Plack::Request::WithEncoding;

set logger => 'erp.api.accounts';


get '/accounts/', sub {
    my ($env) = @_;
    my $req = Plack::Request::WithEncoding->new($env);
    my $label = $req->parameters->{label} // '';
    $label =~ s/\*//g;

    my $account = LedgerSMB::DBObject::Account->new(dbh => $env->{'lsmb.app'});
    return [ HTTP_OK,
             [ 'Content-Type' => '' ],
             [ json()->encode(
                   [
                    grep { (! $label) || $_->{label} =~ m/\Q$label\E/i }
                    map { $_->{label} = $_->{accno} . '--' . $_->{description};
                          $_ }
                    $account->list()
                   ])
             ]
        ];
};


get '/accounts/:id', sub {
    my ($env, %p) = @_;
};

post '/accounts/', sub {

};

del '/accounts/:id', sub {

};


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
