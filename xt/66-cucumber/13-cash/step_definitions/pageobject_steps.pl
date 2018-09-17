#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


Then qr/I should see a Batch with these values:/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $data = C->data;
    my $batch_rows = $page->batch_rows;
    my $ok;

    #   | label          | value      |
    #   | Control Number | B-1001     |
    #   | Description    | Test Batch |
    #   | Post Date      | 2018-01-01 |

    my %classes = (
        'Control Number' => 'control_code',
        'Description'    => 'description',
        'Post Date'      => 'default_date',
    );

    ROW: foreach my $row(@{$batch_rows}) {

        TEST: foreach my $test(@{$data}) {
            my $class = $classes{$test->{label}}
                or BAIL_OUT "unknown field: " . $test->{label};

            my $result = $row->find(sprintf(
                './td[contains(@class, "%s") and normalize-space(.)="%s"]',
                $class,
                $test->{value},
            )) or next ROW;
        }

        # If we get here, all the tests passed for this row.
        # No need to test any more - we've found a winner.
        $ok = 1;
        last;
    }

    ok($ok, 'found a Batch row with matching values');
};


When qr/I click on the Batch with Control Number "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $control_code = $1;

    my $link = $page->batch_link(control_code => $control_code);
    ok($link->click, "clicked batch link with Control Number $control_code");
};


Then qr/I should see the title "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $title = $1;

    my $div = $page->title(title => $title);
    ok($div, "Found title '$title'");
};


1;
