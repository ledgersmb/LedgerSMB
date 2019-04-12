package PageObject::App::AP::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;
use PageObject::App::Invoices::Lines;
use PageObject::App::Invoices::Header;
use PageObject::App::Invoices::Payments;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'ap-invoice',
              './/div[@id="AP-invoice"]',
              tag_name => 'div',
              attributes => {
                  id => 'AP-invoice',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}


sub _verify {
    my ($self) = @_;

    return $self;
}

sub update {
    my ($self) = @_;

    $self->find("*button", text => "Update")->click;
    $self->session->page->body->maindiv->wait_for_content;
}

sub _post_btn {
    my ($self) = @_;

    my $outer = $self->find('.//span[contains(@widgetid,"action-post-")]
                             | .//span[contains(@widgetid,"action-approve-")]');
    my $lbl_id = $outer->get_attribute('widgetid');
    my $label = $self->find(qq{//span[\@id="${lbl_id}_label"]});
    return $label;
}

sub _post_btn_text {
    my ($self) = @_;

    return $self->_post_btn->get_text;
}

sub post {
    my ($self) = @_;
    if ($self->_post_btn_text eq 'Save') {
        # 2-step in case separation of duties is enabled
        $self->_post_btn->click;
        $self->session->page->body->maindiv->wait_for_content;
    }

    $self->session->page->body->maindiv->content->_post_btn->click;
    $self->session->page->body->maindiv->wait_for_content;
}

sub select_vendor {
    my ($self, $vendor) = @_;

    $self->verify;
    my $elem = $self->find("*labeled", text => "Vendor");

    $elem->clear;
    $elem->send_keys($vendor);

    $self->update;
}

sub header {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-header',
                       widget_args => [ counterparty_type => 'vendor' ]);
}

sub lines {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-lines');
}

sub payments {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-payments',
                       widget_args => [ counterparty_type => 'vendor' ]);
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
