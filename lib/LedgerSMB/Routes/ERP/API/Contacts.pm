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

use HTTP::Status qw( HTTP_OK HTTP_NO_CONTENT HTTP_CREATED HTTP_CONFLICT HTTP_FORBIDDEN);

use LedgerSMB::PSGI::Util qw( template_response );
use LedgerSMB::Report::Listings::Business_Type;
use LedgerSMB::Report::Listings::SIC;
use LedgerSMB::Router appname => 'erp/api';
use LedgerSMB::Routes::ERP::API;

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
    my ($c, $formatter) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag FROM sic ORDER BY code|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            code => $row->{code},
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


get api '/contacts/sic' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $formatter = $env->{wire}->get( 'output_formatter' );

    if (my $format = $r->query_parameters->get('format')) {
        my $report = LedgerSMB::Report::Listings::SIC->new(
            _dbh => $c->dbh,
            language => 'en',
            );
        my $renderer = $formatter->report_doc_renderer( $c->dbh, {}, $format );

        return template_response( $report->render( renderer => $renderer ),
                                  disposition => 'attach');
    }

    my $response = _get_sics( $c, $formatter );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/contacts/sic' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_sic( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/contacts/sic/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    # my $response = _del_sic( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return [ HTTP_FORBIDDEN, [ ], [ '' ] ];
};

get api '/contacts/sic/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    return undef if !$params->{id};
    my ($response, $meta) = _get_sic( $c, $params->{id} );

    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/contacts/sic/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*(?>W\/)?"(.*)"\s*$/);
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

patch api '/contacts/sic/{id}' => sub {
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
            discount => $row->{discount} + 0 # string to number conversion
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
            discount => $row->{discount} + 0 # string to number conversion
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_businesstypes {
    my ($c, $formatter) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT * FROM business ORDER BY id|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            id => $row->{id},
            description => $row->{description},
            discount => $row->{discount} + 0 # string to number conversion
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
            discount => $row->{discount} + 0 # Force string to float
        },
        {
            ETag => $row->{etag}
        });
}


get api '/contacts/business-types' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $formatter = $env->{wire}->get( 'output_formatter' );

    if (my $format = $r->query_parameters->get('format')) {
        my $report = LedgerSMB::Report::Listings::Business_Type->new(
            _dbh => $c->dbh,
            language => 'en',
            );
        my $renderer = $formatter->report_doc_renderer( $c->dbh, {}, $format );

        return template_response( $report->render( renderer => $renderer ),
                                  disposition => 'attach');
    }

    my $response = _get_businesstypes( $c, $formatter );
    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/contacts/business-types' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_businesstype( $c, $body );

    return $response && [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/contacts/business-types/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    # my $response = _del_businesstype( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return [ HTTP_FORBIDDEN, [ ], [ '' ] ];
};

get api '/contacts/business-types/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    return undef if !$params->{id};
    my ($response, $meta) = _get_businesstype( $c, $params->{id} );

    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/contacts/business-types/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ m/^\s*(?>W\/)?"(.*)"\s*$/);
    my ($response, $meta) = _update_businesstype(
        $c, {
            id => $params->{id},
            description => $body->{description},
            discount => $body->{discount}
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

patch api '/contacts/business-types/{id}' => sub {
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
  /contacts/sic:
    description: Collection of Standard Industry Codes (SICs)
    get:
      tags:
        - SICs
      summary: Get a list of SICs
      operationId: getSICs
      responses:
        200:
          description: Returns the list of SIC codes
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
                      $ref: '#/components/schemas/SIC'
              examples:
                validSICs:
                  $ref: '#/components/examples/validSICs'
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
        - SICs
      summary: Add SIC entry
      operationId: postSIC
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SIC'
      responses:
        201:
          description: Confirms creation of the new SIC, redirecting to the new resource URI
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
  /contacts/sic/{id}:
    description: Management of individual Standard Industry Code items
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/sic-code'
        style: simple
    get:
      tags:
        - SICs
      summary: Get a single SIC
      operationId: getSICById
      responses:
        200:
          description: Returns the data associated with the SIC code
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/SIC'
              examples:
                validSIC:
                  $ref: '#/components/examples/validSIC'
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
        - SICs
      summary: Update a single SIC
      operationId: putSICByCode
      parameters:
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SIC'
      responses:
        200:
          description: Confirms replacement of SIC resource, returning the new data
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SIC'
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
        - SICs
      summary: Delete a single SIC
      operationId: deleteSICByCode
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        204:
          description: Confirms deletion of the SIC resource
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
        428:
          $ref: '#/components/responses/428'
    patch:
      tags:
        - SICs
      summary: Update a single SIC
      operationId: updateSICByCode
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        200:
          description: Confirms updating the data associated with the SIC code, returning the new SIC data
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SIC'
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
  /contacts/business-types:
    description: Manage business types
    get:
      tags:
        - Business types
      summary: Get business types
      operationId: getBusinessTypes
      responses:
        200:
          description: Returns the list of business types
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
                      $ref: '#/components/schemas/BusinessType'
              examples:
                validBusinessTypes:
                  $ref: '#/components/examples/validBusinessTypes'
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
        - Business types
      summary: Create a business type
      operationId: postBusinessType
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/NewBusinessType'
      responses:
        201:
          description: Confirms creation of the new business type, redirecting to the new resource URI
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
  /contacts/business-types/{id}:
    description: Manage business type
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/business-type-id'
        style: simple
    get:
      tags:
        - Business types
      summary: Get a single business type
      operationId: getBusinessTypesById
      responses:
        200:
          description: Returns the requested business type data
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/BusinessType'
              examples:
                validBusinessType:
                  $ref: '#/components/examples/validBusinessType'
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
        - Business types
      summary: Update a single business type
      operationId: putBusinessTypesById
      parameters:
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/BusinessType'
      responses:
        200:
          description: Confirms replacement of the business type data
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BusinessType'
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
        - Business types
      summary: Delete a single business type
      operationId: deleteBusinessTypesById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        204:
          description: Confirms deletion of the business type resource
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
        428:
          $ref: '#/components/responses/428'
    patch:
      tags:
        - Business types
      summary: Update a single business type
      operationId: updateBusinessTypesById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        200:
          description: Confirms updating the business type data, returning the new resource data
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BusinessType'
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
components:
  headers:
    ETag:
      description: ...
      required: true
      schema:
        type: string
  parameters:
    if-match:
      name: If-Match
      in: header
      description: ...
      required: true
      schema:
        type: string
  examples:
    validSICs:
      summary: Valid SICs (collection response)
      description: SIC collection response
      value:
        _links: []
        items:
        - code: "541510"
          description: Design of computer systems
    validSIC:
      summary: Valid SIC
      description: Standard Industry Code
      value:
        code: "541510"
        description: Design of computer systems
    validBusinessTypes:
      summary: Valid Business Types (collection response)
      description: Business Types collection response
      value:
        _links: []
        items:
        - id: 1
          description: Big customer
          discount: 0.05
    validBusinessType:
      summary: Valid Business Type
      description: Business Type Entry
      value:
        id: 1
        description: Big customer
        discount: 0.05
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
      allOf:
      - $ref: '#/components/schemas/NewBusinessType'
      - type: object
        required:
          - id
        properties:
          id:
            $ref: '#/components/schemas/business-type-id'
    NewBusinessType:
      type: object
      required:
        - description
      properties:
        description:
          type: string
        discount:
          type: number
          format: float
