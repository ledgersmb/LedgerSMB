package LedgerSMB::RESTXML::Document::SalesOrder;
use strict;
use warnings;
use base qw(LedgerSMB::RESTXML::Document::Base);

sub handle_get {
    my ( $self, $args ) = @_;

    print "Content-type: text/html\n\n";
    print "It still works";

}

1;
