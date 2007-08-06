package LedgerSMB::DBObject::Vendor;

use base qw(LedgerSMB);
use LedgerSMB::DBObject;

sub save_to_db {
    
    my $self = shift @_;
    
    my $id;
    if ($self->{id} >= 1) {
        $id = $self->{id};
    }
    else {
        $id = $self->next_vendor_id();
    }
    $id = $self->save($id, $self->{discount}, $self->{tax_included}, 
        $self->{creditlimit}, $self->{terms}, $self->{vendornumber}, 
        $self->{cc}, $self->{bcc}, $self->{business_id}, $self->{language},
        $self->{pricegroup}, $self->{currency}, $self->{startdate}, 
        $self->{enddate}
    );
    
    # Undef in the created field causes the system to use now() as the current
    # creation date.
    $self->location_save(
        $id, 1, $self->{line_one}, $self->{line_two}, $self->{line_three},
        $self->{city_province}, $self->{mailing_code}, $self->{country}, undef
        
    );
    return $id;
}
1;