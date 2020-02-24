package LedgerSMB::Routes::ERP::API::MenuNodes;

=head1 NAME

LedgerSMB::Routes::ERP::API::MenuNodes - Webservice routes for menu nodes

=head1 DESCRIPTION

Webservice routes for menu nodes

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::MenuNodes;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK );
use JSON::MaybeXS;

use LedgerSMB::DBObject::Menu;
use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.menu-nodes';

my $json = JSON::MaybeXS->new( pretty => 1,
                               utf8 => 1,
                               indent => 1,
                               convert_blessed => 1,
                               allow_bignum => 1);


get '/menu-nodes/' => sub {
    my ($env) = @_;
    my $locale = locale($env);

    my $menu = LedgerSMB::DBObject::Menu->new(dbh => $env->{'lsmb.app'});
    $menu->generate;
    $_->{label} = $locale->maketext($_->{label})
        for (@{$menu->{menu_items}});

    return [ 200, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             [ $json->encode( $menu->{menu_items} ) ] ];
};


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
