#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


When qr/I search with these parameters:/, sub {
    my %h = map { $_->{parameter} => $_->{value} } @{C->data};
    S->{ext_wsl}->page->body->maindiv->content->search(%h);
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
        './/table/tbody/tr'
    );
    my $row_count = scalar @rows;

    # Discount final row if it contains totals
    my $final_element = pop @rows;
    if($final_element->get_attribute('class') =~ m/listtotal/) {
        $row_count --;
    }

    is(scalar @rows, $wanted_row_count, "report contains $wanted_row_count rows");
};


Then qr/I expect the '(.*)' report column to contain '(.*)' for (.*) '(.*)'/, sub {
    my @rows = S->{ext_wsl}->page->body->maindiv->content->rows;
    my $column = $1;
    my $value = $2;
    my $row = $3;
    my $row_id = $4;

    ok((grep { $value eq $_->{$column}
               && $row_id eq $_->{$row} } @rows),
       "Column '$column' contains '$value' for row '$row_id' ($row)");
};


Then qr/I should see a heading "(.*)" displaying "(.*)"$/, sub {
    my $heading = $1;
    my $contents = $2;
    ok(
        find_report_heading({Heading => $heading, Contents => $contents}),
        "Found header '$heading' displaying '$contents'"
    );
};


Then qr/I should see these headings:$/, sub {
    my $data = C->data;

    foreach my $wanted(@{$data}) {
        ok(
            find_report_heading($wanted),
            "Found header '$wanted->{Heading}' displaying '$wanted->{Contents}'",
        );
    }
};


sub find_report_heading {
    my $heading = shift;
    my $header_div = S->{ext_wsl}->page->body->maindiv->find(
        '//form[@id="search-report-dynatable"]'.
        '/div[@class="heading_section"]'.
        qq{/div[label[.="$heading->{Heading}:"]]}.
        qq{/span[\@class="report_header" and normalize-space(.)="$heading->{Contents}"]}
    ) or die "Matching heading not found '$heading->{Heading}' : '$heading->{Contents}'";
    return $header_div;
}


1;
