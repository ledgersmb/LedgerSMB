#=====================================================================
# LedgerSMB Small Medium Business Accounting
# http://www.ledgersmb.org/
#

# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed 
# under the GNU General Public License version 2 or, at your option, any later 
# version.  For a full list including contact information of contributors, 
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (c) 2001
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
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
#======================================================================
#
# Order entry module
# Quotation module
#
#======================================================================


use LedgerSMB::OE;
use LedgerSMB::IR;
use LedgerSMB::IS;
use LedgerSMB::PE;
use LedgerSMB::Tax;
use LedgerSMB::Locale;

require "bin/arap.pl";
require "bin/io.pl";


1;
# end of main


sub add {

  if ($form->{type} eq 'purchase_order') {
    $form->{title} = $locale->text('Add Purchase Order');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_order') {
    $form->{title} = $locale->text('Add Sales Order');
    $form->{vc} = 'customer';
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Add Request for Quotation');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Add Quotation');
    $form->{vc} = 'customer';
  }

  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&vc=$form->{vc}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}" unless $form->{callback};

  $form->{rowcount} = 0;

  &order_links;
  &prepare_order;
  &display_form;

}


sub edit {
  
  if ($form->{type} =~ /(purchase_order|bin_list)/) {
    $form->{title} = $locale->text('Edit Purchase Order');
    $form->{vc} = 'vendor';
    $form->{type} = 'purchase_order';
  }
  if ($form->{type} =~ /((sales|work)_order|(packing|pick)_list)/) {
    $form->{title} = $locale->text('Edit Sales Order');
    $form->{vc} = 'customer';
    $form->{type} = 'sales_order';
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Edit Request for Quotation');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Edit Quotation');
    $form->{vc} = 'customer';
  }

  &order_links;
  &prepare_order;
  &display_form;
  
}



sub order_links {

  # retrieve order/quotation
  OE->retrieve(\%myconfig, \%$form);

  # get customer/vendor
  $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP", undef, $form->{transdate}, 1);
  
  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};
  $form->{currency} = $form->{defaultcurrency} unless $form->{currency};
  
  for (@curr) { $form->{selectcurrency} .= "<option>$_\n" }

  $form->{oldlanguage_code} = $form->{language_code};
  
  $l{language_code} = $form->{language_code};
  $l{searchitems} = 'nolabor' if $form->{vc} eq 'customer';
  
  $form->get_partsgroup(\%myconfig, \%l);
  
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "<option>\n";
    foreach $ref (@ { $form->{all_partsgroup} }) {
      if ($ref->{translation}) {
	$form->{selectpartsgroup} .= qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{translation}\n|;
      } else {
	$form->{selectpartsgroup} .= qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{partsgroup}\n|;
      }
    }
  }

  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "<option>\n";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n| }
  }
 
  if (@{ $form->{"all_$form->{vc}"} }) {
    unless ($form->{"$form->{vc}_id"}) {
      $form->{"$form->{vc}_id"} = $form->{"all_$form->{vc}"}->[0]->{id};
    }
  }
  
  for (qw(terms taxincluded)) { $temp{$_} = $form->{$_} }
  $form->{shipto} = 1 if $form->{id};
  
  # get customer / vendor
  AA->get_name(\%myconfig, \%$form);

  if ($form->{id}) {
    for (qw(terms taxincluded)) { $form->{$_} = $temp{$_} }
  }

  ($form->{$form->{vc}}) = split /--/, $form->{$form->{vc}};
  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;

  # build selection list
  $form->{"select$form->{vc}"} = "";
  if (@{ $form->{"all_$form->{vc}"} }) {
    $form->{$form->{vc}} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
    for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
  }
  
  # departments
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "<option>\n";
    $form->{department} = "$form->{department}--$form->{department_id}" if $form->{department_id};

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
  }

  $form->{employee} = "$form->{employee}--$form->{employee_id}";

  # sales staff
  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = "";
    for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
  }

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "<option>\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| }
  }
  
  # forex
  $form->{forex} = $form->{exchangerate};
  
}


sub prepare_order {

  $form->{format} = "postscript" if $myconfig{printer};
  $form->{media} = $myconfig{printer};
  $form->{formname} = $form->{type};
  $form->{sortby} ||= "runningnumber";
  $form->{currency} =~ s/ //g;
  $form->{oldcurrency} = $form->{currency};
  
  if ($form->{id}) {
    
    for (qw(ordnumber quonumber shippingpoint shipvia notes intnotes shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact)) { $form->{$_} = $form->quote($form->{$_}) }
    
    foreach $ref (@{ $form->{form_details} } ) {
      $i++;
      for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }

      $form->{"projectnumber_$i"} = qq|$ref->{projectnumber}--$ref->{project_id}| if $ref->{project_id};
      $form->{"partsgroup_$i"} = qq|$ref->{partsgroup}--$ref->{partsgroup_id}| if $ref->{partsgroup_id};

      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"} * 100);

      ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces = ($dec > 2) ? $dec : 2;
      
      for (map { "${_}_$i" } qw(sellprice listprice)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $decimalplaces) }

      ($dec) = ($form->{"lastcost_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces = ($dec > 2) ? $dec : 2;

      $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces);
      
      $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});
      $form->{"oldqty_$i"} = $form->{"qty_$i"};
      
      for (qw(partnumber sku description unit)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }
      $form->{rowcount} = $i;
    }
  }

  $form->{oldtransdate} = $form->{transdate};

  if ($form->{type} eq 'sales_quotation') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Quotations--Quotation/;
    }
    
    $form->{selectformname} = qq|<option value="sales_quotation">|.$locale->text('Quotation');
  }
  
  if ($form->{type} eq 'request_quotation') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Quotations--RFQ/;
    }
    
    $form->{selectformname} = qq|<option value="request_quotation">|.$locale->text('RFQ');
  }
  
  if ($form->{type} eq 'sales_order') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Order Entry--Sales Order/;
    }
    
    $form->{selectformname} = qq|<option value="sales_order">|.$locale->text('Sales Order').qq| 
    <option value="work_order">|.$locale->text('Work Order').qq|
    <option value="pick_list">|.$locale->text('Pick List').qq|
    <option value="packing_list">|.$locale->text('Packing List');
  }
  
  if ($form->{type} eq 'purchase_order') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Order Entry--Purchase Order/;
    }
    
    $form->{selectformname} = qq|<option value="purchase_order">|.$locale->text('Purchase Order').qq| 
    <option value="bin_list">|.$locale->text('Bin List');
  }

  if ($form->{type} eq 'ship_order') {
    $form->{selectformname} = qq|<option value="pick_list">|.$locale->text('Pick List').qq| 
    <option value="packing_list">|.$locale->text('Packing List');
  }
  
  if ($form->{type} eq 'receive_order') {
    $form->{selectformname} = qq|<option value="bin_list">|.$locale->text('Bin List');
  }

}


sub form_header {

  $checkedopen = ($form->{closed}) ? "" : "checked";
  $checkedclosed = ($form->{closed}) ? "checked" : "";

  if ($form->{id}) {
    $openclosed = qq|
      <tr>
	<th nowrap align=right><input name=closed type=radio class=radio value=0 $checkedopen> |.$locale->text('Open').qq|</th>
	<th nowrap align=left><input name=closed type=radio class=radio value=1 $checkedclosed> |.$locale->text('Closed').qq|</th>
      </tr>
|;
  }

  # set option selected
  $form->{selectcurrency} =~ s/ selected//;
  $form->{selectcurrency} =~ s/option>\Q$form->{currency}\E/option selected>$form->{currency}/; 
  
  for ("$form->{vc}", "department", "employee") {
    $form->{"select$_"} = $form->unescape($form->{"select$_"});
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
  }
  
    
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $exchangerate = qq|<tr>|;
  $exchangerate .= qq|
                <th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select name=currency>$form->{selectcurrency}</select></td> | if $form->{defaultcurrency};
  $exchangerate .= qq|
                <input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
|;

  if ($form->{defaultcurrency} && $form->{currency} ne $form->{defaultcurrency}) {
    if ($form->{forex}) {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchange Rate').qq|</th><td>$form->{exchangerate}</td>
      <input type=hidden name=exchangerate value=$form->{exchangerate}>
|;
    } else {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchange Rate').qq|</th><td><input name=exchangerate size=10 value=$form->{exchangerate}></td>|;
    }
  }
  $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
</tr>
|;



  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);

  $terms = qq|
                    <tr>
		      <th align=right nowrap>|.$locale->text('Terms').qq|</th>
		      <td nowrap><input name=terms size="3" maxlength="3" value=$form->{terms}> |.$locale->text('days').qq|</td>
                    </tr>
|;


  if ($form->{business}) {
    $business = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Business').qq|</th>
		<td colspan=3>$form->{business}
		&nbsp;&nbsp;&nbsp;|;
    $business .= qq|
		<b>|.$locale->text('Trade Discount').qq|</b>
		|.$form->format_amount(\%myconfig, $form->{tradediscount} * 100).qq| %| if $form->{vc} eq 'customer';
    $business .= qq|</td>
	      </tr>
|;
  }

  if ($form->{type} !~ /_quotation$/) {
    $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('Order Number').qq|</th>
                <td><input name=ordnumber size=20 value="$form->{ordnumber}"></td>
		<input type=hidden name=quonumber value="$form->{quonumber}">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Date').qq|</th>
		<td><input name=transdate size=11 title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap=true>|.$locale->text('Required by').qq|</th>
		<td><input name=reqdate size=11 title="$myconfig{dateformat}" value=$form->{reqdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('PO Number').qq|</th>
		<td><input name=ponumber size=20 value="$form->{ponumber}"></td>
	      </tr>
|;
    
    $n = ($form->{creditremaining} < 0) ? "0" : "1";
    
    $creditremaining = qq|
	      <tr>
		<td></td>
		<td colspan=3>
		  <table>
		    <tr>
		      <th align=right nowrap>|.$locale->text('Credit Limit').qq|</th>
		      <td>|.$form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0").qq|</td>
		      <td width=10></td>
		      <th align=right nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n" nowrap>|.$form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0").qq|</td>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
  } else {
    $reqlabel = ($form->{type} eq 'sales_quotation') ? $locale->text('Valid until') : $locale->text('Required by');
    if ($form->{type} eq 'sales_quotation') {
      $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('Quotation Number').qq|</th>
		<td><input name=quonumber size=20 value="$form->{quonumber}"></td>
		<input type=hidden name=ordnumber value="$form->{ordnumber}">
	      </tr>
|;
    } else {
      $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('RFQ Number').qq|</th>
		<td><input name=quonumber size=20 value="$form->{quonumber}"></td>
		<input type=hidden name=ordnumber value="$form->{ordnumber}">
	      </tr>
|;

      $terms = "";
    }
     

    $ordnumber .= qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Quotation Date').qq|</th>
		<td><input name=transdate size=11 title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap=true>$reqlabel</th>
		<td><input name=reqdate size=11 title="$myconfig{dateformat}" value=$form->{reqdate}></td>
	      </tr>
|;

  }

  $ordnumber .= qq|
<input type=hidden name=oldtransdate value=$form->{oldtransdate}>|;

  if ($form->{"select$form->{vc}"}) {
    $vc = qq|<select name=$form->{vc}>$form->{"select$form->{vc}"}</select>
             <input type=hidden name="select$form->{vc}" value="|
	     .$form->escape($form->{"select$form->{vc}"},1).qq|">|;
  } else {
    $vc = qq|<input name=$form->{vc} value="$form->{$form->{vc}}" size=35>|;
  }

  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td colspan=3><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|
		.$form->escape($form->{selectdepartment},1).qq|">
		</td>
	      </tr>
| if $form->{selectdepartment};

  $employee = qq|
              <input type=hidden name=employee value="$form->{employee}">
|;

  if ($form->{type} eq 'sales_order') {
    if ($form->{selectemployee}) {
      $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|"
	      </tr>
|;
    }
  } else {
    if ($form->{selectemployee}) {
      $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Employee').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|"
	      </tr>
|;
    }
  }

  $i = $form->{rowcount} + 1;
  $focus = "partnumber_$i";
  
  $form->header;
  
  print qq|
<body onLoad="document.forms[0].${focus}.focus()" />

<form method=post action="$form->{script}">
|;

  $form->hide_form(qw(id type formname media format printed emailed queued vc title discount creditlimit creditremaining tradediscount business recurring));

  print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
	  <td>
	    <table width=100%>
	      <tr>
		<th align=right>$vclabel</th>
		<td colspan=3>$vc</td>
		<input type=hidden name=$form->{vc}_id value=$form->{"$form->{vc}_id"}>
		<input type=hidden name="old$form->{vc}" value="$form->{"old$form->{vc}"}">
	      </tr>
	      $creditremaining
	      $business
	      $department
	      $exchangerate
	      <tr>
		<th align=right>|.$locale->text('Shipping Point').qq|</th>
		<td colspan=3><input name=shippingpoint size=35 value="$form->{shippingpoint}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Ship via').qq|</th>
		<td colspan=3><input name=shipvia size=35 value="$form->{shipvia}"></td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $openclosed
	      $employee
	      $ordnumber
	      $terms
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

|;

  $form->hide_form(qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts));

  for (split / /, $form->{taxaccounts}) {
    print qq|
<input type=hidden name="${_}_rate" value=$form->{"${_}_rate"}>
<input type=hidden name="${_}_description" value="$form->{"${_}_description"}">
|;
  }

}


sub form_footer {

  $form->{invtotal} = $form->{invsubtotal};

  if (($rows = $form->numtextrows($form->{notes}, 35, 8)) < 2) {
    $rows = 2;
  }
  if (($introws = $form->numtextrows($form->{intnotes}, 35, 8)) < 2) {
    $introws = 2;
  }
  $rows = ($rows > $introws) ? $rows : $introws;
  $notes = qq|<textarea name=notes rows=$rows cols=35 wrap=soft>$form->{notes}</textarea>|;
  $intnotes = qq|<textarea name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;


  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";

  $taxincluded = "";
  if ($form->{taxaccounts}) {
    $taxincluded = qq|
            <tr height="5"></tr>
            <tr>
	      <td align=right>
	      <input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
	      <th align=left>|.$locale->text('Tax Included').qq|</th>
	    </tr>
|;
  }

  if (!$form->{taxincluded}) {
    
      my @taxes = Tax::init_taxes($form, $form->{taxaccounts});
      $form->{invtotal} += Tax::calculate_taxes(\@taxes, 
        $form, $form->{invsubtotal}, 0);
      foreach my $item (@taxes) {
        my $taccno = $item->account;
	$form->{"${taccno}_total"} = $form->format_amount(\%myconfig, 
	  $item->value, 2);
	
	$tax .= qq|
	      <tr>
		<th align=right>$form->{"${taccno}_description"}</th>
		<td align=right>$form->{"${taccno}_total"}</td>
	      </tr>
	      | if $item->value;
      }

    $form->{invsubtotal} = $form->format_amount(\%myconfig, $form->{invsubtotal}, 2, 0);
    
    $subtotal = qq|
	      <tr>
		<th align=right>|.$locale->text('Subtotal').qq|</th>
		<td align=right>$form->{invsubtotal}</td>
	      </tr>
|;

  }

  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2, 0);


  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=left>|.$locale->text('Notes').qq|</th>
		<th align=left>|.$locale->text('Internal Notes').qq|</th>
	      </tr>
	      <tr valign=top>
		<td>$notes</td>
		<td>$intnotes</td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $subtotal
	      $tax
	      <tr>
		<th align=right>|.$locale->text('Total').qq|</th>
		<td align=right>$form->{invtotal}</td>
	      </tr>
	      $taxincluded
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
<input type=hidden name=oldinvtotal value=$form->{oldinvtotal}>
<input type=hidden name=oldtotalpaid value=$totalpaid>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

  &print_options;

  print qq|
    </td>
  </tr>
</table>

<br>
|;

# type=submit $locale->text('Update')
# type=submit $locale->text('Print')
# type=submit $locale->text('Schedule')
# type=submit $locale->text('Save')
# type=submit $locale->text('Print and Save')
# type=submit $locale->text('Ship to')
# type=submit $locale->text('Save as new')
# type=submit $locale->text('Print and Save as new')
# type=submit $locale->text('E-mail')
# type=submit $locale->text('Delete')
# type=submit $locale->text('Sales Invoice')
# type=submit $locale->text('Vendor Invoice')
# type=submit $locale->text('Quotation')
# type=submit $locale->text('RFQ')
# type=submit $locale->text('Sales Order')
# type=submit $locale->text('Purchase Order')

  if (! $form->{readonly}) {
    %button = ('update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'print' => { ndx => 2, key => 'P', value => $locale->text('Print') },
	       'save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
	       'ship_to' => { ndx => 4, key => 'T', value => $locale->text('Ship to') },
	       'e_mail' => { ndx => 5, key => 'E', value => $locale->text('E-mail') },
	       'print_and_save' => { ndx => 6, key => 'R', value => $locale->text('Print and Save') },
	       'save_as_new' => { ndx => 7, key => 'N', value => $locale->text('Save as new') },
	       'print_and_save_as_new' => { ndx => 8, key => 'W', value => $locale->text('Print and Save as new') },
	       'sales_invoice' => { ndx => 9, key => 'I', value => $locale->text('Sales Invoice') },
	       'sales_order' => { ndx => 10, key => 'O', value => $locale->text('Sales Order') },
	       'quotation' => { ndx => 11, key => 'Q', value => $locale->text('Quotation') },
	       'vendor_invoice' => { ndx => 12, key => 'I', value => $locale->text('Vendor Invoice') },
	       'purchase_order' => { ndx => 13, key => 'O', value => $locale->text('Purchase Order') },
	       'rfq' => { ndx => 14, key => 'Q', value => $locale->text('RFQ') },
	       'schedule' => { ndx => 15, key => 'H', value => $locale->text('Schedule') },
	       'delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
	      );


    %a = ();
    for ("update", "ship_to", "print", "e_mail", "save") { $a{$_} = 1 }
    $a{'print_and_save'} = 1 if ${LedgerSMB::Sysconfig::latex};
    
    if ($form->{id}) {
      
      $a{'delete'} = 1;
      $a{'save_as_new'} = 1;
      $a{'print_and_save_as_new'} = 1 if ${LedgerSMB::Sysconfig::latex};

      if ($form->{type} =~ /sales_/) {
	if ($myconfig{acs} !~ /AR--Sales Invoice/) {
	  $a{'sales_invoice'} = 1;
	}
      } else {
	if ($myconfig{acs} !~ /AP--Vendor Invoice/) {
	  $a{'vendor_invoice'} = 1;
	}
      }
	
      if ($form->{type} eq 'sales_order') {
        if ($myconfig{acs} !~ /Quotations--RFQ/) {
	  $a{'quotation'} = 1;
	}
      }
      
      if ($form->{type} eq 'purchase_order') {
	if ($myconfig{acs} !~ /Quotations--RFQ/) {
	  $a{'rfq'} = 1;
	}
      }
      
      if ($form->{type} eq 'sales_quotation') {
	if ($myconfig{acs} !~ /Order Entry--Sales Order/) {
	  $a{'sales_order'} = 1;
	}
      }
      
      if ($myconfig{acs} !~ /Order Entry--Purchase Order/) {
	if ($form->{type} eq 'request_quotation') {
	  $a{'purchase_order'} = 1;
	}
      }
    }

    if ($form->{type} =~ /_order/) {
      $a{'schedule'} = 1;
    }

  }

  for (keys %button) { delete $button{$_} if ! $a{$_} }
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  $form->hide_form(qw(rowcount callback path login sessionid));
  
  print qq| 
</form>

</body>
</html>
|;

}


sub update {

  if ($form->{type} eq 'generate_purchase_order') {
    
    for (1 .. $form->{rowcount}) {
      if ($form->{"ndx_$_"}) {
	$form->{"$form->{vc}_id_$_"} = $form->{"$form->{vc}_id"};
	$form->{"$form->{vc}_$_"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
      }
    }
    
    &po_orderitems;
    exit;
  }
  
  $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});

  if ($form->{vc} eq 'customer') {
    $buysell = "buy";
    $ARAP = "AR";
  } else {
    $buysell = "sell";
    $ARAP = "AP";
  }

  if ($newname = &check_name($form->{vc})) {
    &rebuild_vc($form->{vc}, $ARAP, $form->{transdate}, 1);
  }

  if ($form->{transdate} ne $form->{oldtransdate}) {
    $form->{reqdate} = ($form->{terms}) ? $form->current_date(\%myconfig, $form->{transdate}, $form->{terms} * 1) : $form->{reqdate};
    $form->{oldtransdate} = $form->{transdate};
    &rebuild_vc($form->{vc}, $ARAP, $form->{transdate}, 1) if ! $newname;

    if ($form->{currency} ne $form->{defaultcurrency}) {
      delete $form->{exchangerate};
      $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell)));
    }

    $form->{selectemployee} = "";
    if (@{ $form->{all_employee} }) {
      for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
    }
  }


  if ($form->{currency} ne $form->{oldcurrency}) {
    delete $form->{exchangerate};
    $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell)));
  }
    
  my $i = $form->{rowcount};
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

  for (qw(partsgroup projectnumber)) {
    $form->{"select$_"} = $form->unescape($form->{"select$_"}) if $form->{"select$_"};
  }

  if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq "")) {

    $form->{creditremaining} += ($form->{oldinvtotal} - $form->{oldtotalpaid});
    &check_form;
    
  } else {

    $retrieve_item = "";
    if ($form->{type} eq 'purchase_order' || $form->{type} eq 'request_quotation') {
      $retrieve_item = "IR::retrieve_item";
    }
    if ($form->{type} eq 'sales_order' || $form->{type} eq 'sales_quotation') {
      $retrieve_item = "IS::retrieve_item";
    }

    &{ "$retrieve_item" }("", \%myconfig, \%$form);
    
    $rows = scalar @{ $form->{item_list} };

    if ($form->{language_code} && $rows == 0) {
      $language_code = $form->{language_code};
      $form->{language_code} = "";
      if ($retrieve_item) {
	&{ "$retrieve_item" }("", \%myconfig, \%$form);
      }
      $form->{language_code} = $language_code;
      $rows = scalar @{ $form->{item_list} };
    }
    
    if ($rows) {
      
      if ($rows > 1) {
	
	&select_item;
	exit;
	
      } else {

        $form->{"qty_$i"} = ($form->{"qty_$i"} * 1) ? $form->{"qty_$i"} : 1;
	$form->{"reqdate_$i"}	= $form->{reqdate} if $form->{type} ne 'sales_quotation';
	$sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
	
	for (qw(partnumber description unit)) { $form->{item_list}[$i]{$_} = $form->quote($form->{item_list}[$i]{$_}) }
	for (keys %{ $form->{item_list}[0] }) { $form->{"${_}_$i"} = $form->{item_list}[0]{$_} }

        $form->{"discount_$i"} = $form->{discount} * 100;
	
        if ($sellprice) {
	  $form->{"sellprice_$i"} = $sellprice;
	  
	  ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
	  $dec = length $dec;
	  $decimalplaces1 = ($dec > 2) ? $dec : 2;
	} else {
	  ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
	  $dec = length $dec;
	  $decimalplaces1 = ($dec > 2) ? $dec : 2;

	  $form->{"sellprice_$i"} /= $exchangerate;
	}
	
	($dec) = ($form->{"lastcost_$i"} =~ /\.(\d+)/);
	$dec = length $dec;
	$decimalplaces2 = ($dec > 2) ? $dec : 2;

	for (qw(listprice lastcost)) { $form->{"${_}_$i"} /= $exchangerate }

	$amount = $form->{"sellprice_$i"} * $form->{"qty_$i"} * (1 - $form->{"discount_$i"} / 100);
	for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0 }
	for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
	if (!$form->{taxincluded}) {
	  my @taxes = Tax::init_taxes($form, $form->{taxaccounts});
	  $amount += Tax::calculate_taxes(\@taxes, $form, $amount, 0);
	}
	
	$form->{creditremaining} -= $amount;

	for (qw(sellprice listprice)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces1) }
	$form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces2);
	
	$form->{"oldqty_$i"} = $form->{"qty_$i"};
	for (qw(qty discount)) { $form->{"{_}_$i"} =  $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }

      }

      &display_form;

    } else {
      # ok, so this is a new part
      # ask if it is a part or service item

      if ($form->{"partsgroup_$i"} && ($form->{"partsnumber_$i"} eq "") && ($form->{"description_$i"} eq "")) {
	$form->{rowcount}--;
	&display_form;
      } else {
		
	$form->{"id_$i"}	= 0;
	$form->{"unit_$i"}	= $locale->text('ea');
	&new_item;

      }
    }
  }

}



sub search {

  $requiredby = $locale->text('Required by');

  if ($form->{type} eq 'purchase_order') {
    $form->{title} = $locale->text('Purchase Orders');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
  
  if ($form->{type} eq 'receive_order') {
    $form->{title} = $locale->text('Receive Merchandise');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
  
  if ($form->{type} eq 'generate_sales_order') {
    $form->{title} = $locale->text('Generate Sales Order from Purchase Orders');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
  
  if ($form->{type} eq 'consolidate_sales_order') {
    $form->{title} = $locale->text('Consolidate Sales Orders');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }

  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Request for Quotations');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('RFQ Number');
    $ordnumber = 'quonumber';
    $employee = $locale->text('Employee');
  }
  
  if ($form->{type} eq 'sales_order') {
    $form->{title} = $locale->text('Sales Orders');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }
  
  if ($form->{type} eq 'ship_order') {
    $form->{title} = $locale->text('Ship Merchandise');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }
  
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Quotations');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Quotation Number');
    $ordnumber = 'quonumber';
    $employee = $locale->text('Employee');
    $requiredby = $locale->text('Valid until');
  }

  if ($form->{type} eq 'generate_purchase_order') {
    $form->{title} = $locale->text('Generate Purchase Orders from Sales Order');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }
  
  if ($form->{type} eq 'consolidate_purchase_order') {
    $form->{title} = $locale->text('Consolidate Purchase Orders');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
 
  $l_employee = qq|<input name="l_employee" class=checkbox type=checkbox value=Y> $employee|;
  $l_manager = qq|<input name="l_manager" class=checkbox type=checkbox value=Y> |.$locale->text('Manager');

  if ($form->{type} =~ /(ship|receive)_order/) {
    OE->get_warehouses(\%myconfig, \%$form);

    $l_manager = "";

    # warehouse
    if (@{ $form->{all_warehouse} }) {
      $form->{selectwarehouse} = "<option>\n";
      $form->{warehouse} = qq|$form->{warehouse}--$form->{warehouse_id}|;

      for (@{ $form->{all_warehouse} }) { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }

      $warehouse = qq|
	      <tr>
		<th align=right>|.$locale->text('Warehouse').qq|</th>
		<td><select name=warehouse>$form->{selectwarehouse}</select></td>
		<input type=hidden name=selectwarehouse value="|.
		$form->escape($form->{selectwarehouse},1).qq|">
	      </tr>
|;

    }
  }

  # setup vendor / customer selection
  $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP");

  for (@{ $form->{"all_$form->{vc}"} }) { $vc .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }

  $selectemployee = "";
  if (@{ $form->{all_employee} }) {
    $selectemployee = "<option>\n";
    for (@{ $form->{all_employee} }) { $selectemployee .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }

    $selectemployee = qq|
      <tr>
	<th align=right>$employee</th>
	<td colspan=3><select name=employee>$selectemployee</select></td>
      </tr>
|;
  } else {
    $l_employee = $l_manager = "";
  }

  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);
  
# $locale->text('Vendor')
# $locale->text('Customer')
  
  $vc = ($vc) ? qq|<select name=$form->{vc}><option>\n$vc</select>| : qq|<input name=$form->{vc} size=35>|;

  # departments  
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "<option>\n";

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
  }

  $department = qq|  
        <tr>  
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td colspan=3><select name=department>$form->{selectdepartment}</select></td>
	</tr>
| if $form->{selectdepartment}; 

  if ($form->{type} =~ /(consolidate.*|generate.*|ship|receive)_order/) {
     
    $openclosed = qq|
	        <input type=hidden name="open" value=1>
|;

  } else {
   
    $openclosed = qq|
	      <tr>
	        <td nowrap><input name="open" class=checkbox type=checkbox value=1 checked> |.$locale->text('Open').qq|</td>
	        <td nowrap><input name="closed" class=checkbox type=checkbox value=1 $form->{closed}> |.$locale->text('Closed').qq|</td>
	      </tr>
|;
  }

  if (@{ $form->{all_years} }) {
    # accounting years
    $form->{selectaccountingyear} = "<option>\n";
    for (@{ $form->{all_years} }) { $form->{selectaccountingyear} .= qq|<option>$_\n| }
    $form->{selectaccountingmonth} = "<option>\n";
    for (sort keys %{ $form->{all_month} }) { $form->{selectaccountingmonth} .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	<th align=right>|.$locale->text('Period').qq|</th>
	<td colspan=3>
	<select name=month>$form->{selectaccountingmonth}</select>
	<select name=year>$form->{selectaccountingyear}</select>
	<input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	<input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	<input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	<input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	</td>
      </tr>
|;
  }

  if ($form->{type} =~ /_order/) {
    $ponumber = qq|
        <tr>
          <th align=right>|.$locale->text('PO Number').qq|</th>
          <td colspan=3><input name="ponumber" size=20></td>
        </tr>
|;


    $l_ponumber = qq|<input name="l_ponumber" class=checkbox type=checkbox value=Y> |.$locale->text('PO Number');
  }

  @a = ();
  push @a, qq|<input name="l_runningnumber" class=checkbox type=checkbox value=Y> |.$locale->text('No.');
  push @a, qq|<input name="l_id" class=checkbox type=checkbox value=Y> |.$locale->text('ID');
  push @a, qq|<input name="l_$ordnumber" class=checkbox type=checkbox value=Y checked> $ordlabel|;
  push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Date');
  push @a, $l_ponumber if $l_ponumber;
  push @a, qq|<input name="l_reqdate" class=checkbox type=checkbox value=Y checked> $requiredby|;
  push @a, qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $vclabel|;
  push @a, $l_employee if $l_employee;
  push @a, $l_manager if $l_manager;
  push @a, qq|<input name="l_shipvia" class=checkbox type=checkbox value=Y> |.$locale->text('Ship via');
  push @a, qq|<input name="l_netamount" class=checkbox type=checkbox value=Y> |.$locale->text('Amount');
  push @a, qq|<input name="l_tax" class=checkbox type=checkbox value=Y> |.$locale->text('Tax');
  push @a, qq|<input name="l_amount" class=checkbox type=checkbox value=Y checked> |.$locale->text('Total');
  push @a, qq|<input name="l_curr" class=checkbox type=checkbox value=Y checked> |.$locale->text('Currency');


  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
          <th align=right>$vclabel</th>
          <td colspan=3>$vc</td>
        </tr>
	$warehouse
	$department
	$selectemployee
        <tr>
          <th align=right>$ordlabel</th>
          <td colspan=3><input name="$ordnumber" size=20></td>
        </tr>
	$ponumber
        <tr>
          <th align=right>|.$locale->text('Ship via').qq|</th>
          <td colspan=3><input name="shipvia" size=40></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name="description" size=40></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('From').qq|</th>
          <td><input name=transdatefrom size=11 title="$myconfig{dateformat}"></td>
          <th align=right>|.$locale->text('To').qq|</th>
          <td><input name=transdateto size=11 title="$myconfig{dateformat}"></td>
        </tr>
        <input type=hidden name=sort value=transdate>
	$selectfrom
        <tr>
          <th align=right>|.$locale->text('Include in Report').qq|</th>
          <td colspan=3>
	    <table>
	      $openclosed
|;

  while (@a) {
    for (1 .. 5) {
      print qq|<td nowrap>|. shift @a;
      print qq|</td>\n|;
    }
    print qq|</tr>\n|;
  }

  print qq|
	      <tr>
	        <td><input name="l_subtotal" class=checkbox type=checkbox value=Y> |.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td colspan=4><hr size=3 noshade></td></tr>
</table>

<br>
<input type=hidden name=nextsub value=transactions>
|;

  $form->hide_form(qw(path login sessionid vc type));
  
  print qq|
<button class="submit" type="submit" name="action" value="continue">|.$locale->text('Continue').qq|</button>
</form>
|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub transactions {
  
  # split vendor / customer
  ($form->{$form->{vc}}, $form->{"$form->{vc}_id"}) = split(/--/, $form->{$form->{vc}});

  OE->transactions(\%myconfig, \%$form);
  
  $ordnumber = ($form->{type} =~ /_order/) ? 'ordnumber' : 'quonumber';
  $name = $form->escape($form->{$form->{vc}});
  $name .= qq|--$form->{"$form->{vc}_id"}| if $form->{"$form->{vc}_id"};
  
  # construct href
  $href = qq|$form->{script}?action=transactions|;
  for ("oldsort", "direction", "path", "type", "vc", "login", "sessionid", "transdatefrom", "transdateto", "open", "closed") { $href .= qq|&$_=$form->{$_}| }
  for ("$ordnumber", "department", "warehouse", "shipvia", "ponumber", "description", "employee") { $href .= qq|&$_=|.$form->escape($form->{$_}) }
  $href .= "&$form->{vc}=$name";

  # construct callback
  $name = $form->escape($form->{$form->{vc}},1);
  $name .= qq|--$form->{"$form->{vc}_id"}| if $form->{"$form->{vc}_id"};
  
  # flip direction
  $form->sort_order();
  
  $callback = qq|$form->{script}?action=transactions|;
  for ("oldsort", "direction", "path", "type", "vc", "login", "sessionid", "transdatefrom", "transdateto", "open", "closed") { $callback .= qq|&$_=$form->{$_}| }
  for ("$ordnumber", "department", "warehouse", "shipvia", "ponumber", "description", "employee") { $callback .= qq|&$_=|.$form->escape($form->{$_},1) }
  $callback .= "&$form->{vc}=$name";


  @columns = $form->sort_columns("transdate", "reqdate", "id", "$ordnumber", "ponumber", "name", "netamount", "tax", "amount", "curr", "employee", "manager", "shipvia", "open", "closed");
  unshift @columns, "runningnumber";

  $form->{l_open} = $form->{l_closed} = "Y" if ($form->{open} && $form->{closed}) ;

  for (@columns) {
    if ($form->{"l_$_"} eq "Y") {
      push @column_index, $_;

      if ($form->{l_curr} && $_ =~ /(amount|tax)/) {
	push @column_index, "fx_$_";
      }
      
      # add column to href and callback
      $callback .= "&l_$_=Y";
      $href .= "&l_$_=Y";
    }
  }
  
  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }
 
  $requiredby = $locale->text('Required by');

  $i = 1; 
  if ($form->{vc} eq 'vendor') {
    if ($form->{type} eq 'receive_order') {
      $form->{title} = $locale->text('Receive Merchandise');
    }
    if ($form->{type} eq 'purchase_order') {
      $form->{title} = $locale->text('Purchase Orders');
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Purchase Order'}{code} = qq|<button class="submit" type="submit" name="action" value="purchase_order">|.$locale->text('Purchase Order').qq|</button> |;
	$button{'Order Entry--Purchase Order'}{order} = $i++;
      }
    }
    if ($form->{type} eq 'generate_sales_order') {
      $form->{title} = $locale->text('Purchase Orders');
      $form->{type} = "purchase_order";
      unshift @column_index, "ndx";
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Sales Order'}{code} = qq|<button class="submit" type="submit" name="action" value="generate_sales_order">|.$locale->text('Generate Sales Order').qq|</button> |;
	$button{'Order Entry--Sales Order'}{order} = $i++;
      }
    }
    if ($form->{type} eq 'consolidate_purchase_order') {
      $form->{title} = $locale->text('Purchase Orders');
      $form->{type} = "purchase_order";
      unshift @column_index, "ndx";
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Purchase Order'}{code} = qq|<button class="submit" type="submit" name="action" value="consolidate_orders">|.$locale->text('Consolidate Orders').qq|</button> |;
	$button{'Order Entry--Purchase Order'}{order} = $i++;
      }
    }

    if ($form->{type} eq 'request_quotation') {
      $form->{title} = $locale->text('Request for Quotations');
      $quotation = $locale->text('RFQ');

      if ($myconfig{acs} !~ /Quotations--Quotations/) {
	$button{'Quotations--RFQ'}{code} = qq|<button class="submit" type="submit" name="action" value="rfq_">|.$locale->text('RFQ ').qq|"</button> |;
	$button{'Quotations--RFQ'}{order} = $i++;
      }
      
    }
    $name = $locale->text('Vendor');
    $employee = $locale->text('Employee');
  }
  if ($form->{vc} eq 'customer') {
    if ($form->{type} eq 'sales_order') {
      $form->{title} = $locale->text('Sales Orders');
      $employee = $locale->text('Salesperson');

      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Sales Order'}{code} = qq|<button class="submit" type="submit" name="action" value="sales_order">|.$locale->text('Sales Order').qq|</button> |;
	$button{'Order Entry--Sales Order'}{order} = $i++;
      }

    }
    if ($form->{type} eq 'generate_purchase_order') {
      $form->{title} = $locale->text('Sales Orders');
      $form->{type} = "sales_order";
      $employee = $locale->text('Salesperson');
      unshift @column_index, "ndx";
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Purchase Order'}{code} = qq|<button class="submit" type="submit" name="action" value="generate_purchase_orders">|.$locale->text('Generate Purchase Orders').qq|</button> |;
	$button{'Order Entry--Purchase Order'}{order} = $i++;
      }
    }
    if ($form->{type} eq 'consolidate_sales_order') {
      $form->{title} = $locale->text('Sales Orders');
      $form->{type} = "sales_order";
      unshift @column_index, "ndx";
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Sales Order'}{code} = qq|<button class="submit" type="submit" name="action" value="consolidate_orders">|.$locale->text('Consolidate Orders').qq|</button> |;
	$button{'Order Entry--Sales Order'}{order} = $i++;
      }
    }

    if ($form->{type} eq 'ship_order') {
      $form->{title} = $locale->text('Ship Merchandise');
      $employee = $locale->text('Salesperson');
    }
    if ($form->{type} eq 'sales_quotation') {
      $form->{title} = $locale->text('Quotations');
      $employee = $locale->text('Employee');
      $requiredby = $locale->text('Valid until');
      $quotation = $locale->text('Quotation');

      if ($myconfig{acs} !~ /Quotations--Quotations/) {
	$button{'Quotations--Quotation'}{code} = qq|<button class="submit" type="submit" name="action" value="quotation_">|.$locale->text('Quotation ').qq|</button> |;
	$button{'Quotations--Quotation'}{order} = $i++;
      }
      
    }
    $name = $locale->text('Customer');
  }

  for (split /;/, $myconfig{acs}) { delete $button{$_} }

  $column_header{ndx} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{runningnumber} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{id} = qq|<th><a class=listheading href=$href&sort=id>|.$locale->text('ID').qq|</a></th>|;
  $column_header{transdate} = qq|<th><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</a></th>|;
  $column_header{reqdate} = qq|<th><a class=listheading href=$href&sort=reqdate>$requiredby</a></th>|;
  $column_header{ordnumber} = qq|<th><a class=listheading href=$href&sort=ordnumber>|.$locale->text('Order').qq|</a></th>|;
  $column_header{ponumber} = qq|<th><a class=listheading href=$href&sort=ponumber>|.$locale->text('PO Number').qq|</a></th>|;
  $column_header{quonumber} = qq|<th><a class=listheading href=$href&sort=quonumber>$quotation</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>$name</a></th>|;
  $column_header{netamount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_header{tax} = qq|<th class=listheading>|.$locale->text('Tax').qq|</th>|;
  $column_header{amount} = qq|<th class=listheading>|.$locale->text('Total').qq|</th>|;
  $column_header{curr} = qq|<th><a class=listheading href=$href&sort=curr>|.$locale->text('Curr').qq|</a></th>|;
  $column_header{shipvia} = qq|<th><a class=listheading href=$href&sort=shipvia>|.$locale->text('Ship via').qq|</a></th>|;
  $column_header{open} = qq|<th class=listheading>|.$locale->text('O').qq|</th>|;
  $column_header{closed} = qq|<th class=listheading>|.$locale->text('C').qq|</th>|;

  $column_header{employee} = qq|<th><a class=listheading href=$href&sort=employee>$employee</a></th>|;
  $column_header{manager} = qq|<th><a class=listheading href=$href&sort=manager>|.$locale->text('Manager').qq|</a></th>|;

  for (qw(amount tax netamount)) { $column_header{"fx_$_"} = "<th>&nbsp;</th>" }
  
  if ($form->{$form->{vc}}) {
    $option = $locale->text(ucfirst $form->{vc});
    $option .= " : $form->{$form->{vc}}";
  }
  if ($form->{warehouse}) {
    ($warehouse) = split /--/, $form->{warehouse};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Warehouse');
    $option .= " : $warehouse";
  }
  if ($form->{department}) {
    $option .= "\n<br>" if ($option);
    ($department) = split /--/, $form->{department};
    $option .= $locale->text('Department')." : $department";
  }
  if ($form->{employee}) {
    ($employee) = split /--/, $form->{employee};
    $option .= "\n<br>" if ($option);
    if ($form->{vc} eq 'customer') {
      $option .= $locale->text('Salesperson');
    } else {
      $option .= $locale->text('Employee');
    }
    $option .= " : $employee";
  }
  if ($form->{ordnumber}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Order Number')." : $form->{ordnumber}";
  }
  if ($form->{quonumber}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Quotation Number')." : $form->{quonumber}";
  }
  if ($form->{ponumber}) {
    $option = $locale->text('PO Number');
    $option .= " : $form->{ponumber}";
  }
  if ($form->{shipvia}) {
    $option .= "\n<br>" if ($option); 
    $option .= $locale->text('Ship via')." : $form->{shipvia}";
  }
  if ($form->{description}) {
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{transdatefrom}) {
    $option .= "\n<br>".$locale->text('From')." ".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
  }
  if ($form->{transdateto}) {
    $option .= "\n<br>".$locale->text('To')." ".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }
  if ($form->{open}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Open');
  }
  if ($form->{closed}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Closed');
  }
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;

  # add sort and escape callback
  $callback .= "&sort=$form->{sort}";
  $form->{callback} = $callback;
  $callback = $form->escape($callback);

  # flip direction
  $direction = ($form->{direction} eq 'ASC') ? "ASC" : "DESC";
  $href =~ s/&direction=(\w+)&/&direction=$direction&/;

  if (@{ $form->{OE} }) {
    $sameitem = $form->{OE}->[0]->{$form->{sort}};
  }

  $action = "edit";
  $action = "ship_receive" if ($form->{type} =~ /(ship|receive)_order/);

  $warehouse = $form->escape($form->{warehouse});

  $i = 0;
  foreach $oe (@{ $form->{OE} }) {

    $i++;

    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $oe->{$form->{sort}}) {
	&subtotal;
	$sameitem = $oe->{$form->{sort}};
      }
    }
    
    if ($form->{l_curr}) {
      for (qw(netamount amount)) { $oe->{"fx_$_"} = $oe->{$_} }
      $oe->{fx_tax} = $oe->{fx_amount} - $oe->{fx_netamount};
      for (qw(netamount amount)) { $oe->{$_} *= $oe->{exchangerate} }

      for (qw(netamount amount)) { $column_data{"fx_$_"} = "<td align=right>".$form->format_amount(\%myconfig, $oe->{"fx_$_"}, 2, "&nbsp;")."</td>" }
      $column_data{fx_tax} = "<td align=right>".$form->format_amount(\%myconfig, $oe->{fx_amount} - $oe->{fx_netamount}, 2, "&nbsp;")."</td>"; 
      
      $totalfxnetamount += $oe->{fx_netamount}; 
      $totalfxamount += $oe->{fx_amount};

      $subtotalfxnetamount += $oe->{fx_netamount};
      $subtotalfxamount += $oe->{fx_amount};
    }
    
    for (qw(netamount amount)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $oe->{$_}, 2, "&nbsp;")."</td>" }
    $column_data{tax} = "<td align=right>".$form->format_amount(\%myconfig, $oe->{amount} - $oe->{netamount}, 2, "&nbsp;")."</td>";

    $totalnetamount += $oe->{netamount};
    $totalamount += $oe->{amount};

    $subtotalnetamount += $oe->{netamount};
    $subtotalamount += $oe->{amount};


    $column_data{id} = "<td>$oe->{id}</td>";
    $column_data{transdate} = "<td>$oe->{transdate}&nbsp;</td>";
    $column_data{reqdate} = "<td>$oe->{reqdate}&nbsp;</td>";

    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    $column_data{ndx} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value=$oe->{id} checked></td>|;
    $column_data{$ordnumber} = "<td><a href=$form->{script}?path=$form->{path}&action=$action&type=$form->{type}&id=$oe->{id}&warehouse=$warehouse&vc=$form->{vc}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$oe->{$ordnumber}</a></td>";

    $name = $form->escape($oe->{name});
    $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&action=edit&id=$oe->{"$form->{vc}_id"}&db=$form->{vc}&callback=$callback>$oe->{name}</a></td>|;

    for (qw(employee manager shipvia curr ponumber)) { $column_data{$_} = "<td>$oe->{$_}&nbsp;</td>" }

    if ($oe->{closed}) {
      $column_data{closed} = "<td align=center>*</td>";
      $column_data{open} = "<td>&nbsp;</td>";
    } else {
      $column_data{closed} = "<td>&nbsp;</td>";
      $column_data{open} = "<td align=center>*</td>";
    }

    $j++; $j %= 2;
    print "
        <tr class=listrow$j>";
    
    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

  }
  
  if ($form->{l_subtotal} eq 'Y') {
    &subtotal;
  }
  
  # print totals
  print qq|
        <tr class=listtotal>|;
  
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetamount, 2, "&nbsp;")."</th>";
  $column_data{tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount - $totalnetamount, 2, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, 2, "&nbsp;")."</th>";

  if ($form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal}) {
    $column_data{fx_netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxnetamount, 2, "&nbsp;")."</th>";
    $column_data{fx_tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxamount - $totalfxnetamount, 2, "&nbsp;")."</th>";
    $column_data{fx_amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxamount, 2, "&nbsp;")."</th>";
  }

  for (@column_index) { print "\n$column_data{$_}" }
 
  print qq|
        </tr>
      </td>
    </table>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;

  $form->hide_form(qw(callback type vc path login sessionid department ordnumber ponumber shipvia));
  
  print qq|

<input type=hidden name=rowcount value=$i>

<input type=hidden name=$form->{vc} value="$form->{$form->{vc}}">
<input type=hidden name="$form->{vc}_id" value=$form->{"$form->{vc}_id"}>

|;

  if ($form->{type} !~ /(ship|receive)_order/) {
    for (sort { $a->{order} <=> $b->{order} } %button) { print $_->{code} }
  }

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}



sub subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{netamount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalnetamount, 2, "&nbsp;")."</th>";
  $column_data{tax} = "<td class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount - $subtotalnetamount, 2, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount, 2, "&nbsp;")."</th>";

  if ($form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal}) {
    $column_data{fx_netamount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxnetamount, 2, "&nbsp;")."</th>";
    $column_data{fx_tax} = "<td class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxamount - $subtotalfxnetamount, 2, "&nbsp;")."</th>";
    $column_data{fx_amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxamount, 2, "&nbsp;")."</th>";
  }

  $subtotalnetamount = 0;
  $subtotalamount = 0;
  
  $subtotalfxnetamount = 0;
  $subtotalfxamount = 0;

  print "
        <tr class=listsubtotal>
";
  
  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

}


sub save {

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Order Date missing!');
  } else {
    $msg = $locale->text('Quotation Date missing!');
  }
  
  $form->isblank("transdate", $msg);

  $msg = ucfirst $form->{vc};
  $form->isblank($form->{vc}, $locale->text($msg . " missing!"));

# $locale->text('Customer missing!');
# $locale->text('Vendor missing!');
  
  $form->isblank("exchangerate", $locale->text('Exchange rate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  &validate_items;

  # if the name changed get new values
  if (&check_name($form->{vc})) {
    &update;
    exit;
  }


  # this is for the internal notes section for the [email] Subject
  if ($form->{type} =~ /_order$/) {
    if ($form->{type} eq 'sales_order') {
      $form->{label} = $locale->text('Sales Order');

      $numberfld = "sonumber";
      $ordnumber = "ordnumber";
    } else {
      $form->{label} = $locale->text('Purchase Order');
      
      $numberfld = "ponumber";
      $ordnumber = "ordnumber";
    }

    $err = $locale->text('Cannot save order!');
    
  } else {
    if ($form->{type} eq 'sales_quotation') {
      $form->{label} = $locale->text('Quotation');
      
      $numberfld = "sqnumber";
      $ordnumber = "quonumber";
    } else {
      $form->{label} = $locale->text('Request for Quotation');

      $numberfld = "rfqnumber";
      $ordnumber = "quonumber";
    }
      
    $err = $locale->text('Cannot save quotation!');
 
  }

  if (! $form->{repost}) {
    if ($form->{id}) {
      &repost("Save");
      exit;
    }
  }
  
  if (OE->save(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Order saved!'));
  } else {
    $form->error($err);
  }

}


sub print_and_save {

  $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(postscript|pdf)/;
  $form->error($locale->text('Select a Printer!')) if $form->{media} eq 'screen';

  $old_form = new Form;
  $form->{display_form} = "save";
  for (keys %$form) { $old_form->{$_} = $form->{$_} }
  $old_form->{rowcount}++;

  &print_form($old_form);

}


sub delete {

  $form->header;

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Are you sure you want to delete Order Number');
    $ordnumber = 'ordnumber';
  } else {
    $msg = $locale->text('Are you sure you want to delete Quotation Number');
    $ordnumber = 'quonumber';
  }
  
  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "yes";
  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>$msg $form->{$ordnumber}</h4>
<p>
<button name="action" class="submit" type="submit" value="yes">|.$locale->text('Yes').qq|</button>
</form>

</body>
</html>
|;


}



sub yes {

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Order deleted!');
    $err = $locale->text('Cannot delete order!');
  } else {
    $msg = $locale->text('Quotation deleted!');
    $err = $locale->text('Cannot delete quotation!');
  }
  
  if (OE->delete(\%myconfig, \%$form, ${LedgerSMB::Sysconfig::spool})) {
    $form->redirect($msg);
  } else {
    $form->error($err);
  }

}


sub vendor_invoice { &invoice };
sub sales_invoice { &invoice };

sub invoice {
  
  if ($form->{type} =~ /_order$/) {
    $form->isblank("ordnumber", $locale->text('Order Number missing!'));
    $form->isblank("transdate", $locale->text('Order Date missing!'));

  } else {
    $form->isblank("quonumber", $locale->text('Quotation Number missing!'));
    $form->isblank("transdate", $locale->text('Quotation Date missing!'));
    $form->{ordnumber} = "";
  }

  # if the name changed get new values
  if (&check_name($form->{vc})) {
    &update;
    exit;
  }


  if ($form->{type} =~ /_order/ && $form->{currency} ne $form->{defaultcurrency}) {
    # check if we need a new exchangerate
    $buysell = ($form->{type} eq 'sales_order') ? "buy" : "sell";
    
    $orddate = $form->current_date(\%myconfig);
    $exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $orddate, $buysell);

    if (!$exchangerate) {
      &backorder_exchangerate($orddate, $buysell);
      exit;
    }
  }


  # close orders/quotations
  $form->{closed} = 1;

  OE->save(\%myconfig, \%$form);
  
  $form->{transdate} = $form->current_date(\%myconfig);
  $form->{duedate} = $form->current_date(\%myconfig, $form->{transdate}, $form->{terms} * 1);
 
  $form->{id} = '';
  $form->{closed} = 0;
  $form->{rowcount}--;
  $form->{shipto} = 1;


  if ($form->{type} =~ /_order$/) {
    $form->{exchangerate} = $exchangerate;
    &create_backorder;
  }


  if ($form->{type} eq 'purchase_order' || $form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Add Vendor Invoice');
    $form->{script} = 'ir.pl';
    
    $script = "ir";
    $buysell = 'sell';
  }
  if ($form->{type} eq 'sales_order' || $form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Add Sales Invoice');
    $form->{script} = 'is.pl';
    $script = "is";
    $buysell = 'buy';
  }
 
  for (qw(id subject message cc bcc printed emailed queued)) { delete $form->{$_} }
  $form->{$form->{vc}} =~ s/--.*//g;
  $form->{type} = "invoice";
 
  # locale messages
  $locale = LedgerSMB::Locale->get_handle($myconfig{countrycode}) or
  	$form->error("Locale not loaded: $!\n");
  #$form->{charset} = $locale->encoding;
  $form->{charset} = 'UTF-8';
  $locale->encoding('UTF-8');

  require "bin/$form->{script}";

  # customized scripts
  if (-f "bin/custom/$form->{script}") {
    eval { require "bin/custom/$form->{script}"; };
  }

  # customized scripts for login
  if (-f "bin/custom/$form->{login}_$form->{script}") {
    eval { require "bin/custom/$form->{login}_$form->{script}"; };
  }

  for ("$form->{vc}", "currency") { $form->{"select$_"} = "" }
  for (qw(currency oldcurrency employee department intnotes notes taxincluded)) { $temp{$_} = $form->{$_} }

  &invoice_links;

  $form->{creditremaining} -= ($form->{oldinvtotal} - $form->{ordtotal});

  &prepare_invoice;
  
  for (keys %temp) { $form->{$_} = $temp{$_} }
  
  $form->{exchangerate} = "";
  $form->{forex} = "";
  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell)));
 
  for $i (1 .. $form->{rowcount}) {
    $form->{"deliverydate_$i"} = $form->{"reqdate_$i"};
    for (qw(qty sellprice discount)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }
  }

  for (qw(id subject message cc bcc printed emailed queued audittrail)) { delete $form->{$_} }

  &display_form;

}



sub backorder_exchangerate {
  my ($orddate, $buysell) = @_;

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  # delete action variable
  for (qw(action nextsub exchangerate)) { delete $form->{$_} }

  $form->hide_form;

  $form->{title} = $locale->text('Add Exchange Rate');
  
  print qq|

<input type=hidden name=exchangeratedate value=$orddate>
<input type=hidden name=buysell value=$buysell>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('Currency').qq|</th>
	  <td>$form->{currency}</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Date').qq|</th>
	  <td>$orddate</td>
	</tr>
        <tr>
	  <th align=right>|.$locale->text('Exchange Rate').qq|</th>
	  <td><input name=exchangerate size=11></td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input type=hidden name=nextsub value=save_exchangerate>

<button name="action" class="submit" type="submit" value="continue">|.$locale->text('Continue').qq|</button>

</form>

</body>
</html>
|;


}


sub save_exchangerate {

  $form->isblank("exchangerate", $locale->text('Exchange rate missing!'));
  $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $form->save_exchangerate(\%myconfig, $form->{currency}, $form->{exchangeratedate}, $form->{exchangerate}, $form->{buysell});
  
  &invoice;

}


sub create_backorder {
  
  $form->{shipped} = 1;
 
  # figure out if we need to create a backorder
  # items aren't saved if qty != 0

  $dec1 = $dec2 = 0;
  for $i (1 .. $form->{rowcount}) {
    ($dec) = ($form->{"qty_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $dec1 = ($dec > $dec1) ? $dec : $dec1;
    
    ($dec) = ($form->{"ship_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $dec2 = ($dec > $dec2) ? $dec : $dec2;
    
    $totalqty += $qty = $form->{"qty_$i"};
    $totalship += $ship = $form->{"ship_$i"};
    
    $form->{"qty_$i"} = $qty - $ship;
  }

  $totalqty = $form->round_amount($totalqty, $dec1);
  $totalship = $form->round_amount($totalship, $dec2);

  if ($totalship == 0) {
    for (1 .. $form->{rowcount}) { $form->{"ship_$_"} = $form->{"qty_$_"} }
    $form->{ordtotal} = 0;
    $form->{shipped} = 0;
    return;
  }

  if ($totalqty == $totalship) {
    for (1 .. $form->{rowcount}) { $form->{"qty_$_"} = $form->{"ship_$_"} }
    $form->{ordtotal} = 0;
    return;
  }

  @flds = qw(partnumber description qty ship unit sellprice discount oldqty orderitems_id id bin weight listprice lastcost taxaccounts pricematrix sku onhand deliverydate reqdate projectnumber partsgroup assembly);

  for $i (1 .. $form->{rowcount}) {
    for (qw(qty sellprice discount)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    $form->{"oldship_$i"} = $form->{"ship_$i"};
    $form->{"ship_$i"} = 0;
  }

  # clear flags
  for (qw(id subject message cc bcc printed emailed queued audittrail)) { delete $form->{$_} }

  OE->save(\%myconfig, \%$form);
 
  # rebuild rows for invoice
  @a = ();
  $count = 0;

  for $i (1 .. $form->{rowcount}) {
    $form->{"qty_$i"} = $form->{"oldship_$i"};
    $form->{"oldqty_$i"} = $form->{"qty_$i"};
    
    $form->{"orderitems_id_$i"} = "";

    if ($form->{"qty_$i"}) {
      push @a, {};
      $j = $#a;
      for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
 
  $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
  $form->{rowcount} = $count;

}



sub save_as_new {

  for (qw(closed id printed emailed queued)) { delete $form->{$_} }
  &save;

}


sub print_and_save_as_new {

  for (qw(closed id printed emailed queued)) { delete $form->{$_} }
  &print_and_save;

}


sub ship_receive {

  &order_links;
  
  &prepare_order;

  OE->get_warehouses(\%myconfig, \%$form);

  # warehouse
  if (@{ $form->{all_warehouse} }) {
    $form->{selectwarehouse} = "<option>\n";

    for (@{ $form->{all_warehouse} }) { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }

    if ($form->{warehouse}) {
      $form->{selectwarehouse} = qq|<option value="$form->{warehouse}">|;
      $form->{warehouse} =~ s/--.*//;
      $form->{selectwarehouse} .= $form->{warehouse};
    }
  }

  $form->{shippingdate} = $form->current_date(\%myconfig);
  $form->{"$form->{vc}"} =~ s/--.*//;
  $form->{"old$form->{vc}"} = qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;

  @flds = ();
  @a = ();
  $count = 0;
  foreach $key (keys %$form) {
    if ($key =~ /_1$/) {
      $key =~ s/_1//;
      push @flds, $key;
    }
  }
  
  for $i (1 .. $form->{rowcount}) {
    # undo formatting from prepare_order
    for (qw(qty ship)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    $n = ($form->{"qty_$i"} -= $form->{"ship_$i"});
    if (abs($n) > 0) {
      $form->{"ship_$i"} = "";
      $form->{"serialnumber_$i"} = "";

      push @a, {};
      $j = $#a;

      for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  
  $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
  $form->{rowcount} = $count;
  
  &display_ship_receive;
  
}


sub display_ship_receive {
  
  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);

  $form->{rowcount}++;

  if ($form->{vc} eq 'customer') {
    $form->{title} = $locale->text('Ship Merchandise');
    $shipped = $locale->text('Shipping Date');
  } else {
    $form->{title} = $locale->text('Receive Merchandise');
    $shipped = $locale->text('Date Received');
  }
  
  # set option selected
  for (qw(warehouse employee)) {
    $form->{"select$_"} = $form->unescape($form->{"select$_"});
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
  }


  $warehouse = qq|
	      <tr>
		<th align=right>|.$locale->text('Warehouse').qq|</th>
		<td><select name=warehouse>$form->{selectwarehouse}</select></td>
		<input type=hidden name=selectwarehouse value="|.
		$form->escape($form->{selectwarehouse},1).qq|">
	      </tr>
| if $form->{selectwarehouse};

  $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Contact').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|">
	      </tr>
|;


  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=display_form value=display_ship_receive>
|;

  $form->hide_form(qw(id type media format printed emailed queued vc));

  print qq|
<input type=hidden name="old$form->{vc}" value="$form->{"old$form->{vc}"}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
	  <td>
	    <table width=100%>
	      <tr>
		<th align=right>$vclabel</th>
		<td colspan=3>$form->{$form->{vc}}</td>
		<input type=hidden name=$form->{vc} value="$form->{$form->{vc}}">
		<input type=hidden name="$form->{vc}_id" value=$form->{"$form->{vc}_id"}>
	      </tr>
	      $department
	      <tr>
		<th align=right>|.$locale->text('Shipping Point').qq|</th>
		<td colspan=3>
		<input name=shippingpoint size=35 value="$form->{shippingpoint}">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Ship via').qq|</th>
		<td colspan=3>
		<input name=shipvia size=35 value="$form->{shipvia}">
	      </tr>
	      $warehouse
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $employee
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Number').qq|</th>
		<td>$form->{ordnumber}</td>
		<input type=hidden name=ordnumber value="$form->{ordnumber}">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Date').qq|</th>
		<td>$form->{transdate}</td>
		<input type=hidden name=transdate value=$form->{transdate}>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('PO Number').qq|</th>
		<td>$form->{ponumber}</td>
		<input type=hidden name=ponumber value="$form->{ponumber}">
	      </tr>
	      <tr>
		<th align=right nowrap>$shipped</th>
		<td><input name=shippingdate size=11 value=$form->{shippingdate}></td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

|;

  $form->hide_form(qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc));

  @column_index = qw(partnumber);
  
  if ($form->{type} eq "ship_order") {
    $column_data{ship} = qq|<th class=listheading>|.$locale->text('Ship').qq|</th>|;
  }
  if ($form->{type} eq "receive_order") {
      $column_data{ship} = qq|<th class=listheading>|.$locale->text('Recd').qq|</th>|;
      $column_data{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
      push @column_index, "sku";
  }
  push @column_index, qw(description qty ship unit bin serialnumber);

  my $colspan = $#column_index + 1;
 
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{bin} = qq|<th class=listheading nowrap>|.$locale->text('Bin').qq|</th>|;
  $column_data{serialnumber} = qq|<th class=listheading nowrap>|.$locale->text('Serial No.').qq|</th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;
  
  
  for $i (1 .. $form->{rowcount} - 1) {
    
    # undo formatting
    $form->{"ship_$i"} = $form->parse_amount(\%myconfig, $form->{"ship_$i"});

    for (qw(partnumber sku description unit bin serialnumber)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }

    $description = $form->{"description_$i"};
    $description =~ s/\r?\n/<br>/g;
    
    $column_data{partnumber} = qq|<td>$form->{"partnumber_$i"}<input type=hidden name="partnumber_$i" value="$form->{"partnumber_$i"}"></td>|;
    $column_data{sku} = qq|<td>$form->{"sku_$i"}<input type=hidden name="sku_$i" value="$form->{"sku_$i"}"></td>|;
    $column_data{description} = qq|<td>$description<input type=hidden name="description_$i" value="$form->{"description_$i"}"></td>|;
    $column_data{qty} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|<input type=hidden name="qty_$i" value="$form->{"qty_$i"}"></td>|;
    $column_data{ship} = qq|<td align=right><input name="ship_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|></td>|;
    $column_data{unit} = qq|<td>$form->{"unit_$i"}<input type=hidden name="unit_$i" value="$form->{"unit_$i"}"></td>|;
    $column_data{bin} = qq|<td>$form->{"bin_$i"}<input type=hidden name="bin_$i" value="$form->{"bin_$i"}"></td>|;
    
    $column_data{serialnumber} = qq|<td><input name="serialnumber_$i" size=15 value="$form->{"serialnumber_$i"}"></td>|;
    
    print qq|
        <tr valign=top>|;

    for (@column_index) { print "\n$column_data{$_}" }
  
    print qq|
        </tr>
|;
    $form->hide_form("orderitems_id_$i","id_$i","partsgroup_$i");

  }
 
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

  $form->{copies} = 1;
  
  &print_options;
  
  print qq|
    </td>
  </tr>
</table>
<br>
|;

# type=submit $locale->text('Done')

  %button = ('update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
             'print' => { ndx => 2, key => 'P', value => $locale->text('Print') },
	     'ship_to' => { ndx => 4, key => 'T', value => $locale->text('Ship to') },
	     'e_mail' => { ndx => 5, key => 'E', value => $locale->text('E-mail') },
	     'done' => { ndx => 11, key => 'D', value => $locale->text('Done') },
	    );
  
  for ("update", "print") { $form->print_button(\%button, $_) }
  
  if ($form->{type} eq 'ship_order') {
    for ('ship_to', 'e_mail') { $form->print_button(\%button, $_) }
  }
  
  $form->print_button(\%button, 'done');
  
  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  $form->hide_form(qw(rowcount callback path login sessionid));
  
  print qq|
  
</form>

</body>
</html>
|;


}


sub done {

  if ($form->{type} eq 'ship_order') {
    $form->isblank("shippingdate", $locale->text('Shipping Date missing!'));
  } else {
    $form->isblank("shippingdate", $locale->text('Date received missing!'));
  }
  
  $total = 0;
  for (1 .. $form->{rowcount} - 1) { $total += $form->{"ship_$_"} = $form->parse_amount(\%myconfig, $form->{"ship_$_"}) }
  
  $form->error($locale->text('Nothing entered!')) unless $total;

  if (OE->save_inventory(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Inventory saved!'));
  } else {
    $form->error($locale->text('Could not save!'));
  }

}


sub search_transfer {
  
  OE->get_warehouses(\%myconfig, \%$form);

  # warehouse
  if (@{ $form->{all_warehouse} }) {
    $form->{selectwarehouse} = "<option>\n";
    $form->{warehouse} = qq|$form->{warehouse}--$form->{warehouse_id}| if $form->{warehouse_id};

    for (@{ $form->{all_warehouse} }) { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
  } else {
    $form->error($locale->text('Nothing to transfer!'));
  }
  
  $form->get_partsgroup(\%myconfig, { searchitems => 'part'});
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "<option>\n";
    for (@{ $form->{all_partsgroup} }) { $form->{selectpartsgroup} .= qq|<option value="$_->{partsgroup}--$_->{id}">$_->{partsgroup}\n| }
  }
  
  $form->{title} = $locale->text('Transfer Inventory');
 
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer from').qq|</th>
          <td><select name=fromwarehouse>$form->{selectwarehouse}</select></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer to').qq|</th>
          <td><select name=towarehouse>$form->{selectwarehouse}</select></td>
        </tr>
	<tr>
	  <th align="right" nowrap="true">|.$locale->text('Part Number').qq|</th>
	  <td><input name=partnumber size=20></td>
	</tr>
	<tr>
	  <th align="right" nowrap="true">|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Group').qq|</th>
	  <td><select name=partsgroup>$form->{selectpartsgroup}</select></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=nextsub value=list_transfer>

<button class="submit" type="submit" name="action" value="continue">|.$locale->text('Continue').qq|</button>|;

  $form->hide_form(qw(path login sessionid));

  print qq|
</form>
|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub list_transfer {

  $form->{sort} = "partnumber" unless $form->{sort};

  OE->get_inventory(\%myconfig, \%$form);
  
  # construct href
  $href = "$form->{script}?action=list_transfer";
  for (qw(direction oldsort path login sessionid)) { $href .= "&$_=$form->{$_}" }
  for (qw(partnumber fromwarehouse towarehouse description partsgroup)) { $href .= "&$_=".$form->escape($form->{$_}) }

  $form->sort_order();
  
  # construct callback
  $callback = "$form->{script}?action=list_transfer";
  for (qw(direction oldsort path login sessionid)) { $callback .= "&$_=$form->{$_}" }
  for (qw(partnumber fromwarehouse towarehouse description partsgroup)) { $callback .= "&$_=".$form->escape($form->{$_},1) }

  @column_index = $form->sort_columns(qw(partnumber description partsgroup make model fromwarehouse qty towarehouse transfer));

  $column_header{partnumber} = qq|<th><a class=listheading href=$href&sort=partnumber>|.$locale->text('Part Number').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{partsgroup} = qq|<th><a class=listheading href=$href&sort=partsgroup>|.$locale->text('Group').qq|</a></th>|;
  $column_header{fromwarehouse} = qq|<th><a class=listheading href=$href&sort=warehouse>|.$locale->text('From').qq|</a></th>|;
  $column_header{towarehouse} = qq|<th class=listheading>|.$locale->text('To').qq|</th>|;
  $column_header{qty} = qq|<th class=listheading>|.$locale->text('Qty').qq|</a></th>|;
  $column_header{transfer} = qq|<th class=listheading>|.$locale->text('Transfer').qq|</a></th>|;

  
  ($warehouse, $warehouse_id) = split /--/, $form->{fromwarehouse};
  
  if ($form->{fromwarehouse}) {
    $option .= "\n<br>";
    $option .= $locale->text('From Warehouse')." : $warehouse";
  }
  ($warehouse, $warehouse_id) = split /--/, $form->{towarehouse};
  if ($form->{towarehouse}) {
    $option .= "\n<br>";
    $option .= $locale->text('To Warehouse')." : $warehouse";
  }
  if ($form->{partnumber}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Part Number')." : $form->{partnumber}";
  }
  if ($form->{description}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{partsgroup}) {
    ($partsgroup) = split /--/, $form->{partsgroup};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Group')." : $partsgroup";
  }

  $form->{title} = $locale->text('Transfer Inventory');

  $callback .= "&sort=$form->{sort}";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=warehouse_id value=$warehouse_id>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

for (@column_index) { print "\n$column_header{$_}" }

print qq|
	</tr>
|;

  if (@{ $form->{all_inventory} }) {
    $sameitem = $form->{all_inventory}->[0]->{$form->{sort}};
  }

  $i = 0;
  foreach $ref (@{ $form->{all_inventory} }) {

    $i++;

    $column_data{partnumber} = qq|<td><input type=hidden name="id_$i" value=$ref->{id}>$ref->{partnumber}</td>|;
    $column_data{description} = "<td>$ref->{description}&nbsp;</td>";
    $column_data{partsgroup} = "<td>$ref->{partsgroup}&nbsp;</td>";
    $column_data{fromwarehouse} = qq|<td><input type=hidden name="warehouse_id_$i" value=$ref->{warehouse_id}>$ref->{warehouse}&nbsp;</td>|;
    $column_data{towarehouse} = qq|<td>$warehouse&nbsp;</td>|;
    $column_data{qty} = qq|<td><input type=hidden name="qty_$i" value=$ref->{qty}>|.$form->format_amount(\%myconfig, $ref->{qty}).qq|</td>|;
    $column_data{transfer} = qq|<td><input name="transfer_$i" size=4></td>|;

    $j++; $j %= 2;
    print "
        <tr class=listrow$j>";
    
    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

  }
  
  print qq|
      </table>
    </td>
  </tr>
  
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>

<input name=callback type=hidden value="$callback">

<input type=hidden name=rowcount value=$i>
|;

  $form->{action} = "transfer";
  $form->hide_form(qw(path login sessionid action));

  print qq|
<button class="submit" type="submit" name="action" value="transfer">|.$locale->text('Transfer').qq|</button>|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;


}


sub transfer {

  if (OE->transfer(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Inventory transferred!'));
  } else {
    $form->error($locale->text('Could not transfer Inventory!'));
  }

}


sub rfq_ { &add };
sub quotation_ { &add };


sub generate_purchase_orders {

  for (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$_"}) {
      $ok = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $ok;
  
  ($null, $argv) = split /\?/, $form->{callback};
  
  for (split /\&/, $argv) {
    ($key, $value) = split /=/, $_;
    $form->{$key} = $value;
  }

  $form->{vc} = "vendor";

  OE->get_soparts(\%myconfig, \%$form);

  # flatten array
  $i = 0;
  foreach $parts_id (sort { $form->{orderitems}{$a}{partnumber} cmp $form->{orderitems}{$b}{partnumber} } keys %{ $form->{orderitems} }) {

    $required = $form->{orderitems}{$parts_id}{required};
    next if $required <= 0;

    $i++;
    
    $form->{"required_$i"} = $form->format_amount(\%myconfig, $required);
    $form->{"id_$i"} = $parts_id;
    $form->{"sku_$i"} = $form->{orderitems}{$parts_id}{partnumber};

    $form->{"curr_$i"} = $form->{defaultcurrency};
    $form->{"description_$i"} = $form->{orderitems}{$parts_id}{description};

    $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{lastcost}, 2);

    $form->{"qty_$i"} = $required;
    
    if (exists $form->{orderitems}{$parts_id}{"parts$form->{vc}"}) {
      $form->{"qty_$i"} = "";

      foreach $id (sort { $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$a}{lastcost} * $form->{$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$a}{curr}} <=> $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$b}{lastcost} * $form->{$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$b}{curr}} } keys %{ $form->{orderitems}{$parts_id}{"parts$form->{vc}"} }) {
	$i++;

	$form->{"qty_$i"} = $form->format_amount(\%myconfig, $required);
    
 	$form->{"description_$i"} = "";
	for (qw(partnumber curr)) { $form->{"${_}_$i"} = $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{$_} }

        $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{lastcost}, 2);
        $form->{"leadtime_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{leadtime});
	$form->{"fx_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{lastcost} * $form->{$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{curr}}, 2);

	$form->{"id_$i"} = $parts_id;
	
	$form->{"$form->{vc}_$i"} = qq|$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{name}--$id|;
	$form->{"$form->{vc}_id_$i"} = $id;

        $required = "";
      }
    }
    $form->{"blankrow_$i"} = 1;
  }

  $form->{rowcount} = $i;

  &po_orderitems;

}


sub po_orderitems {

  @column_index = qw(sku description partnumber leadtime fx lastcost curr required qty name);
  
  $column_header{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
  $column_header{partnumber} = qq|<th class=listheading>|.$locale->text('Part Number').qq|</th>|;
  $column_header{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_header{name} = qq|<th class=listheading>|.$locale->text('Vendor').qq|</th>|;
  $column_header{qty} = qq|<th class=listheading>|.$locale->text('Order').qq|</th>|;
  $column_header{required} = qq|<th class=listheading>|.$locale->text('Req').qq|</th>|;
  $column_header{lastcost} = qq|<th class=listheading>|.$locale->text('Cost').qq|</th>|;
  $column_header{fx} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{leadtime} = qq|<th class=listheading>|.$locale->text('Lead').qq|</th>|;
  $column_header{curr} = qq|<th class=listheading>|.$locale->text('Curr').qq|</th>|;


  $form->{title} = $locale->text('Generate Purchase Orders');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;

  for $i (1 .. $form->{rowcount}) {

    for (qw(sku partnumber description curr)) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}&nbsp;</td>| }

    for (qw(required leadtime lastcost fx)) { $column_data{$_} = qq|<td align=right>$form->{"${_}_$i"}</td>| }
    
    $column_data{qty} = qq|<td align=right><input name="qty_$i" size=6 value=$form->{"qty_$i"}></td>|;
   
    if ($form->{"$form->{vc}_id_$i"}) {
      $name = $form->{"$form->{vc}_$i"};
      $name =~ s/--.*//;
      $column_data{name} = qq|<td>$name</td>|;
      $form->hide_form("$form->{vc}_id_$i", "$form->{vc}_$i");
    } else {
      $column_data{name} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value="1"></td>|;
    }

    $form->hide_form(map { "${_}_$i" } qw(id sku partnumber description curr required leadtime lastcost fx name blankrow));
    
    $blankrow = $form->{"blankrow_$i"};

BLANKROW:
    $j++; $j %= 2;
    print "
        <tr class=listrow$j>";
    
    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

    if ($blankrow) {
      for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
      $blankrow = 0;

      goto BLANKROW;
    }
      
  }

  print qq|
      </table>
    </td>
  </tr>
  
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;

  $form->hide_form(qw(callback department ponumber path login sessionid employee_id vc nextsub rowcount type));
  
  print qq|
<button class="submit" type="submit" name="action" value="generate_orders">|.$locale->text('Generate Orders').qq|</button>|;

  print qq|
<button class="submit" type="submit" name="action" value="select_vendor">|.$locale->text('Select Vendor').qq|</button>|;
 
  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub generate_orders {

  if (OE->generate_orders(\%myconfig, \%$form)) {
    $form->redirect;
  } else {
    $form->error($locale->text('Order generation failed!'));
  }
  
}



sub consolidate_orders {

  for (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$_"}) {
      $ok = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $ok;
  
  ($null, $argv) = split /\?/, $form->{callback};
  
  for (split /\&/, $argv) {
    ($key, $value) = split /=/, $_;
    $form->{$key} = $value;
  }

  if (OE->consolidate_orders(\%myconfig, \%$form)) {
    $form->redirect;
  } else {
    $form->error($locale->text('Order generation failed!'));
  }

}


sub select_vendor {

  for (1 .. $form->{rowcount}) {
    last if ($ok = $form->{"ndx_$_"});
  }

  $form->error($locale->text('Nothing selected!')) unless $ok;
  
  $form->header;
  
  print qq|
<body onload="document.forms[0].vendor.focus()" />

<form method=post action=$form->{script}>

<b>|.$locale->text('Vendor').qq|</b> <input name=vendor size=40>

|;

  $form->{nextsub} = "vendor_selected";
  $form->{action} = "vendor_selected";
  
  $form->hide_form;
  
  print qq|
<button class="submit" type="submit" name="action" value="continue">|.$locale->text('Continue').qq|</button>

</form>
|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub vendor_selected {

  if (($rv = $form->get_name(\%myconfig, $form->{vc}, $form->{transdate})) > 1) {
    &select_name($form->{vc});
    exit;
  }

  if ($rv == 1) {
    for (1 .. $form->{rowcount}) {
      if ($form->{"ndx_$_"}) {
	$form->{"$form->{vc}_id_$_"} = $form->{name_list}[0]->{id};
	$form->{"$form->{vc}_$_"} = "$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}";
      }
    }
  } else {
    $msg = ucfirst $form->{vc} . " not on file!" unless $msg;
    $form->error($locale->text($msg));
  }

  &po_orderitems;
  
}


