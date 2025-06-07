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
            '//table[@id="report_headings"]'.
            qq{//input[\@id="their-total" and \@value="$heading->{Contents}"]}
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


# find_reconciliation_totals({section => 'Cleared'})
#
# Extracts and returns the totals for the specified section of the
# Reconciliation Report.

sub find_reconciliation_totals {
    my $self = shift;
    my $args = shift;
    my $rv;

    if($args->{section} =~ m/^Cleared$/i) {
        $rv = {
            'Books Debits' => $self->find(
                q{//td[@id="total_cleared_debits"]}
            )->get_text,
            'Books Credits' => $self->find(
                q{//td[@id="total_cleared_credits"]}
            )->get_text,
        };
    }
    elsif($args->{section} =~ m/^Mismatched$/i) {
        $rv = {
            'Our Debits' => $self->find(
                q{//td[@id="total_mismatch_our_debits"]}
            )->get_text,
            'Our Credits' => $self->find(
                q{//td[@id="total_mismatch_our_credits"]}
            )->get_text,
            'Their Debits' => $self->find(
                q{//td[@id="total_mismatch_their_debits"]}
            )->get_text,
            'Their Credits' => $self->find(
                q{//td[@id="total_mismatch_their_credits"]}
            )->get_text,
        };
    }
    elsif($args->{section} =~ m/^Outstanding$/i) {
        $rv = {
            'Our Debits' => $self->find(
                q{//td[@id="total_outstanding_debits"]}
            )->get_text,
            'Our Credits' => $self->find(
                q{//td[@id="total_outstanding_credits"]}
            )->get_text,
        };
    }
    else {
        die "unknown reconciliation report section: $args->{section}";
    }

    return $rv;
}

sub has_reconciliation_section {
    my $self = shift;
    my $args = shift;

    if ($args->{section} =~ m/^Outstanding/i) {
        return $self->find_all(q{//*[@id="outstanding-table"]});
    }
    elsif ($args->{section} =~ m/^Mismatched/i) {
        return $self->find_all(q{//*[@id="error-table"]});
    }
    else {
        die "unknown reconciliation report section: $args->{section}";
    }
}

sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
