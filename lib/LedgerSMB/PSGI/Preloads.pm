package LedgerSMB::PSGI::Preloads;

=head1 NAME

LedgerSMB::PSGI::Preloads - Modules to be pre-loaded for PSGI applications

=head1 DESCRIPTION

This module does nothing more than C<use> a number of modules which are
either assumed to take a long time to load or to use a lot of memory.
During the initial loading phase, this module (and its dependencies)
will be loaded. If the C<--preload-app> option to C<plackup> or
C<starman> is being used, the memory savings are being achieved by
loading the Perl modules before forking each of the workers.

Additionally, loading of "workflow scripts" will be faster due to
the fact that dependencies have been pre-loaded and don't need loading
at request-dispatch time.

=head1 SYNOPSIS

 use LedgerSMB::PSGI::Preloads;

=head1 METHODS

This module declares no methods.

=cut

use strict;
use warnings;

# Preloads
use LedgerSMB;
use LedgerSMB::AA;
use LedgerSMB::GL;
use LedgerSMB::IIAA;
use LedgerSMB::IR;
use LedgerSMB::IS;
use LedgerSMB::PE;
use LedgerSMB::File;
use LedgerSMB::Form;
use LedgerSMB::Legacy_Util;
use LedgerSMB::PGObject;
use LedgerSMB::Scripts::login;
use LedgerSMB::Tax;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
