package PageObject::App::Roles::Dynatable;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose::Role;
use namespace::autoclean;


# title ()
#
# Returns the page title div with content matching the specified
# `title` parameter

sub title {
    my $self = shift;
    my %params = @_;
    my $title = $self->find(sprintf(
        './div[@class="listtop" and normalize-space(.)="%s"]',
        $params{title},
    ));
    return $title
}

sub find_heading {
    my $self = shift;
    my $heading = shift;
    my $header_div = $self->find(
        '//form[@id="search-report-dynatable"]'.
        '/div[@class="heading_section"]'.
        qq{/div[label[.="$heading->{Heading}:"]]}.
        qq{/span[\@class="report_header" and normalize-space(.)="$heading->{Contents}"]}
    ) or die "Matching heading not found '$heading->{Heading}' : '$heading->{Contents}'";
    return $header_div;
}

sub _extract_column_headings {
    my $self = shift;

    my @heading_nodes = $self->find_all('.//table/thead/tr/th
                                         | .//table/thead/tr/td');
    return map { $_->get_text } @heading_nodes;;
}

# rows()
#
# Returns an array of hashrefs representing the rows in
# the table. The hashref contains the text content of each
# column, keyed by the column heading, plus an additional
# `_element` key representing the original <tr> element.

sub rows {
    my $self = shift;

    my @headings = $self->_extract_column_headings;
    my @rows = $self->find_all('.//table[contains(@class, "dynatable")]/tbody/tr');

    return map {
        my @cells = $_->find_all('./td | ./th');
        my %row_values;
        @row_values{@headings} = map { $_->get_text } @cells;
        $row_values{_element} = $_;
        \%row_values;
    } @rows;
}


1;
