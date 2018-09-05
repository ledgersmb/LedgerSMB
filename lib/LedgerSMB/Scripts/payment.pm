
package LedgerSMB::Scripts::payment;

=head1 NAME

LedgerSMB::Scripts::payment - Web entrypoints for payment handling.

=head1 DESCRIPTION

Defines the controller functions and workflow logic for payment processing.

=head1 LICENSE AND COPYRIGHT

Portions Copyright (c) 2007, David Mora R and Christian Ceballos B.

Licensed to the public under the terms of the GNU GPL version 2 or later.

Original copyright notice below.

#=====================================================================
# PLAXIS
# Copyright (c) 2007
#
#  Author: David Mora R
#        Christian Ceballos B
#
#
#
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


=head1 METHODS

=cut

use strict;
use warnings;

use List::Util qw/sum/;

use LedgerSMB::App_State;
use LedgerSMB::Company_Config;
use LedgerSMB::DBObject::Payment;
use LedgerSMB::DBObject::Date;
use LedgerSMB::Magic qw( MAX_DAYS_IN_MONTH EC_VENDOR );
use LedgerSMB::PGDate;
use LedgerSMB::PGNumber;
use LedgerSMB::Report::Invoices::Payments;
use LedgerSMB::Request::Helper::ParameterMap;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;
use LedgerSMB::Template::UI;


# CT:  A few notes for future refactoring of this code:
# 1:  I don't think it is a good idea to make the UI too dependant on internal
#     code structures but I don't see a good alternative at the moment.
# 2:  CamelCasing: -1
# 3:  Not good to have this much duplication of code all the way down the stack.
#     At the moment this is helpful because it gives us an opportunity to look
#     at various sets of requirements and workflows, but for future versions
#     if we don't refactor, this will turn into a bug factory.
# 4:  Both current interfaces have issues regarding separating layers of logic
#     and concern properly.

# CT:  Plans are to completely rewrite all payment logic for 1.4 anyway.

=over

=item payments($request)

Prepare and display the Payments Filter screen.

C<payments> is a L<LedgerSMB> object reference. The following request keys
must be defined:

  * dbh
  * account_class
  * batch_id

=cut

sub payments {
    my ($request) = @_;
    my $payment_data = {
        dbh => $request->{dbh},
        account_class => $request->{account_class},
        batch_id => $request->{batch_id},
    };
    my $payment = LedgerSMB::DBObject::Payment->new({'base' => $payment_data});
    $payment->get_metadata();

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'payments/payments_filter',
                             { request => $request,
                               payment => $payment });
}

=item get_search_criteria($request)

Displays the 'Search Payments' screen.

C<$request> is a L<LedgerSMB> object reference. The following keys must be
set:

  * dbh
  * account_class

Optionally the following key may be defined, if the search is to be used to
find payments to add as vouchers to a reversing batch:

  * batch_id

=cut

sub get_search_criteria {
    my ($request) = @_;

    my $payment_data = {
        dbh => $request->{dbh},
        account_class => $request->{account_class},
        all_months => LedgerSMB::App_State->all_months->{dropdown},
    };

    # Additional data needed if this search is to create reversing vouchers
    $payment_data->{batch_id} = $request->{batch_id} if $request->{batch_id};

    my $payment = LedgerSMB::DBObject::Payment->new({'base' => $payment_data});
    $payment->get_metadata();

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render(
        $request,
        'Reports/filters/payments',
        $payment
    );
}

=item pre_bulk_post_report

    This displays a report of the expected GL activity of a payment batch before it
    is saved.  For receipts, this just redirects to bulk_post currently.

=cut


my $bulk_post_map = input_map(
    [ qr/^(?<fld>id|source|memo|paid)_(?<cid>\d+)$/ => '@contacts<cid>:%<fld>' ],
    [ qr/^contact_label_(?<cid>\d+)$/ => '@contacts<cid>:%pay_to>' ],
    [ qr/^(?<fld>invoice_date|invnumber|due|payment|invoice|net)_(?<cid>\d+)_(?<invrow>\d+)$/
      => '@contacts<cid>:@invoices<invrow>:%<fld>' ],
    [ qr/(?<fld>cash_accno|ar_ap_accno)$/ => '%<fld>' ],
    [ qr/^transdate$/ => '%date_paid' ],
    [ qr/^datepaid$/ => '%payment_date' ],
    [ qr/^(?<fld>multiple)$/ => '%<fld>' ],
    );

sub pre_bulk_post_report {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new( # printed document
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => ($request->{report_format}) ? $request->{report_format} : 'HTML',
    );
    my $cols;
    @$cols =  qw(pay_to accno source memo debits credits);
    my $heading = {
        pay_to          => $request->{_locale}->text('Pay To'),
        accno           => $request->{_locale}->text('Account Number'),
        acc_description => $request->{_locale}->text('Account Title'),
        transdate       => $request->{_locale}->text('Date'),
        source          => $request->{_locale}->text('Source'),
        memo            => $request->{_locale}->text('Memo'),
        debits           => $request->{_locale}->text('Debits'),
        credits          => $request->{_locale}->text('Credits')
    };

    # parse the flat "request" namespace into a hierarchical structure
    # as defined by the $bulk_post_map transform
    my $data = $bulk_post_map->($request);

    # The user interface sets the 'id' field true-ish when the customer
    # is selected for inclusion in the bulk payment
    @{$data->{contacts}} = grep { $_->{id} } @{$data->{contacts}};
    for my $crow (@{$data->{contacts}}) {
        $crow->{accno} = $data->{ar_ap_accno};
        $crow->{transdate} = $request->{payment_date};
        $crow->{amount} =
            sum map { LedgerSMB::PGNumber->from_input($_->{payment}) }
            @{$crow->{invoices}};
        $crow->{amount} *= -1
                    if ($request->{account_class} == EC_VENDOR);
        $crow->{debits} = ($crow->{amount} < 0) ? ($crow->{amount} * -1) : 0;
        $crow->{credits} = ($crow->{amount} > 0) ? $crow->{amount} : 0;;
    }
    my $rows = $data->{contacts};

    my $total = sum map { $_->{amount} } @{$data->{contacts}};
    my $total_debits = sum map { $_->{debits} } @{$data->{contacts}};
    my $total_credits = sum map { $_->{credits} } @{$data->{contacts}};

    # Cash summary
    my $ref = {
       accno     => $request->{cash_accno},
       transdate => $request->{date_paid},
       source    => $request->{_locale}->text('Total'),
       amount    => $total,
    };
    $ref->{amount} *= -1;

    if ($ref->{amount} < 0) {
        $ref->{debits} = $ref->{amount} * -1;
        $ref->{credits} = 0;
    } else {
        $ref->{debits} = 0;
        $ref->{credits} = $ref->{amount};
    }
    $total_debits += $ref->{debits};
    $total_credits += $ref->{credits};
    push @$rows, $ref;
    push @$rows,
       {class   => 'subtotal',
        debits  => $total_debits,
        credits => $total_credits};

    my $buttons = [{
        text  => $request->{_locale}->text('Save Batch'),
        name  => 'action',
        value => 'post_payments_bulk',
        class => 'submit',
    }];
    delete $request->{$_}
       for qw(action dbh);
    return $template->render({
        form => $request,
        hiddens => $request,
        columns => $cols,
        heading => $heading,
        rows    => $rows,
        buttons => $buttons,
    });
}


=item get_search_results

Displays the payment search results.

inputs currently expected include

=over

=item credit_id

=item date_from

=item date_to

=item source

=item cash_accno

=item account_class

=back

=cut


sub get_search_results {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Invoices::Payments->new(%$request);
    $request->{hiddens} = {
        batch_id => $request->{batch_id},
      cash_accno => $request->{cash_accno},
        currency => $request->{currency},
    exchangerate => $request->{exchangerate},
   date_reversed => $request->{date_reversed},
   account_class => $request->{account_class},
    };
    return $report->render($request);
}

=item reverse_payments

This reverses payments selected in the search results.

=cut

sub reverse_payments {
    my ($request) = @_;

    my $date_reversed = LedgerSMB::PGDate->from_input(
        $request->{date_reversed}
    );

    foreach my $count (1 .. $request->{rowcount_}) {
        # Reverse only the selected payments
        if ($request->{"select_$count"}) {

            my $data = {
                          dbh => $request->{dbh},
                date_reversed => $date_reversed,
                     batch_id => $request->{batch_id},
                   cash_accno => $request->{cash_accno},
                     currency => $request->{currency},
                 exchangerate => $request->{exchangerate},
                       source => $request->{"source_$count"},
                    credit_id => $request->{"credit_id_$count"},
                account_class => $request->{"entity_class_$count"},
                   voucher_id => $request->{"voucher_id_$count"},
                    date_paid => LedgerSMB::PGDate->from_input(
                                     $request->{"date_paid_$count"}
                                 ),
            };

            my $payment = LedgerSMB::DBObject::Payment->new({base => $data});
            $payment->reverse;
        }
    }

    # Go back to search for more payments/receipts to reverse
    return get_search_criteria($request);
}

=item post_payments_bulk

This is a light-weight wrapper around LedgerSMB::DBObject::Payment->post_bulk.

Please see the documentation of that function as to expected inouts.

Additionally, this checks against the XSRF framework and  reloads the screen
with a notice to try again if the attempt to close out the form key is not
successful.

=cut

sub post_payments_bulk {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    if ($request->close_form){
        my $data = $bulk_post_map->($request);
        $payment->post_bulk($data);
    } else {
        $payment->{notice} =
           $payment->{_locale}->text('Data not saved.  Please try again.');
        return display_payments($request);
    }

    return payments($request);
}

=item print

Prints a stack of checks.  Currently the logic from the single payment interface
is not merged in, meaning that $request->{multiple} must be set to a true value.

=cut

sub print {
    use LedgerSMB::Batch;
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->{company} = $payment->{_user}->{company};
    $payment->{address} = $payment->{_user}->{address};

    my $template;

    if ($payment->{batch_id}){
        my $batch = LedgerSMB::Batch->new(
                         {base => $payment,
                         copy  => 'base' }
        );
        $batch->{batch_id} = $payment->{batch_id};
        $batch->get;
        $payment->{batch_description} = $batch->{description};
        $payment->{batch_control_code} = $batch->{control_code};
    }

    $payment->{format_amount} =
        sub {return LedgerSMB::PGNumber->from_input(@_)->to_output(); };

    my $data = $bulk_post_map->($request);
    if ($data->{multiple}){
        $payment->{checks} = [];

        # consider only contacts which have been explicitly selected
        # for inclusion in the bulk payment ($contact->{id} == true-ish)
        for my $contact (grep { $_->{id} } @{$data->{contacts}}){
            my ($check) = $payment->call_procedure(
                     funcname => 'company_get_billing_info', args => [$id]
            );
            $check->{entity_class} = $payment->{account_class};
            $check->{id} = $contact->{id};
            $check->{amount} = LedgerSMB::PGNumber->from_db('0');
            $check->{invoices} = [];
            $check->{source} = $contact->{source};

            my $inv_count;
            my $check_max_invoices = $request->setting->get(
                         'check_max_invoices'
            );
            if ($check_max_invoices > scalar(@{$contact->{invoices}})) {
                $inv_count = scalar(@{$contact->{invoices}});
            } else {
                $inv_count = $check_max_invoices;
            }

            for my $invoice (@{$contact->{invoices}}) {
                if ($contact->{paid} eq 'some'){
                    $invoice->{paid} = LedgerSMB::PGNumber
                        ->from_input($invoice->{payment});
                } elsif ($contact->{paid} eq 'all'){
                    $invoice->{paid} = LedgerSMB::PGNumber
                        ->from_input($invoice->{net});
                } else {
                    $payment->error('Invalid Payment Amount Option');
                }
                $check->{amount} += $invoice->{paid};
                $invoice->{paid} = $invoice->{paid}->to_output(
                    format => '1000.00',
                    money => 1
                );
                push @{$check->{invoices}}, $invoice
                    if scalar(@{$check->{invoices}}) <= $inv_count;
            }
            my $amt = $check->{amount}->copy;
            $amt->bfloor();
            $check->{text_amount} = $payment->text_amount($amt);
            $check->{decimal} = ($check->{amount} - $amt) * 100;
            $check->{amount} = $check->{amount}->to_output(
                    format => '1000.00',
                    money => 1
            );
            push @{$payment->{checks}}, $check;
        }
        $template = LedgerSMB::Template->new( # printed document
            user => $payment->{_user},
            template => 'check_multiple',
            format => uc $payment->{'format'},
            path => 'DB',
            output_options => {
               filename => 'printed-checks',
            },
        );
        return $template->render($payment);
    } else {

    }
    return;
}

=item update_payments

Displays the bulk payment screen with current data

=cut

sub update_payments {
    return display_payments(@_);
}

=item display_payments($request)

This displays the bulk payment screen with current data.

C<$request> is a L<LedgerSMB> object reference.

Required request parameters:

  * dbh
  * action
  * account_class [1|2]
  * batch_id
  * batch_date
  * currency
  * source_start

Optionally accepts the following filtering parameters:

  * ar_ap_accno
  * meta_number

Though the following filtering parameters appear to be available,
they are not supported by the underlying C<payment_get_all_contact_invoices>
database query:

  * business_id
  * date_from
  * date_to

=cut

sub display_payments {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->get_payment_detail_data();
    $request->open_form();
    my $db_fx = $payment->get_exchange_rate($payment->{currency},
                                            $payment->{batch_date});
    if ($db_fx){
        $payment->{exchangerate} = $db_fx->bstr;
        $payment->{fx_from_db} = 1;
    } else {
        $payment->{exchangerate} = undef;
    }
    $payment->{grand_total} = LedgerSMB::PGNumber->from_input(0);
    my $source = $request->{source_start};
    for (@{$payment->{contact_invoices}}){
        my $contact_total = 0;
        my $contact_to_pay = 0;

        for my $invoice (@{$_->{invoices}}){
            if (($payment->{action} ne 'update_payments')
                  or (defined $payment->{"id_$_->{contact_id}"})){
                $payment->{"paid_$_->{contact_id}"} = ''
                    unless defined $payment->{"paid_$_->{contact_id}"};
            }
            $invoice->[6] = $invoice->[3] - $invoice->[4] - $invoice->[5];  ## no critic (ProhibitMagicNumbers) sniff
            $contact_to_pay += $invoice->[6];  ## no critic (ProhibitMagicNumbers) sniff
            $invoice->[7] = $invoice->[6]->to_db;  ## no critic (ProhibitMagicNumbers) sniff

            my $fld = "payment_$_->{contact_id}_" . $invoice->[0];
            $contact_total += LedgerSMB::PGNumber->from_input($payment->{$fld});

            $invoice->[3] = $invoice->[3]->to_output(money  => 1);  ## no critic (ProhibitMagicNumbers) sniff
            $invoice->[4] = $invoice->[4]->to_output(money  => 1);
            $invoice->[5] = $invoice->[5]->to_output(money  => 1);
            $invoice->[6] = $invoice->[6]->to_output(money  => 1);

            if ('display_payments' eq $request->{action}) {
                $payment->{$fld} = $invoice->[6];
            }
            else {
                $payment->{$fld} //= 0;
                $payment->{$fld} =
                    LedgerSMB::PGNumber->from_input($payment->{$fld})
                    ->to_output(money => 1);
            }
        }
        if ($payment->{"paid_$_->{contact_id}"} ne 'some') {
                  $contact_total = $contact_to_pay;
        }
        $_->{contact_total} = $contact_total;
        $_->{to_pay} = $contact_to_pay;
        $payment->{grand_total} += $contact_total
            if ($payment->{"id_$_->{contact_id}"}
                or (defined $payment->{"paid_$_->{contact_id}"}
                    and $payment->{"paid_$_->{contact_id}"} eq 'some'));

        my ($check_all) = $request->setting->get('check_payments');
        if ($payment->{account_class} == 1 and $check_all){
            $payment->{"id_$_->{contact_id}"} = $_->{contact_id};
        }

        if ($payment->{account_class} == 1
            && $request->{"id_$_->{contact_id}"}) {
            # AP && selected
            $_->{source} = $source;
            $source++;
        }
        if ($payment->{account_class} == 2) {
            $_->{source} = $request->{"source_$_->{contact_id}"};
        }
        $_->{total_due} = $_->{total_due}->to_output(money  => 1);
        $_->{contact_total} = $_->{contact_total}->to_output(money  => 1);
        $_->{to_pay} = $_->{to_pay}->to_output(money  => 1);
    }
    $payment->{grand_total} = $payment->{grand_total}->to_output(money  => 1);
    @{$payment->{media_options}} = (
            {text  => $request->{_locale}->text('Screen'),
             value => 'screen'});
    for (keys %LedgerSMB::Sysconfig::printer){
         push @{$payment->{media_options}},
              {text  => $_,
               value => $_};
    }
    if ($LedgerSMB::Sysconfig::latex){
        @{$payment->{format_options}} = (
              {text => 'PDF',        value => 'PDF'},
              {text => 'Postscript', value => 'Postscript'},
        );
        $payment->{can_print} = 1;
    }

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'payments/payments_detail',
                             { request => $request,
                               payment => $payment });
}

=item payment

This method is used to set the filter screen and prints it, using the
TT2 system.

=cut

sub payment {
    my ($request)    = @_;
    #my $locale       = $request->{_locale};
    my $dbPayment = LedgerSMB::DBObject::Payment->new({'base' => $request});

    # Lets get the currencies (this uses the $dbPayment->{account_class} property)
    my @currOptions;
    my @arrayOptions = $request->setting->get_currencies();

    for my $ref (0 .. $#arrayOptions) {
        push @currOptions, { value => $arrayOptions[$ref],
                             text => $arrayOptions[$ref]};

    }
    # Lets build filter by period
    my $date = LedgerSMB::DBObject::Date->new({base => $request});
    $date->build_filter_by_period($request->{_locale});
    # Lets set the data in a hash for the template system. :)
    my $select = {
        script => 'payment.pl',
        stylesheet => $request->{_user}->{stylesheet},
        login    => { name  => 'login',
                      value => $request->{_user}->{login}   },
        curr => {
            name => 'curr',
            options => \@currOptions
        },
                month => {
                    name => 'month',
                    options => $date->{monthsOptions}
            },
        year => {
            name => 'year',
            options => $date->{yearsOptions}
        },
        interval_radios => $date->{radioOptions},
        amountfrom => {
            name => 'amountfrom',
        },
        amountto => {
            name => 'amountto',
        },
        accountclass => {
            name  => 'account_class',
            value => $dbPayment->{account_class}
        },
        type => {
            name  => 'type',
            value => $request->{type}
        },
        action => {
            name => 'action',
            value => 'payment1_5',
            text => $request->{_locale}->text('Continue'),
        }
    };

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'payments/payment1', $select);
}


=item payment1_5

This method is called between payment and payment2, it will search the database
for entity_credit_accounts that match the parameter, if only one is found it will
run unnoticed by the user, if more than one is found it will ask the user to pick
one to handle the payment against

=cut

sub payment1_5 {
    my ($request)    = @_;
    #my $locale       = $request->{_locale};#avoid duplicating variables as much as possible?
    my  $dbPayment = LedgerSMB::DBObject::Payment->new({'base' => $request});
    my @array_options = $dbPayment->get_entity_credit_account();
    if ($#array_options == -1) {
        return &payment($request);
    } elsif ($#array_options == 0) {
        $request->{'vendor-customer'} = $array_options[0]->{id}.'--'.$array_options[0]->{name};
        return &payment2($request);
    }
    else {
        # Lets call upon the template system
        my @company_options;
        for my $ref (0 .. $#array_options) {
            push @company_options, {    id => $array_options[$ref]->{id},
                                        name => $array_options[$ref]->{name},
                                        meta_number => $array_options[$ref]->{meta_number}};
        }
        @company_options = sort { $a->{name} cmp $b->{name} } @company_options;
        my $select = {
            companies => \@company_options,
            script       => 'payment.pl',
            stylesheet   => $request->{_user}->{stylesheet},
            login        => {  name     => 'login',
                               value    => $request->{_user}->{login}},
            department   => {  name     => 'department',
                               value    => $request->{department}},
            currency     => {  name     => 'curr',
                               value    => $request->{curr}},
            datefrom     => {  name     => 'datefrom',
                               value    => $request->{datefrom}},
            dateto       => {  name     => 'dateto',
                               value    => $request->{dateto}},
            amountfrom   => {  name     => 'amountfrom',
                               value    => $request->{datefrom}},
            amountto     => {  name     => 'amountto',
                               value    => $request->{dateto}},
            accountclass => {  name     => 'account_class',
                               value    => $dbPayment->{account_class}},
            type         => {  name  => 'type',
                               value => $request->{type}},
            action       => {  name => 'action',
                               value => 'payment2',
                               text =>  $request->{_locale}->text('Continue')}
        };

        my $template = LedgerSMB::Template::UI->new_UI;
        return $template->render($request, 'payments/payment1_5', $select);
    }

}


=item update_payment2($request)

This method is used by the payment2 form when executing the action
associated with the Update button. The difference with the primary
method is in the handling of the "invoice checkboxes".

=cut

sub update_payment2 {
    my ($request) = @_;

    return payment2($request, update => 1);
}

=item payment2($request, update => $boolean)

This method is used  for the payment module, it is a consecuence
of the payment sub, and its used for all the mechanics of an invoices
payment module.

=cut

sub payment2 {
    my ($request, %args) = @_;
    my $locale       = $request->{_locale};
    my $Payment = LedgerSMB::DBObject::Payment->new({'base' => $request});
    # VARIABLES
    my ($project_id, $project_number, $project_name, $department_name );
    my @project;
    my @selected_checkboxes;
    my @department;
    my $currency_options;
    my $exchangerate;
    my $module;
    my $b_units;
    if ($request->{account_class} == 2){
        $module = 'AR';
    } elsif ($request->{account_class} == 1){
        $module = 'AP';
    }

    my @b_classes = $request->call_procedure(
        funcname => 'business_unit__list_classes',
        args => ['1', $module]);

    for my $cls (@b_classes){
        my @units = $request->call_procedure(
            funcname => 'business_unit__list_by_class',
            args => [$cls->{id}, $request->{transdate},
                     $request->{credit_id}, '0'],
            );
        $b_units->{$cls->{id}} = \@units;
    }
    # LETS GET THE CUSTOMER/VENDOR INFORMATION

    ($Payment->{entity_credit_id}, $Payment->{company_name})
        = split /--/ , $request->{'vendor-customer'};

    # WE NEED TO RETRIEVE A BILLING LOCATION,
    # THIS IS HARDCODED FOR NOW... Should we change it?
    $Payment->{location_class_id} = '1';
    my @vc_options;
    @vc_options = $Payment->get_vc_info();
    # LETS BUILD THE PROJECTS INFO
    # I DONT KNOW IF I NEED ALL THIS,
    # BUT AS IT IS AVAILABLE I'LL STORE IT FOR LATER USAGE.
    if ($request->{projects}) {
        ($project_id, $project_number, $project_name)
            = split /--/ ,  $request->{projects} ;
        @project = {
            name => 'projects',
            text => $project_number . ' ' . $project_name,
            value => $request->{projects}};
    }
    # LETS GET THE DEPARTMENT INFO
    # WE HAVE TO SET $dbPayment->{department_id} NOW,
    # THIS DATA WILL BE USED LATER
    # WHEN WE CALL FOR payment_get_open_invoices. :)
    if ($request->{department}) {
        ($Payment->{department_id}, $department_name)
            = split /--/, $request->{department};
        @department = {
            name => 'department',
            text => $department_name,
            value => $request->{department}};
    }
    my @account_options = $Payment->list_accounting();
    my @sources_options = $Payment->get_sources(\%$locale);
    my $default_currency = $Payment->get_default_currency();
    my $currency_text  =
        $request->{curr} eq $default_currency ? '' : '('.$request->{curr}.')';
    my $default_currency_text = $currency_text ? '('.$default_currency.')' : '';
    my @column_headers =  (
        {text => $locale->text('Invoice')},
        {text => $locale->text('Date')},
        {text => $locale->text('Total').$default_currency_text},
        {text => $locale->text('Paid').$default_currency_text},
        {text => $locale->text('Discount').$default_currency_text},
        {text => $locale->text('Apply Disc')},
        {text => $locale->text('Memo')},
        {text => $locale->text('Amount Due').$default_currency_text}
        );

    if ($default_currency ne $request->{curr} ) {
        push @column_headers, {text => $locale->text('Exchange Rate')},
        {text => $locale->text('Amount Due') . $currency_text};
        @column_headers[7,8] = @column_headers[8,7];

        # select the exchange rate for the currency at the payment date
        # this has preference over what comes from the request, because the
        # payment date may have changed since the last request and the
        # currency rate in the request can be associated with the old payment
        # date -- for example when a rate has been entered for the current
        # date and the user selects a different date after opening
        # the screen: today's rate would be used with no way for the user
        # to override, if we would simply take the exrate from the request.
        $exchangerate = $Payment->get_exchange_rate(
            $request->{curr},
            $request->{datepaid}
            ? $request->{datepaid} : $Payment->{current_date});

        if ((! $exchangerate)
            && $request->{datepaid} eq $request->{olddatepaid}) {
            $exchangerate = $request->{exrate};
        }

        if ($exchangerate) {
            $currency_options = {
                name => 'exrate',
                #THERE IS A STRANGE BEHAVIOUR WITH THIS,
                #IF I DONT USE THE DOUBLE QUOTES, IT WILL PRINT THE ADDRESS
                #THERE MUST BE A REASON FOR THIS, I MUST RETURN TO IT LATER
                value => "$exchangerate",
                text =>  "$exchangerate"
            };
        } else {
            $currency_options = { name => 'exrate'};
        }

    } else {
        # WE MUST SET EXCHANGERATE TO 1 FOR THE MATHS SINCE WE
        # ARE USING THE DEFAULT CURRENCY
        $exchangerate = 1;
        $currency_options = {
            name => 'exrate',
            value => 1,
            text =>  1
        };
    }
    # FINALLY WE ADD TO THE COLUMN HEADERS A LAST FIELD TO PRINT THE CLOSE INVOICE CHECKBOX TRICK :)
    if ($request->{account_class} == 1) {
        push @column_headers,
            {
                text => $locale->text('To pay').$currency_text
            },
            {
                text => 'X'
            };
    } else {
        push @column_headers,
            {
                text => $locale->text('Received').$currency_text
            },
            {
                text => 'X'
            };
    }
    my @invoice_data;
    my @topay_state;
    my @open_invoices  = $Payment->get_open_invoices();
    my $unhandled_overpayment;
    for my $invoice (@open_invoices) {
        $invoice->{invoice_date} = $invoice->{invoice_date}->to_output;

        if ($args{update}
            && ! $request->{"checkbox_$invoice->{invoice_id}"}) {
            next;
        }

        my $request_topay_fx_bigfloat
            = LedgerSMB::PGNumber->from_input($request->{"topay_fx_$invoice->{invoice_id}"});
        # SHOULD I APPLY DISCCOUNTS?
        $request->{"optional_discount_$invoice->{invoice_id}"} =
            $request->{first_load}
        ? 'on'
            :  $request->{"optional_discount_$invoice->{invoice_id}"};

        # LETS SET THE EXCHANGERATE VALUES
        #tshvr4 meaning of next statement? does the same in either case!
        my $due_fx = $invoice->{due_fx};

        my $topay_fx_value;
        if ("$exchangerate") {
            $topay_fx_value =   $due_fx;
            if (!$request->{"optional_discount_$invoice->{invoice_id}"}) {
                $topay_fx_value = $due_fx =
                    $due_fx +
                    ($invoice->{discount}/$invoice->{exchangerate});
            }
        } else {
            #    $topay_fx_value = "N/A";
        }


        # We need to check for unhandled overpayment, see the post
        # function for details
        # First we will see if the discount should apply?


        # We need to compute the unhandled_overpayment, notice that
        # all the values inside the if already have
        # the exchangerate applied

        # XXX:  This causes issues currently, so display of unhandled
        # overpayment has disabled.  Was getting numbers that didn't make
        # a lot of sense to me. --CT
        $due_fx ||= 0;
        $request_topay_fx_bigfloat ||= 0;
        if ( $due_fx <  $request_topay_fx_bigfloat) {
            # We need to store all the overpayments
            # so we can use it on the screen
            $unhandled_overpayment =
                $unhandled_overpayment + $request_topay_fx_bigfloat
                - $due_fx;
            #$request->{"topay_fx_$invoice->{invoice_id}"} = "$due_fx";
            $request_topay_fx_bigfloat=$due_fx;
        }
        my $paid = $invoice->{amount} -
            $invoice->{due} - $invoice->{discount};
        my $paid_formatted = $paid->to_output;
        # Now its time to build the link to the invoice :)
        my $uri_module;
        #TODO move following code to sub getModuleForUri() ?
        if($Payment->{account_class} == 1) { # 1 is vendor
            if($invoice->{invoice}) {
                $uri_module='ir';
            }
            else {
                $uri_module='ap';
            }
        }#account_class 1
        elsif($Payment->{account_class} == 2) { # 2 is customer
            if($invoice->{invoice}) {
                $uri_module='is';
            }
            else {
                $uri_module='ar';
            }
        }#account_class 2
        else {
            #TODO
            $uri_module='??';
        }
        #my $uri = $Payment->{account_class} == 1 ? 'ap' : 'ar';
        my $uri = $uri_module . '.pl?action=edit&id='
            . $invoice->{invoice_id} . '&login=' . $request->{login};
        my $invoice_id = $invoice->{invoice_id};
        my $invoice_amt = $invoice->{amount};
        push @invoice_data, {
            invoice => {
                number => $invoice->{invnumber},
                id     =>  $invoice_id,
                href   => $uri },
            invoice_date      => "$invoice->{invoice_date}",
            amount            => $invoice_amt ? $invoice_amt->to_output() : '',
            due               => $request->{"optional_discount_$invoice_id"}?  $invoice->{due} : $invoice->{due} + $invoice->{discount},
            paid              => $paid_formatted,
            discount          => $request->{"optional_discount_$invoice_id"} ? "$invoice->{discount}" : 0 ,
            optional_discount =>  $request->{"optional_discount_$invoice_id"},
            exchange_rate     =>  "$invoice->{exchangerate}",
            due_fx            =>  "$due_fx", # This was set at the begining of the for statement
            topay             => $invoice->{due} - $invoice->{discount},
            source_text       =>  $request->{"source_text_$invoice_id"},
            optional          =>  $request->{"optional_pay_$invoice_id"},
            selected_account  =>  $request->{"account_$invoice_id"},
            selected_source   =>  $request->{"source_$invoice_id"},
            memo              =>  {
                name  => "memo_invoice_$invoice_id",
                value => $request->{"memo_invoice_$invoice_id"}
            },#END HASH
            topay_fx          =>  {
                name  => "topay_fx_$invoice_id",
                value => $request->{"topay_fx_$invoice_id"} //
                    ( $topay_fx_value ?
                      LedgerSMB::PGNumber->from_input($topay_fx_value)->to_output()
                      : ''),
            }#END HASH
        };# END PUSH

        push @topay_state, {
            id  => "topaystate_$invoice_id",
            value => $request->{"topaystate_$invoice_id"}
        }; #END PUSH
    }# END FOR
    # And finally, we are going to store the information for the overpayment / prepayment / advanced payment
    # and all the stuff, this is only needed for the update function.
    my @overpayment;
    my @overpayment_account;
    # Got to build the account selection box first.
    @overpayment_account = $Payment->list_overpayment_accounting();
    # Now we build the structure for the UI
    $request->{overpayment_qty} //= 1;
    for my $i (1 .. $request->{overpayment_qty}) {
        if (!$request->{"overpayment_checkbox_$i"}) {
            if ( $request->{"overpayment_topay_$i"} ) {
                # Now we split the account selected options
                my ($id, $accno, $description) =
                    split(/--/, $request->{"overpayment_account_$i"});
                my ($cashid, $cashaccno, $cashdescription  ) =
                    split(/--/, $request->{"overpayment_cash_account_$i"});

                push @overpayment, {
                    amount  => LedgerSMB::PGNumber->from_input($request->{"overpayment_topay_$i"}),
                    source1 => $request->{"overpayment_source1_$i"},
                    source2 => $request->{"overpayment_source2_$i"},
                    memo    => $request->{"overpayment_memo_$i"},
                    account => {
                        id          => $id,
                        accno       => $accno,
                        description => $description
                    },
                            cashaccount => {
                                id     =>   $cashid,
                                accno  =>  $cashaccno,
                                description => $cashdescription
                        }
                };
            }
            else {
                $i = $request->{overpayment_qty} + 1;
            }
        }
    }
    # We need to set the available media and format from printing
    my @media_options;
    push  @media_options, {value => 1, text => 'Screen'};
    if ($#{LedgerSMB::Sysconfig::printer}) {
        for (keys %{LedgerSMB::Sysconfig::printer}) {
            push  @media_options, {value => 1, text => $_};
        }
    }
    push  @media_options, {value => 1, text => 'e-mail'};

    #$request->error("@media_options");
    my @format_options;
    push @format_options, {value => 1, text => 'HTML'};
    if (${LedgerSMB::Sysconfig::latex}) {
        push  @format_options,
        {value => 2, text => 'PDF' },
        {value => 3, text => 'POSTSCRIPT' };
    }
    # LETS BUILD THE SELECTION FOR THE UI
    # Notice that the first data inside this selection is the firs_load, this
    # will help payment2.html to know wether it is being called for the first time
    my $select = {
        script     => 'payment.pl',
        first_load => $request->{first_load},
        stylesheet => $request->{_user}->{stylesheet},
        header  =>  { text => $request->{type} eq 'receipt' ? $locale->text('Receipt') : $locale->text('Payment') },
        type    =>  { name  => 'type',
                      value =>  $request->{type} },
        login    => { name  => 'login',
                      value => $request->{login}   },
        accountclass => {
            name  => 'account_class',
            value => $Payment->{account_class}
        },
        project =>  @project ? \@project : '' ,        # WE NEED TO VERIFY THAT THE ARRAY EXISTS, IF IT DOESNT,
        department => @department ? \@department : '', # WE WILL PASS A NULL STRING, THIS FIXES THE ISSUES
        # I WAS HAVING WITH THE NULL ARRAYS, STILL UGLY :P
        account => \@account_options,
        selected_account => $request->{account},
        datepaid => {
            name => 'datepaid',
            value => $request->{datepaid} ? $request->{datepaid} : $Payment->{current_date}
        },
        source => \@sources_options,
        selected_source => $request->{source},
        source_value => $request->{source_value},
        defaultcurrency => {
            text => $default_currency
        },
                curr => {
                    name  => 'curr',
                    value => $request->{curr},
            },
        column_headers => \@column_headers,
        rows        =>  \@invoice_data,
        topay_subtotal => (sum map { $_->{topay} } @invoice_data) // 0,
        topay_state   => \@topay_state,
        vendorcustomer => {
            name => 'vendor-customer',
            value => $request->{'vendor-customer'}
        },
        unhandled_overpayment => {
            name => 'unhandledoverpayment',
            value => $unhandled_overpayment   }  ,
        vc => {
            name => $Payment->{company_name}, # We will assume that the first Billing Information as default
            address => [
                {text => $vc_options[0]->{'line_one'}},
                {text =>  $vc_options[0]->{'line_two'}},
                {text =>  $vc_options[0]->{'line_three'}},
                {text => $vc_options[0]->{city}},
                {text => $vc_options[0]->{state}},
                {text => $vc_options[0]->{country}},
                ]
        },
        format => {
           name => 'FORMAT',
           options => \@format_options
        },
        media => {
           name => 'MEDIA',
           options => \@media_options
        },
        exrate => $currency_options,
        notes => $request->{notes},
        overpayment         => \@overpayment,
        overpayment_account => \@overpayment_account,
        overpayment_subtotal => (sum map { $_->{amount} } @overpayment) // 0,
        payment_total => (sum map { $_->{amount} } @overpayment)
            + (sum map { $_->{topay} } @invoice_data),
    };

    $select->{selected_account} = $vc_options[0]->{cash_account_id}
        unless defined $select->{selected_account};
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'payments/payment2', $select);
}

=item post_payment

This method is used  for the payment module (not the bulk payment),
and its used for all the mechanics of storing a payment.

=cut

sub post_payment {
    my ($request) = @_;
    my $locale       = $request->{_locale};
    my $Payment = LedgerSMB::DBObject::Payment->new({'base' => $request});

    if (!$request->{exrate}) {
        $Payment->error($locale->text('Exchange rate hasn\'t been defined!'));}
    # LETS GET THE CUSTOMER/VENDOR INFORMATION
    ($Payment->{entity_credit_id}, $Payment->{company_name}) = split /--/ , $request->{'vendor-customer'};
    # LETS GET THE DEPARTMENT INFO

    if ($request->{department} and ( $request->{department} =~ /^(\d+)--*/ ) ) {
        $Payment->{department_id} = $1;
    } else {
        $Payment->{department_id} = undef;
    }

    #
    # We want to set a gl_description,
    # since we are using two tables there is no need to use doubled information,
    # we could specify this gl is the result of a payment movement...
    #
    $Payment->{gl_description} =
        $locale->text('This gl movement, is a consecuence of a payment transaction');
    #
    # Im not sure what this is for... gotta comment this later
    $Payment->{approved} = 'true';
    #
    # We have to setup a lot of things before we can process the payment
    # they are related to payment_post sql function, so if you have any doubts
    # look there.
    #-------------------------------------------------------------------------
    #
    # Variable definition
    #
    # We use the prefix op to refer to the overpayment variables.

    # This variable might be fuzzy, we are using it to handle invalid data
    my $unhandled_overpayment = 0;
    # i.e. a user set an overpayment qty inside an invoice.
    my @array_options;
    my @amount;
    my @discount;
    my @cash_account_id;
    my @memo;
    my @source;
    my @transaction_id;
    my @op_amount;
    my @op_cash_account_id;
    my @op_source;
    my @op_memo;
    my @op_account_id;
    #
    # We need the invoices in order to process the income data, this is
    # done this way since the data we have isn't indexed in any way.
    #
    # Ok, we want to use the disccount information in order to do some
    # accounting movements, we will process it with the same logic for
    # a regular payment, and see where does this leave us.
    #
    $Payment->{vc_name} = $Payment->{company_name};
    @array_options = $Payment->get_entity_credit_account();
    my $discount_account_id = $array_options[0]->{discount};
    @array_options = $Payment->get_open_invoices();
    for my $ref (0 .. $#array_options) {
        if ($request->{"checkbox_$array_options[$ref]->{invoice_id}"}
            && ($request->{"topay_fx_$array_options[$ref]->{invoice_id}"})) {
            # First i have to determine if discounts will apply
            # we will assume that a discount should apply only
            # if this is the last payment of an invoice
            my  $temporary_discount = 0;
            my  $request_topay_fx_bigfloat =
                LedgerSMB::PGNumber->from_input($request->{"topay_fx_$array_options[$ref]->{invoice_id}"});
            if (($request->{"optional_discount_$array_options[$ref]->{invoice_id}"})
                && ($array_options[$ref]->{due_fx}
                    <=  $request_topay_fx_bigfloat
                        +  $array_options[$ref]->{discount_fx})) {
                $temporary_discount = $array_options[$ref]->{discount_fx};
            }
            #
            # The prefix cash is to set the movements of the cash accounts,
            # same names are used for ap/ar accounts w/o the cash prefix.
            #
            my $sign = "$array_options[$ref]->{due_fx}" <=> 0;
            if ( $sign * LedgerSMB::PGNumber->from_input($array_options[$ref]->{due_fx})->bround($LedgerSMB::Company_Config::decimal_places)
                 <
                 $sign * LedgerSMB::PGNumber->from_input($request_topay_fx_bigfloat)->bround($LedgerSMB::Company_Config::decimal_places)
                ){
                # We need to store all the overpayments
                # so we can use it on a new payment2 screen
                $unhandled_overpayment += $request_topay_fx_bigfloat
                    + $temporary_discount - $array_options[$ref]->{amount} ;

            }
            if ($temporary_discount != 0) {
                push @amount, $temporary_discount;
                push @cash_account_id, $discount_account_id;
                push @source, $locale->text('Applied discount');
                push @transaction_id, $array_options[$ref]->{invoice_id};
            }

             # We'll use this for both cash and ap/ar accounts
            push @amount,   $request_topay_fx_bigfloat;
            push @cash_account_id,
               $request->{"optional_pay_$array_options[$ref]->{invoice_id}"}
               ? $request->{"account_$array_options[$ref]->{invoice_id}"}
               : $request->{account};

            # We'll use this for both source and ap/ar accounts
            push @source, $request->{"optional_pay_$array_options[$ref]"}
              ? $request->{"source_$array_options[$ref]->{invoice_id}"} .' ' . $request->{"source_text_$array_options[$ref]->{invoice_id}"}
              : $request->{source}.' '.$request->{source_value};
            push @memo,
                $request->{"memo_invoice_$array_options[$ref]->{invoice_id}"};
            push @transaction_id, $array_options[$ref]->{invoice_id};
        }
    }
    # Check if there is an unhandled overpayment and run payment2 as needed
    if ($unhandled_overpayment) {
        $request->{payment_id} = 0;
        return payment2($request);
    }
    #
    # Now we need the overpayment information.
    #
    # We will use the prefix op to indicate it is an overpayment information.
    #
    # note: I love the for's C-like syntax.
    for (my $i=1 ; $i <= $request->{overpayment_qty}; $i++) {
        if (!$request->{"overpayment_checkbox_$i"}) {
            # Is overpayment marked as deleted ?
            if ( $request->{"overpayment_topay_$i"} ) {
                # Is this overpayment an used field?
                # Now we split the account selected options, using the
                # namespace the if statement provides for us.
                $request->{"overpayment_topay_$i"} =
                    LedgerSMB::PGNumber->from_input($request->{"overpayment_topay_$i"});

                my $id;
                if ( $request->{"overpayment_account_$i"} =~ /^(\d+)--*/) {
                    $id = $1;
                }
                my $cashid;
                if ( $request->{"overpayment_cash_account_$i"} =~ /^(\d+)--*/) {
                    $cashid = $1;
                }
                push @op_amount, $request->{"overpayment_topay_$i"};
                push @op_cash_account_id, $cashid;
                push @op_source, $request->{"overpayment_source1_$i"}
                   . ' ' .$request->{"overpayment_source2_$i"};
                push @op_memo, $request->{"overpayment_memo_$i"};
                if (not $id and $id ne '0'){
                    $request->error($request->{_locale}->text('No overpayment account selected.  Was one set up?'));
                }
                push @op_account_id, $id;
            }
        }
    }
    # Finally we store all the data inside the LedgerSMB::DBObject::Payment object.
    $Payment->{cash_account_id}    = \@cash_account_id;
    $Payment->{amount}             = \@amount;
    $Payment->{source}             = \@source;
    $Payment->{memo}               = \@memo;
    $Payment->{transaction_id}     = \@transaction_id;
    $Payment->{op_amount}          = \@op_amount;
    $Payment->{op_cash_account_id} = \@op_cash_account_id;
    $Payment->{op_source}          = \@op_source;
    $Payment->{op_memo}            = \@op_memo;
    $Payment->{op_account_id}      = \@op_account_id;
    # Ok, passing the control to postgresql and hoping for the best...

    $Payment->post_payment();
    if ($request->{continue_to_calling_sub}) {
        $request->{payment_id} = $Payment->{payment_id};
        return;
    }
    else {
        # Our work here is done, ask for more payments.
        return payment($request);
    }
}

=item print_payment

This sub will print the payment on the selected media, it needs to
receive the $Payment object with all this information.

=cut

sub print_payment {
    my ($request, $Payment) = @_;
    my $locale    = $Payment->{_locale};
    $Payment->gather_printable_info();
    my $header = @{$Payment->{header_info}}[0];
    my @rows   = @{$Payment->{line_info}};
    ###############################################################################
    #                 FIRST CODE SECTION
    #
    # THE FOLLOWING LINES OF CODE ADD SOME EXTRA PROCESSING TO THE DATA THAT
    # WILL BE  AVAILIBLE ON THE UI,
    # PLEASE FEEL FREE TO ADD EXTRA LINES IF YOU NEED IT (AND KNOW WHAT YOU ARE DOING).
    ###############################################################################
    # First we need to solve some ugly behaviour in the template system
    $header->{amount} = abs("$header->{amount}");
    # The next code will enable number to text conversion
    $Payment->init();
    $header->{amount2text} = $Payment->num2text($header->{amount});
    ############################################################################
    # IF YOU NEED MORE INFORMATION ON THE HEADER AND ROWS ITEMS CHECK SQL FUNCTIONS
    # payment_gather_header_info AND payment_gather_line_info
    for my $row (@rows) {
        $row->{amount} = $row->{amount}->to_output(money => 1);
    }
    my $select = {
        header        => $header,
        rows          => \@rows,
        format_amount => sub {LedgerSMB::PGNumber->from_input(@_)->to_output()}
  };
  $Payment->{templates_path} = 'templates/'.$request->setting->get('templates').'/';
  my $template = LedgerSMB::Template->new( # printed document
      user     => $Payment->{_user},
      locale   => $Payment->{_locale},
      path     => $Payment->{templates_path},
      template => 'printPayment',
      format => 'HTML' );
  return $template->render($select); ###TODO: psgi-render-to-attachment
}

=item post_and_print_payment

This is simply a shortcut between post_payment and print_payment methods, please refer
to these functions

=cut

sub post_and_print_payment {
    my ($request) = @_;
    $request->{continue_to_calling_sub} = 1;
    $request->{payment_id} = &post_payment($request);
    my $locale       = $request->{_locale};
    my $Payment = LedgerSMB::DBObject::Payment->new({'base' => $request});
    return print_payment($request, $Payment);
}

=item use_overpayment

This item will do the trick to use the overpayment information stored
inside the payments, it should be powerful enough to link overpayment
from one customer to other customers.

=cut

sub use_overpayment {
    my ($request) = @_;
    my $locale    = $request->{_locale};
    my $Payment   = LedgerSMB::DBObject::Payment->new({'base' => $request});
    my @arrayOptions;
    my @entities;

    #We will use $ui to handle all the data needed by the User Interface
    my $ui = {
        script => 'payment.pl',
        stylesheet => $request->{_user}->{stylesheet}
    };
    $ui->{account_class} = {
        name => 'account_class',
        value => $request->{account_class}
    };

    #We want to get all the customer/vendor with unused overpayment
    my @data = $Payment->get_open_overpayment_entities();
    for my $ref (0 .. $#data) {
        push @entities, { value => $data[$ref]->{id},
                          name =>  $data[$ref]->{name}};
    }

    my @currOptions;
    @arrayOptions = $request->setting->get_currencies();

    for my $ref (0 .. $#arrayOptions) {
        push @currOptions, { value => $arrayOptions[$ref],
                             text => $arrayOptions[$ref]};
    }


    $ui->{curr} = \@currOptions;
    $ui->{entities} =  \@entities;
    $ui->{action}   =  {
        name => 'action',
        value => 'use_overpayment2',
        text => $locale->text('Continue')
    };
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'payments/use_overpayment1', $ui);
}


=item use_overpayment2

This sub runs to allow the user to specify the invoices in which an
overpayment should be used

=cut


sub use_overpayment2 {
    my ($request) = @_;
    my $locale    = $request->{_locale};
    my $Payment   = LedgerSMB::DBObject::Payment->new({'base' => $request});
    my $Selected_entity;
    my @vc_info;
    my @vc_list;
    my @overpayments;
    my @ui_overpayments;
    my @avble_invoices;
    my @ui_avble_invoices;
    my @ui_selected_inv;
    my $exchangerate;
    my $ui_exchangerate;
    my @selected_checkboxes;
    my %seen_invoices;
    my $ui_to_use_subtotal = 0;
    my $ui_avble_subtotal = 0;
    my @hiddens;
    my $vc_entity_info;
    my $default_currency;
    my %amount_to_be_used;
    my %ovp_repeated_invoices;
    my %invoice_id_amount_to_pay;
    my $count;
    my $warning = $Payment->{'warning'};

    # First we need to insert some hidden information

    push @hiddens, { id => 'entity_credit_id',
                     name =>  'entity_credit_id',
                     type => 'hidden',
                     value => $request->{entity_credit_id}};
    push @hiddens, { id  => 'account_class',
                     name => 'account_class',
                     type => 'hidden',
                     value =>  $request->{account_class} };
    push @hiddens, { id  => 'login',
                     name => 'login',
                     type => 'hidden',
                     value => $request->{login}   };
    push @hiddens, { id  => 'curr',
                     name => 'curr',
                     type => 'hidden',
                     value => $request->{curr}   };

    #lets search the entity default currency
    $default_currency = $Payment->get_default_currency();


    # WE NEED TO KNOW IF WE ARE USING A CURRENCY THAT NEEDS AN EXCHANGERATE
    if ($default_currency ne $request->{curr} ) {
        # DOES THE CURRENCY IN USE HAS AN EXCHANGE RATE?, IF SO
        # WE MUST SET THE VALUE, OTHERWISE THE UI WILL HANDLE IT
        $exchangerate = $Payment->{exrate} ?
            $Payment->{exrate} :
            $Payment->get_exchange_rate($request->{curr},
                                        $Payment->{datepaid} ? $Payment->{datepaid} : $Payment->{current_date});
        if ($exchangerate) {
            $ui_exchangerate = {
                id => 'exrate',
                name => 'exrate',
                value => "$exchangerate", #THERE IS A STRANGE BEHAVIOUR WITH THIS,
                text =>  "$exchangerate"  #IF I DONT USE THE DOUBLE QUOTES, IT WILL PRINT THE ADDRESS
                    #THERE MUST BE A REASON FOR THIS, I MUST RETURN TO IT LATER
            };
        } else {
            $ui_exchangerate = {
                id => 'exrate',
                name => 'exrate'};
        }

    } else {
        # WE MUST SET EXCHANGERATE TO 1 FOR THE MATHS SINCE WE
        # ARE USING THE DEFAULT CURRENCY
        $exchangerate = 1;
        $ui_exchangerate = {
            id => 'exrate',
            name => 'exrate',
            value => 1,
            text =>  1
        };
    }

    #get the owner of the overpayment info
    $vc_entity_info = $Payment->get_vc_info();



    #list all the vendor/customer
    @vc_info = $Payment->get_entity_credit_account();
    for my $ref (0 .. $#vc_info) {
        my ($name) = split(/:/, $vc_info[$ref]->{name});
        push @vc_list, { value            => $vc_info[$ref]->{id},
                         name            => $name,
                         vc_discount_accno => $vc_info[$ref]->{discount}};
    }


    $count=1;
    #lets see which invoice do we have printed
    while ($Payment->{"entity_id_$count"})
    {
        if ($Payment->{"checkbox_$count"})
        {
            $count++;
            next;
        }

        if ($ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{qq|$Payment->{"selected_accno_$count"}|}
            != $Payment->{"selected_accno_$count"}) {

            # the "ovp_repeated_invoices" hash will store the conbination
            # of invoice id and overpayment account, if this convination has
            # already printed do not print it again
            $ovp_repeated_invoices{$Payment->{"invoice_id_$count"}}->{$Payment->{"selected_accno_$count"}} =
                $Payment->{"selected_accno_$count"};

            # the "repeated invoice" flag will check if this invoice has
            # already been printed, if it does, do not print the apply
            # discount checkbox in the UI

            my $ovp_inv_payment =
                $ovp_repeated_invoices{$Payment->{"invoice_id_$count"}};
            if (! $ovp_inv_payment->{repeated_invoice}){
                $ovp_inv_payment->{optional_discount} =
                    $Payment->{"optional_discount_$count"};
                $ovp_inv_payment->{repeated_invoice} = 'false';
            } else{
                $ovp_inv_payment->{repeated_invoice} = 'true';
            }

            $ui_to_use_subtotal += $Payment->{"amount_$count"};

            my ($id,$name) = split(/--/, $Payment->{"entity_id_$count"});
            my ($ovp_chart_id, $ovp_selected_accno) =
                split(/--/, $Payment->{"selected_accno_$count"});
            my $applied_due =
                ($ovp_inv_payment->{optional_discount})
                ? $Payment->{"due_$count"}
                : $Payment->{"due_$count"} + $Payment->{"discount_$count"};

            $amount_to_be_used{"$ovp_selected_accno"} +=
                $Payment->{"amount_$count"};
            # this hash will keep track of the amount to be paid of an
            # specific invoice_id, this amount could not be more than the
            # due of that invoice.
            $invoice_id_amount_to_pay{qq|$Payment->{"invoice_id_$count"}|} +=
                $Payment->{"amount_$count"};
            if($invoice_id_amount_to_pay{qq|$Payment->{"invoice_id_$count"}|}
               > $applied_due) {
                $warning .= $locale->text('The amount of the invoice number').qq| $Payment->{"invnumber_$count"} |.$locale->text('is lesser than the amount to be paid').qq|\n|;
            }
            ###################################################################
            #    ojo no me gusta como esta implementado
            ###################################################################
            if($Payment->{"amount_$count"} < 0){
                $warning .= $locale->text('The amount of the invoice number').qq| $Payment->{"invnumber_$count"} |.$locale->text('is lesser than 0').qq|\n|;
            }
            #lets make the href for the invoice
            my $uri = $Payment->{account_class} == 1 ? 'ap' : 'ar';
            $uri .= '.pl?action=edit&id='
                . $Payment->{"invoice_id_$count"} . '&login='
                . $request->{login};

            push @ui_selected_inv,
            {
                invoice           => {
                    number => $Payment->{"invnumber_$count"},
                    id     => $Payment->{"invoice_id_$count"},
                    href   => $uri },
                entity_name       => $name,
                entity_id         => $Payment->{"entity_id_$count"},
                vc_discount_accno => $Payment->{"vc_discount_accno_$count"},
                invoice_date      => $Payment->{"invoice_date_$count"},
                applied_due       => $applied_due,
                optional_discount => $ovp_inv_payment->{optional_discount},
                repeated_invoice  => $ovp_inv_payment->{repeated_invoice},
                due               => $Payment->{"due_$count"},
                discount          => $Payment->{"discount_$count"},
                selected_accno    => {
                    id        => $ovp_chart_id,
                    ovp_accno => $ovp_selected_accno },
                amount            => $Payment->{"amount_$count"}} unless ($seen_invoices{$Payment->{"invoice_id_$count"}}++);
        }
        $count++;
    }


    #lets search which available invoice do we have for the selected entity
    if (($Payment->{new_entity_id} != $Payment->{entity_credit_id})
        && ! $Payment->{new_checkbox})
    {
        $request->{entity_credit_id} = $Payment->{new_entity_id};
        # lets create an object who has the entity_credit_id of the
        # selected entity
        $Selected_entity =
            LedgerSMB::DBObject::Payment->new({'base' => $Payment});
        $Selected_entity->{invnumber} = $Selected_entity->{new_invoice} ;

        my ($id,$name,$vc_discount_accno) =
            split(/--/, $Selected_entity->{new_entity_id});
        my ($ovp_chart_id, $ovp_selected_accno) =
            split(/--/, $Selected_entity->{new_accno});

        $Selected_entity->{entity_credit_id} = $id;

        @avble_invoices = $Selected_entity->get_open_invoice();
        for my $ref (0 .. $#avble_invoices) {

            # this hash will store the convination of invoice id and
            # overpayment account, if this convination has already printed
            # do not print it again
            if ($ovp_repeated_invoices{$avble_invoices[$ref]->{invoice_id}}->{$Selected_entity->{new_accno}}
                != $Selected_entity->{new_accno}){
                $ovp_repeated_invoices{$avble_invoices[$ref]->{invoice_id}}->{$Selected_entity->{new_accno}} =
                    $Selected_entity->{new_accno};

                # the "repeated invoice" flag will check if this invoice has
                # already been printed, if it does, do not print the apply
                # discount checkbox in the UI
                if (!$ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{repeated_invoice}){
                    $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{repeated_invoice} = 'false';
                } else{
                    $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{repeated_invoice} = 'true';
                }


                if (!$ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{optional_discount}){
                    $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{optional_discount} = 'true';
                }

                $invoice_id_amount_to_pay{qq|$avble_invoices[$ref]->{invoice_id}|} +=
                    $Selected_entity->{new_amount};
                $ui_to_use_subtotal += $Selected_entity->{new_amount};
                $amount_to_be_used{$ovp_selected_accno} +=
                    $Selected_entity->{new_amount};

                #lets make the href for the invoice
                my $uri = $Payment->{account_class} == 1 ? 'ap' : 'ar';
                $uri .= '.pl?action=edit&id='
                    . $avble_invoices[$ref]->{invoice_id}
                    . '&login=' . $request->{login};

                push @ui_avble_invoices, {
                    invoice       => {
                        number => $avble_invoices[$ref]->{invnumber},
                        id     => $avble_invoices[$ref]->{invoice_id},
                        href   => $uri },
                    entity_name       => $name,
                    vc_discount_accno => $vc_discount_accno,
                    entity_id        => qq|$Selected_entity->{entity_credit_id}--$name|,
                    invoice_date        => $avble_invoices[$ref]->{invoice_date},
                    applied_due       => $Payment->{"due_$count"},
                    repeated_invoice  => $ovp_repeated_invoices{$avble_invoices[$ref]->{invoice_id}}->{repeated_invoice},
                    due            => $avble_invoices[$ref]->{due},
                    discount          => $avble_invoices[$ref]->{discount},
                    selected_accno    => {
                        id       => $ovp_chart_id,
                        ovp_accno => $ovp_selected_accno },
                    amount        => $Selected_entity->{new_amount}} unless ($seen_invoices{$avble_invoices[$ref]->{invoice_id}}++)
            }
        }
    }


    # we need to get all the available overpayments
    @overpayments = $Payment->get_available_overpayment_amount();

    for my $ref (0 .. $#overpayments) {
        my $overpay = $overpayments[$ref];
        push @ui_overpayments, {
            id          =>  $overpay->{chart_id},
            accno       =>  $overpay->{accno},
            description =>  $overpay->{description},
            amount      =>  $overpay->{movements},
            available   =>  $overpay->{available},
            touse       =>  $amount_to_be_used{$overpay->{accno}},
        };
        $ui_avble_subtotal += $overpay->{available};
    }


    # We start with our data selection called ui

    my $ui = {
        script        => 'payment.pl',
        exrate        => $ui_exchangerate,
        datepaid        => {name           => 'datepaid',
                            value    => $Payment->{datepaid}? $Payment->{datepaid} : $Payment->{current_date},
                            size    => '10'},
        notes        => $Payment->{notes},
        vc_entity_info    => $vc_entity_info,
        curr                => $request->{curr},
        default_curr         => $default_currency,
        dont_search_inv    => $Payment->{new_checkbox},
        vc_list            => \@vc_list,
        entity_credit_id     => $Payment->{entity_credit_id},
        selected_inv        => \@ui_selected_inv,
        avble_invoices       => \@ui_avble_invoices,
        account_class        => $request->{account_class},
        overpayments         => \@ui_overpayments,
        to_use_subtotal       => $ui_to_use_subtotal,
        avble_subtotal    => $ui_avble_subtotal,
        stylesheet       => $request->{_user}->{stylesheet},
        warning        => $warning,
        header          => { text => $locale->text('Use overpayment/prepayment')},
    };

    # Lastly we include the hiddens on the UI

    $ui->{hiddens} = \@hiddens;

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'payments/use_overpayment2', $ui);
}

=item post_overpayment

This method reorganize the selected invoices by customer/vendor and adapt
them to make them fit with the post_payment sql method, calling it once
by customer/vendor id

=cut


sub post_overpayment {
    my ($request) = @_;
    my $locale    = $request->{_locale};
    my %entity_list;
    my %invoice_id_amount_to_pay;
    my @amount;
    my @discount;
    my @cash_account_id;
    my @memo;
    my @source;
    my @transaction_id;
    # this variables will store all the unused overpayment which will
    # be used to pay the invoices
    my %entity_unused_ovp;
    my $unused_ovp_index;

    #let's store all unused invoice in entity_unused_ovp, it will be

    #lets see which invoice do we have, and reorganize them by vendor/customer
    my $count=1;
    while ($request->{"entity_id_$count"})
    {

        if ($request->{"checkbox_$count"})
        {
            $count++;
            next;
        }

        my ($entity_id, $entity_name) =
            split(/--/, $request->{"entity_id_$count"});
        my ($ovp_chart_id, $ovp_selected_accno) =
            split(/--/, $request->{"selected_accno_$count"});

        # Let's see which will the amount of the invoice due that will
        # be paid from an overpayment
        my $applied_due =
            ($request->{"optional_discount_$count"}
             && $request->{"amount_$count"} == $request->{"due_$count"})
            ? $request->{"due_$count"}
            : $request->{"due_$count"} + $request->{"discount_$count"};

        # let's check if the overpayment movements of the $ovp_chart_id accno
        # has already been searched, if not, search and store it to later use
        if(!$entity_unused_ovp{"$ovp_chart_id"})
        {
            $entity_unused_ovp{"$ovp_chart_id"} =
                LedgerSMB::DBObject::Payment->new({'base' => $request});
            $entity_unused_ovp{$ovp_chart_id}->{chart_id} = $ovp_chart_id;
            # this call will store the unused overpayments in
            # $entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}
            # just check the .pm
            $entity_unused_ovp{"$ovp_chart_id"}->get_unused_overpayments();
            # this counter will keep track of the ovp that had been used to
            # pay the invoices
            $entity_unused_ovp{$ovp_chart_id}->{unused_ovp_index} = 0;
        }
        $unused_ovp_index =
            $entity_unused_ovp{$ovp_chart_id}->{unused_ovp_index};

        ###############################################################
        #        Warnings Section
        ###############################################################
        # In this section, the post_overpayment will check some user inputs
        # and verify if those are apted to call the post method, if not just
        # store a warning message in the
        # $request->{warning} variable and then call the use_overpayment2
        # method and it will manage it

        # the $invoice_id_amount_to_pay hash will keep track of the amount to
        # be paid of an specific invoice_id, this amount could not be more than
        # the due of that invoice
        $invoice_id_amount_to_pay{$request->{"invoice_id_$count"}} +=
            $request->{"amount_$count"};
        if($invoice_id_amount_to_pay{$request->{"invoice_id_$count"}}
           > $applied_due){
            $request->{warning} .= "Warning\n";
        }

        #The amount to be paid shouldn't be negative
        if ($request->{"amount_$count"} < 0){
            $request->{warning} .= "Warning\n";
        }

        #Is the amount to be paid null?, tell the user and he/she will be able to manage it
        if ($request->{"amount_$count"} == 0 )
        {
            $request->{warning} .= $locale->text('The amount to be pay of the invoice number').qq| $request->{"invnumber_$count"} |.$locale->text('is null').qq|\n|;
        }

        #if the amount to be paid is bigger than the amount of the invoice, just call the update method and it will manage it
        if($request->{warning}){
            return use_overpayment2($request);
        }


        if (! $entity_list{$entity_id}) {
            $entity_list{$entity_id} =
                LedgerSMB::DBObject::Payment->new({base => $request});
            my $list_key = $entity_list{$entity_id};
            $list_key->{entity_credit_id} = $entity_id;
            $list_key->{gl_description} =
                $locale->text('This gl movement, is the result of a overpayment transaction');

            # Im not sure what this is for... gotta comment this later
            $list_key->{approved} = 'true';
        }


        my $list_key = $entity_list{$entity_id};

        #Let's fill all our entity invoice info, if it has a discount, store it into the discount accno
        if ($list_key->{"optional_discount_$count"} && $list_key->{"amount_$count"} == $list_key->{"due_$count"}) {
            push @{$list_key->{array_amount}}, $list_key->{"discount_$count"};
            push @{$list_key->{array_cash_account_id}}, $list_key->{"vc_discount_accno_$count"};
            push @{$list_key->{array_source}}, $locale->text('Applied discount by an overpayment');
            push @{$list_key->{array_transaction_id}}, $list_key->{"invoice_id_$count"};
            push @{$list_key->{array_memo}}, undef;
            push @{$list_key->{ovp_payment_id}}, undef;
        }

        #this is the amount of the present invoice that will be paid from the $ovp_chart_id accno
        my $tmp_ovp_amount = $list_key->{"amount_$count"};

        #let's store the AR/AP movement vs the overpayment accno, and keep track of all the ovp_id that will be use
        while($tmp_ovp_amount > 0)
        {
            #Send a warning if there are no more available amount in the $ovp_chart_id accno
            if (@{$entity_unused_ovp{$ovp_chart_id}->{unused_overpayment}}[$unused_ovp_index]->{available} eq '')
            {
                $request->{warning} .= $locale->text('The amount to be pay from the accno').qq| $ovp_chart_id |.$locale->text('is bigger than the amount available').qq|\n|;
                $tmp_ovp_amount = -1;
                next;
            }
            if (@{$entity_unused_ovp{$ovp_chart_id}->{unused_overpayment}}[$unused_ovp_index]->{available} >= $tmp_ovp_amount)
            {
                push @{$list_key->{array_amount}}, $tmp_ovp_amount;
                push @{$list_key->{array_cash_account_id}}, $ovp_chart_id;
                push @{$list_key->{array_source}},
                       $locale->text('use of an overpayment');
                push @{$list_key->{array_transaction_id}},
                       $list_key->{"invoice_id_$count"};
                push @{$list_key->{array_memo}}, undef;
                push @{$list_key->{ovp_payment_id}},
                       @{$entity_unused_ovp{$ovp_chart_id}->{unused_overpayment}}[$unused_ovp_index]->{payment_id};

                $tmp_ovp_amount = 0;
                #lets see if there is more amount on the present overpayment movement
                my $tmp_residual_ovp_amount = @{$entity_unused_ovp{$ovp_chart_id}->{unused_overpayment}}[$unused_ovp_index]->{available} - $tmp_ovp_amount;
                if ($tmp_residual_ovp_amount == 0)
                {
                    $entity_unused_ovp{$ovp_chart_id}->{unused_ovp_index}++;
                }
            } else{
                $tmp_ovp_amount -= @{$entity_unused_ovp{$ovp_chart_id}->{unused_overpayment}}[$unused_ovp_index]->{available};

                push @{$list_key->{array_amount}}, @{$entity_unused_ovp{$ovp_chart_id}->{unused_overpayment}}[$unused_ovp_index]->{available};
                push @{$list_key->{array_cash_account_id}}, $ovp_chart_id;
                push @{$list_key->{array_source}}, $locale->text('use of an overpayment');
                push @{$list_key->{array_transaction_id}}, $list_key->{"invoice_id_$count"};
                push @{$list_key->{array_memo}}, undef;
                push @{$list_key->{ovp_payment_id}}, @{$entity_unused_ovp{$ovp_chart_id}->{unused_overpayment}}[$unused_ovp_index]->{payment_id};

                $unused_ovp_index = $entity_unused_ovp{$ovp_chart_id}->{unused_ovp_index}++;
            }
        }

        $count++;
    }



    # Now we have all our movements organized by vendor/customer, it is time to call the post_payment sql method by each one of them
    for my $key (keys %entity_list)
    {
        my $list_key = $entity_list{$key};
        for my $field (qw(amount cash_account_id source memo transaction_id
                          ovp_payment_id)) {
            $list_key->{$key} =
                $list_key->{"array_$field"};
        }

        $entity_list{$key}->post_payment();
    }

    return use_overpayment($request);

}

=back

=cut

{
    local ($!, $@) = (undef, undef);
    my $do_ = 'scripts/custom/payment.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error(payment.pm)\n\n" );
            }
        }
    }
};

1;
