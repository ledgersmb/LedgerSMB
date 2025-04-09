package LedgerSMB::Routes::ERP::API::Countries;

=head1 NAME

LedgerSMB::Routes::ERP::API::Countries - Webservice routes for configured countries

=head1 DESCRIPTION

Webservice routes for configuration of countries

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Countries;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_NO_CONTENT HTTP_CREATED HTTP_CONFLICT HTTP_FORBIDDEN );
use JSON::MaybeXS;
use Locale::CLDR;

use LedgerSMB::PSGI::Util qw( template_response );
use LedgerSMB::Report::Listings::Country;
use LedgerSMB::Router appname => 'erp/api';
use LedgerSMB::Routes::ERP::API;

set logger => 'erp.api.countries';
set api_schema => openapi_schema(\*DATA);


##############################################################################
#
#
#     COUNTRIES
#
#
#############################################################################


sub _add_country {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO country (name, short_name) VALUES (?, ?)
          RETURNING *, md5(last_updated::text) as etag|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{name}, $w->{code} ) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            name => $row->{name},
            code => $row->{short_name}
        },
        {
            ETag => $row->{etag}
        });
}

sub _del_country {
    my ($c, $code) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM country WHERE short_name = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $code ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_country {
    my ($c, $code) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag,
                 country.short_name is not distinct from (select "value"
                                                       from defaults
                                                      where setting_key = 'default_country') as "default"
            FROM country WHERE short_name = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($code) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return undef unless $row;
    return (
        {
            code => $row->{short_name},
            default => $row->{default} ? JSON::MaybeXS->true : JSON::MaybeXS->false,
            name => $row->{name},
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_countries {
    my ($env, $c, $formatter) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *,
             md5(last_updated::text) as etag,
             country.short_name is not distinct from (select "value"
                                from defaults
                               where setting_key = 'default_country') as "default"
            FROM country ORDER BY name|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;

    my $locale = locale($env);
    my $regions = Locale::CLDR->new($locale->language_tag)->all_regions;
    my @results;

    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            _meta => {
                ETag => $row->{etag},
            },
            code => $row->{short_name},
            default => $row->{default} ? JSON::MaybeXS->true : JSON::MaybeXS->false,
            name => $row->{name},
            localizedName => $regions->{$row->{short_name}} // $row->{name},
        };
    }
    die $sth->errstr if $sth->err;

    my $fc = scalar $formatter->get_formats->@*;
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

sub _update_country {
    my ($c, $w, $m) = @_;

    $c->dbh->do('SAVEPOINT set_default')
        or die $c->dbh->errstr;
    if ($w->{default}) {
        $c->dbh->do(q|
             INSERT INTO defaults (setting_key, value)
                VALUES ('default_country', $1)
             ON CONFLICT (setting_key) DO UPDATE SET value = $1
|, {}, $w->{code})
            or die $c->dbh->errstr;
    }

    my $sth = $c->dbh->prepare(
        q|UPDATE country SET name = ?
           WHERE short_name = ? AND md5(last_updated::text) = ?
          RETURNING *, md5(last_updated::text) as etag,
             country.short_name is not distinct from (select "value"
                                                   from defaults
                                                  where setting_key = 'default_country') as "default"|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{name}, $w->{code}, $m->{ETag} )
        or die $sth->errstr;
    if ($sth->rows == 0) {
        $c->dbh->do('ROLLBACK TO SAVEPOINT set_default')
            or die $c->dbh->errstr;
        my ($response, $meta) = _get_country($c, $w->{code});
        return (undef, {}) unless $response;

        # Obviously, the hashes must have mismatched
        return (undef, { conflict => 1 });
    }

    $c->dbh->do('RELEASE SAVEPOINT set_default')
        or die $c->dbh->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return (
        {
            name => $row->{name},
            default => $row->{default} ? JSON::MaybeXS->true : JSON::MaybeXS->false,
            code => $row->{short_name}
        },
        {
            ETag => $row->{etag}
        });
}


get api '/countries' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $formatter = $env->{wire}->get( 'output_formatter' );

    if (my $format = $r->query_parameters->get('format')) {
        my $report = LedgerSMB::Report::Listings::Country->new(
            _dbh => $c->dbh,
            language => 'en',
            );
        my $renderer = $formatter->report_doc_renderer( $c->dbh, {}, $format );

        return template_response( $report->render( renderer => $renderer ),
                                  disposition => 'attach');
    }

    my $response = _get_countries($env, $c, $formatter);
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/countries' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_country( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/countries/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    # my $response = _del_country( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return [ HTTP_FORBIDDEN, [ ], [ '' ] ];
};

get api '/countries/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _get_country( $c, $params->{id} );

    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/countries/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ s/^\s*(W\/)?"|"\s*$//gr);
    my ($response, $meta) = _update_country(
        $c, {
            code => $params->{id},
            default => $body->{default},
            name    => $body->{name}
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

patch api '/countries/{id}' => sub {
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

Copyright (C) 2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;


__DATA__
paths:
  /countries:
    description: Management of country configuration
    get:
      tags:
        - Countries
      summary: Get available countries
      operationId: getCountries
      responses:
        200:
          description: Returns a list of configured countries
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
                      $ref: '#/components/schemas/Country'
                    example:
                      $ref: '#/components/examples/validCountry'
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
        - Countries
      summary: Create a country
      operationId: postCountry
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Country'
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
  /countries/{id}:
    description: Manage a single country
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/country-code'
        style: simple
    get:
      tags:
        - Countries
      summary: Get a single country
      operationId: getCountryById
      responses:
        200:
          description: Returns the data associated with the country
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Country'
              examples:
                validCountry:
                  $ref: '#/components/examples/validCountry'
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
        - Countries
      summary: Update a single country
      operationId: putCountryById
      parameters:
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Country'
      responses:
        200:
          description: Confirms replacement of country data, returning the new data
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Country'
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
        - Countries
      summary: Delete a single country
      operationId: deleteCountryById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        204:
          description: Confirms deletion of the country resource
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
        428:
          $ref: '#/components/responses/428'
    patch:
      tags:
        - Countries
      summary: Update a single country
      operationId: updateCountryById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        200:
          description: Confirms updating the country resource, returning the new data
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
  schemas:
    country-code:
      type: string
      pattern: '^[a-zA-Z]{2}$'
    Country:
      type: object
      required:
        - code
        - name
      properties:
        _meta:
          type: object
        code:
          $ref: '#/components/schemas/country-code'
        default:
          type: boolean
        name:
          type: string
        localizedName:
          type: string
  examples:
    validCountry:
      summary: Valid Country
      description: Netherlands entry
      value:
        code: NL
        default: false
        name: Netherlands
