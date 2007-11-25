package LedgerSMB::DBObject::Vendor;

use base qw(LedgerSMB::DBObject::Company);
use strict;

my $ENTITY_CLASS = 1;

sub set_entity_class {
    my $self = shift @_;
    $self->{entity_class} = $ENTITY_CLASS;
}
    
1;
