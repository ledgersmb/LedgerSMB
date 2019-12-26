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


# parse_batch_row($tr_element)
#
# Given a tr element representing a row from the table of batches,
# return a hashref representing the field text.

sub parse_batch_row {
    my $self = shift;
    my $row = shift;
    my $rv = {
        'Batch Number' => $row->find('./td[contains(@class, "control_code")]')->get_text,
        'Description' => $row->find('./td[contains(@class, "description")]')->get_text,
        'Post Date' => $row->find('./td[contains(@class, "default_date")]')->get_text,
    };

    return $rv;
}


# find_batch_row($wanted)
#
# Returns the batch table <tr> element with fields
# matching those specified in supplied $wanted hashref.
#
# For example:
# my $element = find_batch_row({
#     'Batch Number' => 'B-11001',
#     'Description' => 'Batch B-11001',
#     'Post Date' => '2018-01-01'
# });

sub find_batch_row {
    my $self = shift;
    my $wanted = shift;

    ROW: foreach my $element(@{$self->batch_rows}) {
        my $row = $self->parse_batch_row($element);

        TEST: foreach my $key(keys %{$wanted}) {
            defined $row->{$key} && $row->{$key} eq $wanted->{$key}
                or next ROW;
        }

        # Stop searching as soon as we find a matching row
        return $element;
    }

    return;
}


# batch_link(batch_number => $batch_number)
#
# Returns the first link from the table of existing batches having
# the specified control_number

sub batch_link {
    my $self = shift;
    my %params = @_;

    my $row = $self->find(
        "//table[\@id='batch_list']/tbody/tr/td/a[" .
        "  normalize-space(.)='$params{batch_number}'" .
        "]"
    );

    return $row;
}


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
