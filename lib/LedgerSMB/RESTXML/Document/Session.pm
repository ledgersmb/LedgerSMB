
=head1 NAME

LedgerSMB::RESTXML::Document::Session - Sets up an authentication session for iterativly accessing documents.

=head1 SYNOPSIS

This sets up an authentication session for iteratively accessing documents in LedgerSMB.  A user should
post a login document to /Session/userid, and upon success, they will receive a cookie which they can use to further
access other resources.

=cut

package LedgerSMB::RESTXML::Document::Session;
use strict;
use warnings;
use base qw(LedgerSMB::RESTXML::Document::Base);

sub handle_get {
    my ( $self, $args ) = @_;

}

sub handle_post {
    my ( $self, $args ) = @_;
    print "Content-type: text/html\n\nhi";

}

1;
