#!/usr/bin/perl

use Locale::Country;
use Locale::Language;

# scan the locale directory and read in the LANGUAGE files
opendir DIR, "$ARGV[0]";

my @dir = grep !/^\..*$/, readdir DIR;

foreach my $dir (@dir) {
  $dir = substr( $dir, 0, -3 );
  my $desc = code2language( substr( $dir, 0, 2 ) );
  $desc .= ( "/" . code2country( substr( $dir, 3, 2 ) ) )
    if length($dir) > 2;
  $desc .= ( " " . substr( $dir, 6 ) ) if length($dir) > 5;
  print "$dir|$desc\n";
}

closedir(DIR);



