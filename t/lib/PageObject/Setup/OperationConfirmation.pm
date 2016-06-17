package PageObject::Setup::OperationConfirmation;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';


sub _verify {
    my ($self) = @_;
    my $page = $self->stash->{ext_wsl}->page;

    my $elements =
        $page->find_all('*contains', text => 'LedgerSMB may now be used');

    croak "Not on the operation confirmation page" .scalar(@$elements)
        if scalar(@$elements) != 1;

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
