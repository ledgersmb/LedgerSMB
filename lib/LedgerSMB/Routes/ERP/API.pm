package LedgerSMB::Routes::ERP::API;

=head1 NAME

LedgerSMB::Routes::ERP::API - Webservice routes header

=head1 DESCRIPTION

Webservice routes for configuration of languages

=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use LedgerSMB::Router appname => 'erp/api';


set api_schema => openapi_schema(\*DATA);


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;


__DATA__
openapi: 3.0.3
info:
  title: LedgerSMB API
  version: 0.0.1
  contact:
    name: "LedgerSMB API Support"
    url: "https://github.com/ledgersmb/LedgerSMB/issues"
    email: devel@lists.ledgersmb.org
  description: |
    LedgerSMB comes with a web service API. The version number assigned follows
    the [rules of semantic versioning](https://semver.org/). The current major
    version is 0 (zero), meaning that it's not considered to have stabilized
    yet. The main reason is that not all functions have been ironed out yet:
    filtering, sorting and pagination are to be specified and implemented.

    The API is hosted on `erp/api/v0`, on the same root as `login.pl`. That is
    to say that if LedgerSMB's login screen is hosted at
    `https://example.org/login.pl` then the API can be found at
    `https://example.org/erp/api/v0`. All paths mentioned in this document will
    be appended to that. E.g. the items in the menu for the authenticated user
    can be accessed through `https://example.org/erp/api/v0/menu-nodes`.
  license:
    name: GPL-2.0-or-later
    url: https://spdx.org/licenses/GPL-2.0-or-later.html
servers:
  - url: 'http://lsmb/erp/api/v0'
security:
  - cookieAuth: []
components:
  headers:
    ETag:
      description: |
        The API uses the ETag parameter to prevent different clients modifying
        the same resource around the same time from overwriting each other's
        data: the later updates will be rejected based on verification of this
        parameter.
        Clients need to retain the ETag returned on a request when they might
        want to update the values later.
      required: true
      schema:
        type: string
  parameters:
    if-match:
      name: If-Match
      in: header
      description: |
        Clients need to provide the If-Match parameter on update operations
        (PUT and PATCH) with the ETag obtained in the request from which
        data are being updated. Requests missing this header will be
        rejected with HTTP response code 428. Requests trying to update
        outdated content will be rejected with HTTP response code 412.
      required: true
      schema:
        type: string
  responses:
    304:
      description: Not modified
    400:
      description: Bad request
    401:
      description: Unauthorized
    403:
      description: Forbidden
    404:
      description: Not Found
    409:
      description: Conflict
    412:
      description: Precondition failed (If-Match header)
    413:
      description: Payload too large
    428:
      description: Precondition required
  securitySchemes:
    cookieAuth:
      type: apiKey
      in: cookie
      name: LedgerSMB
      description: |
        The authenticating cookie can be obtained by sending a `POST` request
        to `login.pl?__action=authenticate&company=<url-encoded-company` with a
        JSON object in the body of the request, containing these three fields

        * company
        * username
        * password

        as if they had been entered on the login page in the browser. Please
        note that the request `Content-Type` must be set to `application/json`
        and that an `X-Requested-With` header is expected with the value
        `XMLHttpRequest`.

        **Note**: the cookie value is updated on each response; the next
        request *must* be executed with the new cookie value.

        **Note 2**: the validity of the cookie is as long the user's timeout
        when logged into the application (default: 90 minutes).

        **Note 3**: Sites may customize the name of the cookie in order to run
        multiple versions in parallel. The advice is to append the version name
        to the cookie, resulting in cookie name `LedgerSMB-1.1` for LedgerSMB
        version 1.1.
