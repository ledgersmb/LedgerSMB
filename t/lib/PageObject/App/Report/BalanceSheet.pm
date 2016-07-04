package PageObject::App::Report::BalanceSheet;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

__PACKAGE__->self_register(
              'reports-balance-sheet-params',
              './/div[@id="balance-sheet-parameters"]',
              tag_name => 'div',
              attributes => {
                  id => 'balance-sheet-parameters',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

sub run {
    my ($self, %options) = @_;

    # TODO: verify that we're in a 'run this report' state

    $self->find('*labeled', text => 'Through date')->send_keys($options{date});
    $self->find('*button', text => 'Generate')->click;
    ###TODO: Refresh current page; the 'click' replaced it...
}

sub account_balances {
    my ($self) = @_;
    # due to the TODO above, we can't use $self here.. it's gone out of scope
    my @account_rows = $self->session->page
        ->find_all('tr.account', scheme => 'css');
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
