package PageObject::App::Contacts::EditContact;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'edit_contact',
    './/div[@id="edit_contact"]',
    tag_name => 'div',
    attributes => {
        id => 'edit_contact',
    }
);

sub _verify {
    my ($self) = @_;
    return $self;
}


sub find_tab {
    my $self = shift;
    my $tab_text = shift;

    my $tab = $self->find(
        '//div[@id="contact_tabs_tablist"]'.
        '//span[@class="tabLabel" and normalize-space(.)="'.$tab_text.'"]'
    );

    return $tab;
}


sub tab_is_selected {
    my $self = shift;
    my $tab_label = shift;

    my $tab = $self->find_tab($tab_label) or die "$tab_label tab not found";
    my $selected = $tab->get_attribute('aria-selected');

    return $selected;
}


__PACKAGE__->meta->make_immutable;
1;
