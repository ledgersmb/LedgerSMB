package LedgerSMB::Routes::ERP::API::Products;

=head1 NAME

LedgerSMB::Routes::ERP::API::Products - Webservice routes for goods & services

=head1 DESCRIPTION

Webservice routes for goods & services

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Products;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_CREATED HTTP_NOT_FOUND HTTP_CONFLICT );
use Plack::Request::WithEncoding;

use LedgerSMB::Company;
use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.products';
set api_schema => openapi_schema(\*DATA);


sub _add_warehouse {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO warehouse (description) VALUES (?)
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description} ) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            id => $row->{id},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}

sub _del_warehouse {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM warehouse WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $id ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_warehouse {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag FROM warehouse WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($id) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return undef unless $row;
    return (
        {
            id => $row->{id},
            description => $row->{description},
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_warehouses {
    my ($c) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT * FROM warehouse|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            id => $row->{id},
            description => $row->{description},
        };
    }
    die $sth->errstr if $sth->err;

    return \@results;
}

sub _update_warehouse {
    my ($c, $w, $m) = @_;
    my $sth = $c->dbh->prepare(
        q|UPDATE warehouse SET description = ?
           WHERE id = ? AND md5(last_updated::text) = ?
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{id}, $m->{ETag} ) or die $sth->errstr;
    if ($sth->rows == 0) {
        my ($response, $meta) = _get_warehouse($c, $w->{id});
        return (undef, {}) unless $response;

        # Obviously, the hashes must have mismatched
        return (undef, { conflict => 1 });
    }

    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            id => $row->{id},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}


get api '/products/warehouses/' => sub {
    my ($env, $body, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my $response = _get_warehouses( $c );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/products/warehouses/' => sub {
    my ($env, $body, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my ($response, $meta) = _add_warehouse( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del '/products/warehouses/:id' => sub {
    my ($env, $body, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my $response = _del_warehouse( $c, $params->{id} );

    return [ HTTP_NOT_FOUND, [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
             [ 'Not found' ] ]
        unless defined $response;

    return [ HTTP_OK, [ ], [ '' ] ];
};

get '/products/warehouses/:id' => sub {
    my ($env, $body, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my ($response, $meta) = _get_warehouse( $c, $params->{id} );

    return [ HTTP_NOT_FOUND, [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
             [ 'Not found' ] ]
        unless defined $response;

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put '/products/warehouses/:id' => sub {
    my ($env, $body, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*"(.*)"\s*$/);
    my ($response, $meta) = _update_warehouse(
        $c, {
            id => $params->{id},
            description => $body->{description}
        },
        {
            ETag => $ETag
        });

    return [ HTTP_CONFLICT, [], [ '' ] ]
        if ($meta->{conflict});

    return [ HTTP_NOT_FOUND, [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
             [ 'Not found' ] ]
        unless defined $response;

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};

patch '/products/warehouses/:id' => sub {
    my ($env, $body, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);
    my $type = ($r->parameters->{type} // '') =~ s/[*]//gr;
    my $partnumber = ($r->parameters->{partnumber} // '') =~ s/[*]//gr;
    my $description = ($r->parameters->{description} // '') =~ s/[*]//gr;

    return [ HTTP_OK, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             [ json()->encode(
                   0
               ) ] ];
};


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;


__DATA__
openapi: 3.0.0
info:
  title: Retrieval of warehouse configuration
  version: 0.0.1
paths:
  /products/warehouses/:
    get:
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Warehouse'
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/NewWarehouse'
      responses:
        201:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
            Location:
              schema:
                type: string
                format: uri-reference
  /products/warehouses/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/warehouse-id'
        style: simple
    get:
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Warehouse'
        304:
          description: ...
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
    put:
      parameters:
        - name: If-Match
          in: header
          required: true
          schema:
            type: string
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Warehouse'
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Warehouse'
        304:
          description: ...
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        412:
          $ref: '#/components/responses/412'
        413:
          $ref: '#/components/responses/413'
        428:
          $ref: '#/components/responses/428'
    delete:
      parameters:
        - name: 'If-Match'
          in: header
          required: true
          schema:
            type: string
      responses:
        204:
          description: ...
    patch:
      parameters:
        - name: 'If-Match'
          in: header
          required: true
          schema:
            type: string
      responses:
        200:
          description: ...
components:
  headers:
    ETag:
      description: ...
      required: true
      schema:
        type: string
    If-Match:
      description: ...
      required: true
      schema:
        type: string
  schemas:
    warehouse-id:
      type: integer
      format: int64
      minimum: 1
    Warehouse:
      allOf:
        - $ref: '#/components/schemas/NewWarehouse'
        - type: object
          required:
            - id
          properties:
            id:
              $ref: '#/components/schemas/warehouse-id'
    NewWarehouse:
      type: object
      required:
        - description
      properties:
        name:
          type: string
  responses:
    400:
      description: Bad request
    401:
      description: Unauthorized
    403:
      description: Forbidden
    404:
      description: Not Found
    412:
      description: Precondition failed (If-Match header)
    413:
      description: Payload too large
    428:
      description: Precondition required
