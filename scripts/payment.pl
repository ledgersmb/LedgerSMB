=pod

=head1 NAME

LedgerSMB::Scripts::payment - LedgerSMB class defining the Controller functions for payment handling.

=head1 SYNOPSIS

Defines the controller functions and workflow logic for payment processing.

=head1 COPYRIGHT

Copyright (c) 2007, David Mora R and Christian Ceballos B.

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
use LedgerSMB::DBObject::Payment;
use LedgerSMB::DBObject::Date;
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
        $template = LedgerSMB::Template->new(
            user     => $request->{_user},
            locale   => $request->{_locale},
            path     => 'UI/payments',
            template => 'payments_filter',
            format   => 'HTML', 
        );
    }
    $template->render($payment);
}

sub display_payments {
    my ($request) = @_;
    my $payment =  LedgerSMB::DBObject::Payment->new({'base' => $request});
    $payment->get_payment_detail_data();
	$payment->debug({file => '/tmp/delme'});
    for (@{$payment->{contact_invoices}}){
        $_->{total_due} = $payment->format_amount(amount =>  $_->{total_due});
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
TT2 system. (hopefully it will... )

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

# Lets get the customer or vendor :)
 my @vcOptions;
 @arrayOptions = $dbPayment->get_open_accounts();
 for my $ref (0 .. $#arrayOptions) {
    push @vcOptions, { value => $arrayOptions[$ref]->{id}.'--'.$arrayOptions[$ref]->{name},
                       text => $arrayOptions[$ref]->{name}};
 }
# Lets get the open currencies (this uses the $dbPayment->{account_class} property)
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
  vendor_customer => {
    name => 'vendor-customer',
    options => \@vcOptions
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
    value => 'payment2', 
    text => $locale->text("Continue"),
  },
};
# Lets call upon the template system
my $template;

  $template = LedgerSMB::Template->new(
  user     => $request->{_user},
  locale   => $request->{_locale},
  path     => 'UI/payments',
  template => 'payment1',
  format => 'HTML', );
$template->render($select);# And finally, Lets print the screen :)
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
# TODO TODO TODO TODO TODO TODO TODO
($Payment->{entity_id}, $Payment->{company_name}) = split /--/ , $request->{'vendor-customer'};
# WE NEED TO RETRIEVE A BILLING LOCATION, THIS IS HARDCODED FOR NOW... Should we change it? 
$Payment->{location_class_id} = '1';
#$request->error($Payment->{entity_id});
my @vc_options;
@vc_options = $Payment->get_vc_info();
# TODO TODO TODO TODO TODO TODO TODO
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
@array_options = $Payment->get_vc_info();
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
     @column_headers[5,6,7] = @column_headers[6,7,5];
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

for my $ref (0 .. $#array_options) {
 if (  !$request->{"checkbox_$array_options[$ref]->{invoice_id}"}) {
# LETS SET THE EXCHANGERATE VALUES
   my $due_fx; my $topay_fx_value;
   if ("$exchangerate") {
       $topay_fx_value =   $due_fx = "$array_options[$ref]->{due}"/"$exchangerate";
   } else {
       $topay_fx_value = $due_fx = "N/A";
   }
   push @invoice_data, {       invoice => { number => $array_options[$ref]->{invnumber},
                                            id     =>  $array_options[$ref]->{invoice_id},
                                            href   => 'ar.pl?id='."$array_options[$ref]->{invoice_id}"
                                           },  
                               invoice_date      => "$array_options[$ref]->{invoice_date}",
                               amount            => "$array_options[$ref]->{amount}",
                               due               => "$array_options[$ref]->{due}",
                               paid              => "$array_options[$ref]->{amount}" - "$array_options[$ref]->{due}",
                               exchange_rate     => "$exchangerate",
                               due_fx            =>  $due_fx, # This was set at the begining of the for statement
                               topay             => "$array_options[$ref]->{due}",
                               source_text       =>  $request->{"source_text_$array_options[$ref]->{invoice_id}"},
                               optional          =>  $request->{"optional_pay_$array_options[$ref]->{invoice_id}"},
                               selected_account  =>  $request->{"account_$array_options[$ref]->{invoice_id}"},
                               selected_source   =>  $request->{"source_$array_options[$ref]->{invoice_id}"},
                               topay_fx          =>  { name  => "topay_fx_$array_options[$ref]->{invoice_id}",
                                                       value => $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} ? 
                                                           $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} eq 'N/A' ?
                                                           $topay_fx_value :
                                                           $request->{"topay_fx_$array_options[$ref]->{invoice_id}"} :
                                                           $topay_fx_value
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

        push @overpayment, {amount  => $request->{"overpayment_topay_$i"},
                                   source1 => $request->{"overpayment_source1_$i"},
                                   source2 => $request->{"overpayment_source2_$i"},
                                   account => { id          => $id,
                                                accno       => $accno,
                                                description => $description
                                              }  
                                  };
     } else {
      $i = $request->{overpayment_qty} + 1; 
     }
   }  
}  
# LETS BUILD THE SELECTION FOR THE UI
my $select = {
  stylesheet => $request->{_user}->{stylesheet},
  header  =>  { text => $request->{type} eq 'receipt' ? $locale->text('Receipt') : $locale->text('Payment') },
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
    options => [
      {value => 1, text => "HTML" },
      {value => 2, text => "PDF" },
      {value => 3, text => "POSTSCRIPT" }
    ],
  },
    media => {
    name => 'MEDIA',
    options => [
      {value => 1, text => "Screen" },
      {value => 2, text => "PRINTER" },
      {value => 3, text => "EMAIL" }
    ],
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


eval { do "scripts/custom/payment.pl"};
1;
