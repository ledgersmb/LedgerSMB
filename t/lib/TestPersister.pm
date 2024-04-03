package TestPersister;

use parent 'Workflow::Persister';
use Storable qw(freeze thaw);
use Workflow::Persister::RandomId;

my @FIELDS = qw( wf_store hist_store );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init( $params );
    $self->use_random( 'yes' );
    $self->assign_generators;
    $self->wf_store( {} );
    $self->hist_store( {} );
}

sub create_workflow {
    my ( $self, $wf ) = @_;
    my $wf_id = $self->workflow_id_generator->pre_fetch_id();
    $self->wf_store->{ $wf_id } = freeze(
        {
            id          => $wf->id,
            state       => $wf->state,
            last_update => $wf->last_update,
            type        => $wf->type,
            context     => $wf->context,
        }
        );

    return $wf_id;
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;
    return thaw( $self->wf_store->{ $wf_id } );
}

sub update_workflow {
    my ( $self, $wf ) = @_;
    $self->wf_store->{ $wf->id } = freeze(
        {
            id          => $wf->id,
            state       => $wf->state,
            last_update => $wf->last_update,
            type        => $wf->type,
            context     => $wf->context,
        }
        );
}

sub create_history {
    my ( $self, $wf, @history ) = @_;
    for my $h (@history) {
        next if $h->is_saved;

        $h->id( $self->history_id_generator->pre_fetch_id() );
    }

    $self->hist_store->{ $wf->id } = [
        map { freeze( { $_->%{qw(id workflow_id action description date time_zone user state)} } ) } @history
        ];
}

sub fetch_history {
    my ( $self, $wf ) = @_;
    my @histories = (
        map { thaw( $_ ) }
        @{ $self->hist_store->{ $wf->id } // [] }
        );
    $_->set_saved for @histories;

    return @histories;
}

1;
