package LedgerSMB::Routes::ERP::API::Languages;

=head1 NAME

LedgerSMB::Routes::ERP::API::Languages - Webservice routes for configured languages

=head1 DESCRIPTION

Webservice routes for configuration of languages

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Languages;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_NO_CONTENT HTTP_CREATED HTTP_CONFLICT HTTP_FORBIDDEN );
use JSON::MaybeXS;

use LedgerSMB::PSGI::Util qw( template_response );
use LedgerSMB::Report::Listings::Language;
use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.languages';
set api_schema => openapi_schema(\*DATA);


##############################################################################
#
#
#     LANGUAGES
#
#
#############################################################################


sub _add_language {
    my ($c, $w) = @_;
    my $sth = $c->dbh->prepare(
        q|INSERT INTO language (code, description) VALUES (?, ?)
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

sub _del_language {
    my ($c, $code) = @_;
    my $sth = $c->dbh->prepare(
        q|DELETE FROM language WHERE code = ?|
        ) or die $c->dbh->errstr;

    $sth->execute( $code ) or die $sth->errstr;
    return undef unless $sth->rows > 0;

    return 1;
}

sub _get_language {
    my ($c, $code) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *, md5(last_updated::text) as etag,
                 language.code is not distinct from (select "value"
                                                       from defaults
                                                      where setting_key = 'default_language') as "default"
            FROM language WHERE code = ?|
        ) or die $c->dbh->errstr;

    $sth->execute($code) or die $sth->errstr;
    my $row = $sth->fetchrow_hashref('NAME_lc');
    die $sth->errstr if $sth->err;

    return undef unless $row;
    return (
        {
            code => $row->{code},
            default => $row->{default} ? JSON::MaybeXS->true : JSON::MaybeXS->false,
            description => $row->{description},
        },
        {
            ETag => $row->{etag}
        });
}

sub _get_languages {
    my ($c, $formatter) = @_;
    my $sth = $c->dbh->prepare(
        q|SELECT *,
             md5(last_updated::text) as etag,
             language.code is not distinct from (select "value"
                                from defaults
                               where setting_key = 'default_language') as "default"
            FROM language ORDER BY code|
        ) or die $c->dbh->errstr;

    $sth->execute() or die $sth->errstr;
    my @results;
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @results, {
            _meta => {
                ETag => $row->{etag},
            },
            code => $row->{code},
            default => $row->{default} ? JSON::MaybeXS->true : JSON::MaybeXS->false,
            description => $row->{description},
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

sub _update_language {
    my ($c, $w, $m) = @_;

    $c->dbh->do('SAVEPOINT set_default')
        or die $c->dbh->errstr;
    if ($w->{default}) {
        $c->dbh->do(q|
                INSERT INTO defaults (setting_key, value)
                   VALUES ('default_language', $1)
                 ON CONFLICT (setting_key) DO UPDATE SET value = $1
|, {}, $w->{code})
            or die $c->dbh->errstr;
    }

    my $sth = $c->dbh->prepare(
        q|UPDATE language SET description = ?
           WHERE code = ? AND md5(last_updated::text) = ?
          RETURNING *, md5(last_updated::text) as etag,
             language.code is not distinct from (select "value"
                                                   from defaults
                                                  where setting_key = 'default_language') as "default"|
        ) or die $c->dbh->errstr;

    $sth->execute( $w->{description}, $w->{code}, $m->{ETag} )
        or die $sth->errstr;
    if ($sth->rows == 0) {
        $c->dbh->do('ROLLBACK TO SAVEPOINT set_default')
            or die $c->dbh->errstr;
        my ($response, $meta) = _get_language($c, $w->{code});
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
            code => $row->{code},
            default => $row->{default} ? JSON::MaybeXS->true : JSON::MaybeXS->false,
            description => $row->{description},
        },
        {
            ETag => $row->{etag}
        });
}


get api '/languages' => sub {
    my ($env, $r, $c, $body, $params) = @_;
    my $formatter = $env->{wire}->get( 'output_formatter' );

    if (my $format = $r->query_parameters->get('format')) {
        my $report = LedgerSMB::Report::Listings::Language->new(
            _dbh => $c->dbh,
            language => 'en',
            );
        my $renderer = $formatter->report_doc_renderer( $c->dbh, {}, $format );

        return template_response( $report->render( renderer => $renderer ),
                                  disposition => 'attach');
    }

    my $response = _get_languages( $c, $formatter );
    return [ 200,
             [ 'Content-Type' => 'application/json; charset=UTF-8' ],
             $response  ];
};

post api '/languages' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _add_language( $c, $body );
    return [
        HTTP_CREATED,
        [ 'Content-Type' => 'application/json; charset=UTF-8',
          'ETag' => qq|"$meta->{ETag}"|
        ],
        $response ];
};

del api '/languages/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    # my $response = _del_language( $c, $params->{id} );

    # return 'undef' if $response is undef, which it is when not found
    return [ HTTP_FORBIDDEN, [ ], [ '' ] ];
};

get api '/languages/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($response, $meta) = _get_language( $c, $params->{id} );

    return $response && [ HTTP_OK,
             [ 'Content-Type' => 'application/json; charset=UTF-8',
               'ETag' => qq|"$meta->{ETag}"| ],
             $response ];
};


put api '/languages/{id}' => sub {
    my ($env, $r, $c, $body, $params) = @_;

    my ($ETag) = ($r->headers->header('If-Match') =~ s/^\s*(W\/)?"|"\s*$//gr);
    my ($response, $meta) = _update_language(
        $c, {
            code => $params->{id},
            default => $body->{default},
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

patch api '/languages/{id}' => sub {
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
  /languages:
    description: Management of language configuration
    get:
      tags:
        - Languages
      summary: Get available languages
      operationId: getLanguages
      responses:
        200:
          description: Returns the full set of configured languages
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
                      $ref: '#/components/schemas/Language'
              examples:
                validLanguages:
                  $ref: '#/components/examples/validLanguages'
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
        - Languages
      summary: Create a language
      operationId: postLanguage
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Language'
      responses:
        201:
          description: |
            Confirms successfull creation of the new resource (language),
            returning the data from the resource and in the Location header
            the canonical location to access the resource.
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
  /languages/{id}:
    description: Manage a single language
    parameters:
      - name: id
        in: path
        required: true
        schema:
          $ref: '#/components/schemas/language-code'
        style: simple
    get:
      tags:
        - Languages
      summary: Get a single language
      operationId: getLanguageById
      responses:
        200:
          description: Returns the requested single resource's data
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            'application/json':
              schema:
                $ref: '#/components/schemas/Language'
              examples:
                validLanguage:
                  $ref: '#/components/examples/validLanguage'
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
        - Languages
      summary: Update a single language
      operationId: putLanguageById
      parameters:
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Language'
      responses:
        200:
          description: |
            Confirms successful replacement of the resource's data,
            returning the new data of the resource.
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Language'
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
        - Languages
      summary: Delete a single language
      operationId: deleteLanguageById
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
        - Languages
      summary: Update a single language
      operationId: updateLanguageById
      parameters:
        - $ref: '#/components/parameters/if-match'
      responses:
        200:
          description: |
            Confirms successful update,
            returning the new data for the resource
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
components:
  schemas:
    language-code:
      type: string
      pattern: '^[a-z]{2}(_[A-Z]{2})?$'
      example: fr_CA
    Language:
      type: object
      required:
        - code
        - description
      properties:
        _meta:
          type: object
        code:
          $ref: '#/components/schemas/language-code'
        default:
          type: boolean
        description:
          type: string
          example: French (Canada)
  examples:
    validLanguages:
      summary: Valid languages (collection response)
      description: languages collection response
      value:
        _links: []
        items:
        - code: fr_CA
          default: false
          description: French (Canada)
        - code: nl_NL
          default: false
          description: Dutch (Netherlands)
    validLanguage:
      summary: Valid Language
      description: French Canadian entry
      value:
        code: fr_CA
        default: false
        description: French (Canada)
