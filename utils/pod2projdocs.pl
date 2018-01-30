#!/usr/bin/perl -w

use strict;
use Pod::ProjectDocs;

my $pd = Pod::ProjectDocs->new(
    outroot => 'UI/pod',
    libroot => './lib/',
    title   => 'LedgerSMB Documentation',
);
$pd->gen();

