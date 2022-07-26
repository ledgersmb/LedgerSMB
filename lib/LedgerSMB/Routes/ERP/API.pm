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
