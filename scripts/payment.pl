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
#  path     => 'UI',
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
my   $dbPayment = LedgerSMB::DBObject::Payment->new({'base' => $request});

my @array_options;
# LETS GET THE CUSTOMER/VENDOR INFORMATION	
 ($dbPayment->{entity_id}, my $vendor_customer_name) = split /--/ , $request->{'vendor-customer'};

my @array_options;
my $exchangerate;

# LETS BUILD THE PROJECTS INFO
# I DONT KNOW IF I NEED ALL THIS, BUT AS IT IS AVAILABLE I'LL STORE IT FOR LATER USAGE.
my ($project_id, $project_number, $project_name)  = split /--/ ,  $request->{projects} ; 
my @project = { name => 'project',  text => $project_number.' '.$project_name,  value => $project_id   };
# LETS GET THE DEPARTMENT INFO
my ($department_id, $department_name)             = split /--/, $request->{department};
my @department = { name => 'department',  text => $department_name,  value => $department_id };
# LETS GET ALL THE ACCOUNTS
my @account_options;
@array_options = $dbPayment->list_accounting();
for my $ref (0 .. $#array_options) {
      push @account_options, {    value => $array_options[$ref]->{id},
                                  text =>  $array_options[$ref]->{description}};
}
# LETS GET THE POSSIBLE SOURCES
my @sources_options;
@array_options = $dbPayment->get_sources(\%$locale);
for my $ref (0 .. $#array_options) {
   push @sources_options, { value => $array_options[$ref],
                            text =>  $array_options[$ref]};
}
# WE MUST PREPARE THE ENTITY INFORMATION
  @array_options = $dbPayment->get_vc_info();
# LETS BUILD THE CURRENCIES INFORMATION 
# FIRST, WE NEED TO KNOW THE DEFAULT CURRENCY
my $default_currency = $dbPayment->get_default_currency(); 
my @currency_options;
# LETS BUILD THE COLUMN HEADERS WE ALWAYS NEED 
# THE OTHER HEADERS WILL BE BUILT IF THE RIGHT CONDITIONS ARE MET.
# -----------------------------------------------
# SOME USERS WONT USE MULTIPLE CURRENCIES, AND WONT LIKE THE FACT CURRENCY BEING
# ON THE SCREEN ALL THE TIME, SO IF THEY ARE USING THE DEFAULT CURRENCY WE WONT PRINT IT
my $currency_text  =  $request->{curr} eq $default_currency ? '' : '('.$request->{curr}.')';
my $default_currency_text = $currency_text ? '('.$default_currency.')' : '';

my @columnAS =  ({text => $locale->text('Invoice')},
                       {text => $locale->text('Date')},
                       {text => $locale->text('Total').$default_currency_text},
                       {text => $locale->text('Paid').$default_currency_text},
                       {text => $locale->text('Amount Due').$default_currency_text},
                       {text => $locale->text('To pay').$default_currency_text} 
                      );

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
       $exchangerate = $dbPayment->get_exchange_rate($request->{curr}, $dbPayment->{current_date});
   if ($exchangerate) {
     @currency_options = {
          name => 'date_curr',
          value => "$exchangerate", #THERE IS A STRANGE BEHAVIOUR WITH THIS, 
          text =>  "$exchangerate"  #IF I DONT USE THE DOUBLE QUOTES, IT WILL PRINT THE ADDRESS
                                    #THERE MUST BE A REASON FOR THIS, I MUST RETURN TO IT LATER
	  };
   } else {
   @currency_options = {
        name => 'date_curr'};
   }
 
 } else {
 # WE MUST SET EXCHANGERATE TO 1 FOR THE MATHS SINCE WE
 # ARE USING THE DEFAULT CURRENCY
   $exchangerate = 1;
 }
# WE NEED TO QUERY THE DATABASE TO CHECK FOR OPEN INVOICES
# IF WE DONT HAVE ANY INVOICES MATCHING THE FILTER PARAMETERS, WE WILL WARN THE USER AND STOP
# THE PROCCESS. 
my @invoice_data;
@array_options  = $dbPayment->get_open_invoices(); 
if (!$array_options[0]->{invoice_id}) { 
  $request->error($locale->text("Nothing to do"));
}
for my $ref (0 .. $#array_options) {
      push @invoice_data, {       invoice => { number => $array_options[$ref]->{invnumber},
                                               href   => 'ar.pl?id='."$array_options[$ref]->{invoice_id}"
                                              },  
                                  invoice_date  => "$array_options[$ref]->{invoice_date}",
                                  amount        => "$array_options[$ref]->{amount}",
                                  due           => "$array_options[$ref]->{due}",
                                  paid          => "$array_options[$ref]->{amount}" - "$array_options[$ref]->{due}",
                                  exchange_rate => "$exchangerate",
                                  due_fx        => "$exchangerate"? "$array_options[$ref]->{due}"/"$exchangerate" : 'N/A',
                                  topay         =>  "$array_options[$ref]->{due}",
                                  topay_fx      => { name  => "topay_fx_$ref",
                                                     value => "$exchangerate" ? "$array_options[$ref]->{due}"/"$exchangerate" : 'N/A'
                                                   }  
                                                     
                           };
}
# LETS BUILD THE SELECTION FOR THE UI
my $select = {
  stylesheet => $request->{_user}->{stylesheet},
  header  =>  { text => $request->{type} eq 'receipt' ? $locale->text('Receipt') : $locale->text('Payment') },
  project => @project,
  department => @department,
  account => { 
             name    => 'account',
             options => \@account_options},
  datepaid => {
	name => 'datepaid',
	value => $dbPayment->{current_date}
  },
  source => {
    name => 'source',
    options => \@sources_options
  },
  source_text => {

	name => 'source_text',
  },
  
  defaultcurrency => {
        text => $default_currency
  },
  curr => {
	  text => $request->{curr}  
  },
  column_headers => \@column_headers,
  rows		=>  \@invoice_data,
 
  vc => { name => $vendor_customer_name,
          address =>  [ {text => 'Crra 83 #32 -1'},
          	  {text => '442 6464'},
		  {text => 'Medellín'},
		  {text => 'Colombia'}]},
  
  post => {
    accesskey =>  'O',
    title     =>  'POST ALT+O',
    name => 'action',
    value => 'post', 
    text => "POST"
  },
  post_and_print => {
    accesskey =>  'R',
    title     =>  'POST AND PRINT ALT+R',
    name => 'action',
    value => 'post_and_print', 
    text => "POST AND PRINT"
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
 date_curr => @currency_options # I HAVE TO PUT THIS LAST, BECAUSE IT CAN BE NULL
                                # THIS IS AN UGLY HACK THAT MUST BE FIXED.  
};
my $template = LedgerSMB::Template->new(
  user     => $request->{_user},
  locale   => $request->{_locale},
#  path     => 'UI/payments',
  path => 'UI',
  template => 'payment2',
  format => 'HTML' );
eval {$template->render($select) };
if ($@) { $request->error("$@");  }
}
 
1;
