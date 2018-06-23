package LedgerSMB::Scripts::currency;

use strict;
use warnings;

=pod

=head1 NAME

LedgerSMB:Scripts::currency

=head1 DESCRIPTION

This module provides the workflow scripts for managing currencies and fx rates.

=head1 METHODS

=over

=cut

use LedgerSMB::Template;
use LedgerSMB::Currency;
use LedgerSMB::Exchangerate;
use LedgerSMB::Exchangerate_Type;
use LedgerSMB::Setting;

use Log::Log4perl;
use Text::CSV;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::currency');


=item list_currencies

Displays a list of configured currencies.  No inputs required or used.

=cut

sub list_currencies {
    my ($request) = @_;
    my @currencies = LedgerSMB::Currency->list();
    my $default_curr = LedgerSMB::Setting->new()->get('curr');
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'Configuration/currency',
        locale => $request->{_locale},
        format => 'HTML',
            path=>'UI'
    );
    my $columns;
    @$columns = qw(curr description drop);
    my $column_names = {
        curr => 'ID',
        description => 'Description',
    };
    my $column_heading = $template->column_heading($column_names);
    my $rows = [];
    my $rowcount = '0';
    my $base_url = 'currency.pl?action=delete_currency';
    for my $s (@currencies) {
        $s->{i} = $rowcount % 2;
        if ($s->{curr} eq $default_curr) {
           $s->{drop} = {
               text => '(' . $request->{_locale}->text('default') . ')',
           };
        }
        else {
           $s->{drop} = {
               href =>"$base_url&curr=$s->{curr}",
               text => '[' . $request->{_locale}->text('delete') . ']',
           };
        }
        push @$rows, $s;
        ++$rowcount;
    }
    $request->{title} = $request->{_locale}->text('Defined currencies');
    $template->render({
   form    => $request,
        columns => $columns,
    heading => $column_heading,
        rows    => $rows,
        buttons => [],
        hiddens => [],
    });

}

=item save_currency

Creates a currency - or if it exists, updates the description.

=cut

sub save_currency {
    my ($request) = @_;

    my $currency = LedgerSMB::Currency->new(%$request);
    $currency->save;

    return &list_currencies($request);
}

=item delete_currency

Deletes a currency. Returns an error in case the currency is
still referenced in the system.

=cut

sub delete_currency {
    my ($request) = @_;

    my $currency = LedgerSMB::Currency->new(%$request);
    $currency->delete;

    return &list_currencies($request);
}

=item list_exchangerate_types

Displays a list of configured exchangerate types.  No inputs required or used.

=cut

sub list_exchangerate_types {
    my ($request) = @_;
    my @exchangerate_types = LedgerSMB::Exchangerate_Type->list();
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'Configuration/ratetype',
        locale => $request->{_locale},
        format => 'HTML',
            path=>'UI'
    );
    my $columns;
    @$columns = qw(id description drop);
    my $column_names = {
        id => 'ID',
        description => 'Description',
    };
    my $column_heading = $template->column_heading($column_names);
    my $rows = [];
    my $rowcount = '0';
    my $base_url = 'currency.pl?action=delete_exchangerate_type';
    for my $s (@exchangerate_types) {
        $s->{i} = $rowcount % 2;
        $s->{drop} = {
            href =>"$base_url&id=$s->{id}",
            text => '[' . $request->{_locale}->text('delete') . ']',
        } if ! $s->{builtin};
        push @$rows, $s;
        ++$rowcount;
    }
    $request->{title} = $request->{_locale}->text('Defined exchange rate types');
    $template->render({
   form    => $request,
        columns => $columns,
    heading => $column_heading,
        rows    => $rows,
        buttons => [],
        hiddens => [],
    });

}

=item save_exchangerate_type

Creates a currency - or if it exists, updates the description.

=cut

sub save_exchangerate_type {
    my ($request) = @_;

    my $ratetype = LedgerSMB::Exchangerate_Type->new(%$request);
    $ratetype->save;

    return &list_exchangerate_types($request);
}

=item delete_exchangerate_type

Deletes an exchangerate type. Returns an error in case the rate type is
still referenced in the system.

=cut

sub delete_exchangerate_type {
    my ($request) = @_;

    my $ratetype = LedgerSMB::Exchangerate_Type->new(%$request);
    $ratetype->delete;

    return &list_exchangerate_types($request);
}

=item list_exchangerates

Displays a list of configured exchangerate types.  No inputs required or used.

=cut

sub list_exchangerates {
    my ($request) = @_;
    my @exchangerates = LedgerSMB::Exchangerate->list(
        curr => $request->{curr},
        type_id => $request->{type} || 1,
        offset => $request->{offset},
        limit => $request->{limit} || 30,
        );
    $request->{title} =
        $request->{_locale}->text('Available exchange rates');

    return &_list_exchangerates($request, \@exchangerates);
}

# item _list_exchangerates($request, $rows)
#
# Lists exchangerates in array ref $rows in response to $request
#
# $rows is a reference to an array of LedgerSMB::Exchangerate refs
#
# used by &list_exchangerates and &upload_exchangerates

sub _list_exchangerates {
    my ($request, $exchangerates) = @_;
    my @exchangerate_types = LedgerSMB::Exchangerate_Type->list();
    my @currencies = LedgerSMB::Currency->list();
    my %rate_types = map { $_->{id} => $_->{description} } @exchangerate_types;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'Configuration/rate',
        locale => $request->{_locale},
        format => 'HTML',
            path=>'UI'
    );
    my $columns;
    @$columns = qw(curr rate_type valid_from rate drop);
    my $column_names = {
        id => 'ID',
        description => 'Description',
    };
    my $column_heading = $template->column_heading($column_names);
    my $rows = [];
    my $rowcount = '0';
    my $base_url = 'currency.pl?action=delete_exchangerate';
    for my $s (@$exchangerates) {
        $s->{i} = $rowcount % 2;
        $s->{rate} = $s->{rate}->to_output();
        $s->{drop} = {
            href =>"$base_url&curr=$s->{curr}&rate_type=$s->{rate_type}&valid_from=" . $s->{valid_from}->to_output(),
            text => '[' . $request->{_locale}->text('delete') . ']',
        };
        # Translate here, because the URL above depends on the rate_type_id!
        $s->{rate_type} = $rate_types{$s->{rate_type}};
        push @$rows, $s;
        ++$rowcount;
    }

    $template->render({
   form    => $request,
        columns => $columns,
    heading => $column_heading,
        rows    => $rows,
   currencies => \@currencies,
   exchangerate_types => \@exchangerate_types,
        buttons => [],
        hiddens => [],
    });

}




=item save_exchangerate

Creates a currency - or if it exists, updates the description.

=cut

sub save_exchangerate {
    my ($request) = @_;

    my $ratetype = LedgerSMB::Exchangerate->new(%$request);
    $ratetype->save;

    return &list_exchangerates($request);
}

=item delete_exchangerate

Deletes an exchangerate type. Returns an error in case the rate type is
still referenced in the system.

=cut

sub delete_exchangerate {
    my ($request) = @_;

    my $ratetype = LedgerSMB::Exchangerate->new(%$request);
    $ratetype->delete;

    return &list_exchangerates($request);
}

=item upload_exchangerates



=cut

my @csv_upload_fields = (
    'curr', 'rate_type', 'valid_from', 'rate'
    );

sub upload_exchangerates {
    my ($request) = @_;

    my $csv = Text::CSV->new()
        or $request->error(q{Can't use CSV parser: } . Text::CSV->error_diag());
    my $file = $request->{_request}->upload('import_file');
    my $provided_cols;
    my @rows;

    while (my $row = $csv->getline($file)) {
        my @fields = @$row;

        unless ($provided_cols) {
            my $msg = 'Columns provided in upload (' . join(',',@fields)
                . q{) don't match required columns (}
                . join(',',@csv_upload_fields) . ')';

            $request->error($msg)
                unless scalar(@fields) == scalar(@csv_upload_fields);
            for (0..$#fields) {
                $request->error($msg)
                    unless $fields[$_] eq $csv_upload_fields[$_];
            }
            $provided_cols = $row;
            next;
        }

        my %rowhash = map { $csv_upload_fields[$_] => $fields[$_] } 0..$#fields;
        my $rate = LedgerSMB::Exchangerate->new(%rowhash);
        push @rows, $rate->save;;
    }

    $request->{title} =
        $request->{_locale}->text('Uploaded rates');
    return &_list_exchangerates($request,\@rows);
}


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
