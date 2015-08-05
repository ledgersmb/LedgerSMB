package LedgerSMB::Scripts::currency;
use strict;

=pod

=head1 NAME

LedgerSMB:Scripts::currency

=head1 SYNOPSIS

This module provides the workflow scripts for managing currencies and fx rates.
    
=head1 METHODS
        
=over   
        
=cut

use LedgerSMB::Template;
use LedgerSMB::Currency;
use Log::Log4perl;


my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::currency');


=item list_currencies

Displays a list of configured currencies.  No inputs required or used.

=cut

sub list_currencies {
    my ($request) = @_;
    my @currencies = LedgerSMB::Currency->list();
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
    my $rowcount = "0";
    my $base_url = "currency.pl?action=delete_currency";
    for my $s (@currencies) {
        $s->{i} = $rowcount % 2;
        $s->{drop} = {
            href =>"$base_url&curr=$s->{curr}", 
            text => '[' . $request->{_locale}->text('delete') . ']',
        };
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


=back

=head1 COPYRIGHT

Copyright (C) 2010 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
