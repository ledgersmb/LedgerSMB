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

use LedgerSMB::Currency;
use LedgerSMB::Exchangerate;
use LedgerSMB::Exchangerate_Type;
use LedgerSMB::Setting;
use LedgerSMB::Template::UI;

use Log::Log4perl;
use Text::CSV;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::currency');


=item list_currencies

Displays a list of configured currencies.  No inputs required or used.

=cut

sub list_currencies {
    my ($request) = @_;
    my @currencies = LedgerSMB::Currency->list();
    my $default_curr =
        LedgerSMB::Setting->new({base => $request})->get('curr');
    my $columns = [
        {
            col_id => 'curr',
            name   => 'ID',
            type   => 'text',
        },
        {
            col_id => 'description',
            name   => $request->{_locale}->text('Description'),
            type   => 'text',
        },
        {
            col_id => 'drop',
            type   => 'href',
            href_base => 'currency.pl?action=delete_currency&curr=',
        },
        ];
    my $rows = [];
    for my $s (@currencies) {
        $s->{row_id} = $s->{curr};
        if ($s->{curr} eq $default_curr) {
            $s->{drop_NOHREF} = 1;
            $s->{drop} = $request->{_locale}->text('default');
        }
        elsif ($s->{is_used}) {
            # Cannot delete a currency that's already being used
            $s->{drop_NOHREF} = 1;
            $s->{drop} = $request->{_locale}->text('in use');
        }
        else {
            $s->{drop} = '[' . $request->{_locale}->text('delete') . ']';
        }
        push @$rows, $s;
    }
    my $title = $request->{_locale}->text('Defined currencies');
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Configuration/currency', {
        name    => $title,
        request => $request,
        columns => $columns,
        rows    => $rows,
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
    my $columns = [
        {
            col_id => 'id',
            name   => 'ID',
            type   => 'text',
        },
        {
            col_id => 'description',
            name   => $request->{_locale}->text('Description'),
            type   => 'text',
        },
        {
            col_id => 'drop',
            type   => 'href',
            href_base => 'currency.pl?action=delete_exchangerate_type&id='
        },
        ];
    my $rows = [];
    for my $s (@exchangerate_types) {
        $s->{row_id} = $s->{id};
        if ($s->{builtin}) {
            $s->{drop_NOHREF} = 1;
            $s->{drop} = $request->{_locale}->text('system type');
        }
        elsif ($s->{is_used}) {
            # Cannot delete a currency that's already being used
            $s->{drop_NOHREF} = 1;
            $s->{drop} = $request->{_locale}->text('in use');
        }
        else {
            $s->{drop} = '[' . $request->{_locale}->text('delete') . ']';
        }
        push @$rows, $s;
    }
    my $title = $request->{_locale}->text('Defined exchange rate types');
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Configuration/ratetype', {
        name    => $title,
        request => $request,
        columns => $columns,
        rows    => $rows,
        buttons => [],
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
    shift @currencies; # Remove the default currency
    my %rate_types = map { $_->{id} => $_->{description} } @exchangerate_types;
    my $base_url = 'currency.pl?action=delete_exchangerate';
    my $columns = [
        {
            col_id => 'curr',
            name   => 'ID'
        },
        {
            col_id => 'rate_type',
            name   => $request->{_locale}->text('Rate Type'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'valid_from',
            name   => $request->{_locale}->text('Valid From'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'rate',
            name   => $request->{_locale}->text('Rate'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'drop',
            href_base => $base_url,
        },
        ];
    my $rows = [];
    for my $s (@$exchangerates) {
        $s->{rate} = $s->{rate}->to_output();
        $s->{drop_href_suffix} = "&curr=$s->{curr}&rate_type=$s->{rate_type}&valid_from=" . $s->{valid_from}->to_output();
        $s->{drop} = '[' . $request->{_locale}->text('delete') . ']';

        # Translate here, because the URL above depends on the rate_type_id!
        $s->{rate_type} = $rate_types{$s->{rate_type}};
        push @$rows, $s;
    }

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Configuration/rate', {
        name       => '',
        request    => $request,
        columns    => $columns,
        rows       => $rows,
        currencies => \@currencies,
        buttons    => [],
        exchangerate_types => \@exchangerate_types,
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

Copyright (C) 2015-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
