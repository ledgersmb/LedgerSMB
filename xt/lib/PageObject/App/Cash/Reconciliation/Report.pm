package PageObject::App::Cash::Reconciliation::Report;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'cash-reconciliation-report',
    './/div[@id="reconciliation"]',
    tag_name => 'div',
    attributes => {
        id => 'reconciliation',
    }
);


sub find_heading {
    my $self = shift;
    my $heading = shift;
    my $element = $self->find(
        '//table[@id="report_headings"]/tbody'.
        qq{/tr[th[normalize-space(.)="$heading->{Heading}:"]]}.
        qq{/td[normalize-space(.)="$heading->{Contents}"]}
    ) or die "Matching heading not found '$heading->{Heading}' : '$heading->{Contents}'";
    return $element;
}


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
