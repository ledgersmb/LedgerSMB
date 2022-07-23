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

use HTTP::Status qw( HTTP_OK HTTP_CREATED HTTP_CONFLICT );

use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.products';
set api_schema => openapi_schema(\*DATA);


##############################################################################
#
#
#     PRICEGROUPS
#
#
#############################################################################

sub _add_pricegroup {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO pricegroup (pricegroup) VALUES (?)
          RETURNING id, pricegroup as description, md5(last_updated::text) as etag|
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

sub _del_pricegroup {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM pricegroup WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $id ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_pricegroup {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT id, pricegroup as description,
                 md5(last_updated::text) as etag FROM pricegroup WHERE id = ?|
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

sub _get_pricegroups {
    my ($c) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT id, pricegroup as description FROM pricegroup ORDER BY id|
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

sub _update_pricegroup {
    my ($c, $w, $m) = @_;
    my $sth = $c->dbh->prepare(
        q|UPDATE pricegroup SET pricegroup = ?
           WHERE id = ? AND md5(last_updated::text) = ?
          RETURNING id, pricegroup as description, md5(last_updated::text) as etag|
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



get api '/products/pricegroups/' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _get_pricegroups( $c );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/products/pricegroups/' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_pricegroup( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/products/pricegroups/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _del_pricegroup( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return $response && [ HTTP_OK, [ ], [ '' ] ];
};

get api '/products/pricegroups/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _get_pricegroup( $c, $params->{id} );

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/products/pricegroups/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*"(.*)"\s*$/);
    my ($response, $meta) = _update_pricegroup(
        $c, {
            id => $params->{id},
            description => $body->{description}
        },
        {
            ETag => $ETag
        });

    return [ HTTP_CONFLICT, [], [ '' ] ]
        if ($meta->{conflict});

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};

patch api '/products/pricegroups/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $type = ($r->parameters->{type} // '') =~ s/[*]//gr;
    my $partnumber = ($r->parameters->{partnumber} // '') =~ s/[*]//gr;
    my $description = ($r->parameters->{description} // '') =~ s/[*]//gr;

    return [ HTTP_OK, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             [ json()->encode(
                   0
               ) ] ];
};


##############################################################################
#
#
#     WAREHOUSES
#
#
#############################################################################


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
        q|SELECT * FROM warehouse ORDER BY id|
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
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _get_warehouses( $c );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/products/warehouses/' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_warehouse( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/products/warehouses/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _del_warehouse( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return $response && [ HTTP_OK, [ ], [ '' ] ];
};

get api '/products/warehouses/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _get_warehouse( $c, $params->{id} );

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/products/warehouses/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

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

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};

patch api '/products/warehouses/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;
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
  title: Managing products and related configuration
  version: 0.0.1
paths:
  /products/pricegroups:
    description: Managing products and related configuration
    get:
      tags:
        - Price groups
      summary: Get products price groups
      operationId: getProductsPricegroups
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Pricegroup'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
    post:
      tags:
        - Price groups
      summary: Create products price group
      operationId: postProductsPricegroup
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/NewPricegroup'
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
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
  /products/pricegroups/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/pricegroup-id'
        style: simple
    get:
      tags:
        - Price groups
      summary: Get a single products price group
      operationId: getProductsPricegroupById
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Pricegroup'
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
      tags:
        - Price groups
      summary: Create single products price group
      operationId: putProductsPricegroupById
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
              $ref: '#/components/schemas/Pricegroup'
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Pricegroup'
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
      tags:
        - Price groups
      summary: Delete a single products price group
      operationId: deleteProductsPricegroupById
      parameters:
        - name: 'If-Match'
          in: header
          required: true
          schema:
            type: string
      responses:
        204:
          description: ...
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
    patch:
      tags:
        - Price groups
      summary: Update a single products price group
      operationId: updateProductsPricegroupById
      parameters:
        - name: 'If-Match'
          in: header
          required: true
          schema:
            type: string
      responses:
        200:
          description: ...
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
  /products/warehouses:
    description: Manage warehouses
    get:
      tags:
        - Warehouses
      summary: Get a list of warehouses
      operationId: getWarehouses
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Warehouse'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
    post:
      tags:
        - Warehouses
      summary: Create a warehouse
      operationId: postWarehouse
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
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
  /products/warehouses/{id}:
    description: Manage a warehouse
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/warehouse-id'
        style: simple
    get:
      tags:
        - Warehouses
      summary: Get a single warehouse
      operationId: getWarehousesById
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
      tags:
        - Warehouses
      summary: Update a single warehouse
      operationId: putWarehousesById
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
      tags:
        - Warehouses
      summary: Delete a single warehouse
      operationId: deleteWarehousesById
      parameters:
        - name: 'If-Match'
          in: header
          required: true
          schema:
            type: string
      responses:
        204:
          description: ...
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
    patch:
      tags:
        - Warehouses
      summary: Update a single warehouse
      operationId: updateWarehousesById
      parameters:
        - name: 'If-Match'
          in: header
          required: true
          schema:
            type: string
      responses:
        200:
          description: ...
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
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
    common-id:
      type: integer
      format: int64
      minimum: 1
    pricegroup-id:
      $ref: '#/components/schemas/common-id'
    Pricegroup:
      allOf:
        - $ref: '#/components/schemas/NewPricegroup'
        - type: object
          required:
            - id
          properties:
            id:
              $ref: '#/components/schemas/pricegroup-id'
    NewPricegroup:
      type: object
      required:
        - description
      properties:
        description:
          type: string
    warehouse-id:
      $ref: '#/components/schemas/common-id'
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
        description:
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
