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

use HTTP::Status qw( HTTP_OK HTTP_NO_CONTENT HTTP_CREATED HTTP_CONFLICT HTTP_FORBIDDEN );

use LedgerSMB::PSGI::Util qw( template_response );
use LedgerSMB::Report::Inventory::Partsgroups;
use LedgerSMB::Report::Inventory::Pricegroups;
use LedgerSMB::Report::Listings::Warehouse;
use LedgerSMB::Router appname => 'erp/api';
use LedgerSMB::Routes::ERP::API;

set logger => 'erp.api.products';
set api_schema => openapi_schema(\*DATA);


##############################################################################
#
#
#     PARTSGROUPS
#
#
#############################################################################

sub _add_partsgroup {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO partsgroup (parent, partsgroup) VALUES (?, ?)
          RETURNING id, parent, partsgroup as description, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{parent}, $w->{description} ) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            id => $row->{id},
            parent => $row->{parent},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}

sub _del_partsgroup {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM partsgroup WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $id ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_partsgroup {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT id, parent, partsgroup as description,
                 md5(last_updated::text) as etag FROM partsgroup WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($id) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return undef unless $row;
    return (
        {
            id => $row->{id},
            parent => $row->{parent},
            description => $row->{description},
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_partsgroups {
    my ($c, $formatter) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT id, parent, partsgroup as description,
                 md5(last_updated::text) as etag
          FROM partsgroup ORDER BY id|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            id => $row->{id},
            parent => $row->{parent},
            description => $row->{description},
            _meta => { ETag => $row->{etag} }
        };
    }
    die $sth->errstr if $sth->err;

    return {
        items => \@results,
        _links => [
            map {
                +{
                    rel => 'download',
                    href => "?format=$_",
                    title => $_
                }
            } $formatter->get_formats->@* ]
    };
}

sub _update_partsgroup {
    my ($c, $w, $m) = @_;
    my $sth = $c->dbh->prepare(
        q|UPDATE partsgroup SET partsgroup = ?
           WHERE id = ? AND md5(last_updated::text) = ?
          RETURNING id, parent, partsgroup as description, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{id}, $m->{ETag} ) or die $sth->errstr;
    if ($sth->rows == 0) {
        my ($response, $meta) = _get_partsgroup($c, $w->{id});
        return (undef, {}) unless $response;

        # Obviously, the hashes must have mismatched
        return (undef, { conflict => 1 });
    }

    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            id => $row->{id},
            parent => $row->{parent},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}

get api '/products/partsgroups' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $formatter = $env->{wire}->get( 'output_formatter' );

    if (my $format = $r->query_parameters->get('format')) {
        my $report = LedgerSMB::Report::Inventory::Partsgroups->new(
            _dbh => $c->dbh,
            language => 'en',
            );
        my $renderer = $formatter->report_doc_renderer( $c->dbh, {}, $format );

        return template_response( $report->render( renderer => $renderer ),
                                  disposition => 'attach');
    }

    my $response = _get_partsgroups( $c, $formatter );
    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/products/partsgroups' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_partsgroup( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/products/partsgroups/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    #my $response = _del_partsgroup( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return [ HTTP_FORBIDDEN, [ ], [ '' ] ];
};

get api '/products/partsgroups/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    return undef if !$params->{id};
    my ($response, $meta) = _get_partsgroup( $c, $params->{id} );

    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/products/partsgroups/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    $env->{'psgix.logger'}->({
        message => "PUT /products/partsgroups/$params->{id}",
        level => 'info' });
    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*(?>W\/)?"(.*)"\s*$/);
    my ($response, $meta) = _update_partsgroup(
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

patch api '/products/partsgroups/{id}' => sub {
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
    my ($c, $formatter) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT id, pricegroup as description,
                 md5(last_updated::text) as etag
          FROM pricegroup ORDER BY id|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            id => $row->{id},
            description => $row->{description},
            _meta => { ETag => $row->{etag} }
        };
    }
    die $sth->errstr if $sth->err;

    return {
        items => \@results,
        _links => [
            map {
                +{
                    rel => 'download',
                    href => "?format=$_",
                    title => $_
                }
            } $formatter->get_formats->@* ]
    };
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
        my ($response, $meta) = _get_pricegroup($c, $w->{id});
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

get api '/products/pricegroups' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $formatter = $env->{wire}->get( 'output_formatter' );

    if (my $format = $r->query_parameters->get('format')) {
        my $report = LedgerSMB::Report::Inventory::Pricegroups->new(
            _dbh => $c->dbh,
            language => 'en',
            );
        my $renderer = $formatter->report_doc_renderer( $c->dbh, {}, $format );

        return template_response( $report->render( renderer => $renderer ),
                                  disposition => 'attach');
    }

    my $response = _get_pricegroups( $c, $formatter );
    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/products/pricegroups' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_pricegroup( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/products/pricegroups/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    #my $response = _del_pricegroup( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return [ HTTP_FORBIDDEN, [ ], [ '' ] ];
};

get api '/products/pricegroups/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    return undef if !$params->{id};
    my ($response, $meta) = _get_pricegroup( $c, $params->{id} );

    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/products/pricegroups/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*(?>W\/)?"(.*)"\s*$/);
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

patch api '/products/pricegroups/{id}' => sub {
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
    my ($c, $formatter) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag FROM warehouse ORDER BY id|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            id => $row->{id},
            description => $row->{description},
            _meta => { ETag => $row->{etag} }
        };
    }
    die $sth->errstr if $sth->err;

    return {
        items => \@results,
        _links => [
            map {
                +{
                    rel => 'download',
                    href => "?format=$_",
                    title => $_
                }
            } $formatter->get_formats->@* ]
    };
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


get api '/products/warehouses' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $formatter = $env->{wire}->get( 'output_formatter' );

    if (my $format = $r->query_parameters->get('format')) {
        my $report = LedgerSMB::Report::Listings::Warehouse->new(
            _dbh => $c->dbh,
            language => 'en',
            );
        my $renderer = $formatter->report_doc_renderer( $c->dbh, {}, $format );

        return template_response( $report->render( renderer => $renderer ),
                                  disposition => 'attach');
    }

    my $response = _get_warehouses( $c, $formatter );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/products/warehouses' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_warehouse( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/products/warehouses/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    # my $response = _del_warehouse( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return [ HTTP_FORBIDDEN, [ ], [ '' ] ];
};

get api '/products/warehouses/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    return undef if !$params->{id};
    my ($response, $meta) = _get_warehouse( $c, $params->{id} );

    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/products/warehouses/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*(?>W\/)?"(.*)"\s*$/);
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

patch api '/products/warehouses/{id}' => sub {
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
paths:
  /products/partsgroups:
    description: Managing products and related configuration
    get:
      tags:
        - Parts groups
      summary: Get products parts groups
      operationId: getProductsPartsgroups
      responses:
        200:
          description: Returns the full list of defined parts groups
          content:
            application/json:
              schema:
                type: object
                required:
                  - items
                properties:
                  _links:
                    type: array
                    items:
                      type: object
                  items:
                    type: array
                    items:
                      $ref: '#/components/schemas/Partsgroup'
                    example:
                      $ref: '#/components/examples/validPartsgroup'
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
        - Parts groups
      summary: Create products parts group
      operationId: postProductsPartsgroup
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/NewPartsgroup'
      responses:
        201:
          description: |
            Confirms creation of the new resource, returning
            the new data
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
  /products/partsgroups/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/partsgroup-id'
        style: simple
    get:
      tags:
        - Parts groups
      summary: Get a single products parts group
      operationId: getProductsPartsgroupById
      responses:
        200:
          description: |
            Returns the data for a single resource
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Partsgroup'
              examples:
                validPartsgroup:
                  $ref: '#/components/examples/validPartsgroup'
        304:
          $ref: '#/components/responses/304'
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
        - Parts groups
      summary: Create single products parts group
      operationId: putProductsPartsgroupById
      parameters:
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Partsgroup'
      responses:
        200:
          description: |
            Confirms successful replacement of the
            resource's data, returning the new state
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Partsgroup'
        304:
          $ref: '#/components/responses/304'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
        412:
          $ref: '#/components/responses/412'
        413:
          $ref: '#/components/responses/413'
        428:
          $ref: '#/components/responses/428'
    delete:
      tags:
        - Parts groups
      summary: Delete a single products price group
      operationId: deleteProductsPartsgroupById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        204:
          description: Confirms successful deletion of the resource
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
    patch:
      tags:
        - Parts groups
      summary: Updaet a single products parts group
      operationId: updateProductsPartsgroupById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        200:
          description: |
            Confirms successful update of the resource,
            returning the new resource state
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
  /products/pricegroups:
    description: Managing products and related configuration
    get:
      tags:
        - Price groups
      summary: Get products price groups
      operationId: getProductsPricegroups
      responses:
        200:
          description: Returns the full list of defined price groups
          content:
            application/json:
              schema:
                type: object
                required:
                  - items
                properties:
                  _links:
                    type: array
                    items:
                      type: object
                  items:
                    type: array
                    items:
                      $ref: '#/components/schemas/Pricegroup'
                    example:
                      $ref: '#/components/examples/validPricegroup'
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
          description: |
            Confirms creation of the new resource, returning
            the new data
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
          description: |
            Returns the data for a single resource
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Pricegroup'
              examples:
                validPricegroup:
                  $ref: '#/components/examples/validPricegroup'
        304:
          $ref: '#/components/responses/304'
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
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Pricegroup'
      responses:
        200:
          description: |
            Confirms successful replacement of the
            resource's data, returning the new state
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Pricegroup'
        304:
          $ref: '#/components/responses/304'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
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
        - $ref: '#/components/parameters/if-match'
      responses:
        204:
          description: Confirms successful deletion of the resource
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
    patch:
      tags:
        - Price groups
      summary: Update a single products price group
      operationId: updateProductsPricegroupById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        200:
          description: |
            Confirms successful update of the resource, returning
            the new resource state
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
  /products/warehouses:
    description: Manage warehouses
    get:
      tags:
        - Warehouses
      summary: Get a list of warehouses
      operationId: getWarehouses
      responses:
        200:
          description: Returns the full set of configured warehouses
          content:
            application/json:
              schema:
                type: object
                required:
                  - items
                properties:
                  _links:
                    type: array
                    items:
                      type: object
                  items:
                    type: array
                    items:
                      $ref: '#/components/schemas/Warehouse'
                    example:
                      validWarehouse:
                        $ref: '#/components/examples/validWarehouse'
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
          description: |
            Confirms successful creation of the new resource,
            returning the new data
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
          description: Returns the data of a single resource
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Warehouse'
              examples:
                validWarehouse:
                  $ref: '#/components/examples/validWarehouse'
        304:
          $ref: '#/components/responses/304'
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
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Warehouse'
      responses:
        200:
          description: |
            Confirms successful replacement of the resources data,
            returning the new state
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Warehouse'
        304:
          $ref: '#/components/responses/304'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
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
        - $ref: '#/components/parameters/if-match'
      responses:
        204:
          description: Confirms deletion of the resource
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
    patch:
      tags:
        - Warehouses
      summary: Update a single warehouse
      operationId: updateWarehousesById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        200:
          description: |
            Confirms successful update of the resource,
            returning the new state
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        409:
          $ref: '#/components/responses/409'
components:
  schemas:
    common-id:
      type: integer
      format: int64
      minimum: 1
    partsgroup-id:
      $ref: '#/components/schemas/common-id'
    Partsgroup:
      allOf:
        - $ref: '#/components/schemas/NewPartsgroup'
        - type: object
          required:
            - id
          properties:
            id:
              $ref: '#/components/schemas/partsgroup-id'
    NewPartsgroup:
      type: object
      required:
        - description
      properties:
        description:
          type: string
        parent:
          type: integer
          format: int64
          minimum: 1
          nullable: true
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
  examples:
    validPartsgroup:
      summary: Valid Partsgroup
      description: Partsgroup entry
      value:
        id: 1
        parent: null
        description: Partsgroup1
    validPricegroup:
      summary: Valid Pricegroup
      description: Pricegroup entry
      value:
        id: 1
        description: Pricegroup1
    validWarehouse:
      summary: Valid Warehouse
      description: Warehouse entry
      value:
        id: 1
        description: Warehouse1
