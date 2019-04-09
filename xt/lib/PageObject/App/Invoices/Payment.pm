package PageObject::App::Invoices::Payment;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';

use PageObject::App;

__PACKAGE__->self_register(
              'invoice-payment',
              './/tr[contains(@class,"invoice-payment")]',
              tag_name => 'tr',
              attributes => {
                  'class' => 'invoice-payment',
              });

# counterparty_type IN ('customer', 'vendor')
has counterparty_type => (is => 'ro', isa => 'Str', required => 1);

has field_map => (is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_field_map');

sub _verify {
    my ($self) = @_;

    ###TODO

    return $self;
};

sub _build_field_map {
    my ($self) = @_;

    return {
        'Date'          => 'datepaid',
        'Source'        => 'source',
        'Memo'          => 'memo',
        'Amount'        => 'amount',
        'Account'       => ($self->counterparty_type eq 'customer' ? 'AR' : 'AP') . '_paid',
    };
}

sub field {
    my ($self, $label) = @_;
    my $fieldname = $self->field_map->{$label};
    return $self->find(qq{.//*[contains(\@name,"${fieldname}")]});
}

sub field_value {
    my ($self, $label, $new_value) = @_;
    my $fieldname = $self->field_map->{$label};
    my $field = $self->find(
        qq{.//input[contains(\@id,"${fieldname}")]
           | .//input[\@type="hidden" and
                      contains(\@name,"${fieldname}")]});
    die "Payment line column ${fieldname} not found"
        if not defined $field;
    my $rv = $field->value;

    $rv = ''
        if ($field->tag_name eq 'input'
            && $field->get_attribute('type') eq 'checkbox'
            && ! $field->selected);

    if (defined $new_value) {
        $field->click;
        $field->clear;
        $field->send_keys($new_value);
    }

    return $rv;
}


sub is_empty {
    my ($self) = @_;
    return ($self->field_value('Date') eq '');
}


__PACKAGE__->meta->make_immutable;

1;
