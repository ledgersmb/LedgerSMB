package LedgerSMB::Routes::ERP::API::GeneralLedger;

=head1 NAME

LedgerSMB::Routes::ERP::API::Ledger - Webservice routes for general ledger data

=head1 DESCRIPTION

Webservice routes for managing general accounting and related configuration.

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::GeneralLedger;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_CREATED HTTP_CONFLICT );

use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.gl';
set api_schema => openapi_schema(\*DATA);


##############################################################################
#
#
#     GIFI
#
#
#############################################################################


sub _add_gifi {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO gifi (accno, description) VALUES (?, ?)
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{accno}, $w->{description} ) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            accno => $row->{accno},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}

sub _del_gifi {
    my ($c, $accno) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM gifi WHERE accno = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $accno ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_gifi {
    my ($c, $accno) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag FROM gifi WHERE accno = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($accno) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return undef unless $row;
    return (
        {
            accno => $row->{accno},
            description => $row->{description},
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_gifis {
    my ($c) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT * FROM gifi ORDER BY accno|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            accno => $row->{accno},
            description => $row->{description},
        };
    }
    die $sth->errstr if $sth->err;

    return \@results;
}

sub _update_gifi {
    my ($c, $w, $m) = @_;
    my $sth = $c->dbh->prepare(
        q|UPDATE gifi SET description = ?
           WHERE accno = ? AND md5(last_updated::text) = ?
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{accno}, $m->{ETag} )
        or die $sth->errstr;
    if ($sth->rows == 0) {
        my ($response, $meta) = _get_gifi($c, $w->{accno});
        return (undef, {}) unless $response;

        # Obviously, the hashes must have mismatched
        return (undef, { conflict => 1 });
    }

    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            accno => $row->{accno},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}


get api '/gl/gifi' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _get_gifis( $c );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/gl/gifi' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_gifi( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/gl/gifi/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _del_sic( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return $response && [ HTTP_OK, [ ], [ '' ] ];
};

get api '/gl/gifi/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _get_gifi( $c, $params->{id} );

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/gl/gifi/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*"(.*)"\s*$/);
    my ($response, $meta) = _update_gifi(
        $c, {
            accno => $params->{id},
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

patch api '/gl/gifi/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $type = ($r->parameters->{type} // '') =~ s/[*]//gr;
    my $partnumber = ($r->parameters->{partnumber} // '') =~ s/[*]//gr;
    my $description = ($r->parameters->{description} // '') =~ s/[*]//gr;

    return [ HTTP_OK, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             [ json()->enaccno(
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
  title: Management of GIFI (canadian accounting) codes configuration
  version: 0.0.1
paths:
  /gl/gifi:
    description: A list of GIFI
    get:
      tags:
        - GIFI
      summary: Get a list of GIFI
      operationId: getWIFIs
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/GIFI'
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
        - GIFI
      summary: Create a single GIFI
      operationId: postWIFI
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/GIFI'
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
  /gl/gifi/{id}:
    description: A single GIFI
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/accno-code'
        style: simple
    get:
      tags:
        - GIFI
      summary: Get a single GIFI
      operationId: getWIFIById
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/GIFI'
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
        - GIFI
      summary: Put a single GIFI
      operationId: putWIFIById
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
              $ref: '#/components/schemas/GIFI'
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/GIFI'
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
        - GIFI
      summary: Delete a single GIFI
      operationId: deleteWIFIById
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
        - GIFI
      summary: Update a single GIFI
      operationId: updateWIFIById
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
    accno-code:
      type: string
      minLength: 1
    GIFI:
      type: object
      required:
        - accno
        - description
      properties:
        accno:
          $ref: '#/components/schemas/accno-code'
        description:
          type: string
          minLength: 1
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
