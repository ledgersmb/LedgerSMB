#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


if (`which msgfmt` eq "") {
    plan skip_all => "'msgfmt' not installed";
    exit 0;
}



opendir PO_DIR, 'locale/po'
    or die "Can't open directory locale/po/: $!";

while (my $entry = readdir PO_DIR) {
    next unless $entry =~ m/.po$/;

    $entry = "locale/po/$entry";
    system("msgfmt -o /dev/null -c '$entry' 2>/dev/null 1>/dev/null");
    ok( $? == 0, "'$entry' passes 'msgfmt -c' validation");
}

closedir PO_DIR;


done_testing;
