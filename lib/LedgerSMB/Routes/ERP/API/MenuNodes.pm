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

use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.menu-nodes';
set api_schema => openapi_schema(\*DATA);

get api '/menu-nodes' => sub {
    my ($env, undef, $c) = @_;
    my $locale = locale($env);

    my $sth = $c->dbh->prepare('select * from menu_generate()');
    $sth->execute or die $sth->errstr;

    my @menu;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @menu, {
            id     => $row->{id},
            url    => $row->{url},
            menu   => $row->{menu} ? \1 : \0,
            label  => $locale->maketext($row->{label}),
            parent => $row->{parent}
        };
    }
    die $sth->errstr if $sth->err;

    return [ 200, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             \@menu ];
};


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;


__DATA__
openapi: 3.0.0
info:
  title: Menu items for the active user
  version: 0.0.1
paths:
  /menu-nodes:
    description: Menu items for the active user
    get:
      tags:
        - UserMenu
      summary: Get the user's menu items
      operationId: getUserMenuNodes
      responses:
        200:
          description: ...
          content:
             application/json:
               schema:
                 type: array
                 items:
                   type: object
                   required:
                     - id
                     - url
                     - parent
                     - label
                     - menu
                   properties:
                     id:
                       type: number
                     url:
                       type: string
                     parent:
                       type: number
                     label:
                       type: string
                     menu:
                       type: boolean
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
components:
  responses:
    400:
      description: Bad request
    401:
      description: Unauthorized
    403:
      description: Forbidden
    404:
      description: Not Found
