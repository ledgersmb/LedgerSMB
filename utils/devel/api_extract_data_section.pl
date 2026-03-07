#!/usr/bin/env perl
use strict;
use warnings;

use File::Spec;

my $outDir = shift @ARGV;
while ( my $file=shift(@ARGV)) {
    my (undef,undef,$yml) = File::Spec->splitpath( $file );
    $yml =~ s/.pm/.yml/;

    open(FILE,'<',$file) or die $!;
    open(YML,'>',"$outDir/$yml") or die $!;

    my $keep=0;
    while(<FILE>)
    {
        if ( $_=~ /^__DATA__/ )
        {
            $keep=1;
            next;
        }
        print YML $_ if $keep;
    }
    close FILE or die $!;
    close YML or dir $1;
}
