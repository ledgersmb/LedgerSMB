#!/usr/bin/perl -w

use strict;
use Pod::ProjectDocs;

my $pd = Pod::ProjectDocs->new(
    outroot => 'UI/pod',
    except => [qr/^UI\/js(-src)?\/(dijit|dojo)/, qr/(blib|conf|dists|doc|.git|log|sql|utils|UI\/pod)/],
    libroot => './',
    title   => 'LedgerSMB Documentation',
);
$pd->gen();

