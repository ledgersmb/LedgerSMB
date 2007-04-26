#!/usr/bin/perl -w
use warnings;
use strict;

LedgerSMB::Handler->cgi_handle();

package LedgerSMB::Handler;
use LedgerSMB::Log;
use warnings;
use strict;
use CGI::Carp qw(fatalsToBrowser);

sub cgi_handle {
    my $self = shift;

    my $script = $ENV{PATH_INFO};

    $script =~ s/^\///;

    # TODO: we can parse out other information, such as
    # Company Identifier, and what not here.

    #return $self->debug();

    if ( $script =~ /\.pl$/ ) {

        # perl scripts should be directly executed.
        warn "[LedgerSMB::Handler] running $script";
        exec("./$script") or croak $!;
    }
    else {

        # redirect them back to the original url

        # infer the base URI, this fails unless the script is named lsmb.pl
        my ($base_uri) = $ENV{SCRIPT_NAME} =~ m#^(.*?)/lsmb.pl#;
        print "Status: 301\nLocation: $base_uri/$script\n\n";
    }
}

sub debug {
    my $self = shift;

    use Data::Dumper;
    print "Content-type: text/plain\n\n";
    print "\$0 is $0\n";
    print Dumper( \%ENV );

}

1;
