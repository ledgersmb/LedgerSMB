package LedgerSMB::RESTXML::Document::Customer;
use strict;
use warnings;
use base qw(LedgerSMB::RESTXML::Document::Base);

sub handle_get {
    my ( $self, $args ) = @_;
    my $user    = $args->{user};
    my $dbh     = $args->{dbh};
    my $handler = $args->{handler};

    my $res = $dbh->selectrow_hashref( q{SELECT * from customer where id = ?},
        undef, $args->{args}[0] );

    if ( !$res ) {
        $handler->not_found("No customer with the id $args->{args}[0] found");
    }
    else {
        $handler->respond(
            $self->hash_to_twig( { name => 'Customer', hash => $res } ) );
    }
}

1;
