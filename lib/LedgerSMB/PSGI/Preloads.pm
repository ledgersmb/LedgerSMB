package LedgerSMB::PSGI::Preloads;

=head1 NAME

LedgerSMB::PSGI::Preloads - Modules to be pre-loaded for PSGI applications

=head1 SYNOPSIS

 use LedgerSMB::PSGI::Preloads;

=cut

use strict;
use warnings;

# Preloads
use LedgerSMB;
use LedgerSMB::Auth;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;
use LedgerSMB::Template::HTML;
use LedgerSMB::Locale;
use LedgerSMB::File;
use LedgerSMB::Scripts::login;
use LedgerSMB::PGObject;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
