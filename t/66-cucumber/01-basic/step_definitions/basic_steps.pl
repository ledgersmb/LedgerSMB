#!perl


use lib 't/lib';
use strict;
use warnings;


use Test::More;
use Test::BDD::Cucumber::StepFile;

use Selenium::Remote::Driver;
use Selenium::Support qw( find_element_by_label try_wait_for_page
 prepare_driver );



sub get_driver {
    my ($stash) = @_;

    return $stash->{feature}->{driver};
}




Given qr/a LedgerSMB instance at "(.*)"/, sub {
    S->{feature}->{URL} = $1;

    return if defined S->{feature}->{driver};

    my $driver = new Selenium::Remote::Driver(
        'port' => 4422,
        ) or die "Can't set up Selenium connection";
    $driver->set_implicit_wait_timeout(3000);
    &prepare_driver($driver);
    S->{feature}->{driver} = $driver;
};

Given qr/a user named "(.*)" with a password "(.*)"/, sub {
    S->{feature}->{user} = $1;
    S->{feature}->{passwd} = $2;
};

When qr/I navigate to '(.*)'/, sub {
    my $url = $ENV{LSMB_BASE_URL} . $1;

    &get_driver(S)->get($url);
    &try_wait_for_page(&get_driver(S));
};


Then qr/I should see a (radio button|textbox|password box) "(.*)"/, sub {
    my $want_type = $1;
    my $label = $2;
    my $element = &find_element_by_label(&get_driver(S), $label);

    my %element_type = (
        'radio button' => 'radio',
        'textbox'      => qr/(text)?/, # text or empty string
        'password box' => 'password',
        );

    is($element->get_tag_name, 'input', "$want_type tag name is 'input'");
    my $type = $element->get_attribute('type') || '';
    ok($type =~ m/^$element_type{$want_type}$/,
       "$want_type tag type att matches $element_type{$want_type}");
};

Then qr/I should see a (dropdown|combobox) "(.*)"/, sub {
    my $want_type = $1;
    my $label = $2;
    my $element = &find_element_by_label(&get_driver(S), $label);

    my %expect_tag_name = (
        'dropdown'    => 'select',
        'combobox'    => 'input',
        );

    is($element->get_tag_name, $expect_tag_name{$want_type},
       "$want_type tag name is '$expect_tag_name{$want_type}'");
};



