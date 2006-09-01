#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# 
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# Inventory Control module
#
#======================================================================


use LedgerSMB::IC;

require "$form->{path}/io.pl";

1;
# end of main



sub add {

  %label = ( part	=> 'Part',
             service	=> 'Service',
	     assembly	=> 'Assembly',
	     labor	=> 'Labor/Overhead', );

# $locale->text('Add Part')
# $locale->text('Add Service')
# $locale->text('Add Assembly')
# $locale->text('Add Labor/Overhead')

  $label = "Add $label{$form->{item}}";
  $form->{title} = $locale->text($label);

  $form->{callback} = "$form->{script}?action=add&item=$form->{item}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  $form->{orphaned} = 1;

  if ($form->{previousform}) {
    $form->{callback} = "";
  }

  &link_part;
  
  &display_form;

}


sub edit {
  
 %label = ( part	=> 'Part',
            service	=> 'Service',
            assembly	=> 'Assembly',
	    labor	=> 'Labor/Overhead', );

# $locale->text('Edit Part')
# $locale->text('Edit Service')
# $locale->text('Edit Assembly')
# $locale->text('Edit Labor/Overhead')

  IC->get_part(\%myconfig, \%$form);

  $label = "Edit $label{$form->{item}}";
  $form->{title} = $locale->text($label);

  $form->{previousform} = $form->escape($form->{previousform}, 1) if $form->{previousform};

  &link_part;

  &display_form;

}



sub link_part {

  IC->create_links("IC", \%myconfig, \%$form);

  # currencies
  $form->{selectcurrency} = "";
  for (split /:/, $form->{currencies}) { $form->{selectcurrency} .= "<option>$_\n" }

  # readonly
  if ($form->{item} eq 'part') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Part/;
    $form->error($locale->text('Cannot create Part').";".$locale->text('Inventory account does not exist!')) if ! @{ $form->{IC_links}{IC} };
    $form->error($locale->text('Cannot create Part').";".$locale->text('Income account does not exist!')) if ! @{ $form->{IC_links}{IC_sale} };
    $form->error($locale->text('Cannot create Part').";".$locale->text('COGS account does not exist!')) if ! @{ $form->{IC_links}{IC_cogs} };
  }
  
  if ($form->{item} eq 'service') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Service/;
    $form->error($locale->text('Cannot create Service').";".$locale->text('Income account does not exist!')) if ! @{ $form->{IC_links}{IC_income} };
    $form->error($locale->text('Cannot create Service').";".$locale->text('Expense account does not exist!')) if ! @{ $form->{IC_links}{IC_expense} };
  }
  
  if ($form->{item} eq 'assembly') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Assembly/;
    $form->error($locale->text('Cannot create Assembly').";".$locale->text('Income account does not exist!')) if ! @{ $form->{IC_links}{IC_income} };
  }
  if ($form->{item} eq 'labor') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Labor\/Overhead/;
    $form->error($locale->text('Cannot create Labor').";".$locale->text('Inventory account does not exist!')) if ! @{ $form->{IC_links}{IC} };
    $form->error($locale->text('Cannot create Labor').";".$locale->text('COGS account does not exist!')) if ! @{ $form->{IC_links}{IC_cogs} };
  }

  
  # parts, assemblies , labor and overhead have the same links
  $taxpart = ($form->{item} eq 'service') ? "service" : "part";
 
  # build the popup menus
  $form->{taxaccounts} = "";
  foreach $key (keys %{ $form->{IC_links} }) {
    
    $form->{"select$key"} = "";
    foreach $ref (@{ $form->{IC_links}{$key} }) {
      # if this is a tax field
      if ($key =~ /IC_tax/) {
	if ($key =~ /$taxpart/) {
	  
	  $form->{taxaccounts} .= "$ref->{accno} ";
	  $form->{"IC_tax_$ref->{accno}_description"} = "$ref->{accno}--$ref->{description}";

	  if ($form->{id}) {
	    if ($form->{amount}{$ref->{accno}}) {
	      $form->{"IC_tax_$ref->{accno}"} = "checked";
	    }
	  } else {
	    $form->{"IC_tax_$ref->{accno}"} = "checked";
	  }
	  
	}
      } else {

	$form->{"select$key"} .= "<option>$ref->{accno}--$ref->{description}\n";
	
      }
    }
  }
  chop $form->{taxaccounts};

  if ($form->{item} !~ /service/) {
    $form->{selectIC_inventory} = $form->{selectIC};
    $form->{selectIC_income} = $form->{selectIC_sale};
    $form->{selectIC_expense} = $form->{selectIC_cogs};
    $form->{IC_income} = $form->{IC_sale};
    $form->{IC_expense} = $form->{IC_cogs};
  }

  # set option
  for (qw(IC_inventory IC_income IC_expense)) { $form->{$_} = "$form->{amount}{$_}{accno}--$form->{amount}{$_}{description}" if $form->{amount}{$_}{accno} }

  delete $form->{IC_links};
  delete $form->{amount};

  $form->get_partsgroup(\%myconfig, {all => 1});
  if ($form->{partsgroup}) {
    $form->{partsgroup} = $form->quote($form->{partsgroup})."--$form->{partsgroup_id}";
  }
  
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = qq|<option>\n|;

    for (@{ $form->{all_partsgroup} }) { $form->{selectpartsgroup} .= qq|<option value="|.$form->quote($_->{partsgroup}).qq|--$_->{id}">$_->{partsgroup}\n| }
    delete $form->{all_partsgroup};
  }

  if ($form->{item} eq 'assembly') {

    for (1 .. $form->{assembly_rows}) {
      if ($form->{"partsgroup_id_$_"}) {
	$form->{"partsgroup_$_"} = qq|$form->{"partsgroup_$_"}--$form->{"partsgroup_id_$_"}|;
      }
    }
    
    $form->get_partsgroup(\%myconfig);

    if (@{ $form->{all_partsgroup} }) {
      $form->{selectassemblypartsgroup} = qq|<option>\n|;

      for (@{ $form->{all_partsgroup} }) { $form->{selectassemblypartsgroup} .= qq|<option value="$_->{partsgroup}--$_->{id}">$_->{partsgroup}\n| }
      delete $form->{all_partsgroup};
    }
  }
  
  # setup make and models
  $i = 1;
  foreach $ref (@{ $form->{makemodels} }) {
    for (qw(make model)) { $form->{"${_}_$i"} = $ref->{$_} }
    $i++;
  }
  $form->{makemodel_rows} = $i - 1;
  delete $form->{makemodels};

  
  # setup vendors
  if (@{ $form->{all_vendor} }) {
    $form->{selectvendor} = "<option>\n";
    for (@{ $form->{all_vendor} }) { $form->{selectvendor} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
    delete $form->{all_vendor};
  }

  # vendor matrix
  $i = 1;
  foreach $ref (@{ $form->{vendormatrix} }) {
    $form->{"vendor_$i"} = qq|$ref->{name}--$ref->{id}|;

    for (qw(partnumber lastcost leadtime vendorcurr)) { $form->{"${_}_$i"} = $ref->{$_} }
    $i++;
  }
  $form->{vendor_rows} = $i - 1;
  delete $form->{vendormatrix};
  
  # setup customers and groups
  if (@{ $form->{all_customer} }) {
    $form->{selectcustomer} = "<option>\n";
    for (@{ $form->{all_customer} }) { $form->{selectcustomer} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
    delete $form->{all_customer};
  }

  if (@{ $form->{all_pricegroup} }) {
    $form->{selectpricegroup} = "<option>\n";
    for (@{ $form->{all_pricegroup} }) { $form->{selectpricegroup} .= qq|<option value="$_->{pricegroup}--$_->{id}">$_->{pricegroup}\n| }
    delete $form->{all_pricegroup};
  }

  $i = 1;
  # customer matrix
  foreach $ref (@{ $form->{customermatrix} }) {

    $form->{"customer_$i"} = "$ref->{name}--$ref->{cid}" if $ref->{cid};
    $form->{"pricegroup_$i"} = "$ref->{pricegroup}--$ref->{gid}" if $ref->{gid};

    for (qw(validfrom validto pricebreak customerprice customercurr)) { $form->{"${_}_$i"} = $ref->{$_} }

    $i++;
    
  }
  $form->{customer_rows} = $i - 1;
  delete $form->{customermatrix};

}



sub form_header {

  if ($form->{lastcost} > 0) {
    $markup = $form->round_amount((($form->{sellprice}/$form->{lastcost} - 1) * 100), 1);
    $form->{markup} = $form->format_amount(\%myconfig, $markup, 1);
  }
  
  ($dec) = ($form->{sellprice} =~ /\.(\d+)/);
  $dec = length $dec;
  $decimalplaces = ($dec > 2) ? $dec : 2;
  
  for (qw(listprice sellprice)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $decimalplaces) }
  
  ($dec) = ($form->{lastcost} =~ /\.(\d+)/);
  $dec = length $dec;
  $decimalplaces = ($dec > 2) ? $dec : 2;
 
  for (qw(lastcost avgcost)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $decimalplaces) }
  
  for (qw(weight rop stock)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}) }
  
  for (qw(partnumber description unit notes)) { $form->{$_} = $form->quote($form->{$_}) }

  if (($rows = $form->numtextrows($form->{notes}, 40)) < 2) {
    $rows = 2;
  }
  
  $notes = qq|<textarea name=notes rows=$rows cols=40 wrap=soft>$form->{notes}</textarea>|;

  if (($rows = $form->numtextrows($form->{description}, 40)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=40 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=40 value="$form->{description}">|;
  }
  
  for (split / /, $form->{taxaccounts}) { $form->{"IC_tax_$_"} = ($form->{"IC_tax_$_"}) ? "checked" : "" }

  $form->{selectIC_inventory} = $form->{selectIC};
  
  # set option
  for (qw(IC_inventory IC_income IC_expense)) {
    if ($form->{$_}) {
      if ($form->{orphaned}) {
	$form->{"select$_"} =~ s/ selected//;
	$form->{"select$_"} =~ s/option>\Q$form->{$_}\E/option selected>$form->{$_}/;
      } else {
	$form->{"select$_"} = qq|<option selected>$form->{$_}|;
      }
    }
  }

  if ($form->{selectpartsgroup}) {
    $form->{selectpartsgroup} = $form->unescape($form->{selectpartsgroup});

    $partsgroup = qq|<input type=hidden name=selectpartsgroup value="|.$form->escape($form->{selectpartsgroup},1).qq|">|;
    
    $form->{partsgroup} = $form->quote($form->{partsgroup});
    $form->{selectpartsgroup} =~ s/(<option value="\Q$form->{partsgroup}\E")/$1 selected/;

    $partsgroup .= qq|\n<select name=partsgroup>$form->{selectpartsgroup}</select>|;
    $group = $locale->text('Group');
  }

  # tax fields
  foreach $item (split / /, $form->{taxaccounts}) {
    $tax .= qq|
      <input class=checkbox type=checkbox name="IC_tax_$item" value=1 $form->{"IC_tax_$item"}>&nbsp;<b>$form->{"IC_tax_${item}_description"}</b>
      <br><input type=hidden name=IC_tax_${item}_description value="$form->{"IC_tax_${item}_description"}">
|;
  }

 
  $sellprice = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Sell Price').qq|</th>
		<td><input name=sellprice size=11 value=$form->{sellprice}></td>
	      </tr>
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('List Price').qq|</th>
		<td><input name=listprice size=11 value=$form->{listprice}></td>
	      </tr>
|;

  $avgcost = qq|
 	      <tr>
                <th align="right" nowrap="true">|.$locale->text('Average Cost').qq|</th>
                <td><input type=hidden name=avgcost value=$form->{avgcost}>$form->{avgcost}</td>
              </tr>
|;

  $lastcost = qq|
 	      <tr>
                <th align="right" nowrap="true">|.$locale->text('Last Cost').qq|</th>
                <td><input name=lastcost size=11 value=$form->{lastcost}></td>
              </tr>
	      <tr>
	        <th align="right" nowrap="true">|.$locale->text('Markup').qq| %</th>
		<td><input name=markup size=5 value=$form->{markup}></td>
		<input type=hidden name=oldmarkup value=$markup>
	      </tr>
|;


  if ($form->{item} =~ /(part|assembly)/) {
    $n = ($form->{onhand} > 0) ? "1" : "0";
    $onhand = qq|
	      <tr>
		<th align="right" nowrap>|.$locale->text('On Hand').qq|</th>
		<th align=left nowrap class="plus$n">&nbsp;|.$form->format_amount(\%myconfig, $form->{onhand}).qq|</th>
	      </tr>
|;

    $rop = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('ROP').qq|</th>
		<td><input name=rop size=10 value=$form->{rop}></td>
	      </tr>
|;
    
    $bin = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Bin').qq|</th>
		<td><input name=bin size=10 value="$form->{bin}"></td>
	      </tr>
|;
    
    $imagelinks = qq|
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <th align=right nowrap>|.$locale->text('Image').qq|</th>
	  <td><input name=image size=40 value="$form->{image}"></td>
	  <th align=right nowrap>|.$locale->text('Microfiche').qq|</th>
	  <td><input name=microfiche size=20 value="$form->{microfiche}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Drawing').qq|</th>
	  <td><input name=drawing size=40 value="$form->{drawing}"></td>
	</tr>
      </table>
    </td>
  </tr>
|;
  }


  if ($form->{item} eq "part") {

    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Inventory').qq|</th>
		<td><select name=IC_inventory>$form->{selectIC_inventory}</select></td>
		<input name=selectIC type=hidden value="$form->{selectIC}">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Income').qq|</th>
		<td><select name=IC_income>$form->{selectIC_income}</select></td>
		<input name=selectIC_income type=hidden value="$form->{selectIC_income}">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('COGS').qq|</th>
		<td><select name=IC_expense>$form->{selectIC_expense}</select></td>
		<input name=selectIC_expense type=hidden value="$form->{selectIC_expense}">
	      </tr>
|;
  
    if ($tax) {
      $linkaccounts .= qq|
	      <tr>
		<th align=right>|.$locale->text('Tax').qq|</th>
		<td>$tax</td>
	      </tr>
|;
    }
  
    $weight = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Weight').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>
			<input name=weight size=10 value=$form->{weight}>
		      </td>
		      <th>
			&nbsp;
			$form->{weightunit}
			<input type=hidden name=weightunit value=$form->{weightunit}>
		      </th>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
    
  }


  if ($form->{item} eq "assembly") {

    $avgcost = "";
    
    if ($form->{project_id}) {
      $weight = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Weight').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>
			<input name=weight size=10 value=$form->{weight}>
		      </td>
		      <th>
			&nbsp;
			$form->{weightunit}
			<input type=hidden name=weightunit value=$form->{weightunit}>
		      </th>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
    } else {
   
      $weight = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Weight').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>
			&nbsp;$form->{weight}
			<input type=hidden name=weight value=$form->{weight}>
		      </td>
		      <th>
			&nbsp;
			$form->{weightunit}
			<input type=hidden name=weightunit value=$form->{weightunit}>
		      </th>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
    }
    

    if ($form->{project_id}) {
      $lastcost = "";
      $avgcost = "";
      $onhand = "";
      $rop = "";
      $form->{isassemblyitem} = 1;

    } else {
      $stock = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Stock').qq|</th>
		<td><input name=stock size=10 value=$form->{stock}></td>
	      </tr>
|;

      $lastcost = qq|
              <tr>
	        <th align="right" nowrap="true">|.$locale->text('Last Cost').qq|</th> 
		<td><input type=hidden name=lastcost value=$form->{lastcost}>$form->{lastcost}</td>
	      </tr>
	      <tr>
	        <th align="right" nowrap="true">|.$locale->text('Markup').qq| %</th>
		<td><input name=markup size=5 value=$form->{markup}></td>
		<input type=hidden name=oldmarkup value=$markup>
	      </tr>
|;

    }

    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Income').qq|</th>
		<td><select name=IC_income>$form->{selectIC_income}</select></td>
		<input name=selectIC_income type=hidden value="$form->{selectIC_income}">
	      </tr>
|;
  
    if ($tax) {
      $linkaccounts .= qq|
	      <tr>
		<th align=right>|.$locale->text('Tax').qq|</th>
		<td>$tax</td>
	      </tr>
|;
    }
  
  }

 
  if ($form->{item} eq "service") {
    $avgcost = "";
    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Income').qq|</th>
		<td><select name=IC_income>$form->{selectIC_income}</select></td>
		<input name=selectIC_income type=hidden value="$form->{selectIC_income}">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Expense').qq|</th>
		<td><select name=IC_expense>$form->{selectIC_expense}</select></td>
		<input name=selectIC_expense type=hidden value="$form->{selectIC_expense}">
	      </tr>
|;
  
    if ($tax) {
      $linkaccounts .= qq|
	      <tr>
		<th align=right>|.$locale->text('Tax').qq|</th>
		<td>$tax</td>
	      </tr>
|;
    }

  }

  if ($form->{item} eq 'labor') {
    $avgcost = "";

    $n = ($form->{onhand} > 0) ? "1" : "0";
    $onhand = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('On Hand').qq|</th>
		<th align=left nowrap class="plus$n">&nbsp;|.$form->format_amount(\%myconfig, $form->{onhand}).qq|</th>
              </tr>
|;
    
    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Labor/Overhead').qq|</th>
		<td><select name=IC_inventory>$form->{selectIC_inventory}</select></td>
		<input name=selectIC type=hidden value="$form->{selectIC}">
	      </tr>

	      <tr>
		<th align=right>|.$locale->text('COGS').qq|</th>
		<td><select name=IC_expense>$form->{selectIC_expense}</select></td>
		<input name=selectIC_expense type=hidden value="$form->{selectIC_expense}">
	      </tr>
|;
  
  }

  if ($form->{id}) {
    $checked = ($form->{obsolete}) ? "checked" : "";
    $obsolete = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Obsolete').qq|</th>
		<td><input name=obsolete type=checkbox class=checkbox value=1 $checked></td>
	      </tr>
|;
    $obsolete = "<input type=hidden name=obsolete value=$form->{obsolete}>" if $form->{project_id};
  }


# type=submit $locale->text('Edit Part')
# type=submit $locale->text('Edit Service')
# type=submit $locale->text('Edit Assembly')


  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">
|;

  $form->hide_form(qw(id item title makemodel alternate onhand orphaned taxaccounts rowcount baseassembly project_id));
  
  print qq|
<table width="100%">
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
          <th align=left>|.$locale->text('Number').qq|</th>
          <th align=left>|.$locale->text('Description').qq|</th>
	  <th align=left>$group</th>
	</tr>
	<tr valign=top>
          <td><input name=partnumber value="$form->{partnumber}" size=20></td>
          <td>$description</td>
	  <td>$partsgroup</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width="100%" height="100%">
        <tr valign=top>
          <td width=70%>
            <table width="100%" height="100%">
              <tr class="listheading">
                <th class="listheading" align="center" colspan=2>|.$locale->text('Link Accounts').qq|</th>
              </tr>
              $linkaccounts
              <tr>
                <th align="left">|.$locale->text('Notes').qq|</th>
              </tr>
              <tr>
                <td colspan=2>
                  $notes
                </td>
              </tr>
            </table>
          </td>
	  <td width="30%">
	    <table width="100%">
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Updated').qq|</th>
		<td><input name=priceupdate size=11 title="$myconfig{dateformat}" value=$form->{priceupdate}></td>    
	      </tr>
	      $sellprice
	      $lastcost
	      $avgcost
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Unit').qq|</th>
		<td><input name=unit size=5 value="$form->{unit}"></td>
	      </tr>
	      $weight
	      $onhand
	      $stock
	      $rop
	      $bin
	      $obsolete
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  $imagelinks
|;
}


sub form_footer {

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(customer_rows));

  if ($form->{item} =~ /(part|assembly)/) {
    $form->hide_form(qw(makemodel_rows));
  }
  
  if ($form->{item} =~ /(part|service)/) {
    $form->hide_form(qw(vendor_rows));
  }

# type=submit $locale->text('Update')
# type=submit $locale->text('Save')
# type=submit $locale->text('Save as new')
# type=submit $locale->text('Delete')

  if (! $form->{readonly}) {
    
    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'Save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
	      );
    
    if ($form->{id}) {

      if (!$form->{isassemblyitem}) {
	$button{'Save as new'} = { ndx => 7, key => 'N', value => $locale->text('Save as new') };
      }

      if ($form->{orphaned}) {
	$button{'Delete'} = { ndx => 16, key => 'D', value => $locale->text('Delete') };
      }
    }
    
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  &assembly_row(++$form->{assembly_rows}) if $form->{item} eq 'assembly';

  $form->hide_form(qw(login path sessionid callback previousform isassemblyitem));
  
  print qq|
</form>

</body>
</html>
|;

}


sub search {

  $form->get_partsgroup(\%myconfig, { searchitems => $form->{searchitems}});

  IC->get_warehouses(\%myconfig, \%$form) unless $form->{searchitems} =~ /(service|labor)/;

  if (@{ $form->{all_partsgroup} }) {
    $partsgroup = qq|<option>\n|;

    for (@{ $form->{all_partsgroup} }) { $partsgroup .= qq|<option value="|.$form->quote($_->{partsgroup}).qq|--$_->{id}">$_->{partsgroup}\n| }

    $partsgroup = qq| 
        <th align=right nowrap>|.$locale->text('Group').qq|</th>
	<td><select name=partsgroup>$partsgroup</select></td>
|;

    $l_partsgroup = qq|<input name=l_partsgroup class=checkbox type=checkbox value=Y> |.$locale->text('Group');
  }

  $l_listprice = qq|<input name=l_listprice class=checkbox type=checkbox value=Y> |.$locale->text('List Price');
  $l_sellprice = qq|<input name=l_sellprice class=checkbox type=checkbox value=Y checked> |.$locale->text('Sell Price');
  $l_lastcost = qq|<input name=l_lastcost class=checkbox type=checkbox value=Y checked> |.$locale->text('Last Cost');
  $l_avgcost = qq|<input name=l_avgcost class=checkbox type=checkbox value=Y checked> |.$locale->text('Average Cost');
  $l_linetotal = qq|<input name=l_linetotal class=checkbox type=checkbox value=Y> |.$locale->text('Line Total');
  $l_markup = qq|<input name=l_markup class=checkbox type=checkbox value=Y> |.$locale->text('Markup');
  $l_account = qq|<input name=l_account class=checkbox type=checkbox value=Y> |.$locale->text('Accounts');
  
  $bought = qq|
          <td>
	    <table>
	      <tr>
		<td><input name=bought class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Vendor Invoices').qq|</td>
	      </tr>
	      <tr>
		<td><input name=onorder class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Purchase Orders').qq|</td>
	      </tr>
	      <tr>
		<td><input name=rfq class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('RFQ').qq|</td>
	      </tr>
	    </table>
	  </td>
|;

  $sold = qq|
	  <td>
	    <table>
	      <tr>
		<td><input name=sold class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Sales Invoices').qq|</td>
	      </tr>
	      <tr>
		<td><input name=ordered class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Sales Orders').qq|</td>
	      </tr>
	      <tr>
		<td><input name=quoted class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Quotations').qq|</td>
	      </tr>
	    </table>
	  </td>
|;

  $fromto = qq|
	  <td>
	    <table>
	      <tr>
		<td nowrap><b>|.$locale->text('From').qq|</b>
		<input name=transdatefrom size=11 title="$myconfig{dateformat}">
		<b>|.$locale->text('To').qq|</b>
		<input name=transdateto size=11 title="$myconfig{dateformat}"></td>
	      </tr>
	      <tr>
		<td nowrap><input name=method class=radio type=radio value=accrual checked>|.$locale->text('Accrual').qq|
		<input name=method class=radio type=radio value=cash>|.$locale->text('Cash').qq|</td>
	      </tr>
	      <tr>
		<td nowrap>
		<input name=open class=checkbox type=checkbox value=1 checked> |.$locale->text('Open').qq|
		<input name=closed class=checkbox type=checkbox> |.$locale->text('Closed').qq|
		<input name=summary type=radio class=radio value=1> |.$locale->text('Summary').qq|
		<input name=summary type=radio class=radio value=0 checked> |.$locale->text('Detail').qq|
		</td>
	      </tr>
	    </table>
	  </td>
|;

  $l_name = qq|<input name=l_name class=checkbox type=checkbox value=Y> |.$locale->text('Name');
  $l_curr = qq|<input name=l_curr class=checkbox type=checkbox value=Y> |.$locale->text('Currency');
  $l_employee = qq|<input name=l_employee class=checkbox type=checkbox value=Y> |.$locale->text('Employee');
  $l_serialnumber = qq|<input name=l_serialnumber class=checkbox type=checkbox value=Y> |.$locale->text('Serial Number');

  $serialnumber = qq|
          <th align=right nowrap>|.$locale->text('Serial Number').qq|</th>
          <td><input name=serialnumber size=20></td>
|;

  $orphaned = qq|
            <input name=itemstatus class=radio type=radio value=orphaned>&nbsp;|.$locale->text('Orphaned');

  if ($form->{searchitems} =~ /(all|part|assembly)/) {
    
    $onhand = qq|
            <input name=itemstatus class=radio type=radio value=onhand>&nbsp;|.$locale->text('On Hand').qq|
            <input name=itemstatus class=radio type=radio value=short>&nbsp;|.$locale->text('Short').qq|
|;

    $makemodel = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Make').qq|</th>
          <td><input name=make size=20></td>
          <th align=right nowrap>|.$locale->text('Model').qq|</th>
          <td><input name=model size=20></td>
        </tr>
|;

    $l_make = qq|<input name=l_make class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Make');
    $l_model = qq|<input name=l_model class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Model');

    $l_bin = qq|<input name=l_bin class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Bin');

    $l_rop = qq|<input name=l_rop class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('ROP');

    $l_weight = qq|<input name=l_weight class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Weight');


    if (@{ $form->{all_warehouse} }) {
      $selectwarehouse = "<option>\n";

      for (@{ $form->{all_warehouse} }) { $selectwarehouse .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
      
      $warehouse = qq|
          <th align=right nowrap>|.$locale->text('Warehouse').qq|</th>
          <td><select name=warehouse>$selectwarehouse</select></td>
|;

      $l_warehouse = qq|<input name=l_warehouse class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Warehouse');

    }

    $drawing = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Drawing').qq|</th>
          <td><input name=drawing size=20></td>
          <th align=right nowrap>|.$locale->text('Microfiche').qq|</th>
          <td><input name=microfiche size=20></td>
        </tr>
|;

    $l_image = qq|<input name=l_image class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Image');
    
    $l_drawing = qq|<input name=l_drawing class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Drawing');
    $l_microfiche = qq|<input name=l_microfiche class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Microfiche');

  }

  if ($form->{searchitems} eq 'assembly') {

    $bought = "";
 
    $toplevel = qq|
        <tr>
	  <td></td>
          <td colspan=3>
	  <input name=null class=radio type=radio checked>&nbsp;|.$locale->text('Top Level').qq|
	  <input name=individual class=checkbox type=checkbox value=1>&nbsp;|.$locale->text('Individual Items').qq|
          </td>
        </tr>
|;
    $bom = qq|<input name=itemstatus type=radio value=bom>&nbsp;|.$locale->text('BOM');
    
  } elsif ($form->{searchitems} eq 'component') {

    $bought = "";
    $sold = "";
    $fromto = "";
    $l_name = "";
    $l_curr = "";
    $l_employee = "";
    $l_serialnumber = "";

    $warehouse = "";
    $serialnumber = "";
    $orphaned = "";
    $l_warehouse = "";
    $l_account = "";
  
  } elsif ($form->{searchitems} eq 'labor') {

    $sold = "";

    $warehouse = "";
    $serialnumber = "";
    $l_avgcost = "";
    
  }
  

  @a = ();
  push @a, qq|<input name=l_runningnumber class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('No.');
  push @a, qq|<input name=l_partnumber class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Number');
  push @a, qq|<input name=l_description class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Description');
  push @a, qq|<input name=l_qty class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Qty');
  push @a, qq|<input name=l_unit class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Unit');
  push @a, qq|<input name=l_priceupdate class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Updated');
  push @a, $l_partsgroup if $l_partsgroup;
  push @a, $l_listprice if $l_listprice;
  push @a, $l_sellprice if $l_sellprice;
  push @a, $l_lastcost if $l_lastcost;
  push @a, $l_avgcost if $l_avgcost;
  push @a, $l_linetotal if $l_linetotal;
  push @a, $l_markup if $l_markup;
  push @a, $l_bin if $l_bin;
  push @a, $l_rop if $l_rop;
  push @a, $l_weight if $l_weight;
  push @a, qq|<input name=l_notes class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Notes');
  push @a, $l_image if $l_image;
  push @a, $l_drawing if $l_drawing;
  push @a, $l_microfiche if $l_microfiche;
  push @a, $l_make if $l_make;
  push @a, $l_model if $l_model;
  push @a, $l_warehouse if $l_warehouse;
  push @a, $l_account if $l_account;
  push @a, $l_name if $l_name;
  push @a, $l_curr if $l_curr;
  push @a, $l_employee if $l_employee;
  push @a, $l_serialnumber if $l_serialnumber;

  %title = ( all	=> 'Items',
             part	=> 'Parts',
	     labor	=> 'Labor/Overhead',
	     service	=> 'Services',
	     assembly	=> 'Assemblies',
	     component	=> 'Components'
	   );

# $locale->text('Items')
# $locale->text('Parts')
# $locale->text('Labor/Overhead')
# $locale->text('Services')
# $locale->text('Assemblies')
# $locale->text('Components')
  
  $form->{title} = $locale->text($title{$form->{searchitems}});
   
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(searchitems title));

  print qq|

<table width="100%">
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name=description size=40></td>
        </tr>
	<tr>
	  $warehouse
	</tr>
	<tr>
	  $partsgroup
	  $serialnumber
	</tr>
	$makemodel
	$drawing
	$toplevel
        <tr>
          <td></td>
          <td colspan=3>
            <input name=itemstatus class=radio type=radio value=active checked>&nbsp;|.$locale->text('Active').qq|
	    $onhand
            <input name=itemstatus class=radio type=radio value=obsolete>&nbsp;|.$locale->text('Obsolete').qq|
	    $orphaned
	    $bom
	  </td>
	</tr>
        <tr>
	  <td></td>
          <td colspan=3>
	    <hr size=1 noshade>
	  </td>
	</tr>
	<tr>
	  <td></td>
	  $bought
	  $sold
	  $fromto
        <tr>
	  <td></td>
          <td colspan=3>
	    <hr size=1 noshade>
	  </td>
	</tr>
	<tr>
          <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
          <td colspan=3>
            <table>
              <tr>
|;

  while (@a) {
    for (1 .. 5) {
      print qq|<td nowrap>|. shift @a;
      print qq|</td>\n|;
    }
    print qq|</tr>\n|;
  }

  print qq|
              </tr>
	      <tr>
                <td><input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|</td>
	      </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td colspan=4><hr size=3 noshade></td></tr>
</table>

<input type=hidden name=nextsub value=generate_report>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->hide_form(qw(path login sessionid));
  
  print qq|
</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  
</body>
</html>
|;

}



sub generate_report {

  # setup $form->{sort}
  unless ($form->{sort}) {
    if ($form->{description} && !($form->{partnumber})) {
      $form->{sort} = "description";
    } else {
      $form->{sort} = "partnumber";
    }
  }
  
  if ($form->{itemstatus} eq 'bom') {
    $form->{l_perassembly} = "Y" if $form->{l_qty} eq "Y";
    $form->{individual} = 1;
    $form->{title} = $locale->text('BOM');
  }

  $callback = "$form->{script}?action=generate_report";
  for (qw(path login sessionid searchitems itemstatus individual bom l_linetotal method)) { $callback .= qq|&$_=$form->{$_}| }
  for (qw(warehouse partsgroup title)) { $callback .= qq|&$_=|.$form->escape($form->{$_},1) }

  # if we have a serialnumber limit search
  if ($form->{serialnumber} || $form->{l_serialnumber}) {
    $form->{l_serialnumber} = "Y";
    unless ($form->{bought} || $form->{sold} || $form->{onorder} || $form->{ordered}) {
      if ($form->{searchitems} eq 'assembly') {
	$form->{sold} = $form->{ordered} = 1;
      } else {
	$form->{bought} = $form->{sold} = $form->{onorder} = $form->{ordered} = 1;
      }
    }
  }

 
  if ($form->{itemstatus} eq 'active') {
    $option .= $locale->text('Active')." : ";
  }
  if ($form->{itemstatus} eq 'obsolete') {
    $form->{onhand} = $form->{short} = 0;
    
    $form->{l_qty} = 0;
    $form->{warehouse} = "";
    $form->{l_warehouse} = 0;

    $option .= $locale->text('Obsolete')." : ";
  }
  if ($form->{itemstatus} eq 'orphaned') {
    $form->{onhand} = $form->{short} = 0;
    $form->{bought} = $form->{sold} = 0;
    $form->{onorder} = $form->{ordered} = 0;
    $form->{rfq} = $form->{quoted} = 0;

    $form->{l_qty} = 0;
    $form->{warehouse} = "";
    $form->{l_warehouse} = 0;

    $form->{transdatefrom} = $form->{transdateto} = "";
    
    $option .= $locale->text('Orphaned')." : ";
  }
  if ($form->{itemstatus} eq 'onhand') {
    $option .= $locale->text('On Hand')." : ";
    $form->{l_onhand} = "Y";
  }
  if ($form->{itemstatus} eq 'short') {
    $option .= $locale->text('Short')." : ";
    $form->{l_onhand} = "Y";
    $form->{l_rop} = "Y" unless $form->{searchitems} eq 'labor';
    
    $form->{warehouse} = "";
    $form->{l_warehouse} = 0;
  }

  if ($form->{l_account}) {
    for (qw(l_name l_curr l_employee)) { delete $form->{$_} }
  } else {
    $ok = 0; 
    foreach $l (qw(l_name l_curr l_employee)) {
      if ($form->{$l}) {
	foreach $v (qw(onorder ordered rfq quoted bought sold)) {
	  if ($form->{$v}) {
	    $ok = 1; 
	    last; 
	  }
	}
	if (!$ok) {
	  for (qw(onorder ordered rfq quoted bought sold)) { $form->{$_} = 1 }
	}
	last;
      }
    }
  }

  if ($form->{onorder}) {
    $form->{l_ordnumber} = "Y";
    $callback .= "&onorder=$form->{onorder}";
    $option .= $locale->text('Purchase Order')." : ";
  }
  if ($form->{ordered}) {
    $form->{l_ordnumber} = "Y";
    $callback .= "&ordered=$form->{ordered}";
    $option .= $locale->text('Sales Order')." : ";
  }
  if ($form->{rfq}) {
    $form->{l_quonumber} = "Y";
    $callback .= "&rfq=$form->{rfq}";
    $option .= $locale->text('RFQ')." : ";
  }
  if ($form->{quoted}) {
    $form->{l_quonumber} = "Y";
    $callback .= "&quoted=$form->{quoted}";
    $option .= $locale->text('Quotation')." : ";
  }
  if ($form->{bought}) {
    $form->{l_invnumber} = "Y";
    $callback .= "&bought=$form->{bought}";
    $option .= $locale->text('Vendor Invoice')." : ";
  }
  if ($form->{sold}) {
    $form->{l_invnumber} = "Y";
    $callback .= "&sold=$form->{sold}";
    $option .= $locale->text('Sales Invoice')." : ";
  }
  if ($form->{sold} || $form->{bought}) {
    $label = ucfirst $form->{method};
    $option .= $locale->text($label) ." : ";
  }

  if ($form->{bought} || $form->{sold} || $form->{onorder} || $form->{ordered} || $form->{rfq} || $form->{quoted}) {
    
    # warehouse stuff is meaningless
    $form->{warehouse} = "";
    $form->{l_warehouse} = 0;
    
    $form->{l_account} = "";

    if ($form->{open}) {
      $callback .= "&open=$form->{open}";
      $option .= $locale->text('Open');
    }
    if ($form->{closed}) {
      $callback .= "&closed=$form->{closed}";
      if ($form->{open}) {
	$option .= " : ".$locale->text('Closed');
      } else {
	$option .= $locale->text('Closed');
      }
    }
    if ($form->{summary}) {
      $callback .= "&summary=$form->{summary}";
      $option .= " : ".$locale->text('Summary');
      $form->{l_ordnumber} = "";
      $form->{l_quonumber} = "";
      $form->{l_invnumber} = "";
    } else {
      $option .= " : ".$locale->text('Detail');
    }
 
    if ($form->{transdatefrom}) {
      $callback .= "&transdatefrom=$form->{transdatefrom}";
      $option .= "\n<br>".$locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
    }
    if ($form->{transdateto}) {
      $callback .= "&transdateto=$form->{transdateto}";
      $option .= "\n<br>".$locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
    }
  }
  
  if ($form->{warehouse}) {
    ($warehouse) = split /--/, $form->{warehouse};
    $option .= "<br>".$locale->text('Warehouse')." : $warehouse";
    $form->{l_warehouse} = 0;
  }
 
  $option .= "<br>";
  
  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $option .= $locale->text('Number').qq| : $form->{partnumber}<br>|;
  }
  if ($form->{partsgroup}) {
    ($partsgroup) = split /--/, $form->{partsgroup};
    $option .= $locale->text('Group').qq| : $partsgroup<br>|;
  }
  if ($form->{serialnumber}) {
    $callback .= "&serialnumber=".$form->escape($form->{serialnumber},1);
    $option .= $locale->text('Serial Number').qq| : $form->{serialnumber}<br>|;
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $description = $form->{description};
    $description =~ s/\r?\n/<br>/g;
    $option .= $locale->text('Description').qq| : $form->{description}<br>|;
  }
  if ($form->{make}) {
    $callback .= "&make=".$form->escape($form->{make},1);
    $option .= $locale->text('Make').qq| : $form->{make}<br>|;
  }
  if ($form->{model}) {
    $callback .= "&model=".$form->escape($form->{model},1);
    $option .= $locale->text('Model').qq| : $form->{model}<br>|;
  }
  if ($form->{drawing}) {
    $callback .= "&drawing=".$form->escape($form->{drawing},1);
    $option .= $locale->text('Drawing').qq| : $form->{drawing}<br>|;
  }
  if ($form->{microfiche}) {
    $callback .= "&microfiche=".$form->escape($form->{microfiche},1);
    $option .= $locale->text('Microfiche').qq| : $form->{microfiche}<br>|;
  }

  if ($form->{l_markup}) {
    $form->{l_sellprice} = "Y";
    $form->{l_lastcostmarkup} = "Y" if $form->{l_lastcost};
    $form->{l_avgcostmarkup} = "Y" if $form->{l_avgcost};
  }

  
  @columns = $form->sort_columns(qw(partnumber description notes assemblypartnumber partsgroup make model bin onhand perassembly rop unit listprice linetotallistprice sellprice linetotalsellprice lastcost linetotallastcost lastcostmarkup avgcost linetotalavgcost avgcostmarkup curr priceupdate weight image drawing microfiche invnumber ordnumber quonumber name employee serialnumber warehouse));
  unshift @columns, "runningnumber";

  if ($form->{l_linetotal}) {
    $form->{l_onhand} = "Y";
    $form->{l_linetotalsellprice} = "Y" if $form->{l_sellprice};
    $form->{l_linetotallastcost} = "Y" if $form->{l_lastcost};
    $form->{l_linetotalavgcost} = "Y" if $form->{l_avgcost};
    $form->{l_linetotallistprice} = "Y" if $form->{l_listprice};
  }

  if ($form->{searchitems} eq 'service') {
    # remove bin, weight and rop from list
    for (qw(bin weight rop)) { $form->{"l_$_"} = "" }

    $form->{l_onhand} = "";
    # qty is irrelevant unless bought or sold
    if ($form->{bought} || $form->{sold} || $form->{onorder} ||
        $form->{ordered} || $form->{rfq} || $form->{quoted}) {
      $form->{l_onhand} = "Y";
    } else {
      for (qw(sellprice lastcost avgcost listprice)) { $form->{"l_linetotal$_"} = "" }
    }
  } else {
    $form->{l_onhand} = "Y" if $form->{l_qty};
  }
 
  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to callback
      $callback .= "&l_$item=Y";
    }
  }

  if ($form->{l_account} eq 'Y') {
    if ($form->{searchitems} eq 'all' || $form->{searchitems} eq 'part') {
      push @column_index, (qw(inventory income expense tax));
    } elsif ($form->{searchitems} eq 'service') {
      push @column_index, (qw(income expense tax));
    } elsif ($form->{searchitems} eq 'assembly') {
      push @column_index, (qw(income tax));
    } else {
      push @column_index, (qw(inventory expense));
    }

    $callback .= "&l_account=Y";
  }
  
  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
  }

  IC->all_parts(\%myconfig, \%$form);

  $callback .= "&direction=$form->{direction}&oldsort=$form->{oldsort}";
  
  $href = $callback;
  
  $form->sort_order();
  
  $callback =~ s/(direction=).*?\&/$1$form->{direction}\&/;

  if ($form->{searchitems} eq 'assembly') {
    if ($form->{l_partnumber}) {
      # replace partnumber with partnumber_
      $ndx = 0;
      foreach $item (@column_index) {
	$ndx++;
	last if $item eq 'partnumber';
      }

      splice @column_index, $ndx, 0, map { "partnumber_$_" } (1 .. $form->{pncol});
      $colspan = $form->{pncol} + 1;
    }
  }

  if ($form->{searchitems} eq 'component') {
    if ($form->{l_partnumber}) {
      # splice it in after the partnumber
      $ndx = 0;
      foreach $item (@column_index) {
	$ndx++;
	last if $item eq 'partnumber';
      }
      
      @a = splice @column_index, 0, $ndx;
      unshift @column_index, "assemblypartnumber";
      unshift @column_index, @a;
    }
  }
  
    
  $column_header{runningnumber} = qq|<th a class=listheading>&nbsp;</th>|;
  $column_header{partnumber} = qq|<th nowrap colspan=$colspan><a class=listheading href=$href&sort=partnumber>|.$locale->text('Number').qq|</a></th>|;
  $column_header{description} = qq|<th nowrap><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{notes} = qq|<th nowrap class=listheading>|.$locale->text('Notes').qq|</th>|;
  $column_header{partsgroup} = qq|<th nowrap><a class=listheading href=$href&sort=partsgroup>|.$locale->text('Group').qq|</a></th>|;
  $column_header{bin} = qq|<th><a class=listheading href=$href&sort=bin>|.$locale->text('Bin').qq|</a></th>|;
  $column_header{priceupdate} = qq|<th nowrap><a class=listheading href=$href&sort=priceupdate>|.$locale->text('Updated').qq|</a></th>|;
  $column_header{onhand} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_header{perassembly} = qq|<th>&nbsp;</th>|;
  $column_header{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_header{listprice} = qq|<th class=listheading nowrap>|.$locale->text('List Price').qq|</th>|;
  $column_header{lastcost} = qq|<th class=listheading nowrap>|.$locale->text('Last Cost').qq|</th>|;
  $column_header{avgcost} = qq|<th class=listheading nowrap>|.$locale->text('Avg Cost').qq|</th>|;
  $column_header{rop} = qq|<th class=listheading nowrap>|.$locale->text('ROP').qq|</th>|;
  $column_header{weight} = qq|<th class=listheading nowrap>|.$locale->text('Weight').qq|</th>|;
  $column_header{avgcostmarkup} = qq|<th class=listheading nowrap>%</th>|;
  $column_header{lastcostmarkup} = qq|<th class=listheading nowrap>%</th>|;

  $column_header{make} = qq|<th nowrap><a class=listheading href=$href&sort=make>|.$locale->text('Make').qq|</a></th>|;
  $column_header{model} = qq|<th nowrap><a class=listheading href=$href&sort=model>|.$locale->text('Model').qq|</a></th>|;
  
  $column_header{invnumber} = qq|<th nowrap><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice Number').qq|</a></th>|;
  $column_header{ordnumber} = qq|<th nowrap><a class=listheading href=$href&sort=ordnumber>|.$locale->text('Order Number').qq|</a></th>|;
  $column_header{quonumber} = qq|<th nowrap><a class=listheading href=$href&sort=quonumber>|.$locale->text('Quotation').qq|</a></th>|;
  
  $column_header{name} = qq|<th nowrap><a class=listheading href=$href&sort=name>|.$locale->text('Name').qq|</a></th>|;
  
  $column_header{employee} = qq|<th nowrap><a class=listheading href=$href&sort=employee>|.$locale->text('Employee').qq|</a></th>|;
  
  $column_header{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Sell Price').qq|</th>|;
  
  for (qw(sellprice lastcost avgcost listprice)) { $column_header{"linetotal$_"} = qq|<th class=listheading nowrap>|.$locale->text('Extended').qq|</th>| }
  
  $column_header{curr} = qq|<th nowrap><a class=listheading href=$href&sort=curr>|.$locale->text('Curr').qq|</a></th>|;
  
  $column_header{image} = qq|<th class=listheading nowrap>|.$locale->text('Image').qq|</a></th>|;
  $column_header{drawing} = qq|<th nowrap><a class=listheading href=$href&sort=drawing>|.$locale->text('Drawing').qq|</a></th>|;
  $column_header{microfiche} = qq|<th nowrap><a class=listheading href=$href&sort=microfiche>|.$locale->text('Microfiche').qq|</a></th>|;
  
  $column_header{serialnumber} = qq|<th nowrap><a class=listheading href=$href&sort=serialnumber>|.$locale->text('Serial Number').qq|</a></th>|;
  
  $column_header{assemblypartnumber} = qq|<th nowrap><a class=listheading href=$href&sort=assemblypartnumber>|.$locale->text('Assembly').qq|</a></th>|;
  
  $column_header{warehouse} = qq|<th nowrap class=listheading>|.$locale->text('Warehouse').qq|</th>|;

  $column_header{inventory} = qq|<th nowrap class=listheading>|.$locale->text('Inventory').qq|</th>|;
  $column_header{income} = qq|<th nowrap class=listheading>|.$locale->text('Income').qq|</th>|;
  $column_header{expense} = qq|<th nowrap class=listheading>|.$locale->text('Expense').qq|</th>|;
  $column_header{tax} = qq|<th nowrap class=listheading>|.$locale->text('Tax').qq|</th>|;
  
  $form->header;

  $i = 1;
  if ($form->{searchitems} eq 'part') {
    $button{'Goods & Services--Add Part'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Part').qq|"> |;
    $button{'Goods & Services--Add Part'}{order} = $i++;
  }
  if ($form->{searchitems} eq 'service') {
    $button{'Goods & Services--Add Service'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Service').qq|"> |;
    $button{'Goods & Services--Add Service'}{order} = $i++;
  }
  if ($form->{searchitems} eq 'assembly') {  
    $button{'Goods & Services--Add Assembly'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Assembly').qq|"> |;
    $button{'Goods & Services--Add Assembly'}{order} = $i++;
  }
  if ($form->{searchitems} eq 'labor') {  
    $button{'Goods & Services--Add Labor/Overhead'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Labor/Overhead').qq|"> |;
    $button{'Goods & Services--Add Labor/Overhead'}{order} = $i++;
  }

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>

  <tr><td>$option</td></tr>

  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }
  
  print qq|
        </tr>
  |;


  # add order to callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);


  $k = $#{@{ $form->{parts} }};
  @groupby = ($form->{sort});
  
  if ($form->{summary}) {
    @groupby = ();
    for (qw(partnumber description notes partsgroup make model bin curr priceupdate image drawing microfiche invnumber ordnumber quonumber name employee serialnumber warehouse)) { $a{$_} = 1 };

    for (@column_index) {
      if ($a{$_}) {
	push @groupby, $_;
      }
    }
    push @groupby, "id";
  }

  if ($k > 0) {
    $samegroup = "";
    for (@groupby) { $samegroup .= $form->{parts}->[0]->{$_} }
  }

  $i = 0;
  $n = 0;

  foreach $ref (@{ $form->{parts} }) {

    $ref->{exchangerate} ||= 1;
    $ref->{discount} *= 1;

    if ($form->{summary}) {
      
      $summary{$ref->{id}}{total} += $ref->{sellprice} * $ref->{onhand};
      $summary{$ref->{id}}{onhand} += $ref->{onhand};
     
      if ($n < $k) {
	$nextgroup = "";
	for (@groupby) { $nextgroup .= $form->{parts}->[$n+1]->{$_} }
	$n++;

	$form->{parts}->[$n]->{exchangerate} ||= 1;

        if ($samegroup eq $nextgroup) {
	  for (qw(exchangerate discount)) { $form->{parts}->[$n]->{$_} = ($ref->{$_} + $form->{parts}->[$n]->{$_}) / 2 }
	  next;
	}
	$samegroup = $nextgroup;
      }

      $ref->{onhand} = $summary{$ref->{id}}{onhand};
      $ref->{sellprice} = ($ref->{onhand}) ? $summary{$ref->{id}}{total} / $ref->{onhand} : 0;
      
      $summary{$ref->{id}}{total} = 0;
      $summary{$ref->{id}}{onhand} = 0;
      
    }
    
    if ($form->{l_subtotal} eq 'Y' && !$ref->{assemblyitem}) {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&parts_subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }
    
    $i++;

    if ($form->{l_curr}) {
      if ($ref->{module} eq 'oe') {
	$ref->{sellprice} = $ref->{sellprice} * (1 - $ref->{discount});
      } else {
	for (qw(sellprice listprice lastcost avgcost)) { $ref->{$_} /= $ref->{exchangerate} }
      }
    } else {
      if ($ref->{module} eq 'oe') {
	$ref->{sellprice} = $ref->{sellprice} * (1 - $ref->{discount});
	for (qw(sellprice listprice lastcost avgcost)) { $ref->{$_} *= $ref->{exchangerate} }
      }
    }

    if (!$form->{summary}) {
      for (qw(sellprice listprice lastcost avgcost)) { $ref->{$_} = $form->round_amount($ref->{$_}, 2) }
    }

    if ($form->{l_markup}) {
      $ref->{lastcostmarkup} = (($ref->{sellprice} / $ref->{lastcost}) - 1) * 100 if $ref->{lastcost} != 0;
      $ref->{avgcostmarkup} = (($ref->{sellprice} / $ref->{avgcost}) - 1) * 100 if $ref->{avgcost} != 0;
    }
    
    # use this for assemblies
    $onhand = $ref->{onhand};

    for (qw(description notes)) { $ref->{$_} =~ s/\r?\n/<br>/g }
    
    for (1 .. $form->{pncol}) { $column_data{"partnumber_$_"} = "<td>&nbsp;</td>" }

    $column_data{runningnumber} = "<td align=right>$i</td>";
    $column_data{partnumber} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";

    if ($ref->{assemblypartnumber}) {
      if ($sameid eq $ref->{id}) {
	$i--;
	for (qw(runningnumber partnumber)) { $column_data{$_} = "<td>&nbsp;</td>" }
      }
    }
    
    $column_data{assemblypartnumber} = "<td><a href=$form->{script}?action=edit&id=$ref->{assembly_id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{assemblypartnumber}&nbsp;</a></td>";

    if ($ref->{assemblyitem}) {
      $onhand = 0 if $form->{sold};
      $ref->{income} = "";
      
      for (qw(runningnumber partnumber)) { $column_data{$_} = "<td>&nbsp;</td>" }
      $i--;
      
      $column_data{"partnumber_$ref->{stagger}"} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";

    }
    
    for (qw(description notes partsgroup employee curr)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    $column_data{onhand} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{onhand}, '', "&nbsp;")."</td>";
    $column_data{perassembly} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{perassembly}, '', "&nbsp;")."</td>";

    if ($form->{summary}) {
      $column_data{sellprice} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{sellprice}, 4, "&nbsp;") . "</td>";
    } else {
      $column_data{sellprice} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{sellprice}, 2, "&nbsp;") . "</td>";
    }
    for (qw(listprice lastcost avgcost)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, 2, "&nbsp;") . "</td>" }
    
    for (qw(lastcost avgcost)) { $column_data{"${_}markup"} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{"${_}markup"}, 1, "&nbsp;")."</td>" }

    if ($form->{l_linetotal}) {
      for (qw(sellprice lastcost avgcost listprice)) { $column_data{"linetotal$_"} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{onhand} * $ref->{$_}, 2, "&nbsp;")."</td>" }
    }

    if ($ref->{assemblyitem} && $ref->{stagger} > 1) {
      for (qw(sellprice lastcost avgcost listprice)) { $column_data{"linetotal$_"} = "<td>&nbsp;</td>" }
    }
    
    if (!$ref->{assemblyitem}) {
      $totalsellprice += $onhand * $ref->{sellprice};
      $totallastcost += $onhand * $ref->{lastcost};
      $totalavgcost += $onhand * $ref->{avgcost};
      $totallistprice += $onhand * $ref->{listprice};

      $subtotalonhand += $onhand;
      $subtotalsellprice += $onhand * $ref->{sellprice};
      $subtotallastcost += $onhand * $ref->{lastcost};
      $subtotalavgcost += $onhand * $ref->{avgcost};
      $subtotallistprice += $onhand * $ref->{listprice};
    }

    $column_data{rop} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{rop}, '', "&nbsp;")."</td>";
    $column_data{weight} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{weight}, '', "&nbsp;")."</td>";
    $column_data{unit} = "<td>$ref->{unit}&nbsp;</td>";
    $column_data{bin} = "<td>$ref->{bin}&nbsp;</td>";
    $column_data{priceupdate} = "<td>$ref->{priceupdate}&nbsp;</td>";
    
    $ref->{module} = 'ps' if $ref->{till};
    $column_data{invnumber} = ($ref->{module} ne 'oe') ? "<td><a href=$ref->{module}.pl?action=edit&type=invoice&id=$ref->{trans_id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{invnumber}&nbsp;</a></td>" : "<td>$ref->{invnumber}&nbsp;</td>";
    $column_data{ordnumber} = ($ref->{module} eq 'oe') ? "<td><a href=$ref->{module}.pl?action=edit&type=$ref->{type}&id=$ref->{trans_id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{ordnumber}&nbsp;</a></td>" : "<td>$ref->{ordnumber}&nbsp;</td>";
    $column_data{quonumber} = ($ref->{module} eq 'oe' && !$ref->{ordnumber}) ? "<td><a href=$ref->{module}.pl?action=edit&type=$ref->{type}&id=$ref->{trans_id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{quonumber}&nbsp;</a></td>" : "<td>$ref->{quonumber}&nbsp;</td>";

    $column_data{name} = "<td>$ref->{name}&nbsp;</td>";
   
    $column_data{image} = ($ref->{image}) ? "<td><a href=$ref->{image}><img src=$ref->{image} height=32 border=0></a></td>" : "<td>&nbsp;</td>";
    $column_data{drawing} = ($ref->{drawing}) ? "<td><a href=$ref->{drawing}>$ref->{drawing}</a></td>" : "<td>&nbsp;</td>";
    $column_data{microfiche} = ($ref->{microfiche}) ? "<td><a href=$ref->{microfiche}>$ref->{microfiche}</a></td>" : "<td>&nbsp;</td>";
    
    for (qw(make model serialnumber warehouse inventory income expense tax)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    
    $j++; $j %= 2;
    print "<tr class=listrow$j>";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
    </tr>
|;

    $sameid = $ref->{id};

  }
  
  
  if ($form->{l_subtotal} eq 'Y') {
    &parts_subtotal;
  }

  if ($form->{"l_linetotal"}) {
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
    $column_data{linetotalsellprice} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalsellprice, 2, "&nbsp;")."</th>";
    $column_data{linetotallastcost} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totallastcost, 2, "&nbsp;")."</th>";
    $column_data{linetotalavgcost} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalavgcost, 2, "&nbsp;")."</th>";
    $column_data{linetotallistprice} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totallistprice, 2, "&nbsp;")."</th>";

    print "<tr class=listtotal>";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|</tr>
    |;
  }

  print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

|;
 
  print qq|

<br>

<form method=post action=$form->{script}>

<input type=hidden name=item value=$form->{searchitems}>
|;

  $form->hide_form(qw(callback path login sessionid));

  foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
    print $item->{code};
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}


sub parts_subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  $subtotalonhand = 0 if ($form->{searchitems} eq 'assembly' && $form->{individual});

  $column_data{onhand} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalonhand, '', "&nbsp;")."</th>";

  $column_data{linetotalsellprice} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalsellprice, 2, "&nbsp;")."</th>";
  $column_data{linetotallistprice} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotallistprice, 2, "&nbsp;")."</th>";
  $column_data{linetotallastcost} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotallastcost, 2, "&nbsp;")."</th>";
  $column_data{linetotalavgcost} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalavgcost, 2, "&nbsp;")."</th>";
  
  $subtotalonhand = 0;
  $subtotalsellprice = 0;
  $subtotallistprice = 0;
  $subtotallastcost = 0;
  $subtotalavgcost = 0;

  print "<tr class=listsubtotal>";

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
  </tr>
|;

}


sub requirements {

  $form->get_partsgroup(\%myconfig, { searchitems => 'parts'});
  $form->all_years(\%myconfig);

  if (@{ $form->{all_partsgroup} }) {
    $partsgroup = qq|<option>\n|;

    for (@{ $form->{all_partsgroup} }) { $partsgroup .= qq|<option value="|.$form->quote($_->{partsgroup}).qq|--$_->{id}">$_->{partsgroup}\n| }

    $partsgroup = qq| 
        <th align=right nowrap>|.$locale->text('Group').qq|</th>
	<td><select name=partsgroup>$partsgroup</select></td>
|;

    $l_partsgroup = qq|<input name=l_partsgroup class=checkbox type=checkbox value=Y> |.$locale->text('Group');
  }

  if (@{ $form->{all_years} }) {
    # accounting years
    $form->{selectaccountingyear} = qq|<option>\n|;
    for (@{ $form->{all_years} }) { $form->{selectaccountingyear} .= qq|<option>$_\n| }
    
    
    $selectfrom = qq|
        <tr>
 	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td colspan=3>
	    <table>
	      <tr>
	        <td>
		<select name=year>$form->{selectaccountingyear}</select>
		</td>
		<td>
|;

    $selectfrom .= qq|
		  <table>
		    <tr>
|;

    for (sort keys %{ $form->{all_month} }) {
      $i = ($_ * 1) - 1;
      if (($i % 3) == 0) {
	$selectfrom .= qq|
		    </tr>
		    <tr>
|;
      }

      $i = $_ * 1;
	
      $selectfrom .= qq|
		      <td nowrap><input name="l_month_$i" class checkbox type=checkbox value=Y>&nbsp;|.$locale->text($form->{all_month}{$_}).qq|</td>\n|;
    }
		
    $selectfrom .= qq|
		    </tr>
		  </table>
		</td>
	      </tr>
	    </table>
	  </td>
        </tr>
|;
  } else {
    $form->error($locale->text('No History!'));
  }

  $form->{title} = $locale->text('Parts Requirements');
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

|;

  print qq|

<table width="100%">

  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name=description size=40></td>
        </tr>
	<tr>
	  $partsgroup
	</tr>
	$selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=requirements_report>
<input type=hidden name=sort value=partnumber>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->hide_form(qw(path login sessionid));
  
  print qq|
</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  
</body>
</html>
|;

}



sub requirements_report {

  $callback = "$form->{script}?action=requirements_report";
  for (qw(path login sessionid year)) { $callback .= qq|&$_=$form->{$_}| }
  for (qw(partsgroup)) { $callback .= qq|&$_=|.$form->escape($form->{$_},1) }
  
  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $option .= $locale->text('Number').qq| : $form->{partnumber}<br>|;
  }
  if ($form->{partsgroup}) {
    ($partsgroup) = split /--/, $form->{partsgroup};
    $option .= $locale->text('Group').qq| : $partsgroup<br>|;
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $description = $form->{description};
    $description =~ s/\r?\n/<br>/g;
    $option .= $locale->text('Description').qq| : $form->{description}<br>|;
  }
  
 
  @column_index = $form->sort_columns(qw(partnumber description));
  unshift @column_index, "runningnumber";
  
  for (1 .. 12) {
    if ($form->{"l_month_$_"}) {
      $callback .= qq|&l_month_$_=$form->{"l_month_$_"}|;
      push @column_index, $_;
      $month{$_} = 1;
    }
  }
  
  push @column_index, "year" unless %month;
  push @column_index, qw(onhand so po order);

  IC->requirements(\%myconfig, \%$form);

  $form->sort_order();
  
  $callback .= "&direction=$form->{direction}&oldsort=$form->{oldsort}";
  
  $href = $callback;
  
  $callback =~ s/(direction=).*?\&/$1$form->{direction}\&/;
    
  if (%month) {
    $option .= $locale->text('Year').qq| : $form->{year}<br>|;
  }
    
  
  $column_header{runningnumber} = qq|<th a class=listheading>&nbsp;</th>|;
  $column_header{partnumber} = qq|<th nowrap colspan=$colspan><a class=listheading href=$href&sort=partnumber>|.$locale->text('Number').qq|</a></th>|;
  $column_header{description} = qq|<th nowrap><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{onhand} = qq|<th class=listheading nowrap>|.$locale->text('Onhand').qq|</th>|;
  $column_header{so} = qq|<th class=listheading nowrap>|.$locale->text('SO').qq|</th>|;
  $column_header{po} = qq|<th class=listheading nowrap>|.$locale->text('PO').qq|</th>|;
  $column_header{order} = qq|<th class=listheading nowrap>|.$locale->text('Order').qq|</th>|;
  $column_header{year} = qq|<th class=listheading nowrap>$form->{year}</th>|;

  for (sort { $a <=> $b } keys %month) { $column_header{$_} = qq|<th class=listheading nowrap>|.$locale->text($locale->{SHORT_MONTH}[$_-1]).qq|</th>| }
  
  $form->{title} = $locale->text('Parts Requirements');
  
  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>

  <tr><td>$option</td></tr>

  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }
  
  print qq|
        </tr>
  |;


  # add order to callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);

  if (@{ $form->{parts} }) {
    $sameid = $form->{parts}->[0]->{id};
  }

  for (keys %month) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $i = 0;
  $qty = 0;
  foreach $ref (@{ $form->{parts} }) {

    if ($ref->{id} != $sameid) {
      
      $i++;
      $column_data{runningnumber} = "<td align=right>$i</td>";
      
      $order = 0 if $order < 0;
      $column_data{order} = "<td align=right>".$form->format_amount(\%myconfig, $order, '', "-")."</td>";
      $j++; $j %= 2;
      print "<tr class=listrow$j>";

      for (@column_index) {
	print "\n$column_data{$_}";
	$column_data{$_} = "<td>&nbsp;</td>";
      }

      print qq|
    </tr>
|;
      $qty = 0;
    }

    
    $ref->{description} =~ s/\r?\n/<br>/g;
    
    $column_data{partnumber} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";

    $column_data{description} = "<td>$ref->{description}&nbsp;</td>";

    $column_data{onhand} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{onhand}, '', "&nbsp;")."</td>";
    $column_data{so} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{so}, '', "&nbsp;")."</td>";
    $column_data{po} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{po}, '', "&nbsp;")."</td>";

    $column_data{$ref->{month}} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{qty}, '', "&nbsp;")."</td>";
    if (%month) {
      $qty += $ref->{qty} if exists $month{$ref->{month}};
    } else {
      $qty += $ref->{qty};
    }
    
    $column_data{year} = "<td align=right>".$form->format_amount(\%myconfig, $qty, '', "&nbsp;")."</td>";

    $order = $qty + $ref->{so} - $ref->{po} - $ref->{onhand};

    $sameid = $ref->{id};

  }
  
  if (@{ $form->{parts} }) {
    $i++;
    $column_data{runningnumber} = "<td align=right>$i</td>";

    $order = 0 if $order < 0;
    $column_data{order} = "<td align=right>".$form->format_amount(\%myconfig, $order, '', "-")."</td>";
    $j++; $j %= 2;
    print "<tr class=listrow$j>";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
    </tr>
|;
  }
 
  print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

|;
 
  print qq|

<br>

<form method=post action=$form->{script}>

|;

  $form->hide_form(qw(callback path login sessionid));

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}


sub makemodel_row {
  my ($numrows) = @_;

  for (qw(make model)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }

  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class="listheading">|.$locale->text('Make').qq|</th>
	  <th class="listheading">|.$locale->text('Model').qq|</th>
	</tr>
|;

  for $i (1 .. $numrows) {
    print qq|
	<tr>
	  <td><input name="make_$i" size=30 value="$form->{"make_$i"}"></td>
	  <td><input name="model_$i" size=30 value="$form->{"model_$i"}"></td>
	</tr>
|;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

}


sub vendor_row {
  my ($numrows) = @_;

  $form->{selectvendor} = $form->unescape($form->{selectvendor});

  $currency = qq|
	  <th class="listheading">|.$locale->text('Curr').qq|</th>| if $form->{selectcurrency};
	  
  print qq|
  <input type=hidden name=selectvendor value="|.$form->escape($form->{selectvendor},1).qq|">
  
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class="listheading">|.$locale->text('Vendor').qq|</th>
	  <th class="listheading">|.$locale->text('Number').qq|</th>
	  <th class="listheading">|.$locale->text('Cost').qq|</th>
	  $currency
	  <th class="listheading">|.$locale->text('Leadtime').qq|</th>
	</tr>
|;

  for $i (1 .. $numrows) {
    
    if ($form->{selectcurrency}) {
      $form->{selectcurrency} =~ s/ selected//;
      $form->{selectcurrency} =~ s/option>$form->{"vendorcurr_$i"}/option selected>$form->{"vendorcurr_$i"}/;
      $currency = qq|
	  <td><select name="vendorcurr_$i">$form->{selectcurrency}</select></td>|;
    }
   
    if ($i == $numrows) {
     
      $vendor = qq|
          <td><input name="vendor_$i" size=35 value="$form->{"vendor_$i"}"></td>
|;
 
      if ($form->{selectvendor}) {
	$vendor = qq|
	  <td width=99%><select name="vendor_$i">$form->{selectvendor}</select></td>
|;
      }
   
    } else {
      
      ($vendor) = split /--/, $form->{"vendor_$i"};
      $vendor = qq|
          <td>$vendor
	  <input type=hidden name="vendor_$i" value="$form->{"vendor_$i"}">
	  </td>
|;
    }
  
    $form->{"partnumber_$i"} = $form->quote($form->{"partnumber_$i"});
    print qq|
	<tr>
	  $vendor
	  <td><input name="partnumber_$i" size=20 value="$form->{"partnumber_$i"}"></td>
	  <td><input name="lastcost_$i" size=10 value=|.$form->format_amount(\%myconfig, $form->{"lastcost_$i"}, 2).qq|></td>
	  $currency
	  <td nowrap><input name="leadtime_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"leadtime_$i"}).qq|> <b>|.$locale->text('days').qq|</b></td>
	</tr>
|;
      
  }

  print qq|
      </table>
    </td>
  </tr>
|;

}


sub customer_row {
  my ($numrows) = @_;

  if ($form->{selectpricegroup}) {
    $pricegroup = qq|
          <th class="listheading">|.$locale->text('Pricegroup').qq|
          </th>
|;
  }

  $form->{selectcustomer} = $form->unescape($form->{selectcustomer});
  $form->{selectpricegroup} = $form->unescape($form->{selectpricegroup});
  
  $form->hide_form(qw(selectcurrency));

  $currency = qq|<th class="listheading">|.$locale->text('Curr').qq|</th>| if $form->{selectcurrency};
	  
  print qq|
  <input type=hidden name=selectcustomer value="|.$form->escape($form->{selectcustomer},1).qq|">
  <input type=hidden name=selectpricegroup value="|.$form->escape($form->{selectpricegroup},1).qq|">
  
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class="listheading">|.$locale->text('Customer').qq|</th>
	  $pricegroup
	  <th class="listheading">|.$locale->text('Break').qq|</th>
	  <th class="listheading">|.$locale->text('Sell Price').qq|</th>
	  $currency
	  <th class="listheading">|.$locale->text('From').qq|</th>
	  <th class="listheading">|.$locale->text('To').qq|</th>
	</tr>
|;

  for $i (1 .. $numrows) {

    if ($form->{selectcurrency}) {
      $form->{selectcurrency} =~ s/ selected//;
      $form->{selectcurrency} =~ s/option>$form->{"customercurr_$i"}/option selected>$form->{"customercurr_$i"}/;
      $currency = qq|
	  <td><select name="customercurr_$i">$form->{selectcurrency}</select></td>|;
    }
    
    if ($i == $numrows) {
      $customer = qq|
          <td><input name="customer_$i" size=35 value="$form->{"customer_$i"}"></td>
	  |;
  
      if ($form->{selectcustomer}) {
	$customer = qq|
	  <td><select name="customer_$i">$form->{selectcustomer}</select></td>
|;
      }

      if ($form->{selectpricegroup}) {
	$pricegroup = qq|
	  <td><select name="pricegroup_$i">$form->{selectpricegroup}</select></td>
|;
      }

    } else {
      ($customer) = split /--/, $form->{"customer_$i"};
      $customer = qq|
          <td>$customer</td>
	  <input type=hidden name="customer_$i" value="$form->{"customer_$i"}">
	  |;

      if ($form->{selectpricegroup}) {
	($pricegroup) = split /--/, $form->{"pricegroup_$i"};
	$pricegroup = qq|
	  <td>$pricegroup</td>
	  <input type=hidden name="pricegroup_$i" value="$form->{"pricegroup_$i"}">
|;
      }
    }
    
    
    print qq|
	<tr>
	  $customer
	  $pricegroup

	  <td><input name="pricebreak_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"pricebreak_$i"}).qq|></td>
	  <td><input name="customerprice_$i" size=10 value=|.$form->format_amount(\%myconfig, $form->{"customerprice_$i"}, 2).qq|></td>
	  $currency
	  <td><input name="validfrom_$i" size=11 title="$myconfig{dateformat}" value="$form->{"validfrom_$i"}"></td>
	  <td><input name="validto_$i" size=11 title="$myconfig{dateformat}" value="$form->{"validto_$i"}"></td>
	</tr>
|;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

}



sub assembly_row {
  my ($numrows) = @_;

  @column_index = qw(runningnumber qty unit bom adj partnumber description sellprice listprice lastcost);
  
  if ($form->{selectassemblypartsgroup}) {
    $form->{selectassemblypartsgroup} = $form->unescape($form->{selectassemblypartsgroup});
    @column_index = qw(runningnumber qty unit bom adj partnumber description partsgroup sellprice listprice lastcost);
  }

  delete $form->{previousform};

  # change callback
  $form->{old_callback} = $form->{callback};
  $callback = $form->{callback};
  $form->{callback} = "$form->{script}?action=display_form";

  # delete action
  for (qw(action header)) { delete $form->{$_} }

  $form->{baseassembly} = 0;
  $previousform = "";
  # save form variables in a previousform variable
  $form->{selectcustomer} = "";   # we seem to have run into a 40kb limit
  foreach $key (sort keys %$form) {
    # escape ampersands
    $form->{$key} =~ s/&/%26/g;
    $previousform .= qq|$key=$form->{$key}&| if $form->{$key};
  }
  chop $previousform;
  $form->{previousform} = $form->escape($previousform, 1);

  $form->{sellprice} = 0;
  $form->{listprice} = 0;
  $form->{lastcost} = 0;
  $form->{weight} = 0;

  $form->{callback} = $callback;


  $column_header{runningnumber} = qq|<th nowrap width=5%>|.$locale->text('Item').qq|</th>|;
  $column_header{qty} = qq|<th align=left nowrap width=10%>|.$locale->text('Qty').qq|</th>|;
  $column_header{unit} = qq|<th align=left nowrap width=5%>|.$locale->text('Unit').qq|</th>|;
  $column_header{partnumber} = qq|<th align=left nowrap width=20%>|.$locale->text('Number').qq|</th>|;
  $column_header{description} = qq|<th nowrap width=50%>|.$locale->text('Description').qq|</th>|;
  $column_header{sellprice} = qq|<th align=right nowrap>|.$locale->text('Sell').qq|</th>|;
  $column_header{listprice} = qq|<th align=right nowrap>|.$locale->text('List').qq|</th>|;
  $column_header{lastcost} = qq|<th align=right nowrap>|.$locale->text('Cost').qq|</th>|;
  $column_header{bom} = qq|<th>|.$locale->text('BOM').qq|</th>|;
  $column_header{adj} = qq|<th>|.$locale->text('A').qq|</th>|;
  $column_header{partsgroup} = qq|<th>|.$locale->text('Group').qq|</th>|;
  
  print qq|
  <p>

  <table width=100%>
  <tr class=listheading>
    <th class=listheading>|.$locale->text('Individual Items').qq|</th>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
|;

  for (@column_index) { print "\n$column_header{$_}" }
  
  print qq|
        </tr>
|;

  $spc = ($form->{path} =~ /lynx/) ? "." : " ";
  $numrows-- if $form->{project_id};

  for $i (1 .. $numrows) {
    for (qw(partnumber description)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }

    $linetotalsellprice = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, 2);
    $form->{sellprice} += $linetotalsellprice;
    
    $linetotallistprice = $form->round_amount($form->{"listprice_$i"} * $form->{"qty_$i"}, 2);
    $form->{listprice} += $linetotallistprice;

    $linetotallastcost = $form->round_amount($form->{"lastcost_$i"} * $form->{"qty_$i"}, 2);
    $form->{lastcost} += $linetotallastcost;


    $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});

    $linetotalsellprice = $form->format_amount(\%myconfig, $linetotalsellprice, 2);
    $linetotallistprice = $form->format_amount(\%myconfig, $linetotallistprice, 2);
    $linetotallastcost = $form->format_amount(\%myconfig, $linetotallastcost, 2);

    if ($i == $numrows && !$form->{project_id}) {

      for (qw(runningnumber unit bom adj)) { $column_data{$_} = qq|<td></td>| }

      $column_data{qty} = qq|<td><input name="qty_$i" size=6 value="$form->{"qty_$i"}" accesskey="$i" title="[Alt-$i]"></td>|;
      $column_data{partnumber} = qq|<td><input name="partnumber_$i" size=15 value="$form->{"partnumber_$i"}"></td>|;
      $column_data{description} = qq|<td><input name="description_$i" size=30 value="$form->{"description_$i"}"></td>|;
      $column_data{partsgroup} = qq|<td><select name="partsgroup_$i">$form->{selectassemblypartsgroup}</select></td>|;

    } else {
      
      $column_data{partnumber} = qq|<td><input class=submit type=submit name=action value="$spc$form->{"partnumber_$i"}"></td>
      <input type=hidden name="partnumber_$i" value="$form->{"partnumber_$i"}">|;
	
      $column_data{runningnumber} = qq|<td><input name="runningnumber_$i" size=3 value="$i"></td>|;
      $column_data{qty} = qq|<td><input name="qty_$i" size=6 value="$form->{"qty_$i"}" accesskey="$i" title="[Alt-$i]"></td>|;

      for (qw(bom adj)) { $form->{"${_}_$i"} = ($form->{"${_}_$i"}) ? "checked" : "" }
      $column_data{bom} = qq|<td align=center><input name="bom_$i" type=checkbox class=checkbox value=1 $form->{"bom_$i"}></td>|;
      $column_data{adj} = qq|<td align=center><input name="adj_$i" type=checkbox class=checkbox value=1 $form->{"adj_$i"}></td>|;

      ($partsgroup) = split /--/, $form->{"partsgroup_$i"};
      $column_data{partsgroup} = qq|<td><input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">$partsgroup</td>|;

      $column_data{unit} = qq|<td><input type=hidden name="unit_$i" value="$form->{"unit_$i"}">$form->{"unit_$i"}</td>|;
      $column_data{description} = qq|<td><input type=hidden name="description_$i" value="$form->{"description_$i"}">$form->{"description_$i"}</td>|;
      
    }
    
    $column_data{sellprice} = qq|<td align=right>$linetotalsellprice</td>|;
    $column_data{listprice} = qq|<td align=right>$linetotallistprice</td>|;
    $column_data{lastcost} = qq|<td align=right>$linetotallastcost</td>|;
    
    print qq|
        <tr>|;

    for (@column_index) { print "\n$column_data{$_}" }
    
    print qq|
        </tr>
|;
    $form->hide_form("id_$i","sellprice_$i","listprice_$i","lastcost_$i","weight_$i","assembly_$i");
    
  }

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{sellprice} = "<th align=right>".$form->format_amount(\%myconfig, $form->{sellprice}, 2)."</th>";
  $column_data{listprice} = "<th align=right>".$form->format_amount(\%myconfig, $form->{listprice}, 2)."</th>";
  $column_data{lastcost} = "<th align=right>".$form->format_amount(\%myconfig, $form->{lastcost}, 2)."</th>";
  
  print qq|
        <tr>|;

  for (@column_index) { print "\n$column_data{$_}" }
    
  print qq|
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  </table>
  <input type=hidden name=assembly_rows value=$form->{assembly_rows}>
  <input type=hidden name=nextsub value=edit_assemblyitem>
  <input type=hidden name=selectassemblypartsgroup value="|.$form->escape($form->{selectassemblypartsgroup},1).qq|">
|;
 
}


sub edit_assemblyitem {

  $pn = substr($form->{action}, 1);

  $i = 0;
  for (1 .. $form->{assembly_rows} - 1) {
    $i++;
    last if $form->{"partnumber_$_"} eq $pn;
  }

  $form->error($locale->text('unexpected error!')) unless $i;
  
  $form->{baseassembly} = ($form->{baseassembly}) ? $form->{baseassembly} : $form->{"assembly_$i"};

  $form->{callback} = qq|$form->{script}?action=edit&id=$form->{"id_$i"}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&rowcount=$i&baseassembly=$form->{baseassembly}&isassemblyitem=1&previousform=$form->{previousform}|;

  $form->redirect;
  
}


sub update {

  if ($form->{item} eq "assembly") {

    $i = $form->{assembly_rows};
    $i = $form->{assembly_rows} + 1 if $form->{project_id};
   
    # if last row is empty check the form otherwise retrieve item
    if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq "")) {
      
      &check_form;
      
    } else {

      IC->assembly_item(\%myconfig, \%$form);

      $rows = scalar @{ $form->{item_list} };
      
      if ($rows) {
	$form->{"adj_$i"} = 1;
	
	if ($rows > 1) {
	  $form->{makemodel_rows}--;
	  $form->{customer_rows}--;
	  &select_item;
	  exit;
	} else {
	  $form->{"qty_$i"} = 1;
	  $form->{"adj_$i"} = 1;
	  for (qw(partnumber description unit)) { $form->{item_list}[$i]{$_} = $form->quote($form->{item_list}[$i]{$_}) }
	  for (keys %{ $form->{item_list}[0] }) { $form->{"${_}_$i"} = $form->{item_list}[0]{$_} }

	  if ($form->{item_list}[0]{partsgroup_id}) {
	    $form->{"partsgroup_$i"} = qq|$form->{item_list}[0]{partsgroup}--$form->{item_list}[0]{partsgroup_id}|;
	  }
	  
	  $form->{"runningnumber_$i"} = $form->{assembly_rows};
	  $form->{assembly_rows}++;

	  &check_form;

	}

      } else {

        $form->{rowcount} = $i;
	$form->{assembly_rows}++;
	
	&new_item;

      }
    }

  } else {
  
    &check_form;

  }

}


sub check_vendor {
  
  @flds = qw(vendor partnumber lastcost leadtime vendorcurr);
  @a = (); 
  $count = 0; 

  for (qw(lastcost leadtime)) { $form->{"${_}_$form->{vendor_rows}"} = $form->parse_amount(\%myconfig, $form->{"${_}_$form->{vendor_rows}"}) }
  
  for $i (1 .. $form->{vendor_rows} - 1) {
    
    for (qw(lastcost leadtime)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{"lastcost_$i"} || $form->{"partnumber_$i"}) {

      push @a, {};
      $j = $#a; 
      for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;

    } 
  }
  
  $i = $form->{vendor_rows};
  
  if (!$form->{selectvendor}) {

    if ($form->{"vendor_$i"} && !$form->{"vendor_id_$i"}) {
      ($form->{vendor}) = split /--/, $form->{"vendor_$i"};
      if (($j = $form->get_name(\%myconfig, vendor)) > 1) {
	&select_name(vendor, $i);
	exit;
      }

      if ($j == 1) {
	# we got one name
	$form->{"vendor_$i"} = qq|$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}|;
      } else {
	# name is not on file
	$form->error(qq|$form->{"vendor_$i"} : |.$locale->text('Vendor not on file!'));
      }
    }
  }

  if ($form->{"vendor_$i"}) {
    push @a, {};
    $j = $#a; 
    for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
    $count++;
  }

  $form->redo_rows(\@flds, \@a, $count, $form->{vendor_rows});
  $form->{vendor_rows} = $count;

}


sub check_customer {
  
  @flds = qw(customer validfrom validto pricebreak customerprice pricegroup customercurr);
  @a = (); 
  $count = 0;

  for (qw(customerprice pricebreak)) { $form->{"${_}_$form->{customer_rows}"} = $form->parse_amount(\%myconfig, $form->{"${_}_$form->{customer_rows}"}) }

  for $i (1 .. $form->{customer_rows} - 1) {

    for (qw(customerprice pricebreak)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{"customerprice_$i"}) {
      if ($form->{"pricebreak_$i"} || $form->{"customer_$i"} || $form->{"pricegroup_$i"}) {
	
	push @a, {};
	$j = $#a; 
	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
	
      }
    }
  }

  $i = $form->{customer_rows};

  if (!$form->{selectcustomer}) {

    if ($form->{"customer_$i"} && !$form->{"customer_id_$i"}) {
      ($form->{customer}) = split /--/, $form->{"customer_$i"};

      if (($j = $form->get_name(\%myconfig, customer)) > 1) {
	&select_name(customer, $i);
	exit;
      }

      if ($j == 1) {
	# we got one name
	$form->{"customer_$i"} = qq|$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}|;
      } else {
	# name is not on file
	$form->error(qq|$form->{customer} : |.$locale->text('Customer not on file!'));
      }
    }
  }

  if ($form->{"customer_$i"} || $form->{"pricegroup_$i"} || ($form->{"customerprice_$i"} || $form->{"pricebreak_$i"})) {
    push @a, {};
    $j = $#a; 
    for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
    $count++;
  }

  $form->redo_rows(\@flds, \@a, $count, $form->{customer_rows});
  $form->{customer_rows} = $count;

}



sub select_name {
  my ($table, $vr) = @_;
  
  @column_index = qw(ndx name address);

  $label = ucfirst $table;
  $column_data{ndx} = qq|<th>&nbsp;</th>|;
  $column_data{name} = qq|<th class=listheading>|.$locale->text($label).qq|</th>|;
  $column_data{address} = qq|<th class=listheading colspan=5>|.$locale->text('Address').qq|</th>|;
  
  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select from one of the names below');

  print qq|
<body>

<form method=post action="$form->{script}">

<input type=hidden name=vr value=$vr>

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
	</tr>
|;

  @column_index = qw(ndx name address city state zipcode country);
  
  my $i = 0;
  foreach $ref (@{ $form->{name_list} }) {
    $checked = ($i++) ? "" : "checked";

    $ref->{name} = $form->quote($ref->{name});
    
   $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
   $column_data{name} = qq|<td><input name="new_name_$i" type=hidden value="$ref->{name}">$ref->{name}</td>|;
   $column_data{address} = qq|<td>$ref->{address1} $ref->{address2}|;
   for (qw(city state zipcode country)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }
    
    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>

<input name="new_id_$i" type=hidden value=$ref->{id}>

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

<input name=lastndx type=hidden value=$i>

|;

  # delete variables
  for (qw(action nextsub name_list)) { delete $form->{$_} }

  $form->hide_form;
  
  print qq|
<input type=hidden name=nextsub value=name_selected>
<input type=hidden name=vc value=$table>
<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub name_selected {

  # replace the variable with the one checked

  # index for new item
  $i = $form->{ndx};
  
  $form->{"$form->{vc}_$form->{vr}"} = qq|$form->{"new_name_$i"}--$form->{"new_id_$i"}|;
  $form->{"$form->{vc}_id_$form->{vr}"} = $form->{"new_id_$i"};

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id name)) { delete $form->{"new_${_}_$i"} }
  }
  
  for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

  &update;

}


sub save {

  if ($form->{obsolete}) {
    $form->error($locale->text("Inventory quantity must be zero before you can set this $form->{item} obsolete!")) if ($form->{onhand});
  }

# expand dynamic strings
# $locale->text('Inventory quantity must be zero before you can set this part obsolete!')
# $locale->text('Inventory quantity must be zero before you can set this assembly obsolete!')

  $olditem = $form->{id};

  # save part
  $rc = IC->save(\%myconfig, \%$form);

  $parts_id = $form->{id};

  # load previous variables
  if ($form->{previousform} && !$form->{callback}) {
    # save the new form variables before splitting previousform
    for (keys %$form) { $newform{$_} = $form->{$_} }

    $previousform = $form->unescape($form->{previousform});
    $baseassembly = $form->{baseassembly};

    # don't trample on previous variables
    for (keys %newform) { delete $form->{$_} }

    # now take it apart and restore original values
    foreach $item (split /&/, $previousform) {
      ($key, $value) = split /=/, $item, 2;
      $value =~ s/%26/&/g;
      $form->{$key} = $value;
    }


    if ($form->{item} eq 'assembly') {

      if ($baseassembly) {
	#redo the assembly
	$previousform =~ /\&id=(\d+)/;
	$form->{id} = $1;
	
	# restore original callback
	$form->{callback} = $form->unescape($form->{old_callback});

	&edit;
	exit;
      }
	
      # undo number formatting
      for (qw(weight listprice sellprice lastcost rop)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

      $form->{assembly_rows}-- if $olditem;
      $i = $newform{rowcount};
      $form->{"qty_$i"} = 1 unless ($form->{"qty_$i"});

      $form->{listprice} -= $form->{"listprice_$i"} * $form->{"qty_$i"};
      $form->{sellprice} -= $form->{"sellprice_$i"} * $form->{"qty_$i"};
      $form->{lastcost} -= $form->{"lastcost_$i"} * $form->{"qty_$i"};
      $form->{weight} -= $form->{"weight_$i"} * $form->{"qty_$i"};

      # change/add values for assembly item
      for (qw(partnumber description bin unit weight listprice sellprice lastcost)) { $form->{"${_}_$i"} = $newform{$_} }

      foreach $item (qw(listprice sellprice lastcost)) {
	$form->{$item} += $form->{"${item}_$i"} * $form->{"qty_$i"};
	$form->{$item} = $form->round_amount($form->{$item}, 2);
      }
	
      $form->{weight} += $form->{"weight_$i"} * $form->{"qty_$i"};

      $form->{"adj_$i"} = 1 if !$olditem;

      $form->{customer_rows}--;
      
    } else {
      # set values for last invoice/order item
      $i = $form->{rowcount};
      $form->{"qty_$i"} = 1 unless ($form->{"qty_$i"});

      for (qw(partnumber description bin unit listprice sellprice partsgroup)) { $form->{"${_}_$i"} = $newform{$_} }
      for (qw(inventory income expense)) {
	$form->{"${_}_accno_id_$i"} = $newform{"IC_$_"};
	$form->{"${_}_accno_id_$i"} =~ s/--.*//;
      }
      $form->{"sellprice_$i"} = $newform{lastcost} if ($form->{vendor_id});

      if ($form->{exchangerate} != 0) {
	$form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} / $form->{exchangerate}, 2);
      }
      
      for (split / /, $newform{taxaccounts}) { $form->{"taxaccounts_$i"} .= "$_ " if ($newform{"IC_tax_$_"}) }
      chop $form->{"taxaccounts_$i"};

      # credit remaining calculation
      $amount = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100) * $form->{"qty_$i"};
      for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
      if (!$form->{taxincluded}) {
	for (split / /, $form->{"taxaccounts_$i"}) { $amount += ($form->{"${_}_base"} * $form->{"${_}_rate"}) }
      }

      $ml = 1;
      if ($form->{type} =~ /invoice/) {
	$ml = -1 if $form->{type} =~ /_invoice/;
      }
      $form->{creditremaining} -= ($amount * $ml);
      
    }
    
    $form->{"id_$i"} = $parts_id;
    delete $form->{action};

    # restore original callback
    $callback = $form->unescape($form->{callback});
    $form->{callback} = $form->unescape($form->{old_callback});
    delete $form->{old_callback};

    $form->{makemodel_rows}--;

    # put callback together
    foreach $key (keys %$form) {
      # do single escape for Apache 2.0
      $value = $form->escape($form->{$key}, 1);
      $callback .= qq|&$key=$value|;
    }
    $form->{callback} = $callback;
  }

  # redirect
  $form->redirect;

}


sub save_as_new {

  $form->{id} = 0;
  &save;

}


sub delete {

  # redirect
  if (IC->delete(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Item deleted!'));
  } else {
    $form->error($locale->text('Cannot delete item!'));
  }

}



sub stock_assembly {

  $form->{title} = $locale->text('Stock Assembly');
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width="100%">
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align="right" nowrap="true">|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
          <td>&nbsp;</td>
        </tr>
        <tr>
          <th align="right" nowrap="true">|.$locale->text('Description').qq|</th>
          <td><input name=description size=40></td>
        </tr>
        <tr>
          <td></td>
	  <td><input name=checkinventory class=checkbox type=checkbox value=1>&nbsp;|.$locale->text('Check Inventory').qq|</td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

<input type=hidden name=sort value=partnumber>
|;

  $form->hide_form(qw(path login sessionid));

  print qq|
<input type=hidden name=nextsub value=list_assemblies>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
 
</body>
</html>
|;

}




sub list_assemblies {

  IC->retrieve_assemblies(\%myconfig, \%$form);

  $callback = "$form->{script}?action=list_assemblies&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&checkinventory=$form->{checkinventory}";
  
  $form->sort_order();
  $href = "$form->{script}?action=list_assemblies&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&checkinventory=$form->{checkinventory}";
  
  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $href .= "&partnumber=".$form->escape($form->{partnumber});
    $form->{sort} = "partnumber" unless $form->{sort};
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $form->{sort} = "description" unless $form->{sort};
  }
 
  $column_header{partnumber} = qq|<th><a class=listheading href=$href&sort=partnumber>|.$locale->text('Number').qq|</th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</th>|;
  $column_header{bin} = qq|<th><a class=listheading href=$href&sort=bin>|.$locale->text('Bin').qq|</th>|;
  $column_header{onhand} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  $column_header{rop} = qq|<th class=listheading>|.$locale->text('ROP').qq|</th>|;
  $column_header{stock} = qq|<th class=listheading>|.$locale->text('Add').qq|</th>|;

  @column_index = $form->sort_columns(qw(partnumber description bin onhand rop stock));
  
  $form->{title} = $locale->text('Stock Assembly');

  
  $form->header;
  

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr size=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;

  # add sort and escape callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);


  $i = 1;
  foreach $ref (@{ $form->{assembly_items} }) {

    for (qw(partnumber description)) { $ref->{$_} = $form->quote($ref->{$_}) }
   
    $column_data{partnumber} = "<td width=20%><a href=$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";
    
    $column_data{description} = qq|<td width=50%>$ref->{description}&nbsp;</td>|;
    $column_data{bin} = qq|<td>$ref->{bin}&nbsp;</td>|;
    $column_data{onhand} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{onhand}, "", "&nbsp;").qq|</td>|;
    $column_data{rop} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{rop}, '', "&nbsp;").qq|</td>|;
    $column_data{stock} = qq|<td width=10%><input name="qty_$i" size=10 value=|.$form->format_amount(\%myconfig, $ref->{stock}).qq|></td>
    <input type=hidden name="stock_$i" value=$ref->{stock}>|;

    $j++; $j %= 2;
    print qq|<tr class=listrow$j><input name="id_$i" type=hidden value=$ref->{id}>\n|;
    
    for (@column_index) { print "\n$column_data{$_}" }
    
    print qq|
	</tr>
|;

    $i++;

  }
  
  $i--;
  print qq|
      </td>
    </table>
  <tr>
    <td><hr size=3 noshade>
  </tr>
</table>
|;

  $form->hide_form(qw(checkinventory path login sessionid callback));

  print qq|
<input type=hidden name=rowcount value="$i">
<input type=hidden name=nextsub value=restock_assemblies>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;
 
}


sub restock_assemblies {


  if ($form->{checkinventory}) {
    for (1 .. $form->{rowcount}) { $form->error($locale->text('Quantity exceeds available units to stock!')) if $form->parse_amount($myconfig, $form->{"qty_$_"}) > $form->{"stock_$_"} }
  }

  if (IC->restock_assemblies(\%myconfig, \%$form)) {
    if ($form->{callback} =~ /(direction=)(.*?)\&/) {
      $direction = ($2 eq 'ASC') ? 'DESC' : 'ASC';
    }
    $form->{callback} =~ s/direction=(.*?)\&/direction=$direction\&/;
    $form->redirect($locale->text('Assemblies restocked!'));
  } else {
    $form->error($locale->text('Cannot stock assemblies!'));
  }
  
}


sub continue { &{ $form->{nextsub} } };

sub add_part { &add };
sub add_service { &add };
sub add_assembly { &add };
sub add_labor_overhead { &add };


