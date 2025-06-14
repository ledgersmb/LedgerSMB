#!perl


use lib 'xt/lib';
use strict;
use warnings;

use LedgerSMB::App_State;
use LedgerSMB::Database;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Entity::User;
use Selenium::Remote::WDKeys;

use Module::Runtime qw(use_module);
use PageObject::App::Login;
use PageObject::App::AR::Invoice;

use Test::More;
use Test::BDD::Cucumber::StepFile;

When qr/I open the sales invoice entry screen/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, 'Accounts Receivable > Sales Invoice';

    my $content = S->{ext_wsl}->page->body->maindiv->content;
    S->{ext_wsl}->page->body->menu->click_menu(\@path);
    S->{ext_wsl}->page->body->maindiv->wait_for_content(replaces => $content);
};

When qr/I open the AR transaction entry screen/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, 'Accounts Receivable > Add Transaction';

    my $content = S->{ext_wsl}->page->body->maindiv->content;
    S->{ext_wsl}->page->body->menu->click_menu(\@path);
    S->{ext_wsl}->page->body->maindiv->wait_for_content(replaces => $content);
};

When qr/I select customer "(.*)"/, sub {
    my $customer = $1;

    my $page = S->{ext_wsl}->page->body->maindiv->content;
    $page->select_customer($customer);
};

When qr/I open the purchase invoice entry screen/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, 'Accounts Payable > Vendor Invoice';

    S->{ext_wsl}->page->body->menu->click_menu(\@path);
    S->{ext_wsl}->page->body->verify;
};

When qr/I open the AP transaction entry screen/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, 'Accounts Payable > Add Transaction';

    S->{ext_wsl}->page->body->menu->click_menu(\@path);
    S->{ext_wsl}->page->body->verify;
};

When qr/I select vendor "(.*)"/, sub {
    my $vendor = $1;

    my $page = S->{ext_wsl}->page->body->maindiv->content;
    $page->select_vendor($vendor);

};


When qr/I add an invoice line with (?:part|service) "(.+)"( with these values:)?$/, sub {
    my $part = $1;
    my $has_data = $2;

    my $session = S->{ext_wsl};
    my $inv = $session->page->body->maindiv->content;
    my @empty = $inv->lines->empty_lines;
    my $empty = shift @empty;
    my $item = $empty->field_value('Item');

    $empty->field_value('Number', $part);
    $empty->field('Item')->click;
    ###TODO: this requires the part to have a description:
    $session->wait_for(
        sub {
            return ($empty->field_value('Description') ne '');
        });
    $inv->update;
    if ($has_data) {
        $inv = $session->page->body->maindiv->content;
        my ($line) =
            grep { $_->field_value('Item') eq $item } $inv->lines->all_lines;
        for my $row (@{C->data}) {
            $line->field_value($row->{name}, $row->{value});
        }
        $inv->update;
    }
};

When qr/I post the invoice/, sub {

    my $session = S->{ext_wsl};
    my $inv = $session->page->body->maindiv->content;
    $inv->post;

};

Then qr/I expect to see (?:an invoice|a transaction) with (\d+) (empty )?lines?/, sub {
    my ($count, $empty) = ($1, $2);

    my $page = S->{ext_wsl}->page->body->maindiv->content;
    ###TODO: verify this is an invoice!

    my @lines = $empty ? $page->lines->empty_lines : $page->lines->all_lines;
    is(scalar(@lines), $count, 'Expected number of lines matches actual');
};

Then qr/I expect to see these (?:invoice|transaction) header fields and values/, sub {
    my $data = C->data;

    my $header = S->{ext_wsl}->page->body->maindiv->content->header;

    for my $exp_hdr (@$data) {
        my $val = $exp_hdr->{value};
        is($header->field_value($exp_hdr->{name}),
           $exp_hdr->{value},
           qq{Invoice header field $exp_hdr->{name} matches expected value});
    }
};

Then qr/I expect to see an invoice with these lines/, sub {
    my $expected_lines = C->data;
    my $actual_lines =
        S->{ext_wsl}->page->body->maindiv->content->lines->all_lines;

    while (1) {
        my $expected_line = shift @{$expected_lines};
        my $actual_line = shift @{$actual_lines};

        if (! $expected_line && ! $actual_line) {
            last;
        }
        elsif (! $expected_line && $actual_line->is_empty) {
            next;
        }
        elsif (! $expected_line) { # actual_line isn't empty
            fail('all actual lines in the list of expected lines');
        }
        elsif ($expected_line &&
               (! $actual_line || $actual_line->is_empty)) {
            fail('invoice has fewer lines than expected');
        }
        else { # expected_line isn't empty and neither is actual_line
            for my $field (sort keys %$expected_line) {
               S->{ext_wsl}->wait_for(
                    sub {
                        return $actual_line->field_value($field) eq $expected_line->{$field};
                    });
                is($actual_line->field_value($field),
                   $expected_line->{$field},
                   qq{Actual value for field $field matches expectation});
            }
        }
    }
};

Then qr/I expect to see the invoice(?: subtotal of ([^\s]+) and)? total of ([^\s]+)(?: ([A-Z]{3,3}))?( with these( automatic| manual)? taxes| without taxes)?/, sub {
    my $expected_subtotal = $1;
    my $expected_total = $2;
    my $expected_curr = $3;
    my $has_taxes_data = $4;
    my $taxes_type = $5;
    my $expected_taxes = C->data;

    if ($expected_taxes eq '') {
        # in case no table is specified ('without taxes'),
        # an empty string is being returned by C->data();
        # however, we need it to be an empty array...
        $expected_taxes = [];
    }

    if ($expected_subtotal) {
        my $subtotal = S->{ext_wsl}->page->body->maindiv->content->subtotal;
        is($subtotal->{amount}, $expected_subtotal,
           q{Actual subtotal matches expected value});
        if ($expected_curr) {
            is($subtotal->{currency}, $expected_curr,
               q{Actual subtotal currency matches expected value});
        }
    }

    my $total = S->{ext_wsl}->page->body->maindiv->content->total;
    is($total->{amount}, $expected_total,
       q{Actual total matches expected value});
    if ($expected_curr) {
        is($total->{currency}, $expected_curr,
           q{Actual total currency matches expected value});
    }

    if ($has_taxes_data) {
        my $taxes = S->{ext_wsl}->page->body->maindiv->content->taxes;
        # Note that the line below verifies the "without taxes" case
        # by virtue of requiring an empty set of tax lines.
        # Also note that $has_taxes_data is true in the without-taxes case,
        # because the matched value $4 will contain ' without taxes'
        is(scalar(@$taxes), scalar(@$expected_taxes),
           q{Actual tax line count matches expected number of lines});
        my %taxes = map { $_->{description} => $_ } @$taxes;
        for my $expected_tax (@$expected_taxes) {
            ok(exists $taxes{$expected_tax->{description}},
               qq{Actual taxes has a row with description '$expected_tax->{description}'});

            my $tax = $taxes{$expected_tax->{description}};
            is($tax->{amount}, $expected_tax->{amount},
               qq{Actual tax matches expected amount for $expected_tax->{description}});
            if ($expected_tax->{type} && $expected_tax->{type} eq 'manual') {
                is($tax->{type}, 'manual', q{Actual tax type matches expected type});
                for my $field (qw/ rate basis code memo /) {
                    if (exists $expected_tax->{$field}) {
                        is($tax->{$field}, $expected_tax->{$field},
                           qq{Actual tax $field matches expected value});
                    }
                }
            }
        }
    }
};

Then qr/I expect to see (\d+) (empty )?payment lines?/, sub {
    my ($count, $empty) = ($1, $2);
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    ###TODO: verify this is an invoice!

    $page = $page->payments;
    my @payments = $page->payment_lines;
    if ($empty) {
        @payments = grep { $_->is_empty } @payments;
    }
    is(scalar(@payments), $count, 'Expected number of lines matches actual');
};

Then qr/I expect to see these payment lines/, sub {
    my $expected_payments = C->data;
    my $actual_payments =
        S->{ext_wsl}->page->body->maindiv->content->payments->payment_lines;

    while (1) {
        my $expected_line = shift @{$expected_payments};
        my $actual_line = shift @{$actual_payments};

        if (! $expected_line && ! $actual_line) {
            last;
        }
        elsif (! $expected_line && $actual_line->is_empty) {
            next;
        }
        elsif (! $expected_line) {
            fail('all actual lines in the list of expected lines');
        }
        elsif ($expected_line &&
               (! $actual_line || $actual_line->is_empty)) {
            fail('all expected lines present as actual lines');
        }
        else { # $expected_line isn't empty and neither is $actual_line
           for my $field (keys %$expected_line) {
               S->{ext_wsl}->wait_for(
                    sub {
                        return $actual_line->field_value($field) eq $expected_line->{$field};
                    });
                is($actual_line->field_value($field),
                   $expected_line->{$field},
                   qq{Actual value for field $field matches expectation});
            }
        }
    }
};

When qr/I select (part|service) "(.+)" on (the empty line|empty line (\d+))/,
    sub {
        my $type = $1;
        my $partname = $2;
        my $empty_line_no = $4 // 1;
        my $invoice = S->{ext_wsl}->page->body->maindiv->content;
        my @lines = grep { $_->is_empty } @{$invoice->lines};
        my $empty = $lines[$empty_line_no - 1];
        my $part_selector = $empty->get_property('partnumber');
        $part_selector->click;
        $part_selector->clear;
        $part_selector->send_keys($partname);
        ###@@@TODO wait-for-popup, instead of sleep 1
        sleep 1;
        $part_selector->send_keys(KEYS->{tab});
        ###@@@TODO: TAB confirms the top row (which should now be the only one)
};

Then qr/I expect to see an invoice with (these|(\d+) empty) lines?/, sub {
    my $type = $1;
    my $empty_lines = $2;
    my $invoice = S->{ext_wsl}->page->body->maindiv->content;
    my @lines =  @{$invoice->lines};
    my @empty_lines = grep { $_->is_empty } @lines;

    # the definition of an empty line is: no partnumber, empty description,
    #   Qty = 0, Unit empty, OH empty, Price = 0.00, % = 0,
    #   extended = 0.00, Delivery Date empty, notes_* empty,
    #   serialnumber_* empty
    if ($type ne 'these') {
        is(scalar(@empty_lines), $empty_lines, 'Number of empty lines matches');
        return;
    }

    my @keys = keys %{${C->data}[0]};
    # foreach my $line (@{C->data}) {
    #     foreach my $key (keys %$line) {
    #         $line->{$key} =~ s/^\s+|\s+$//g;
    #     }
    # }
    my @actual =
        map { my $line = $_;
              my %row = map { $_ => $line->get_value($_)  }  @keys;
              \%row }
        @lines;

    is_deeply(\@actual, C->data, "Invoice lines show expected data on");
};

my %invoice_property_map = (
    'Invoice Created' => 'crdate',
    'Due Date' => 'duedate',
    'Invoice Date' => 'transdate',
    'Order Number' => 'ordnumber',
    'Invoice Number' => 'invnumber',
    'PO Number' => 'ponumber',
    'Description' => 'description',
    'Currency' => 'currency',
    'Shipping Point' => 'shippingpoint',
    'Ship via' => 'shipvia',
    'Notes' => 'notes',
    'Internal Notes' => 'intnotes',
    );

Then qr/I expect to see an invoice with these document properties/, sub {
    my $invoice = S->{ext_wsl}->page->body->maindiv->content;
    my $today = LedgerSMB::PGDate->today;
    $today = $today->to_output;
    map { $_->{value} =~ s/^\@today\@$/$today/ } @{C->data};
    my %expects = map { $_->{property} => $_->{value} } @{C->data};
    my %actuals = map {
        my $id = $invoice_property_map{$_};
        my $value = $invoice->find(".//*[\@id='$id']")->get_attribute('value');
        $_ => $value;
    } keys %expects;
    is_deeply(\%actuals, \%expects, 'Invoice properties match expectations');
};

1;
