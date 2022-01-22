#!/usr/bin/perl

use Locales unicode => 1;

# scan the locale directory and read in the LANGUAGE files
opendir DIR, "$ARGV[0]";

my $locale = Locales->new('en_US');
my %regions = $locale->get_territory_lookup();
my %languages = $locale->get_language_lookup();

my @dir = grep !/^\..*$/, readdir DIR;

foreach my $dir (@dir) {
  $dir = substr( $dir, 0, -3 );
  my ($language,$region) = split /_/, $dir;
  my $desc = $languages{$dir} // $languages{$language};
  # Append the country if required
  $desc .= '/' . $regions{lc($region)}
      if $region && !$languages{$dir};
  $desc .= ( " " . substr( $dir, 6 ) ) if length($dir) > 5;
  print "$dir|$desc\n";
}

closedir(DIR);
