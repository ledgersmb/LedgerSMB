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
    my $xpath;

    if($heading->{Heading} eq 'Ending Statement Balance') {
        $xpath = (
            '//table[@id="report_headings"]/tbody'.
            qq{/tr[th[normalize-space(.)="$heading->{Heading}:"]]}.
            q{/td/div[@id="widget_their-total"]/div/}.
            qq{/input[\@value="$heading->{Contents}"]}
        );
    }
    else {
        $xpath = (
            '//table[@id="report_headings"]/tbody'.
            qq{/tr[th[normalize-space(.)="$heading->{Heading}:"]]}.
            qq{/td[normalize-space(.)="$heading->{Contents}"]}
        );
    }

    my $element = $self->find($xpath)
        or die "Matching heading not found '$heading->{Heading}' : '$heading->{Contents}'";

    return $element;
}


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
