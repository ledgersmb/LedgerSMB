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
openapi: 3.0.0
info:
  title: LedgerSMB API
  version: 0.0.1
  contact:
    name: "LedgerSMB API Support"
    url: "https://github.com/ledgersmb/LedgerSMB/issues"
  description: LedgerSMB API
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
      name: LedgerSMB-1.10
