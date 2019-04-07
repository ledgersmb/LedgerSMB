package PageObject::App::AR::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;
use PageObject::App::Invoices::Lines;
use PageObject::App::Invoices::Header;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'ar-invoice',
              './/div[@id="AR-invoice"]',
              tag_name => 'div',
              attributes => {
                  id => 'AR-invoice',
              });



sub _verify {
    my ($self) = @_;

    return $self;
}

sub update {
    my ($self) = @_;

    $self->find("*button", text => "Update")->click;
    $self->session->page->body->maindiv->wait_for_content;
}

sub select_customer {
    my ($self, $customer) = @_;

    $self->verify;
    my $elem = $self->find("*labeled", text => "Customer");

    $elem->clear;
    $elem->send_keys($customer);

    $self->update;
}

sub header {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-header',
                       widget_args => [ counterparty_type => 'customer' ]);
}

sub lines {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-lines');
}

sub _extract_total {
    my ($self, $type) = @_;
    my $total_elm = $self->find(".invoice-$type", scheme => 'css');
    my @child_elms = $total_elm->find_all('./*');

    my $rv = {
        amount => $child_elms[1]->get_text,
    };

    if ($child_elms[2]) {
        # there's also a currency indicator
        $rv->{currency} = $child_elms[2]->get_text;
    }
    return $rv;
}

sub total {
    my ($self) = @_;

    return $self->_extract_total('total');
}


sub subtotal {
    my ($self) = @_;

    return $self->_extract_total('subtotal');
}

sub taxes {
    my ($self) = @_;
    my @tax_rows = $self->find_all('.invoice-auto-tax, .invoice-manual-tax', scheme => 'css');
    my @taxes = ();

    for my $tax_row (@tax_rows) {
        my @tax_elms = $tax_row->find_all('./*');
        if ($tax_row->get_attribute('class') =~ m/\binvoice-auto-tax\b/) {
            my $tax = {
                type => 'automatic',
                description => $tax_elms[0]->get_text,
                amount => $tax_elms[1]->get_text,
            };
            if ($tax_elms[2]) {
                $tax->{currency} = $tax_elms[2]->get_text;
            }

            push @taxes, $tax;
        }
        else { # manual tax input
            my $tax = {
                type => 'manual',
                description => $tax_elms[0]->get_text,
                amount => $tax_elms[1]->find('.//input[contains(@name,"mt_amount_")]')->value,
                rate => $tax_elms[2]->find('.//input[contains(@name,"mt_rate_")]')->value,
                basis => $tax_elms[3]->find('.//input[contains(@name,"mt_basis_")]')->value,
                code => $tax_elms[4]->find('.//input[contains(@name,"mt_ref_")]')->value,
                memo => $tax_elms[5]->find('.//input[contains(@name,"mt_memo_")]')->value,
            };

            push @taxes, $tax;
        }
    }

    return \@taxes;
}

__PACKAGE__->meta->make_immutable;

1;
