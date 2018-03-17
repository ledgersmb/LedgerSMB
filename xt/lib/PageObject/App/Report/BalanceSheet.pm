package PageObject::App::Report::BalanceSheet;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'reports-balance-sheet',
              './/div[@id="PNL" and contains(@class,"balance-sheet")]',
              tag_name => 'div',
              classes => ['balance-sheet'],
              attributes => {
                  id => 'PNL',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

sub account_balances {
    my ($self) = @_;
    my @account_rows = $self->find_all('tr.account', scheme => 'css');
    my @rv;

    for my $row (@account_rows) {
        my $accno = $row->get_attribute('data-lsmb-account');
        $accno //= 'current earnings'; # the only one without a data-account att

        my @value_columns = $row->find_all('td.amount', scheme => 'css');
        my @values;
        push @values, $_->get_text
            for (@value_columns);

        push @rv, { accno => $accno,
                    values => \@values };
    }
    return wantarray ? @rv : \@rv;
}

__PACKAGE__->meta->make_immutable;

1;
