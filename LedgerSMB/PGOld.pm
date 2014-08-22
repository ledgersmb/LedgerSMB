=head1 NAME

LedgerSMB::PGOld - Old DBObject replacement for 1.3-era LedgerSMB code

=head1 SYNPOSIS

This is like DBObject but uses the PGObject::Simple for base functionality.

=head1 METHODS

See PGObject::Simple

=cut

package LedgerSMB::PGOld;
use PGObject::Simple;
use LedgerSMB::App_State;

sub set_dbh {
    my ($self) = @_;
    $self->{_DBH} =  LedgerSMB::App_State::DBH();
}

1; 
