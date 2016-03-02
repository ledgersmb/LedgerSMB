=head1 NAME

LedgerSMB::RESTXML::Document::Base - Base XML:Twig structure function

=cut

package LedgerSMB::RESTXML::Document::Base;
use strict;
use warnings;
use XML::Twig;
use Carp;

sub handle_post {
    my ( $self, $args ) = @_;

    return $args->{handler}->unsupported('the POST method is not implemented.');
}

sub handle_put {
    my ( $self, $args ) = @_;
    return $self->{handler}->unsupported('the PUT method is not implemented.');
}

sub handle_delete {
    my ( $self, $args ) = @_;
    return $self->{handler}
      ->unsupported('the DELETE method is not implemented.');
}

sub handle_get {
    my ( $self, $args ) = @_;

    return $self->{handler}->unsupported('the GET method is not implemented.');
}

=head3 hash_to_twig

Convinenve function to convert a hashref to a XML::Twig structure.

passed a hashref, required arguments:

hash - the hash to convert

name - the name of the root element.

optional arguments:

sort - by default, on set to 0 to disable.  toggles whether or not hash keys are sorted
in the resulting xml node created.  Disabling this may save some performance if converting a lot of
nodes at once.

=cut

sub hash_to_twig {
    my ( $self, $args ) = @_;

    my $hash = $args->{hash}
      || croak "Need a hash to convert to use hash_to_twig";
    my $name = $args->{name}
      || croak "Need a root element name to use hash_to_twig";
    my @keyorder = keys %$hash;

    @keyorder = sort @keyorder
      unless defined( $args->{sort} )
      and $args->{sort} == 0;

    return XML::Twig::Elt->new(
        $name,
        $args->{root_attr} || {},
        map { XML::Twig::Elt->new( $_, { '#CDATA' => 1 }, $hash->{$_} ) }
          @keyorder
    );
}

1;

