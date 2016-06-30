package PageObject::App::Report::BalanceSheet;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';


sub _verify {
    my ($self) = @_;

    return $self;
}

sub run {
    my ($self, %options) = @_;
    my $page = $self->stash->{ext_wsl}->page;

    # TODO: verify that we're in a 'run this report' state

    $page->find('*labeled', text => 'Through date')->send_keys($options{date});
    $page->find('*button', text => 'Generate')->click;
}

sub account_balances {
    my ($self) = @_;
    my @account_rows = $self->stash->{ext_wsl}->page
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
