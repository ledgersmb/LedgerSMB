
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
=pod

=item payment

This method is used to set the filter screen and prints it, using the 
TT2 system. (hopefully it will... )

=back

=cut

sub payment {
 my ($request)    = @_;  
 my $locale       = $request->{_locale};
 my $templateData;
 my  $dbPayment = LedgerSMB::DBObject::Payment->new({'base' => $request});
# Lets get the project data... 
 my  @projectOptions; 
 my  @arrayOptions  = $dbPayment->list_open_projects();
 push @projectOptions, {}; #A blank field on the select box 
 for my $ref (0 .. $#arrayOptions) {
       push @projectOptions, { value => $arrayOptions[$ref]->{id},
                                text => $arrayOptions[$ref]->{projectnumber}."--".$arrayOptions[$ref]->{description}};
 }
# Lets get the departments data...
  my @departmentOptions;
  my $role =  $request->{type} eq 'receipt' ? 'P' : 'C';
  @arrayOptions = $dbPayment->list_departments($role);
  push @departmentOptions, {}; # A blank field on the select box
  for my $ref (0 .. $#arrayOptions) {
      push @departmentOptions, { value => $arrayOptions[$ref]->{id},
                                  text => $arrayOptions[$ref]->{description}};
  }
# Lets get the customer or vendor :)
 my @vcOptions;
 $dbPayment->{account_class} = $request->{type} eq 'receipt' ? 2 : 1;
 @arrayOptions = $dbPayment->get_open_accounts();
 for my $ref (0 .. $#arrayOptions) {
    push @vcOptions, { value => $arrayOptions[$ref]->{id},
                       text => $arrayOptions[$ref]->{description}};
 }
# Lets get the open currencies (this uses the $dbPayment->{account_class} property)
 my @currOptions;
 @arrayOptions = $dbPayment->get_open_currencies(); 
 for my $ref (0 .. $#arrayOptions) {
     push @arrayOptions, { value => $arrayOptions[$ref]->{id},
                           text => $arrayOptions[$ref]->{description}};
 }
# Lets build filter by period
my $date = LedgerSMB::DBObject::Date->new({base => $request});
   $date->build_filter_by_period($locale);
# Lets set the data in a hash for the template system. :)    
my $select = {
  stylesheet => $request->{_user}->{stylesheet},
  projects => {
    name => 'projects',
    options => \@projectOptions
  },
  department => {
    name => 'department',
    options => \@departmentOptions
  },
  customer => {
    name => 'customer',
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
	type => 'text',
	name => 'amountfrom',
	size => '10',
	maxlength => '10'
  },
  amountto => {
	type => 'text',
	name => 'amountto',
	size => '10',
	maxlength => '10'
  },
  sort => {
    type => 'hidden',
    value => 'sort_value'	
  },
  action => {
    name => 'action',
    value => 'continue', 
    text => $locale->text("Continue"),
  },

};
# Lets call upon the template system
my $template;

  $template = LedgerSMB::Template->new(
  user     => $request->{_user},
  locale   => $request->{_locale},
  path     => 'UI',
  template => 'payment1',
  format => 'HTML', );
$template->render($select);# And finally, Lets print the screen :)
}

1;
