=head1 NAME

LedgerSMB::Scripts::payment - LedgerSMB class defining the Controller functions for payment handling.

=head1 SYNOPSIS

Defines the controller functions and workflow logic for payment processing.

=head1 COPYRIGHT

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


package LedgerSMB::Scripts::payment;
use LedgerSMB::Template;
use LedgerSMB::Setting;
use LedgerSMB::Sysconfig;
use LedgerSMB::DBObject::Payment;
use LedgerSMB::DBObject::Date;
use LedgerSMB::PGNumber;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Report::Invoices::Payments;
use strict;
use warnings;

# CT:  A few notes for future refactoring of this code:
# 1:  I don't think it is a good idea to make the UI too dependant on internal
#     code structures but I don't see a good alternative at the moment.
# 2:  CamelCasing: -1
# 3:  Not good to have this much duplication of code all the way down the stack.#     At the moment this is helpful because it gives us an opportunity to look
#     at various sets of requirements and workflows, but for future versions
#     if we don't refactor, this will turn into a bug factory.
# 4:  Both current interfaces have issues regarding separating layers of logic
#     and concern properly.

# CT:  Plans are to completely rewrite all payment logic for 1.4 anyway.

=over

=item payments

This method is used to set the filter screen and prints it, using the
TT2 system.

=cut

sub payments {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->get_metadata();
    if (!defined $payment->{batch_date}){
        $payment->error("No Batch Date!");
    }
    my @curr = LedgerSMB::Setting->new()->get_currencies;
    $payment->{default_currency} = $curr[0];
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payments',
        template => 'payments_filter',
        format   => 'HTML',
    );

    $template->render({ request => $request,
                        payment => $payment });
}

=item get_search_criteria

Displays the payment criteria screen.  Optional inputs are

=over

=item batch_id

=item batch_date

=back

=cut

sub get_search_criteria {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->get_metadata();
    if ($payment->{batch_id} && $payment->{batch_date}){
        $payment->{date_reversed} = $payment->{batch_date};
    }
    @{$payment->{currencies}} = $payment->get_open_currencies();
    $payment->{report_name} = 'payments';
    LedgerSMB::Scripts::reports::start_report($payment);
}

=item pre_bulk_post_report

This displays a report of the expected GL activity of a payment batch before it
is saved.  For receipts, this just redirects to bulk_post currently.

=cut

sub pre_bulk_post_report {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => ($request->{report_format}) ? $request->{report_format} : 'HTML',
    );
    my $cols;
    @$cols =  qw(pay_to accno source memo debits credits);
    my $rows = [];
    my $total_debits = 0;
    my $total_credits = 0;
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
    my $total = 0;
    for my $crow (1 .. $request->{contact_count}){
        my $ref;
        my $cid = $request->{"contact_$crow"};
        if ($request->{"id_$cid"}){
            $ref = {pay_to    => $request->{"contact_label_$cid"},
                    accno     => $request->{ar_ap_accno},
                    transdate => $request->{date_paid},
                    source    => $request->{"source_$cid"},
                    memo      => $request->{"memo_$cid"},
                    amount    => 0
                   };
            for my $invrow (1 .. $request->{"invoice_count_$cid"}){
                 my $inv_id = $request->{"invoice_${cid}_$invrow"};
                 $ref->{amount} += $request->{"payment_$inv_id"};
             }
             # If vendor, this is debit-normal so multiply by -1
             if ($request->{account_class} == 1){ # vendor
                 $ref->{amount} *= -1;
              }
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
              $total += $ref->{amount};
        }
    }


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
    $request->{action} = "p";
    $template->render({
        form => $request,
        hiddens => $request,
        columns => $cols,
        heading => $heading,
        rows    => $rows,
        buttons => $buttons,
    });
}

# Is this even used?  It would just redirect back to the report which is not
# helpful.  --CT

sub p_payments_bulk_post {
    my ($request) = @_;
    pre_bulk_post_report(@_);
}

# wrapper around post_payments_bulk munged for dynatable.

sub p_post_payments_bulk {
    post_payments_bulk(@_);
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
    };
    $report->render($request);
}

=item reverse_payments

This reverses payments selected in the search results.

=cut

sub reverse_payments {
    my ($request) = @_;
    $request->dates('date_reversed');
    $request->dates_series(0, $request->{rowcount_}, 'date_paid');
    $request->{account_class} = 1;
    my $payment = LedgerSMB::DBObject::Payment->new({base => $request});
    for my $count (1 .. $payment->{rowcount_}){
        if ($payment->{"select_$count"}){
           $payment->{account_class} = $payment->{"entity_class_$count"};
           $payment->{credit_id} = $payment->{"credit_id_$count"};
           $payment->{date_paid} = $payment->{"date_paid_$count"};
           $payment->{source} = $payment->{"source_$count"};
           $payment->{voucher_id} = $payment->{"voucher_id_$count"};
           $payment->reverse;
        }
    }
    get_search_criteria($payment);
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
        $payment->post_bulk();
    } else {
        $payment->{notice} =
           $payment->{_locale}->text('Data not saved.  Please try again.');
        return display_payments($request);
    }

    payments($request);
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

    $payment->{format_amount} = sub {return PGObject::PGNumber->from_input(@_)->to_output(); };

    if ($payment->{multiple}){
        $payment->{checks} = [];
        for my $line (1 .. $payment->{contact_count}){
            my $id = $payment->{"contact_$line"};
            next if !defined $payment->{"id_$id"};
            my ($check) = $payment->call_procedure(
                     funcname => 'company_get_billing_info', args => [$id]
            );
            $check->{entity_class} = $payment->{account_class};
            $check->{id} = $id;
            $check->{amount} = LedgerSMB::PGNumber->from_db('0');
            $check->{invoices} = [];
            $check->{source} = $payment->{"source_$id"};

            my $inv_count;
            my $check_max_invoices = LedgerSMB::Setting->get(
                         'check_max_invoices'
            );
            if ($check_max_invoices > $payment->{"invoice_count_$id"}) {
                $inv_count = $payment->{"invoice_count_$id"};
            } else {
                $inv_count = $check_max_invoices;
            }

            for my $inv (1 .. $payment->{"invoice_count_$id"}){
                my $invhash = {};
                my $inv_id = $payment->{"invoice_${id}_$inv"};
                for (qw(invnumber due invoice_date)){
                    $invhash->{$_} = $payment->{"${_}_${inv_id}"};
                }
                if ($payment->{"paid_$id"} eq 'some'){
                    $invhash->{paid} = LedgerSMB::PGNumber->from_input($payment->{"payment_${inv_id}"});
                } elsif ($payment->{"paid_$id"} eq 'all'){
                    $invhash->{paid} = LedgerSMB::PGNumber->from_input($payment->{"net_${inv_id}"});
                } else {
                    $payment->error("Invalid Payment Amount Option");
                }
                $check->{amount} += $invhash->{paid};
                push @{$check->{invoices}}, $invhash if $inv <= $inv_count;
            }
            my $amt = $check->{amount}->copy;
            $amt->bfloor();
            $check->{text_amount} = $payment->text_amount($amt);
            $check->{decimal} = ($check->{amount} - $amt) * 100;
            $check->{amount} = $check->{amount}->to_output(format => '1000.00');
            push @{$payment->{checks}}, $check;
        }
        $template = LedgerSMB::Template->new(
            user => $payment->{_user}, template => 'check_multiple',
            format => uc $payment->{'format'},
        no_auto_output => 1,
            output_args => $payment,
        );
            $template->render($payment);
            $template->output(%$payment);
        $request->{action} = 'update_payments';
        display_payments(@_);

    } else {

    }

}

=item update_payments

Displays the bulk payment screen with current data

=cut

sub update_payments {
    display_payments(@_);
}

=item display_payments

This displays the bulk payment screen with current data.

=cut

sub display_payments {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->{default_currency} =  $payment->get_default_currency();;
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
    for (@{$payment->{contact_invoices}}){
        my $contact_total = 0;
        my $contact_to_pay = 0;
        for my $invoice (@{$_->{invoices}}){
            if (($payment->{action} ne 'update_payments')
                  or (defined $payment->{"id_$_->{contact_id}"})){
                   $payment->{"paid_$_->{contact_id}"} = "" unless defined $payment->{"paid_$_->{contact_id}"};
            }
            $invoice->[6] = $invoice->[3] - $invoice->[4] - $invoice->[5];
            $contact_total +=  $invoice->[6];
            $contact_to_pay += $invoice->[3];
            $invoice->[3] = $invoice->[3]->to_output(money  => 1);
            $invoice->[4] = $invoice->[4]->to_output(money  => 1);
            $invoice->[5] = $invoice->[5]->to_output(money  => 1);
            $invoice->[6] = $invoice->[6]->to_output(money  => 1);
            my $fld = "payment_" . $invoice->[0];

            if ('display_payments' eq $request->{action} ){
                $payment->{"$fld"} = $invoice->[6];
            }
        }
        if ($payment->{"paid_$_->{contact_id}"} ne 'some') {
                  $contact_total = $contact_to_pay;
        }
        if (($payment->{action} ne 'update_payments')
                  or (defined $payment->{"id_$_->{contact_id}"})){
            $_->{contact_total} = $contact_total;
            $_->{to_pay} = $contact_to_pay;
            $payment->{grand_total} += $contact_total;

            my ($check_all) = LedgerSMB::Setting->get('check_payments');
            if ($payment->{account_class} == 1 and $check_all){
                 $payment->{"id_$_->{contact_id}"} = $_->{contact_id};
            }

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

    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payments',
        template => 'payments_detail',
        format   => 'HTML',
    );
    $template->render({ request => $request,
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
 my $Settings = LedgerSMB::Setting->new({'base' => $request});

# Lets get the currencies (this uses the $dbPayment->{account_class} property)
 my @currOptions;
 my @arrayOptions;
 @arrayOptions = $Settings->get_currencies();

 for my $ref (0 .. $#arrayOptions) {
     push @currOptions, { value => $arrayOptions[$ref],
                           text => $arrayOptions[$ref]};

 }
# Lets build filter by period
my $date = LedgerSMB::DBObject::Date->new({base => $request});
   $date->build_filter_by_period($request->{_locale});
# Lets set the data in a hash for the template system. :)
my $select = {
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
    text => $request->{_locale}->text("Continue"),
  }
};

    my $template;
     $template = LedgerSMB::Template->new(
     user     => $request->{_user},
     locale   => $request->{_locale},
     path     => 'UI/payments',
     template => 'payment1',
     format   => 'HTML' );
     $template->render($select);# And finally, Lets print the screen :)
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
   &payment($request);
} elsif ($#array_options == 0) {
   $request->{'vendor-customer'} = $array_options[0]->{id}.'--'.$array_options[0]->{name};
   &payment2($request);
} else {
   # Lets call upon the template system
   my @company_options;
   for my $ref (0 .. $#array_options) {
       push @company_options, {    id => $array_options[$ref]->{id},
                                   name => $array_options[$ref]->{name},
                                   meta_number => $array_options[$ref]->{meta_number}};
   }
   my $select = {
    companies => \@company_options,
    stylesheet => $request->{_user}->{stylesheet},
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
                       text =>  $request->{_locale}->text("Continue")}
    };
    my $template;
     $template = LedgerSMB::Template->new(
     user     => $request->{_user},
     locale   => $request->{_locale},
     path     => 'UI/payments',
     template => 'payment1_5',
     format   => 'HTML' );
    $template->render($select);
 }

}

=item payment2

This method is used  for the payment module, it is a consecuence of the payment sub,
and its used for all the mechanics of an invoices payment module.

=cut

sub payment2 {
my ($request) = @_;
my $locale       = $request->{_locale};
my $Payment = LedgerSMB::DBObject::Payment->new({'base' => $request});
# VARIABLES
my ($project_id, $project_number, $project_name, $department_id, $department_name );
my @array_options;
my @project;
my @selected_checkboxes;
my @department;
my @currency_options;
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

($Payment->{entity_credit_id}, $Payment->{company_name}) = split /--/ , $request->{'vendor-customer'};

# WE NEED TO RETRIEVE A BILLING LOCATION, THIS IS HARDCODED FOR NOW... Should we change it?
$Payment->{location_class_id} = '1';
my @vc_options;
@vc_options = $Payment->get_vc_info();
# LETS BUILD THE PROJECTS INFO
# I DONT KNOW IF I NEED ALL THIS, BUT AS IT IS AVAILABLE I'LL STORE IT FOR LATER USAGE.
if ($request->{projects}) {
  ($project_id, $project_number, $project_name)  = split /--/ ,  $request->{projects} ;
  @project = { name => 'projects',  text => $project_number.' '.$project_name,  value => $request->{projects}};
}
# LETS GET THE DEPARTMENT INFO
# WE HAVE TO SET $dbPayment->{department_id} NOW, THIS DATA WILL BE USED LATER WHEN WE
# CALL FOR payment_get_open_invoices. :)
if ($request->{department}) {
 ($Payment->{department_id}, $department_name)             = split /--/, $request->{department};
 @department = { name => 'department',  text => $department_name,  value => $request->{department}};
}
# LETS GET ALL THE ACCOUNTS
my @account_options = $Payment->list_accounting();
# LETS GET THE POSSIBLE SOURCES
my @sources_options = $Payment->get_sources(\%$locale);
# LETS BUILD THE CURRENCIES INFORMATION
# FIRST, WE NEED TO KNOW THE DEFAULT CURRENCY
my $default_currency = $Payment->get_default_currency();
# LETS BUILD THE COLUMN HEADERS WE ALWAYS NEED
# THE OTHER HEADERS WILL BE BUILT IF THE RIGHT CONDITIONS ARE MET.
# -----------------------------------------------
# SOME USERS WONT USE MULTIPLE CURRENCIES, AND WONT LIKE THE FACT CURRENCY BEING
# ON THE SCREEN ALL THE TIME, SO IF THEY ARE USING THE DEFAULT CURRENCY WE WONT PRINT IT
my $currency_text  =  $request->{curr} eq $default_currency ? '' : '('.$request->{curr}.')';
my $default_currency_text = $currency_text ? '('.$default_currency.')' : '';
my @column_headers =  ({text => $locale->text('Invoice')},
                       {text => $locale->text('Date')},
                       {text => $locale->text('Total').$default_currency_text},
                       {text => $locale->text('Paid').$default_currency_text},
                       {text => $locale->text('Discount').$default_currency_text},
                       {text => $locale->text('Apply Disc')},
                       {text => $locale->text('Memo')},
                       {text => $locale->text('Amount Due').$default_currency_text}
                       );
 # WE NEED TO KNOW IF WE ARE USING A CURRENCY THAT NEEDS AN EXCHANGERATE
 if ($default_currency ne $request->{curr} ) {
 # FIRST WE PUSH THE OTHER COLUMN HEADERS WE NEED
     push @column_headers, {text => $locale->text('Exchange Rate')},
                           {text => $locale->text('Amount Due').$currency_text};
 # WE SET THEM IN THE RIGHT ORDER FOR THE TABLE INSIDE THE UI
     @column_headers[7,8] = @column_headers[8,7];

     # select the exchange rate for the currency at the payment date
     # this has preference over what comes from the request, because the payment date
     # may have changed since the last request and the currency rate in the request
     # can be associated with the old payment date -- for example when a rate has been
     # entered for the current date and the user selects a different date after opening
     # the screen: today's rate would be used with no way for the user to override, if
     # we would simply take the exrate from the request.
     $exchangerate = $Payment->get_exchange_rate($request->{curr},
                         $request->{datepaid} ? $request->{datepaid}
                         : $Payment->{current_date});
     $exchangerate = $request->{exrate}
        if ((! $exchangerate) &&
        $request->{datepaid} eq $request->{olddatepaid});


   if ($exchangerate) {
     @currency_options = {
          name => 'exrate',
          value => "$exchangerate", #THERE IS A STRANGE BEHAVIOUR WITH THIS,
          text =>  "$exchangerate"  #IF I DONT USE THE DOUBLE QUOTES, IT WILL PRINT THE ADDRESS
                                    #THERE MUST BE A REASON FOR THIS, I MUST RETURN TO IT LATER
      };
   } else {
   @currency_options = {
        name => 'exrate'};
   }

 } else {
 # WE MUST SET EXCHANGERATE TO 1 FOR THE MATHS SINCE WE
 # ARE USING THE DEFAULT CURRENCY
   $exchangerate = 1;
   @currency_options = {
                          name => 'exrate',
                          value => 1,
                          text =>  1
                       };
  }
# FINALLY WE ADD TO THE COLUMN HEADERS A LAST FIELD TO PRINT THE CLOSE INVOICE CHECKBOX TRICK :)
if ($request->{account_class} == 1){
 push @column_headers, {text => $locale->text('To pay').$currency_text},
                       {text => 'X'};
} else {
 push @column_headers, {text => $locale->text('Received').$currency_text},
                       {text => 'X'};
}
my @invoice_data;
my @topay_state;
@array_options  = $Payment->get_open_invoices();
my $unhandled_overpayment;
for my $ref (0 .. $#array_options) {
 $array_options[$ref]->{invoice_date} = $array_options[$ref]->{invoice_date}->to_output;
 if (  !$request->{"checkbox_$array_options[$ref]->{invoice_id}"}) {
   my $request_topay_fx_bigfloat=LedgerSMB::PGNumber->from_input($request->{"topay_fx_$array_options[$ref]->{invoice_id}"});
# SHOULD I APPLY DISCCOUNTS?
      $request->{"optional_discount_$array_options[$ref]->{invoice_id}"} = $request->{first_load}? "on":  $request->{"optional_discount_$array_options[$ref]->{invoice_id}"};

# LETS SET THE EXCHANGERATE VALUES
   #tshvr4 meaning of next statement? does the same in either case!
   my $due_fx = $array_options[$ref]->{due_fx};

   my $topay_fx_value;
   if ("$exchangerate") {
       $topay_fx_value =   $due_fx;
       if (!$request->{"optional_discount_$array_options[$ref]->{invoice_id}"}) {
       $topay_fx_value = $due_fx = $due_fx + ($array_options[$ref]->{discount}/$array_options[$ref]->{exchangerate});
        }
   } else {
   #    $topay_fx_value = "N/A";
   }


# We need to check for unhandled overpayment, see the post function for details
# First we will see if the discount should apply?


# We need to compute the unhandled_overpayment, notice that all the values inside the if already have
# the exchangerate applied

# XXX:  This causes issues currently, so display of unhandled overpayment has
# disabled.  Was getting numbers that didn't make a lot of sense to me. --CT
      $due_fx ||= 0;
      $request_topay_fx_bigfloat ||= 0;
      if ( $due_fx <  $request_topay_fx_bigfloat) {
         # We need to store all the overpayments so we can use it on the screen
         $unhandled_overpayment = $unhandled_overpayment + $request_topay_fx_bigfloat - $due_fx;
         #$request->{"topay_fx_$array_options[$ref]->{invoice_id}"} = "$due_fx";
         $request_topay_fx_bigfloat=$due_fx;
     }
 my $paid = $array_options[$ref]->{amount} - $array_options[$ref]->{due} - $array_options[$ref]->{discount};
 my $paid_formatted=$paid->to_output;
 #Now its time to build the link to the invoice :)
 my $uri_module;
 #TODO move following code to sub getModuleForUri() ?
 if($Payment->{account_class} == 1) # 1 is vendor
 {
  if($array_options[$ref]->{invoice})
  {
   $uri_module='ir';
  }
  else
  {
   $uri_module='ap';
  }
 }#account_class 1
 elsif($Payment->{account_class} == 2) # 2 is customer
 {
  if($array_options[$ref]->{invoice})
  {
   $uri_module='is';
  }
  else
  {
   $uri_module='ar';
  }
 }#account_class 2
 else
 {
  #TODO
  $uri_module='??';
 }
#my $uri = $Payment->{account_class} == 1 ? 'ap' : 'ar';
 my $uri =$uri_module.'.pl?action=edit&id='.$array_options[$ref]->{invoice_id}.'&path=bin/mozilla&login='.$request->{login};

   push @invoice_data, {       invoice => { number => $array_options[$ref]->{invnumber},
                                            id     =>  $array_options[$ref]->{invoice_id},
                                            href   => $uri
                                           },
                               invoice_date      => "$array_options[$ref]->{invoice_date}",
                               amount            => $array_options[$ref]->{amount}->to_output,
                               due               => $request->{"optional_discount_$array_options[$ref]->{invoice_id}"}?  $array_options[$ref]->{due} : $array_options[$ref]->{due} + $array_options[$ref]->{discount},
                               paid              => $paid_formatted,
                               discount          => $request->{"optional_discount_$array_options[$ref]->{invoice_id}"} ? "$array_options[$ref]->{discount}" : 0 ,
                               optional_discount =>  $request->{"optional_discount_$array_options[$ref]->{invoice_id}"},
                               exchange_rate     =>  "$array_options[$ref]->{exchangerate}",
                               due_fx            =>  "$due_fx", # This was set at the begining of the for statement
                               topay             => "$array_options[$ref]->{due}" - "$array_options[$ref]->{discount}",
                               source_text       =>  $request->{"source_text_$array_options[$ref]->{invoice_id}"},
                               optional          =>  $request->{"optional_pay_$array_options[$ref]->{invoice_id}"},
                               selected_account  =>  $request->{"account_$array_options[$ref]->{invoice_id}"},
                               selected_source   =>  $request->{"source_$array_options[$ref]->{invoice_id}"},
                               memo              =>  { name  => "memo_invoice_$array_options[$ref]->{invoice_id}",
                                                       value => $request->{"memo_invoice_$array_options[$ref]->{invoice_id}"}
                                                     },#END HASH
                               topay_fx          =>  { name  => "topay_fx_$array_options[$ref]->{invoice_id}",
                                                       value =>  (defined $request->{"topay_fx_$array_options[$ref]->{invoice_id}"}) ?
                                                           $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} eq 'N/A' ?
                                                           "$topay_fx_value" :
                                                           "$request_topay_fx_bigfloat":
                                                           "$topay_fx_value"
                                                           # Ugly hack, but works ;) ...
                                                 }#END HASH
                           };# END PUSH

   push @topay_state, {
                       id  => "topaystate_$array_options[$ref]->{invoice_id}",
                       value => $request->{"topaystate_$array_options[$ref]->{invoice_id}"}
                      }; #END PUSH

 }
 else {
  push @selected_checkboxes, {name => "checkbox_$array_options[$ref]->{invoice_id}",
                              value => "checked"} ;
 } #END IF
}# END FOR
# And finally, we are going to store the information for the overpayment / prepayment / advanced payment
# and all the stuff, this is only needed for the update function.
my @overpayment;
my @overpayment_account;
# Got to build the account selection box first.
@overpayment_account = $Payment->list_overpayment_accounting();
# Now we build the structure for the UI
for (my $i=1 ; $i <= $request->{overpayment_qty}; $i++) {
   if (!$request->{"overpayment_checkbox_$i"}) {
     if ( $request->{"overpayment_topay_$i"} ) {
     # Now we split the account selected options
     my ($id, $accno, $description) = split(/--/, $request->{"overpayment_account_$i"});
     my ($cashid, $cashaccno, $cashdescription  ) = split(/--/, $request->{"overpayment_cash_account_$i"});

        push @overpayment, {amount  => $request->{"overpayment_topay_$i"},
                                   source1 => $request->{"overpayment_source1_$i"},
                                   source2 => $request->{"overpayment_source2_$i"},
                                   memo    => $request->{"overpayment_memo_$i"},
                                   account => { id          => $id,
                                                accno       => $accno,
                                                description => $description
                                              },
                                   cashaccount => { id     =>   $cashid,
                                                     accno  =>  $cashaccno,
                                                     description => $cashdescription
                                                   }
                                  };
     } else {
      $i = $request->{overpayment_qty} + 1;
     }
   }
}
# We need to set the available media and format from printing
my @media_options;
push  @media_options, {value => 1, text => "Screen"};
if ($#{LedgerSMB::Sysconfig::printer}) {
    for (keys %{LedgerSMB::Sysconfig::printer}) {
      push  @media_options, {value => 1, text => $_};
    }
}
push  @media_options, {value => 1, text => "e-mail"};

#$request->error("@media_options");
my @format_options;
push @format_options, {value => 1, text => "HTML"};
if (${LedgerSMB::Sysconfig::latex}) {
        push  @format_options, {value => 2, text => "PDF" }, {value => 3, text => "POSTSCRIPT" };
}
# LETS BUILD THE SELECTION FOR THE UI
# Notice that the first data inside this selection is the firs_load, this
# will help payment2.html to know wether it is being called for the first time
my $select = {
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
  project =>  @project ? @project : '' ,        # WE NEED TO VERIFY THAT THE ARRAY EXISTS, IF IT DOESNT,
  department => @department ? @department : '', # WE WILL PASS A NULL STRING, THIS FIXES THE ISSUES
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
  curr => {       name  => 'curr',
                  value => $request->{curr},

  },
  column_headers => \@column_headers,
  rows        =>  \@invoice_data,
  topay_state   => \@topay_state,
  vendorcustomer => { name => 'vendor-customer',
                      value => $request->{'vendor-customer'}
                     },
  unhandled_overpayment => { name => 'unhandledoverpayment', value => "$unhandled_overpayment"   }  ,
  vc => { name => $Payment->{company_name}, # We will assume that the first Billing Information as default
          address =>  [ {text => $vc_options[0]->{'line_one'}},
                        {text =>  $vc_options[0]->{'line_two'}},
                        {text =>  $vc_options[0]->{'line_three'}},
                        {text => $vc_options[0]->{city}},
                {text => $vc_options[0]->{state}},
                {text => $vc_options[0]->{country}}]
        },
   format => {
    name => 'FORMAT',
    options => \@format_options
   },
   media => {
    name => 'MEDIA',
    options => \@media_options
  },
 exrate => @currency_options,
 selectedcheckboxes => @selected_checkboxes  ? \@selected_checkboxes : '',
 notes => $request->{notes},
 overpayment         => \@overpayment,
 overpayment_account => \@overpayment_account,
 format_amount => sub {return LedgerSMB::PGNumber->to_output(@_)}
};

$select->{selected_account} = $vc_options[0]->{cash_account_id}
      unless defined $select->{selected_account};
my $template = LedgerSMB::Template->new(
  user     => $request->{_user},
  locale   => $request->{_locale},
  path     => 'UI/payments',
  template => 'payment2',
  format => 'HTML' );
  $template->render($select);
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
# WE HAVE TO SET $dbPayment->{department_id} in order to process
if ($request->{department}) {
 $request->{department} =~ /^(\d+)--*/;
 $Payment->{department_id} = $1;
}
#
# We want to set a gl_description,
# since we are using two tables there is no need to use doubled information,
# we could specify this gl is the result of a payment movement...
#
$Payment->{gl_description} = $locale->text('This gl movement, is a consecuence of a payment transaction');
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
my $unhandled_overpayment = 0; # This variable might be fuzzy, we are using it to handle invalid data
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
# We need the invoices in order to process the income data, this is done this way
# since the data we have isn't indexed in any way.
#
# Ok, we want to use the disccount information in order to do some accounting movements,
# we will process it with the same logic for a regular payment, and see where does this leave us.
#
$Payment->{vc_name} = $Payment->{company_name};
@array_options = $Payment->get_entity_credit_account();# We need to know the disccount account
my $discount_account_id = $array_options[0]->{discount};
@array_options = $Payment->get_open_invoices();
for my $ref (0 .. $#array_options) {
 if ((!$request->{"checkbox_$array_options[$ref]->{invoice_id}"})&&($request->{"topay_fx_$array_options[$ref]->{invoice_id}"})) {
         # First i have to determine if discounts will apply
         # we will assume that a discount should apply only
         # if this is the last payment of an invoice
     my  $temporary_discount = 0;
     my  $request_topay_fx_bigfloat=LedgerSMB::PGNumber->from_input($request->{"topay_fx_$array_options[$ref]->{invoice_id}"});
     if (($request->{"optional_discount_$array_options[$ref]->{invoice_id}"})&&("$array_options[$ref]->{due_fx}" <=  $request_topay_fx_bigfloat +  $array_options[$ref]->{discount_fx})) {
         $temporary_discount = $array_options[$ref]->{discount_fx};
     }
         #
         # The prefix cash is to set the movements of the cash accounts,
         # same names are used for ap/ar accounts w/o the cash prefix.
         #
     my $sign = "$array_options[$ref]->{due_fx}" <=> 0;
     if ( $request->round_amount($sign * "$array_options[$ref]->{due_fx}")
            <
          $request->round_amount($sign * $request_topay_fx_bigfloat )
     ){
         # We need to store all the overpayments so we can use it on a new payment2 screen
         $unhandled_overpayment = $unhandled_overpayment + $request_topay_fx_bigfloat + $temporary_discount - $array_options[$ref]->{amount} ;

     }
         if ($temporary_discount != 0) {
             push @amount, $temporary_discount;
             push @cash_account_id, $discount_account_id;
             push @source, $locale->text('Applied discount');
             push @transaction_id, $array_options[$ref]->{invoice_id};
         }
         push @amount,   $request_topay_fx_bigfloat; # We'll use this for both cash and ap/ar accounts
         push @cash_account_id,  $request->{"optional_pay_$array_options[$ref]->{invoice_id}"} ? $request->{"account_$array_options[$ref]->{invoice_id}"} : $request->{account};
         push @source, $request->{"optional_pay_$array_options[$ref]"} ?
                       $request->{"source_$array_options[$ref]->{invoice_id}"}.' '.$request->{"source_text_$array_options[$ref]->{invoice_id}"}
                       : $request->{source}.' '.$request->{source_value}; # We'll use this for both source and ap/ar accounts
         push @memo, $request->{"memo_invoice_$array_options[$ref]->{invoice_id}"};
         push @transaction_id, $array_options[$ref]->{invoice_id};
 }
}
# Check if there is an unhandled overpayment and run payment2 as needed
if ($unhandled_overpayment) {
&payment2($request);
return 0;
}
#
# Now we need the overpayment information.
#
# We will use the prefix op to indicate it is an overpayment information.
#
# note: I love the for's C-like syntax.
for (my $i=1 ; $i <= $request->{overpayment_qty}; $i++) {
   if (!$request->{"overpayment_checkbox_$i"}) { # Is overpayment marked as deleted ?
     if ( $request->{"overpayment_topay_$i"} ) { # Is this overpayment an used field?
     # Now we split the account selected options, using the namespace the if statement
     # provides for us.
     $request->{"overpayment_topay_$i"} = LedgerSMB::PGNumber->from_input($request->{"overpayment_topay_$i"});
     $request->{"overpayment_account_$i"} =~ /^(\d+)--*/;
     my $id = $1;
     $request->{"overpayment_cash_account_$i"} =~ /^(\d+)--*/;
     my $cashid = $1;
     push @op_amount, $request->{"overpayment_topay_$i"};
     push @op_cash_account_id, $cashid;
     push @op_source, $request->{"overpayment_source1_$i"}.' '.$request->{"overpayment_source2_$i"};
     push @op_memo, $request->{"overpayment_memo_$i"};
     if (!$id and $id ne "0"){
         $request->error($request->{_locale}->text('No overpayment account selected.  Was one set up?'));
     }
     push @op_account_id, $id;
     }
   }
}
# Finally we store all the data inside the LedgerSMB::DBObject::Payment object.
    $Payment->{cash_account_id}    =  $Payment->_db_array_scalars(@cash_account_id);
    $Payment->{amount}             =  $Payment->_db_array_scalars(@amount);
    $Payment->{source}             =  $Payment->_db_array_scalars(@source);
    $Payment->{memo}               =  $Payment->_db_array_scalars(@memo);
    $Payment->{transaction_id}     =  $Payment->_db_array_scalars(@transaction_id);
    $Payment->{op_amount}          =  $Payment->_db_array_scalars(@op_amount);
    $Payment->{op_cash_account_id} =  $Payment->_db_array_scalars(@op_cash_account_id);
    $Payment->{op_source}          =  $Payment->_db_array_scalars(@op_source);
    $Payment->{op_memo}            =  $Payment->_db_array_scalars(@op_memo);
    $Payment->{op_account_id}      =  $Payment->_db_array_scalars(@op_account_id);
# Ok, passing the control to postgresql and hoping for the best...

    $Payment->post_payment();
    if ($request->{continue_to_calling_sub}){ return $Payment->{payment_id} ;}
    else {
    # Our work here is done, ask for more payments.
    &payment($request);
    }
}

=item print_payment

This sub will print the payment on the selected media, it needs to
receive the $Payment object with all this information.

=cut

sub print_payment {
  my ($Payment) = @_;
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
  $Payment->{templates_path} = 'templates/'.LedgerSMB::Setting::get('templates').'/';
  my $template = LedgerSMB::Template->new(
      user     => $Payment->{_user},
      locale   => $Payment->{_locale},
      path     => $Payment->{templates_path},
      template => 'printPayment',
      format => 'HTML' );
  $template->render($select);
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
&print_payment($Payment);
}

=item use_overpayment

This item will do the trick to use the overpayment information stored inside the payments,
it should be powerful enough to link overpayment from one customer to other customers.

=cut

sub use_overpayment {
my ($request) = @_;
my $locale    = $request->{_locale};
my $Payment   = LedgerSMB::DBObject::Payment->new({'base' => $request});
my $Settings = LedgerSMB::Setting->new({'base' => $request});
my @arrayOptions;
my @entities;

#We will use $ui to handle all the data needed by the User Interface
my $ui = { stylesheet => $request->{_user}->{stylesheet}};
$ui->{account_class} = {name => 'account_class', value => $request->{account_class}};

#We want to get all the customer/vendor with unused overpayment
my @data = $Payment->get_open_overpayment_entities();
for my $ref (0 .. $#data) {
       push @entities, { value => $data[$ref]->{id},
                         name =>  $data[$ref]->{name}};
   }

my @currOptions;
@arrayOptions = $Settings->get_currencies();

for my $ref (0 .. $#arrayOptions) {
    push @currOptions, { value => $arrayOptions[$ref],
                          text => $arrayOptions[$ref]};
}


$ui->{curr} = \@currOptions;
$ui->{entities} =  \@entities;
$ui->{action}   =  {name => 'action', value => 'use_overpayment2', text => $locale->text('Continue')};
my $template = LedgerSMB::Template->new(
  user     => $request->{_user},
  locale   => $request->{_locale},
  path     => 'UI/payments',
  template => 'use_overpayment1',
  format => 'HTML' );
$template->render($ui);
}


=item use_overpayment2

This sub runs to allow the user to specify the invoices in which an overpayment should be used

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
my $ui_to_use_subtotal = 0;
my $ui_avble_subtotal = 0;
my @hiddens;
my $vc_entity_info;
my $default_currency;
my %amount_to_be_used;
my %ovp_repeated_invoices;
my %invoice_id_amount_to_pay;
my $count;
my $warning = $Payment->{"warning"};

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

  if ($ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{qq|$Payment->{"selected_accno_$count"}|} != $Payment->{"selected_accno_$count"}){

    #the "ovp_repeated_invoices" hash will store the convination of invoice id and overpayment account, if this convination has already printed
    #do not print it again
    $ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{qq|$Payment->{"selected_accno_$count"}|} = $Payment->{"selected_accno_$count"};

    #the "repeated invoice" flag will check if this invoice has already been printed, if it does, do not print the apply discount checkbox in the UI
    if (!$ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{"repeated_invoice"}){
      $ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{"optional_discount"} = $Payment->{"optional_discount_$count"};
      $ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{"repeated_invoice"} = 'false';
    } else{
      $ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{"repeated_invoice"} = 'true';
    }

    $ui_to_use_subtotal += $Payment->{"amount_$count"};

    my ($id,$name) = split(/--/, $Payment->{"entity_id_$count"});
    my ($ovp_chart_id, $ovp_selected_accno) = split(/--/, $Payment->{"selected_accno_$count"});
    my $applied_due = ($ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{"optional_discount"})? $Payment->{"due_$count"}: $Payment->{"due_$count"} + $Payment->{"discount_$count"};

    $amount_to_be_used{"$ovp_selected_accno"} += $Payment->{"amount_$count"};
    #this hash will keep track of the amount to be paid of an specific invoice_id, this amount could not be more than the due of that invoice.
    $invoice_id_amount_to_pay{qq|$Payment->{"invoice_id_$count"}|} += $Payment->{"amount_$count"};
    if($invoice_id_amount_to_pay{qq|$Payment->{"invoice_id_$count"}|} > $applied_due){
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
    $uri .= '.pl?action=edit&id='.$Payment->{"invoice_id_$count"}.'&path=bin/mozilla&login='.$request->{login};

    push @ui_selected_inv, { invoice          => { number => $Payment->{"invnumber_$count"},
                                                        id     => $Payment->{"invoice_id_$count"},
                                                        href   => $uri},
                           entity_name        => $name,
                           entity_id          => $Payment->{"entity_id_$count"},
                           vc_discount_accno     => $Payment->{"vc_discount_accno_$count"},
                           invoice_date       => $Payment->{"invoice_date_$count"},
                           applied_due        => $applied_due,
               optional_discount    => $ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{"optional_discount"},
               repeated_invoice    => $ovp_repeated_invoices{qq|$Payment->{"invoice_id_$count"}|}->{"repeated_invoice"},
               due                => $Payment->{"due_$count"},
               discount        => $Payment->{"discount_$count"},
                           selected_accno     => {id        => $ovp_chart_id,
                                                    ovp_accno => $ovp_selected_accno},
                           amount             => $Payment->{"amount_$count"}};
  }
  $count++;
}


#lets search which available invoice do we have for the selected entity
if ($Payment->{"new_entity_id"} && !$Payment->{"new_checkbox"})
{
  #lets create an object who has the entity_credit_id of the selected entity
  $Selected_entity = LedgerSMB::DBObject::Payment->new({'base' => $Payment});
  $Selected_entity->{"invnumber"} = $Selected_entity->{new_invoice} ;

  my ($id,$name,$vc_discount_accno) = split(/--/, $Selected_entity->{"new_entity_id"});
  my ($ovp_chart_id, $ovp_selected_accno) = split(/--/, $Selected_entity->{"new_accno"});

  $Selected_entity->{"entity_credit_id"} = $id;

  @avble_invoices = $Selected_entity->get_open_invoice();
  for my $ref (0 .. $#avble_invoices) {

    #this hash will store the convination of invoice id and overpayment account, if this convination has already printed
    #do not print it again
    if ($ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{qq|$Selected_entity->{"new_accno"}|} != $Selected_entity->{"new_accno"}){
      $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{qq|$Selected_entity->{"new_accno"}|} = $Selected_entity->{"new_accno"};

      #the "repeated invoice" flag will check if this invoice has already been printed, if it does, do not print the apply discount checkbox in the UI
      if (!$ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{"repeated_invoice"}){
        $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{"repeated_invoice"} = 'false';
      } else{
        $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{"repeated_invoice"} = 'true';
      }


      if (!$ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{"optional_discount"}){
        $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{"optional_discount"} = 'true';
      }

      $invoice_id_amount_to_pay{qq|$avble_invoices[$ref]->{invoice_id}|} += $Selected_entity->{"new_amount"};
      $ui_to_use_subtotal += $Selected_entity->{"new_amount"};
      $amount_to_be_used{"$ovp_selected_accno"} += $Selected_entity->{"new_amount"};

      #lets make the href for the invoice
      my $uri = $Payment->{account_class} == 1 ? 'ap' : 'ar';
      $uri .= '.pl?action=edit&id='.$avble_invoices[$ref]->{invoice_id}.'&path=bin/mozilla&login='.$request->{login};

      push @ui_avble_invoices, { invoice       => { number => $avble_invoices[$ref]->{invnumber},
                                                        id     => $avble_invoices[$ref]->{invoice_id},
                                                        href   => $uri},
                                 entity_name       => $name,
                                 vc_discount_accno => $vc_discount_accno,
                                 entity_id        => qq|$Selected_entity->{"entity_credit_id"}--$name|,
                 invoice_date        => $avble_invoices[$ref]->{invoice_date},
                 applied_due       => $Payment->{"due_$count"},
                 repeated_invoice  => $ovp_repeated_invoices{qq|$avble_invoices[$ref]->{invoice_id}|}->{"repeated_invoice"},
                 due            => "$avble_invoices[$ref]->{due}",
                 discount          => "$avble_invoices[$ref]->{discount}",
                 selected_accno    => {    id       => $ovp_chart_id,
                                        ovp_accno => $ovp_selected_accno},
                 amount        => $Selected_entity->{"new_amount"}}
    }
  }
}


# we need to get all the available overpayments
@overpayments = $Payment->get_available_overpayment_amount();

for my $ref (0 .. $#overpayments) {
       push @ui_overpayments, {     id               =>  $overpayments[$ref]->{chart_id},
                                    accno          =>  $overpayments[$ref]->{accno},
                                    description    =>  $overpayments[$ref]->{description},
                                    amount         =>  "$overpayments[$ref]->{movements}",
                                    available      =>  "$overpayments[$ref]->{available}",
                                    touse          =>  qq|$amount_to_be_used{"$overpayments[$ref]->{accno}"}|
                            };
       $ui_avble_subtotal += "$overpayments[$ref]->{available}";
}


# We start with our data selection called ui

my $ui = { exrate        => $ui_exchangerate,
       datepaid        => {name           => 'datepaid',
                                    value    => $Payment->{"datepaid"}? $Payment->{"datepaid"} : $Payment->{"current_date"},
                                    size    => '10'},
           notes        => $Payment->{"notes"},
       vc_entity_info    => $vc_entity_info,
           curr                => $request->{curr},
           default_curr         => $default_currency,
       dont_search_inv    => $Payment->{"new_checkbox"},
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

my $template =    LedgerSMB::Template->new(
          user     => $request->{_user},
          locale   => $request->{_locale},
          path     => 'UI/payments',
          template => 'use_overpayment2',
          format => 'HTML' );

$template->render($ui);
}

=item post_overpayment

This method reorganize the selected invoices by customer/vendor and adapt them to make them fit with the post_payment sql method, calling it once by customer/vendor id

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
#this variables will store all the unused overpayment which will be used to pay the invoices
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

  my ($entity_id,$entity_name) = split(/--/, $request->{"entity_id_$count"});
  my ($ovp_chart_id, $ovp_selected_accno) = split(/--/, $request->{"selected_accno_$count"});

  #Let's see which will the amount of the invoice due that will be paid from an overpayment
  my $applied_due = ($request->{"optional_discount_$count"} && $request->{"amount_$count"} == $request->{"due_$count"})?
                        $request->{"due_$count"}:
                        $request->{"due_$count"} + $request->{"discount_$count"};

  #let's check if the overpayment movements of the $ovp_chart_id accno has already been searched, if not, search and store it
  #to later use
  if(!$entity_unused_ovp{"$ovp_chart_id"})
  {
    $entity_unused_ovp{"$ovp_chart_id"} = LedgerSMB::DBObject::Payment->new({'base' => $request});
    $entity_unused_ovp{"$ovp_chart_id"}->{"chart_id"} = $ovp_chart_id;
    #this call will store the unused overpayments in $entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"} just check the .pm
    $entity_unused_ovp{"$ovp_chart_id"}->get_unused_overpayments();
    #this counter will keep track of the ovp that had been used to pay the invoices
    $entity_unused_ovp{"$ovp_chart_id"}->{"unused_ovp_index"} = 0;
  }
  $unused_ovp_index = $entity_unused_ovp{"$ovp_chart_id"}->{"unused_ovp_index"};

  ###############################################################
  #        Warnings Section
  ###############################################################
  #In this section, the post_overpayment will check some user inputs and verify if those are apted to call the post method, if not just store a warning message in the
  #$request->{warning} variable and then call the use_overpayment2 method and it will manage it

  #the $invoice_id_amount_to_pay hash will keep track of the amount to be paid of an specific invoice_id, this amount could not be more than the due of that invoice
  $invoice_id_amount_to_pay{qq|$request->{"invoice_id_$count"}|} += $request->{"amount_$count"};
  if($invoice_id_amount_to_pay{qq|$request->{"invoice_id_$count"}|} > $applied_due){
    $request->{"warning"} .= "Warning\n"
  }

  #The amount to be paid shouldn't be negative
  if ($request->{"amount_$count"} < 0){
    $request->{"warning"} .= "Warning\n"
  }

  #Is the amount to be paid null?, tell the user and he/she will be able to manage it
  if ($request->{"amount_$count"} == 0 )
  {
    $request->{"warning"} .= $locale->text('The amount to be pay of the invoice number').qq| $request->{"invnumber_$count"} |.$locale->text('is null').qq|\n|;
  }

  #if the amount to be paid is bigger than the amount of the invoice, just call the update method and it will manage it
  if($request->{"warning"}){
    &use_overpayment2($request);
    return 0;
  }

  #lets fill our entity_list by it's entity ID
  if($entity_list{"$entity_id"})
  {

    #Let's fill all our entity invoice info, if it has a discount, store it into the discount accno
    if ($entity_list{"$entity_id"}->{"optional_discount_$count"} && $entity_list{"$entity_id"}->{"amount_$count"} == $entity_list{"$entity_id"}->{"due_$count"}) {
        push @{$entity_list{"$entity_id"}->{"array_amount"}}, $entity_list{"$entity_id"}->{"discount_$count"};
        push @{$entity_list{"$entity_id"}->{"array_cash_account_id"}}, $entity_list{"$entity_id"}->{"vc_discount_accno_$count"};
        push @{$entity_list{"$entity_id"}->{"array_source"}}, $locale->text('Applied discount by an overpayment');
    push @{$entity_list{"$entity_id"}->{"array_transaction_id"}}, $entity_list{"$entity_id"}->{"invoice_id_$count"};
    push @{$entity_list{"$entity_id"}->{"array_memo"}}, undef;
    push @{$entity_list{"$entity_id"}->{"ovp_payment_id"}}, undef;
    }

    #this is the amount of the present invoice that will be paid from the $ovp_chart_id accno
    my $tmp_ovp_amount = $entity_list{"$entity_id"}->{"amount_$count"};

    #let's store the AR/AP movement vs the overpayment accno, and keep track of all the ovp_id that will be use
    while($tmp_ovp_amount > 0)
    {
      #Send a warning if there are no more available amount in the $ovp_chart_id accno
      if (@{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"} eq '')
      {
        $request->{"warning"} .= $locale->text('The amount to be pay from the accno').qq| $ovp_chart_id |.$locale->text('is bigger than the amount available').qq|\n|;
        $tmp_ovp_amount = -1;
        next;
      }
      if (@{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"} >= $tmp_ovp_amount)
      {
        push @{$entity_list{"$entity_id"}->{"array_amount"}}, $tmp_ovp_amount;
        push @{$entity_list{"$entity_id"}->{"array_cash_account_id"}}, $ovp_chart_id;
        push @{$entity_list{"$entity_id"}->{"array_source"}}, $locale->text('use of an overpayment');
        push @{$entity_list{"$entity_id"}->{"array_transaction_id"}}, $entity_list{"$entity_id"}->{"invoice_id_$count"};
        push @{$entity_list{"$entity_id"}->{"array_memo"}}, undef;
        push @{$entity_list{"$entity_id"}->{"ovp_payment_id"}}, @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"payment_id"};

        $tmp_ovp_amount = 0;
        #lets see if there is more amount on the present overpayment movement
        my $tmp_residual_ovp_amount = @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"} - $tmp_ovp_amount;
        if ($tmp_residual_ovp_amount == 0)
        {
          $entity_unused_ovp{"$ovp_chart_id"}->{"unused_ovp_index"}++;
        }
      } else{
        $tmp_ovp_amount -= @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"};

        push @{$entity_list{"$entity_id"}->{"array_amount"}}, @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"};
        push @{$entity_list{"$entity_id"}->{"array_cash_account_id"}}, $ovp_chart_id;
        push @{$entity_list{"$entity_id"}->{"array_source"}}, $locale->text('use of an overpayment');
        push @{$entity_list{"$entity_id"}->{"array_transaction_id"}}, $entity_list{"$entity_id"}->{"invoice_id_$count"};
        push @{$entity_list{"$entity_id"}->{"array_memo"}}, undef;
        push @{$entity_list{"$entity_id"}->{"ovp_payment_id"}}, @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"payment_id"};

        $unused_ovp_index = $entity_unused_ovp{"$ovp_chart_id"}->{"unused_ovp_index"}++;
      }

    }

  }else {
    #Create an Payment object if this entity has not been saved, this object will encapsulate all the entity info which will be needed to
    #call the sql payment_post method
    $entity_list{"$entity_id"} = LedgerSMB::DBObject::Payment->new({'base' => $request});
    $entity_list{"$entity_id"}->{"entity_credit_id"} = $entity_id;


    # LETS GET THE DEPARTMENT INFO
    # ******************************************, Falta implementarlo!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #if ($request->{department}) {
    #}
    #$entity_list{"$entity_id"}->{"department_id"} = $request->{department};
    #********************************************************

    # We want to set a gl_description,
    # since we are using two tables there is no need to use doubled information,
    # we could specify this gl is the result of a overpayment movement...
    #
    $entity_list{"$entity_id"}->{"gl_description"} = $locale->text('This gl movement, is the result of a overpayment transaction');

    # Im not sure what this is for... gotta comment this later
    $entity_list{"$entity_id"}->{"approved"} = 'true';
    #

    #Let's fill all our entity invoice info, if it has a discount, store it into the discount accno
    if ($entity_list{"$entity_id"}->{"optional_discount_$count"} && $entity_list{"$entity_id"}->{"amount_$count"} == $entity_list{"$entity_id"}->{"due_$count"}) {
        push @{$entity_list{"$entity_id"}->{"array_amount"}}, $entity_list{"$entity_id"}->{"discount_$count"};
        push @{$entity_list{"$entity_id"}->{"array_cash_account_id"}}, $entity_list{"$entity_id"}->{"vc_discount_accno_$count"};
        push @{$entity_list{"$entity_id"}->{"array_source"}}, $locale->text('Applied discount by an overpayment');
    push @{$entity_list{"$entity_id"}->{"array_transaction_id"}}, $entity_list{"$entity_id"}->{"invoice_id_$count"};
    push @{$entity_list{"$entity_id"}->{"array_memo"}}, undef;
    push @{$entity_list{"$entity_id"}->{"ovp_payment_id"}}, undef;

    }

    #this is the amount of the present invoice that will be paid from the $ovp_chart_id accno
    my $tmp_ovp_amount = $entity_list{"$entity_id"}->{"amount_$count"};

    #let's store the AR/AP movement vs the overpayment accno, and keep track of all the ovp_id that will be use
    while($tmp_ovp_amount > 0)
    {
      if (@{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"} >= $tmp_ovp_amount)
      {
        push @{$entity_list{"$entity_id"}->{"array_amount"}}, $tmp_ovp_amount;
        push @{$entity_list{"$entity_id"}->{"array_cash_account_id"}}, $ovp_chart_id;
        push @{$entity_list{"$entity_id"}->{"array_source"}}, $locale->text('use of an overpayment');
        push @{$entity_list{"$entity_id"}->{"array_transaction_id"}}, $entity_list{"$entity_id"}->{"invoice_id_$count"};
        push @{$entity_list{"$entity_id"}->{"array_memo"}}, undef;
        push @{$entity_list{"$entity_id"}->{"ovp_payment_id"}}, @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"payment_id"};

        $tmp_ovp_amount = 0;
        #lets see if there is more amount on the present overpayment movement
        my $tmp_residual_ovp_amount = @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"} - $tmp_ovp_amount;
        if ($tmp_residual_ovp_amount == 0)
        {
          $entity_unused_ovp{"$ovp_chart_id"}->{"unused_ovp_index"}++;
        }
      } else{
        $tmp_ovp_amount -= @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"};

        push @{$entity_list{"$entity_id"}->{"array_amount"}}, @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"available"};
        push @{$entity_list{"$entity_id"}->{"array_cash_account_id"}}, $ovp_chart_id;
        push @{$entity_list{"$entity_id"}->{"array_source"}}, $locale->text('use of an overpayment');
        push @{$entity_list{"$entity_id"}->{"array_transaction_id"}}, $entity_list{"$entity_id"}->{"invoice_id_$count"};
        push @{$entity_list{"$entity_id"}->{"array_memo"}}, undef;
        push @{$entity_list{"$entity_id"}->{"ovp_payment_id"}}, @{$entity_unused_ovp{"$ovp_chart_id"}->{"unused_overpayment"}}[$unused_ovp_index]->{"payment_id"};

        $unused_ovp_index = $entity_unused_ovp{"$ovp_chart_id"}->{"unused_ovp_index"}++;
      }
    }


  }

  $count++;
}



# Now we have all our movements organized by vendor/customer, it is time to call the post_payment sql method by each one of them
for my $key (keys %entity_list)
{
  # Finally we store all the data inside the LedgerSMB::DBObject::Payment object.
  $entity_list{"$key"}->{"amount"}             =  $entity_list{"$key"}->_db_array_scalars(@{$entity_list{"$key"}->{"array_amount"}});
  $entity_list{"$key"}->{"cash_account_id"}    =  $entity_list{"$key"}->_db_array_scalars(@{$entity_list{"$key"}->{"array_cash_account_id"}});
  $entity_list{"$key"}->{"source"}             =  $entity_list{"$key"}->_db_array_scalars(@{$entity_list{"$key"}->{"array_source"}});
  $entity_list{"$key"}->{"memo"}               =  $entity_list{"$key"}->_db_array_scalars(@{$entity_list{"$key"}->{"array_memo"}});
  $entity_list{"$key"}->{"transaction_id"}     =  $entity_list{"$key"}->_db_array_scalars(@{$entity_list{"$key"}->{"array_transaction_id"}});
  $entity_list{"$key"}->{"ovp_payment_id"}     =  $entity_list{"$key"}->_db_array_scalars(@{$entity_list{"$key"}->{"ovp_payment_id"}});

  $entity_list{"$key"}->post_payment();
}

&use_overpayment($request);

}

=back

=cut

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/payment.pl"};
1;

