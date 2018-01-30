package PageObject::App::Search::ReportDynatable;


use strict;
use warnings;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'search-report-dynatable',
              './/form[@id="search-report-dynatable"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-report-dynatable',
              });


sub _extract_column_headings {
    my $self = shift;

    my @heading_nodes = $self->find_all('.//table/thead/tr/th
                                         | .//table/thead/tr/td');
    return map { $_->get_text } @heading_nodes;;
}

sub rows {
    my $self = shift;

    my @headings = $self->_extract_column_headings;
    my @rows = $self->find_all('.//table/tbody/tr');

    return map {
        my @cells = $_->find_all('./td | ./th');
        my %row_values;
        @row_values{@headings} = map { $_->get_text } @cells;
        \%row_values;
    } @rows;
}

sub _verify {
    my ($self) = @_;

    $self->stash->{ext_wsl}->page
        ->find('//form[@id="search-report-dynatable"]');

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
