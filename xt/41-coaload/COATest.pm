package COATest;
use Moose;
use namespace::autoclean;

has 'sqlfile' => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my $self = shift;
        my ($_1,$dir,$type,$name) = $self->{sqlfile} =~ qr(sql\/coa\/(([a-z]{2})\/)?(.+\/)?([^\/\.]+)\.sql$);
        $self->dir($dir // "");
        $self->type($type // "");
        $self->name($name);
    }
);

has [ 'dir', 'type', 'name' ] => (
    is => 'rw',
    isa => 'Str',
);

has 'test_db' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_test_db'
);

sub _build_test_db {
    my $self = shift;
    return "$ENV{LSMB_NEW_DB}_lsmb_test_coa"
          . ( $self->{dir} ? "_$self->{dir}" : "" )
          . "_$self->{name}";
}

__PACKAGE__->meta->make_immutable;
1;
