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

use HTTP::Status qw( HTTP_OK HTTP_CREATED HTTP_BAD_REQUEST HTTP_NOT_FOUND
    HTTP_UNSUPPORTED_MEDIA_TYPE HTTP_INTERNAL_SERVER_ERROR );
use JSONSchema::Validator;
use Plack::Request::WithEncoding;
use YAML::PP;

use LedgerSMB::Company;
use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.products';


my $reader = YAML::PP->new(boolean => 'JSON::PP');
my $schema = $reader->load_string(
    do {
        # slurp __DATA__ section
        local $/ = undef;
        <DATA>;
    });
my $validator = JSONSchema::Validator->new(
    schema => $schema,
    specification => 'OAS30');


sub _add_warehouse {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO warehouse (description) VALUES (?) RETURNING *|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description} ) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return {
        id => $row->{id},
        description => $row->{description}
    };
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
        q|SELECT * FROM warehouse WHERE id = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($id) or die $sth->errstr;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        return {
            id => $row->{id},
            description => $row->{description},
        };
    }
    die $sth->errstr if $sth->err;

    return undef;
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
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|UPDATE warehouse SET description = ? WHERE id = ? RETURNING *|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{id} ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return $row;
}


get '/products/warehouses/' => sub {
    my ($env, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);
    my ($result, $errors, $warnings) =
        $validator->validate_request(
            method => 'GET',
            openapi_path => '/products/warehouses/',
            parameters => {
                path => $params,
                header => { $r->headers->psgi_flatten->@* },
                query => $r->query_parameters->as_hashref_mixed,
            });
    return error($r, HTTP_BAD_REQUEST, [], @$errors)
        if scalar(@$errors) > 0;

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my $response = _get_warehouses( $c );
    my $triplet = [ 200, [ 'Content-Type' => 'application/json; charset=UTF-8' ],
                    [ json()->encode( $response ) ] ];
    ($result, $errors, $warnings) =
        $validator->validate_response(
            method => 'GET',
            openapi_path => '/products/warehouses/',
            status => $triplet->[0],
            parameters => {
                header => { $triplet->[1]->@* },
                path => $params,
                query => $r->query_parameters->as_hashref_mixed,
                body => [1, 'application/json', $response]
            });
    return error($r, HTTP_INTERNAL_SERVER_ERROR, [], @$errors)
        if scalar(@$errors) > 0;

    return $triplet;
};

post '/products/warehouses/' => sub {
    my ($env, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    {
        my $ct = $r->headers->content_type;
        unless ($ct eq 'application/json') {
            return error(
                $r,
                HTTP_UNSUPPORTED_MEDIA_TYPE,
                {
                    msg     => 'Unexpected Content-Type header',
                    details => "Content-Type value '$ct' provided, but 'application/json expected"
                });
        }
    }
    my $body = json()->decode($r->content);
    my ($result, $errors, $warnings) =
        $validator->validate_request(
            method => 'POST',
            openapi_path => '/products/warehouses/',
            parameters => {
                path => $params,
                query => $r->query_parameters->as_hashref_mixed,
                header => { $r->headers->psgi_flatten->@* },
                body => [1, 'application/json', $body]
            });
    return error($r, HTTP_BAD_REQUEST, [], @$errors)
        if scalar(@$errors) > 0;

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my $response = _add_warehouse( $c, $body );
    my $triplet = [ HTTP_CREATED,
                    [ 'Content-Type' => 'application/json; charset=UTF-8',
                      'ETag' => 'wazzzda'
                    ],
                    [ json()->encode( $response ) ] ];
    ($result, $errors, $warnings) =
        $validator->validate_response(
            method => 'POST',
            openapi_path => '/products/warehouses/',
            status => $triplet->[0],
            parameters => {
                header => { $triplet->[1]->@* },
                path => $params,
                query => $r->query_parameters->as_hashref_mixed,
                body => [1, 'application/json', $response]
            });
    return error($r, HTTP_INTERNAL_SERVER_ERROR, [], @$errors)
        if scalar(@$errors) > 0;

    return $triplet;
};

del '/products/warehouses/:id' => sub {
    my ($env, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    {
        my ($result, $errors, $warnings) =
            $validator->validate_request(
                method => 'DELETE',
                openapi_path => '/products/warehouses/{id}',
                parameters => {
                    path => $params,
                    header => { $r->headers->psgi_flatten->@* },
                    query => $r->query_parameters->as_hashref_mixed,
                });
        return error($r, HTTP_BAD_REQUEST, [], @$errors)
            if scalar(@$errors) > 0;
    }

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my $response = _del_warehouse( $c, $params->{id} );

    return [ HTTP_NOT_FOUND, [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
             [ 'Not found' ] ]
        unless defined $response;

    my $triplet = [ HTTP_OK, [ ],
                    [ '' ] ];
    my ($result, $errors, $warnings) =
        $validator->validate_response(
            method => 'DELETE',
            openapi_path => '/products/warehouses/{id}',
            status => $triplet->[0],
            parameters => {
                header => { $triplet->[1]->@* },
                path => $params,
                query => $r->query_parameters->as_hashref_mixed,
                body => [1, 'application/json', $response]
            });
    return error($r, HTTP_INTERNAL_SERVER_ERROR, [], @$errors)
        if scalar(@$errors) > 0;

    return $triplet;
};

get '/products/warehouses/:id' => sub {
    my ($env, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);
    {
        my ($result, $errors, $warnings) =
            $validator->validate_request(
                method => 'GET',
                openapi_path => '/products/warehouses/{id}',
                parameters => {
                    path => $params,
                    header => { $r->headers->psgi_flatten->@* },
                    query => $r->query_parameters->as_hashref_mixed,
                });
        return error($r, HTTP_BAD_REQUEST, [], @$errors)
            if scalar(@$errors) > 0;
    }

    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my $response = _get_warehouse( $c, $params->{id} );

    return [ HTTP_NOT_FOUND, [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
             [ 'Not found' ] ]
        unless defined $response;

    my $triplet = [ HTTP_OK,
                    [ 'Content-Type' => 'application/json; charset=UTF-8',
                      'ETag' => 'abc-def' ],
                    [ json()->encode( $response ) ] ];
    my ($result, $errors, $warnings) =
        $validator->validate_response(
            method => 'GET',
            openapi_path => '/products/warehouses/{id}',
            status => $triplet->[0],
            parameters => {
                header => { $triplet->[1]->@* },
                path => $params,
                query => $r->query_parameters->as_hashref_mixed,
                body => [1, 'application/json', $response]
            });
    return error($r, HTTP_INTERNAL_SERVER_ERROR, [], @$errors)
        if scalar(@$errors) > 0;

    return $triplet;
};


put '/products/warehouses/:id' => sub {
    my ($env, $params) = @_;
    my $r = Plack::Request::WithEncoding->new($env);

    {
        my $ct = $r->headers->content_type;
        unless ($ct eq 'application/json') {
            return error(
                $r,
                HTTP_UNSUPPORTED_MEDIA_TYPE,
                {
                    msg     => 'Unexpected Content-Type header',
                    details => "Content-Type value '$ct' provided, but 'application/json expected"
                });
        }
    }

    {
        my ($result, $errors, $warnings) =
            $validator->validate_request(
                method => 'PUT',
                openapi_path => '/products/warehouses/{id}',
                parameters => {
                    path => $params,
                    header => { $r->headers->psgi_flatten->@* },
                    query => $r->query_parameters->as_hashref_mixed,
                });
        return error($r, HTTP_BAD_REQUEST, [], @$errors)
            if scalar(@$errors) > 0;
    }

    my $body = json()->decode($r->content);
    my $c = LedgerSMB::Company->new(dbh => $env->{'lsmb.db'});
    my $response = _update_warehouse( $c,
                                      {
                                          id => $params->{id},
                                          description => $body->{description}
                                      } );

    return [ HTTP_NOT_FOUND, [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
             [ 'Not found' ] ]
        unless defined $response;

    my $triplet = [ HTTP_OK,
                    [ 'Content-Type' => 'application/json; charset=UTF-8',
                      'ETag' => '"quazar"' ],
                    [ json()->encode( $response ) ] ];
    my ($result, $errors, $warnings) =
        $validator->validate_response(
            method => 'PUT',
            openapi_path => '/products/warehouses/{id}',
            status => $triplet->[0],
            parameters => {
                header => { $triplet->[1]->@* },
                path => $params,
                query => $r->query_parameters->as_hashref_mixed,
                body => [1, 'application/json', $response]
            });
    return error($r, HTTP_INTERNAL_SERVER_ERROR, [], @$errors)
        if scalar(@$errors) > 0;

    return $triplet;
};

patch '/products/warehouses/:id' => sub {
    my ($env, $params) = @_;
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
