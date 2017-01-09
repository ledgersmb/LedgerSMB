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



1;
