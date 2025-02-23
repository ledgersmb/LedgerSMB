#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


When qr/I search with these parameters:/, sub {
    my %h = map { $_->{parameter} => $_->{value} } @{C->data};
    S->{ext_wsl}->page->body->maindiv->content->search(%h);
};


When qr/^I select the rows? where "(.*)" is "(.*)"$/, sub {
    my @rows = S->{ext_wsl}->page->body->maindiv->content->rows;
    my $column = $1;
    my $value = $2;

    foreach my $row(@rows) {
        if ($row->{$column} eq $value) {
            my $checkbox = $row->{_element}->find(
                './td//input[@type="checkbox"]'
            );
            my $checked = $checkbox->get_attribute('checked');
            $checked && $checked eq 'true' or $checkbox->click;
        }
    }
};


Then qr/the Balance Sheet per (.{10}) looks like:/, sub {
    my $date = $1;

    S->{ext_wsl}->page->body->menu->click_menu(['Reports', 'Balance Sheet']);
    S->{ext_wsl}->page->body->maindiv->content->run(date => $date);

    my @step_data =
        map { { accno => $_->{accno},
                values => [ $_->{amount} ] } } @{C->data};
    my $actual_data = S->{ext_wsl}->page->body->maindiv
        ->content->account_balances;
    is_deeply($actual_data, \@step_data, 'Balancesheet account balances match');
};


Then qr/I expect the report to contain (\d+) rows?$/, sub {
    my $wanted_row_count = $1;
    my @rows = S->{ext_wsl}->page->body->maindiv->content->find_all(
        './/table[contains(@class, "dynatable")]/tbody/tr'
    );
    my $row_count = scalar @rows;

    # Discount final row if it contains totals
    my $final_element = pop @rows;
    if($final_element && $final_element->get_attribute('class') =~ m/listtotal/) {
        $row_count --;
    }

    is($row_count, $wanted_row_count, "report contains $wanted_row_count rows");
};


Then qr/I expect the '(.*)'\s+(?:report )?column to contain '(.*)'\s+for (.*) '(.*)'/, sub {
    my @rows = S->{ext_wsl}->page->body->maindiv->content->rows;
    my $column = $1;
    my $value = $2;
    my $row = $3;
    my $row_id = $4;
    $value =~ s/^\$\$(.+)$/S->{$1}/e;

    ok((grep { $value eq $_->{$column}
               && $row_id eq $_->{$row} } @rows),
       "Column '$column' contains '$value' for row '$row_id' ($row)");
};


Then qr/I should see a heading "(.*)" displaying "(.*)"$/, sub {
    my $heading = $1;
    my $contents = $2;

    my $found = S->{ext_wsl}->page->body->maindiv->content->find_heading({
        Heading => $heading,
        Contents => $contents
    });

    ok(
        $found,
        "Found header '$heading' displaying '$contents'"
    );
};


Then qr/I should see these headings:$/, sub {
    my $data = C->data;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    foreach my $wanted(@{$data}) {
        ok(
            $page->find_heading($wanted),
            "Found header '$wanted->{Heading}' displaying '$wanted->{Contents}'",
        );
    }
};


When qr/^I click "(.*)" for the row with (.*) "(.*)"$/, sub {
    my $link_text = $1;
    my $column = $2;
    my $value = $3;
    my @rows = S->{ext_wsl}->page->body->maindiv->content->rows;

    ok(@rows, qq/found row with $column "$value"/);

    foreach my $row(@rows) {
        if ($row->{$column} eq $value) {
            my $link = $row->{_element}->find(
                qq{.//a[.="$1"]}
            );

            ok($link, "found $link_text link for $column '$value'");
            $link->click;
            S->{ext_wsl}->page->body->maindiv->
                wait_for_content(replaces => $link);
            return;
        }
    }
};


Then qr/I should see the title "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $title = $1;

    my $div = $page->title(title => $title);
    ok($div, "Found title '$title'");
};


1;
