=pod

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
# 	   Christian Ceballos B	   
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
use LedgerSMB::Sysconfig;
use LedgerSMB::DBObject::Payment;
use LedgerSMB::DBObject::Date;
use Error::Simple;
use strict; 

# CT:  A few notes for future refactoring of this code:
# 1:  I don't think it is a good idea to make the UI too dependant on internal
#     code structures but I don't see a good alternative at the moment.
# 2:  CamelCasing: -1

=pod

=item payment

This method is used to set the filter screen and prints it, using the 
TT2 system.

=back

=cut

sub payments {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->get_metadata();
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payments',
        template => 'payments_filter',
        format   => 'HTML', 
    );
    $template->render($payment);
}

sub get_search_criteria {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->get_metadata();
    if ($payment->{batch_id} && $payment->{batch_date}){
        $payment->{date_reversed} = $payment->{batch_date};
    }
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payments',
        template => 'search',
        format   => 'HTML', 
    );
    $template->render($payment);
}

sub get_search_results {
    my ($request) = @_;
    my $rows = [];
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    my @search_results = $payment->search;
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => ($payment->{format}) ? $payment->{format} : 'HTML',
    ); 

    my $base_url = "payment.pl?";
    my $search_url = "$base_url";
    for my $key (keys %{$request->take_top_level}){
        if ($base_url =~ /\?$/){
            $base_url .= "$key=$request->{key}";
        } else {
            $base_url .= "&$key=$request->{key}";
        }
    }

    my @columns = qw(selected meta_number date_paid amount source company_paid);
    my $contact_type = ($payment->{account_class} == 1) ? 'Vendor' : 'Customer';

    # CT:  Locale strings for gettext:
    #  $request->{_locale}->text("Vendor Number");
    #  $request->{_locale}->text("Customer Number");

    my $heading = {
         selected     => $request->{_locale}->text('Selected'),
         company_paid => {
                          text => $request->{_locale}->text('Company Name'),
                          href => "$search_url&orderby=company_paid",
                         },
         meta_number  => {
                          text => $request->{_locale}->text(
                                        "$contact_type Number"
                                  ),
                          href => "$search_url&orderby=meta_number",
                         },
         date_paid    => {
                          text => $request->{_locale}->text('Date Paid'),
                          href => "$search_url&orderby=date_paid",
                         },
         amount       => {
                          text => $request->{_locale}->text('Total Paid'),
                          href => "$search_url&orderby=amount",
                         },
         source       => {
                          text => $request->{_locale}->text('Source'),
                          href => "$search_url&orderby=source",
                         },
    };


    my $classcount;
    $classcount = 0;
    my $rowcount;
    $rowcount = 1;
    for my $line (@search_results){
        $classcount ||= 0;
        $rowcount += 1;
        push(@$rows, {
          company_paid => $line->{company_paid},
          amount       => $request->format_amount(amount => $line->{amount}),
          i            => "$classcount",
          date_paid    => $line->{date_paid},
          source       => $line->{source},
          meta_number  => $line->{meta_number},
          selected     => {
                          input => {
                                    type  => "checkbox",
                                    name  => "payment_$rowcount",
                                    value => "1",
                          },
           }
        });
        $payment->{"credit_id_$rowcount"} = $line->{credit_id};
        $payment->{"date_paid_$rowcount"} = $line->{date_paid};
        $payment->{"source_$rowcount"} = $line->{source};
        $classcount = ($classcount + 1) % 2;
        ++$rowcount;
    }
    $payment->{rowcount} = $rowcount;
    $payment->{script} = 'payment.pl';
    $payment->{title} = $request->{_locale}->text("Payment Results");
    my $hiddens = $payment->take_top_level;
    $template->render({
        form    => $payment,
        columns => \@columns,
        heading => $heading,
	hiddens => $payment->take_top_level,
        rows    => $rows,
        buttons => [{
                    value => 'reverse_payments',
                    name  => 'action',
                    class => 'submit',
                    type  => 'submit',
                    text  => $request->{_locale}->text('Reverse Payments'),
                   }]
    }); 
}

sub get_search_results_reverse_payments {
    my ($request) = @_;
    my $payment = LedgerSMB::DBObject::Payment->new({base => $request});
    for my $count (1 .. $payment->{rowcount}){
        if ($payment->{"payment_$count"}){
           $payment->{credit_id} = $payment->{"credit_id_$count"};
           $payment->{date_paid} = $payment->{"date_paid_$count"};
           $payment->{source} = $payment->{"source_$count"};
           $payment->reverse;
        }
    }
    get_search_criteria($payment);
}

sub check_job {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->check_job;
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payments',
        template => 'check_job',
        format   => 'HTML', 
    );
    $template->render($payment);
}

sub post_payments_bulk {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->post_bulk();
    my $template;
    if ($payment->{queue_payments}){
        $payment->{job_label} = 'Payments';
        $template = LedgerSMB::Template->new(
            user     => $request->{_user},
            locale   => $request->{_locale},
            path     => 'UI/payments',
            template => 'check_job',
            format   => 'HTML', 
        );
    } else {
        payments($request);
    }
    $template->render($payment);
}

sub print {
    use LedgerSMB::DBObject::Company;
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
        $batch->{id} = $payment->{batch_id};
        $batch->get;
        $payment->{batch_description} = $batch->{description};
        $payment->{batch_control_code} = $batch->{control_code};
    }

    $payment->{format_amount} = sub {return $payment->format_amount(@_); };

    if ($payment->{multiple}){
        $payment->{checks} = [];
        print "Multiple checks printing";
        for my $line (1 .. $payment->{contact_count}){
            my $id = $payment->{"contact_$line"};
            next if !defined $payment->{"id_$id"};
            my $check = LedgerSMB::DBObject::Company->new(
                                {base => $request, copy => 'base' }
            );
            $check->{entity_class} = $payment->{account_class};
            $check->{id} = $id;
            $check->get_billing_info;
            $check->{amount} = $check->parse_amount(amount => '0');
            $check->{invoices} = [];
            $check->{source} = $payment->{"source_$id"};

            my $inv_count; 

            if ($LedgerSMB::Sysconfig::check_max_invoices > 
                           $payment->{"invoice_count_$id"})
            {
                $inv_count = $payment->{"invoice_count_$id"};
            } else {
                $inv_count = $LedgerSMB::Sysconfig::check_max_invoices;
            }

            for my $inv (1 .. $inv_count){
		print STDERR "Invoice $inv of " .$payment->{"invoice_count_$id"} . "\n";
                my $invhash = {};
                my $inv_id = $payment->{"invoice_${id}_$inv"};
                for (qw(invnumber invdate)){
                    $invhash->{$_} = $payment->{"${_}_$inv_id"};
                }
                if ($payment->{"paid_$id"} eq 'some'){
                    $invhash->{paid} = $payment->parse_amount(amount => $payment->{"payment_$inv_id"});
                } elsif ($payment->{"paid_$id"} eq 'all'){
                    $invhash->{paid} = $payment->parse_amount(amount => $payment->{"net_$inv_id"});
                } else {
                    $payment->error("Invalid Payment Amount Option"); 
                }
                $check->{amount} += $invhash->{paid};
                $invhash->{paid} = $check->format_amount(amount => $invhash->{paid});
                push @{$check->{invoices}}, $invhash;
            }
            my $amt = $check->{amount}->copy;
            $amt->bfloor();
            $check->{text_amount} = $payment->text_amount($amt);
            $check->{amount} = $check->format_amount(amount => $check->{amount},
                                                     format => '1000.00');
            $check->{decimal} = $check->format_amount(amount => ($check->{amount} - $amt) * 100);
            push @{$payment->{checks}}, $check;
        }
        $template = LedgerSMB::Template->new(
            user => $payment->{_user}, template => 'check_multiple', 
            format => uc $payment->{'format'},
	    no_auto_output => 1,
            output_args => $payment,
        );
        try {
            $template->render($payment);
            $template->output(%$payment);
        }
        catch Error::Simple with {
            my $E = shift;
            $payment->error( $E->stacktrace );
        };

    } else {

    }

}

sub display_payments {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->get_payment_detail_data();
    for (@{$payment->{contact_invoices}}){
        $_->{total_due} = $payment->format_amount(amount =>  $_->{total_due});
    }

    @{$payment->{media_options}} = (
            {text  => $request->{_locale}->text('Screen'), 
             value => 'screen'});
    for (keys %LedgerSMB::Sysconfig::printer){
         push @{$payment->{media_options}}, 
              {text  => $_,
               value => $LedgerSMB::Sysconfig::printer{$_}};
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
    $template->render($payment);
}
  

=item payment

This method is used to set the filter screen and prints it, using the 
TT2 system. 

=back

=cut

sub payment {
 my ($request)    = @_;  
 my $locale       = $request->{_locale};
 my  $dbPayment = LedgerSMB::DBObject::Payment->new({'base' => $request});
# Lets get the project data... 
 my  @projectOptions; 
 my  @arrayOptions  = $dbPayment->list_open_projects();
  push @projectOptions, {}; #A blank field on the select box 
 for my $ref (0 .. $#arrayOptions) {
       push @projectOptions, { value => $arrayOptions[$ref]->{id}."--".$arrayOptions[$ref]->{projectnumber}."--".$arrayOptions[$ref]->{description},
                                text => $arrayOptions[$ref]->{projectnumber}."--".$arrayOptions[$ref]->{description}};
 }

# Lets get the departments data...
  my @departmentOptions;
  my $role =  $request->{type} eq 'receipt' ? 'P' : 'C';
  @arrayOptions = $dbPayment->list_departments($role);
  push @departmentOptions, {}; # A blank field on the select box
  for my $ref (0 .. $#arrayOptions) {
      push @departmentOptions, {  value => $arrayOptions[$ref]->{id}."--".$arrayOptions[$ref]->{description},
                                  text => $arrayOptions[$ref]->{description}};
  }
# Lets get the currencies (this uses the $dbPayment->{account_class} property)
 my @currOptions;
 @arrayOptions = $dbPayment->get_open_currencies(); 
 for my $ref (0 .. $#arrayOptions) {
     push @currOptions, { value => $arrayOptions[$ref]->{payments_get_open_currencies},
                           text => $arrayOptions[$ref]->{payments_get_open_currencies} };
 }
# Lets build filter by period
my $date = LedgerSMB::DBObject::Date->new({base => $request});
   $date->build_filter_by_period($locale);
# Lets set the data in a hash for the template system. :)    
my $select = {
  stylesheet => $request->{_user}->{stylesheet},
  login    => { name  => 'login', 
                value => $request->{_user}->{login}   },
  projects => {
    name => 'projects',
    options => \@projectOptions
  },
  department => {
    name => 'department',
    options => \@departmentOptions
  },
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
    text => $locale->text("Continue"),
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


=pod

=item payment1_5

This method is called between payment and payment2, it will search the database
for entity_credit_accounts that match the parameter, if only one is found it will
run unnoticed by the user, if more than one is found it will ask the user to pick 
one to handle the payment against

=back

=cut

sub payment1_5 {
my ($request)    = @_;  
my $locale       = $request->{_locale};
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
                                   name => $array_options[$ref]->{name}};
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
                       text => $locale->text("Continue")}
    };
    my $template;
     $template = LedgerSMB::Template->new(
     user     => $request->{_user},
     locale   => $request->{_locale},
     path     => 'UI/payments',
     template => 'payment1_5',
     format   => 'HTML' );
     eval {$template->render($select) };
     if ($@) { $request->error("$@");  } # PRINT ERRORS ON THE UI
 }

}

=pod

=item payment2

This method is used  for the payment module, it is a consecuence of the payment sub,
and its used for all the mechanics of an invoices payment module.

=back

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
my @array_options;
my @currency_options;
my $exchangerate;
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
# WE MUST PREPARE THE ENTITY INFORMATION
#@array_options = $Payment->get_vc_info();# IS THIS WORKING?

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
                       {text => $locale->text('Amount Due').$default_currency_text},
                       {text => $locale->text('To pay').$default_currency_text}
                       );
 # WE NEED TO KNOW IF WE ARE USING A CURRENCY THAT NEEDS AN EXCHANGERATE
 
 if ($default_currency ne $request->{curr} ) {
 # FIRST WE PUSH THE OTHER COLUMN HEADERS WE NEED    
     push @column_headers, {text => $locale->text('Exchange Rate')},
                           {text => $locale->text('Amount Due').$currency_text},
                           {text => $locale->text('To pay').$currency_text};
 # WE SET THEM IN THE RIGHT ORDER FOR THE TABLE INSIDE THE UI   
     @column_headers[6,7,8] = @column_headers[7,8,6];
 # DOES THE CURRENCY IN USE HAS AN EXCHANGE RATE?, IF SO 
 # WE MUST SET THE VALUE, OTHERWISE THE UI WILL HANDLE IT
   $exchangerate = $request->{exrate} ? 
                   $request->{exrate} :
                   $Payment->get_exchange_rate($request->{curr}, 
                   $request->{datepaid} ? $request->{datepaid} : $Payment->{current_date});
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
 push @column_headers, {text => 'X'};
# WE NEED TO QUERY THE DATABASE TO CHECK FOR OPEN INVOICES
# WE WONT DO ANYTHING IF WE DONT FIND ANY INVOICES, THE USER CAN STILL POST A PREPAYMENT
my @invoice_data;
my @topay_state; # WE WILL USE THIS TO HELP UI TO DETERMINE WHAT IS VISIBLE
@array_options  = $Payment->get_open_invoices(); 
my $unhandled_overpayment;
for my $ref (0 .. $#array_options) {
 if (  !$request->{"checkbox_$array_options[$ref]->{invoice_id}"}) {
# SHOULD I APPLY DISCCOUNTS?   
      $request->{"optional_discount_$array_options[$ref]->{invoice_id}"} = $request->{first_load}? "on":  $request->{"optional_discount_$array_options[$ref]->{invoice_id}"};
      
# LETS SET THE EXCHANGERATE VALUES
   my $due_fx; my $topay_fx_value;
   if ("$exchangerate") {
       $topay_fx_value =   $due_fx = $request->round_amount("$array_options[$ref]->{due}"/"$exchangerate");
       if ($request->{"optional_discount_$array_options[$ref]->{invoice_id}"}) {
       $topay_fx_value = $due_fx = $request->round_amount($due_fx - "$array_options[$ref]->{discount}"/"$exchangerate");
        }
   } else {
       $topay_fx_value = $due_fx = "N/A";
   }
# We need to check for unhandled overpayment, see the post function for details
# First we will see if the discount should apply?
     my  $temporary_discount = 0;
     if (($request->{"optional_discount_$array_options[$ref]->{invoice_id}"})&&($due_fx <=  $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} +  $request->round_amount($array_options[$ref]->{discount}/"$exchangerate"))) {
         $temporary_discount = $request->round_amount("$array_options[$ref]->{discount}"/"$exchangerate");
      } 
# We need to compute the unhandled_overpayment, notice that all the values inside the if already have 
# the exchangerate applied       
      if ( $due_fx <  $request->{"topay_fx_$array_options[$ref]->{invoice_id}"}) {
         # We need to store all the overpayments so we can use it on the screen
         $unhandled_overpayment = $request->round_amount($unhandled_overpayment + $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} - $due_fx );
         $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} = "$due_fx";
     }   
   push @invoice_data, {       invoice => { number => $array_options[$ref]->{invnumber},
                                            id     =>  $array_options[$ref]->{invoice_id},
                                            href   => 'ar.pl?id='."$array_options[$ref]->{invoice_id}"
                                           },  
                               invoice_date      => "$array_options[$ref]->{invoice_date}",
                               amount            => "$array_options[$ref]->{amount}",
                               due               => $request->{"optional_discount_$array_options[$ref]->{invoice_id}"}? "$array_options[$ref]->{due}" - "$array_options[$ref]->{discount}": "$array_options[$ref]->{due}",
                               paid              => "$array_options[$ref]->{amount}" - "$array_options[$ref]->{due}",
                               discount          => $request->{"optional_discount_$array_options[$ref]->{invoice_id}"} ? "$array_options[$ref]->{discount}" : 0 ,
                               optional_discount =>  $request->{"optional_discount_$array_options[$ref]->{invoice_id}"},
                               exchange_rate     => "$exchangerate",
                               due_fx            =>  "$due_fx", # This was set at the begining of the for statement
                               topay             => "$array_options[$ref]->{due}" - "$array_options[$ref]->{discount}",
                               source_text       =>  $request->{"source_text_$array_options[$ref]->{invoice_id}"},
                               optional          =>  $request->{"optional_pay_$array_options[$ref]->{invoice_id}"},
                               selected_account  =>  $request->{"account_$array_options[$ref]->{invoice_id}"},
                               selected_source   =>  $request->{"source_$array_options[$ref]->{invoice_id}"},
                               topay_fx          =>  { name  => "topay_fx_$array_options[$ref]->{invoice_id}",
                                                       value => $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} ? 
                                                           $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} eq 'N/A' ?
                                                           "$topay_fx_value" :
                                                           $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} :
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
my @overpayment_account = $Payment->list_overpayment_accounting();
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
# We need to set the availible media and format from printing
my @media_options;
push  @media_options, {value => 1, text => "Screen"};
if ($#{LedgerSMB::Sysconfig::printer}) {
    for (keys %{LedgerSMB::Sysconfig::printer}) {
      push  @media_options, {value => 1, text => $_};
    }
}  
#$request->error("@media_options");  
my @format_options;
push @format_options, {value => 1, text => "HTML"};
if (${LedgerSMB::Sysconfig::latex}) {
        push  @format_options, {value => 2, text => "PDF" }, {value => 3, text => "POSTSCRIPT" };
}    
# LETS BUILD THE SELECTION FOR THE UI
# Notice that the first data inside this selection is the firs_load, this
# will help payment2.html to know wether it is beeing called for the first time
my $select = {
  first_load => $request->{first_load},
  stylesheet => $request->{_user}->{stylesheet},
  header  =>  { text => $request->{type} eq 'receipt' ? $locale->text('Receipt') : $locale->text('Payment') },
  type    =>  { name  => 'type',
                value =>  $request->{type} },
  login    => { name  => 'login', 
                value => $request->{_user}->{login}   },
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
  rows		=>  \@invoice_data,
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
 overpayment_account => \@overpayment_account
};
my $template = LedgerSMB::Template->new(
  user     => $request->{_user},
  locale   => $request->{_locale},
  path     => 'UI/payments',
  template => 'payment2',
  format => 'HTML' );
eval {$template->render($select) };
 if ($@) { $request->error("$@");  } # PRINT ERRORS ON THE UI
}



=pod

=item post_payment

This method is used  for the payment module (not the bulk payment),
and its used for all the mechanics of storing a payment.

=back

=cut

sub post_payment {
my ($request) = @_;
my $locale       = $request->{_locale};
my $Payment = LedgerSMB::DBObject::Payment->new({'base' => $request});
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
$Payment->{gl_description} = $locale->text('This gl movement, is the result of a payment transaction');
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
@array_options = $Payment->get_entity_credit_account();# We need to know the disccount account
my $discount_account_id = $array_options[0]->{discount};
@array_options = $Payment->get_open_invoices(); 
for my $ref (0 .. $#array_options) {
 if (  !$request->{"checkbox_$array_options[$ref]->{invoice_id}"}) {
         # First i have to determine if discounts will apply
         # we will assume that a discount should apply only
         # if this is the last payment of an invoice
     my  $temporary_discount = 0;
     if (($request->{"optional_discount_$array_options[$ref]->{invoice_id}"})&&("$array_options[$ref]->{due}"/"$request->{exrate}" <=  $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} +  $array_options[$ref]->{discount})) {
         $temporary_discount = $array_options[$ref]->{discount};
     }   
         #
         # The prefix cash is to set the movements of the cash accounts, 
         # same names are used for ap/ar accounts w/o the cash prefix.
         #
     if ( "$array_options[$ref]->{due}"/"$request->{exrate}" <  $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} + $temporary_discount ) {
         # We need to store all the overpayments so we can use it on a new payment2 screen
         $unhandled_overpayment = $request->round_amount($unhandled_overpayment + $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} + $temporary_discount - $array_options[$ref]->{amount}) ;
         
     }
         if ($request->{"optional_discount_$array_options[$ref]->{invoice_id}"}) {
             push @amount, $array_options[$ref]->{discount};
             push @cash_account_id, $discount_account_id;
             push @source, $locale->text('Applied discount');
             push @transaction_id, $array_options[$ref]->{invoice_id};        
         }
         push @amount,   $request->{"topay_fx_$array_options[$ref]->{invoice_id}"}; # We'll use this for both cash and ap/ar accounts
         push @cash_account_id,  $request->{"optional_pay_$array_options[$ref]->{invoice_id}"} ? $request->{"account_$array_options[$ref]->{invoice_id}"} : $request->{account};
         push @source, $request->{"source1_$array_options[$ref]->{invoice_id}"}.' '.$request->{"source2_$array_options[$ref]->{invoice_id}"}; # We'll use this for both source and ap/ar accounts
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
     $request->{"overpayment_account_$i"} =~ /^(\d+)--*/;
     my $id = $1; 
     $request->{"overpayment_cash_account_$i"} =~ /^(\d+)--*/;
     my $cashid = $1; 
     push @op_amount, $request->{"overpayment_topay_$i"};
     push @op_cash_account_id, $cashid;
     push @op_source, $request->{"overpayment_source1_$i"}.' '.$request->{"overpayment_source2_$i"};
     push @op_memo, $request->{"overpayment_memo_$i"};
     push @op_account_id, $id;        
     } 
   }  
}
# Finally we store all the data inside the LedgerSMB::DBObject::Payment object. 
    $Payment->{cash_account_id}    =  $Payment->_db_array_scalars(@cash_account_id);
    $Payment->{amount}             =  $Payment->_db_array_scalars(@amount);
    $Payment->{source}             =  $Payment->_db_array_scalars(@source);
    $Payment->{transaction_id}     =  $Payment->_db_array_scalars(@transaction_id);
    $Payment->{op_amount}          =  $Payment->_db_array_scalars(@op_amount);
    $Payment->{op_cash_account_id} =  $Payment->_db_array_scalars(@op_cash_account_id);
    $Payment->{op_source}          =  $Payment->_db_array_scalars(@op_source);
    $Payment->{op_memo}            =  $Payment->_db_array_scalars(@op_memo);
    $Payment->{op_account_id}      =  $Payment->_db_array_scalars(@op_account_id);        
# Ok, hoping for the best...
    $Payment->post_payment();
# We've gotta print anything, in the near future this will redirect to a new payment.
    my $select = {}; 
    my $template = LedgerSMB::Template->new(
      user     => $request->{_user},
      locale   => $request->{_locale},
      path     => 'UI/payments',
      template => 'payment2',
      format => 'HTML' );
    eval {$template->render($select) };
    if ($@) { $request->error("$@");  } # PRINT ERRORS ON THE UI
                
}


eval { do "scripts/custom/payment.pl"};
1;
