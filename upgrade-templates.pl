#!/usr/bin/perl

my $dirpath = $ARGV[1];
$dirpath ||= 'templates';

&process_dir($dirpath);

sub process_dir {
    my $dirpath = shift @_;
    opendir DIR, $dirpath || die "can't open dir $dirpath for reading:$!";
    my @entries = readdir DIR;
    closedir DIR;
    for $entry (@entries) {
        my $path = "$dirpath/$entry";
        if ( -d $path && $entry !~ /^\./ ) {
            &process_dir($path);
        }
        elsif ( $entry !~ /^\./ ) {
            print "Processing path $path\n";
            `perl -ibak -pe 's|\<\%(.*)\%\>|<?lsmb \$1 ?>|g' $path`;
        }
    }
}
