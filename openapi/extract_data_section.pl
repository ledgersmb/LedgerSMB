#!/usr/bin/perl
use strict;
use warnings;

while ( my $file=shift(@ARGV)) {
    my $yaml=$file;
    $yaml =~ s/.+\///;
    $yaml =~ s/.pm/.yaml/;

    open(FILE,'<',$file) or die $!;
    open(YAML,'>',$yaml) or die $!;

    my $keep=0;
    while(<FILE>)
    {
        if ( $_=~ /^__DATA__/ )
        {
            $keep=1;
            next;
        }
        print YAML $_ if $keep;
    }
    close FILE or die $!;
    close YAML or dir $1;
}
