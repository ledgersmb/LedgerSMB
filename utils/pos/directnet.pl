#!/usr/bin/perl

( $host, $proto, $port ) = @ARGV;

socket( SOCK, 2, 1, getprotobynumber($proto) );

$dest = pack( 's n a4 x8', 2, $port, pack( 'CCCC', split( /\./, $host ) ) );

connect( SOCK, $dest );

open( 'STD', '-' );
while ( $line = <STD> ) {
    print SOCK $line;
}
close STD;
close SOCK;

