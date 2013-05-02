package LedgerSMB::RESTXML::Document::Part_Search;
use strict;
use warnings;
use base qw(LedgerSMB::RESTXML::Document::Base);

sub handle_get {
    my ( $self, $args ) = @_;
    my $user    = $args->{user};
    my $dbh     = $args->{dbh};
    my $handler = $args->{handler};

    my $query = $handler->read_query();

    my %terms;

    for my $field ( $query->param() ) {

        # TODO: BIG GAPING HOLE HERE.
        $terms{$field} = $query->param($field);
    }

    if ( $terms{_keyword} ) {
        %terms = (
            description => $terms{_keyword},
            partnumber  => $terms{_keyword},
        );
    }
    my $sql =
      'SELECT id,description,partnumber FROM parts WHERE '
      . join( ' OR ', map { "$_ like ?" } sort keys %terms );

    my $res = $dbh->prepare($sql);

    $res->execute( map { "$terms{$_}\%" } sort keys %terms )
      or return $handler->error( $dbh->errstr );

    my @rows;
    my $row;
    push @rows, $row while $row = $res->fetchrow_hashref();

    $res->finish();

    $handler->respond(
        XML::Twig::Elt->new(
            'Part_Search_Response',
            { 'xmlns:xlink' => "http://www.w3.org/1999/xlink" },
            map {
                $self->hash_to_twig(
                    {
                        name      => 'Part',
                        root_attr => { 'xlink:href' => "Part/$_->{id}" },
                        hash      => $_
                    }
                );
              } @rows
        )
    );
}
1;
