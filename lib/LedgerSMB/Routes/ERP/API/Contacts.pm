package LedgerSMB::Routes::ERP::API::Contacts;

=head1 NAME

LedgerSMB::Routes::ERP::API::Contacts - Webservice routes for contacts

=head1 DESCRIPTION

Webservice routes for managing contacts and related configuration.

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Contacts;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_CREATED HTTP_CONFLICT );

use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.contacts';
set api_schema => openapi_schema(\*DATA);


##############################################################################
#
#
#     SIC
#
#
#############################################################################


sub _add_sic {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO sic (code, description) VALUES (?, ?)
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{code}, $w->{description} ) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            code => $row->{code},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}

sub _del_sic {
    my ($c, $code) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM sic WHERE code = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $code ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_sic {
    my ($c, $code) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag FROM sic WHERE code = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($code) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return undef unless $row;
    return (
        {
            code => $row->{code},
            description => $row->{description},
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_sics {
    my ($c) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT * FROM sic ORDER BY code|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            code => $row->{code},
            description => $row->{description},
        };
    }
    die $sth->errstr if $sth->err;

    return \@results;
}

sub _update_sic {
    my ($c, $w, $m) = @_;
    my $sth = $c->dbh->prepare(
        q|UPDATE sic SET description = ?
           WHERE code = ? AND md5(last_updated::text) = ?
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{code}, $m->{ETag} )
        or die $sth->errstr;
    if ($sth->rows == 0) {
        my ($response, $meta) = _get_sic($c, $w->{code});
        return (undef, {}) unless $response;

        # Obviously, the hashes must have mismatched
        return (undef, { conflict => 1 });
    }

    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            code => $row->{code},
            description => $row->{description}
        },
        {
            ETag => $row->{etag}
        });
}


get api '/contacts/sic/' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _get_sics( $c );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/contacts/sic/' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_sic( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/contacts/sic/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _del_sic( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return $response && [ HTTP_OK, [ ], [ '' ] ];
};

get api '/contacts/sic/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _get_sic( $c, $params->{id} );

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/contacts/sic/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*"(.*)"\s*$/);
    my ($response, $meta) = _update_sic(
        $c, {
            code => $params->{id},
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

patch api '/contacts/sic/:id' => sub {
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
#     BUSINESS TYPES
#
#
#############################################################################


sub _add_businesstype {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO business (description, discount) VALUES (?, ?)
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{discount} ) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            id => $row->{id},
            description => $row->{description},
            discount => $row->{discount},
        },
        {
            ETag => $row->{etag}
        });
}

sub _del_businesstype {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM business WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $id ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_businesstype {
    my ($c, $id) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag FROM business WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($id) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return undef unless $row;
    return (
        {
            id => $row->{id},
            description => $row->{description},
            discount => $row->{discount},
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_businesstypes {
    my ($c) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT * FROM business ORDER BY id|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            id => $row->{id},
            description => $row->{description},
            discount => $row->{discount},
        };
    }
    die $sth->errstr if $sth->err;

    return \@results;
}

sub _update_businesstype {
    my ($c, $w, $m) = @_;
    my $sth = $c->dbh->prepare(
        q|UPDATE business SET description = ?, discount = ?
           WHERE id = ? AND md5(last_updated::text) = ?
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{discount}, $w->{id}, $m->{ETag} )
        or die $sth->errstr;
    if ($sth->rows == 0) {
        my ($response, $meta) = _get_businesstype($c, $w->{id});
        return (undef, {}) unless $response;

        # Obviously, the hashes must have mismatched
        return (undef, { conflict => 1 });
    }

    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            id => $row->{id},
            description => $row->{description},
            discount => $row->{discount},
        },
        {
            ETag => $row->{etag}
        });
}


get api '/contacts/business-types/' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _get_businesstypes( $c );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/contacts/business-types/' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_businesstype( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/contacts/business-types/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my $response = _del_businesstype( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return $response && [ HTTP_OK, [ ], [ '' ] ];
};

get api '/contacts/business-types/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _get_businesstype( $c, $params->{id} );

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/contacts/business-types/:id' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*"(.*)"\s*$/);
    my ($response, $meta) = _update_businesstype(
        $c, {
            id => $params->{id},
            description => $body->{description},
            discount => $body->{discount},
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

patch api '/contacts/business-types/:id' => sub {
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
  title: Management of industry codes configuration
  version: 0.0.1
paths:
  /contacts/sic/:
    get:
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/SIC'
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SIC'
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
  /contacts/sic/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/sic-code'
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
                $ref: '#/components/schemas/SIC'
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
              $ref: '#/components/schemas/SIC'
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SIC'
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
  /contacts/business-types/:
    get:
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/BusinessType'
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/BusinessType'
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
  /contacts/business-types/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/business-type-id'
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
                $ref: '#/components/schemas/BusinessType'
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
              $ref: '#/components/schemas/BusinessType'
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BusinessType'
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
    sic-code:
      type: string
      minLength: 1
    SIC:
      type: object
      required:
        - code
        - description
      properties:
        code:
          $ref: '#/components/schemas/sic-code'
        description:
          type: string
    business-type-id:
      type: number
      format: int64
    BusinessType:
      type: object
      required:
        - id
        - description
      properties:
        id:
          $ref: '#/components/schemas/business-type-id'
        description:
          type: string
        discount:
          type: number
          format: float
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
