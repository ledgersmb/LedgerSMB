package PageObject::App::Cash::Vouchers::Payments;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'cash-vouchers-payments',
    './/div[@id="create-new-batch"]',
    tag_name => 'div',
    attributes => {
        id => 'create-new-batch',
    }
);

sub _verify {
    my ($self) = @_;

    return $self;
}


# batch_rows()
#
# Returns an arrayref of rows in the table of existing batches.

sub batch_rows {
    my $self = shift;
    my $rows = $self->find_all('//table[@id="batch_list"]/tbody/tr');
    return $rows;
}


# batch_row(description => $description)
#
# Returns the first row in the table of existing batches having
# a description matching the specified parameter.

sub batch_row {
    my $self = shift;
    my %params = @_;

    my $row = $self->find(
        "//table[\@id='batch_list']/tbody/tr[" .
        "  td[contains(\@class,'description') and " .
        "  normalize-space(.)='$params{description}']" .
        "]"
    );

    return $row;
}


# batch_link(control_code => $control_code)
#
# Returns the first link from the table of existing batches having
# the specified control_number

sub batch_link {
    my $self = shift;
    my %params = @_;

    my $row = $self->find(
        "//table[\@id='batch_list']/tbody/tr/td/a[" .
        "  normalize-space(.)='$params{control_code}'" .
        "]"
    );

    return $row;
}



__PACKAGE__->meta->make_immutable;

1;
