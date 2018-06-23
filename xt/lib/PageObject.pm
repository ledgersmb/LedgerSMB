package PageObject;

use strict;
use warnings;

use Carp;
use Module::Runtime qw(use_module);

use Moose;
use namespace::autoclean;
extends 'Weasel::Element';

use Weasel::FindExpanders qw/ register_find_expander /;
use Weasel::FindExpanders::Dojo;
use Weasel::FindExpanders::HTML;

use Weasel::WidgetHandlers qw/ register_widget_handler /;
use Weasel::Widgets::Dojo;
use Weasel::Widgets::HTML;


sub self_register {
    my ($class, $mnemonic, $xpath, %widget_options) = @_;
    my $xpath_fn = (ref $xpath) ? $xpath : sub { return $xpath };

    {
        no strict 'refs';
        no warnings 'once';
        ${"${class}::MNEMONIC"} = $mnemonic;
    }
    register_find_expander($mnemonic, 'LedgerSMB', $xpath_fn);
    register_widget_handler($class, 'LedgerSMB', %widget_options);
}

sub open {
    my ($class, $session) = @_;

    $session->get($class->url);

    $session->page->wait_for_body;
    return $session->page->body;
}

sub field_types { return {}; }

sub url { croak "Abstract method 'PageObject::url' called"; }


sub wait_for_page {
    my ($self, $ref) = @_;

    $self->session->wait_for(
        sub {

            if ($ref) {
                local $@;
                # if there's a reference element,
                # wait for it to go stale (raise an exception)
                eval {
                    $ref->tag_name;
                };
                $ref = undef if !defined $@;
                return 0;
            }
            else {
                $self->session->page
                    ->find('body.done-parsing', scheme => 'css');
            }
        });
}

sub verify {
    my ($self, $ref) = @_;

    $self->wait_for_page($ref);
    $self->_verify;
};

sub _verify { croak "Abstract method 'PageObject::verify' called"; }



__PACKAGE__->meta->make_immutable;

1;
