#!/usr/bin/perl

use Locale::CLDR;

# scan the locale directory and read in the LANGUAGE files
opendir DIR, "$ARGV[0]";

my $locale = Locale::CLDR->new('en_US');
my %regions = %{$locale->all_regions}; # Localized countries
my %languages = %{$locale->all_languages()}; # Localized languages

my @dir = grep !/^\..*$/, readdir DIR;

foreach my $dir (@dir) {
  $dir = substr( $dir, 0, -3 );
  my ($language,$region) = split /_/, $dir;
  my $desc = $languages{$dir} // $languages{$language};
  # Append the country if required
  $desc .= '/' . $regions{$region}
      if $region && !$languages{$dir};
  $desc .= ( " " . substr( $dir, 6 ) ) if length($dir) > 5;
  print "$dir|$desc\n";
}

closedir(DIR);
