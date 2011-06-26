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
#
#  Author: DWS Systems Inc.
#     Web: http://www.ledgersmb.org/
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
# Inventory invoicing module
#
#======================================================================

use LedgerSMB::IS;
use LedgerSMB::PE;
use LedgerSMB::Tax;

require "bin/arap.pl";
require "bin/io.pl";

1;

# end of main
sub on_update{}

sub add {
    if ($form->{type} eq 'credit_invoice'){
        $form->{title} = $locale->text('Add Credit Invoice');
        $form->{subtype} = 'credit_invoice';
        $form->{reverse} = 1;
    } else {
        $form->{title} = $locale->text('Add Sales Invoice');
        $form->{reverse} = 0;
    }
    $form->{callback} =
"$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &invoice_links;
    &prepare_invoice;
    &display_form;

}

sub edit {

    if ($form->{reverse}) {
        $form->{title} = $locale->text('Add Credit Invoice');
        $form->{subtype} = 'credit_invoice';
    } else {
        $form->{title} = $locale->text('Add Sales Invoice');
    }
    &invoice_links;
    &prepare_invoice;
    &display_form;

}

sub invoice_links {

    $form->{vc}   = "customer";
    $form->{type} = "invoice";

    # create links
    $form->create_links( module => "AR",
			 myconfig => \%myconfig,
			 vc => "customer",
			 billing => 1,
			 job => 1 );

    # currencies
    @curr = split /:/, $form->{currencies};
    $form->{defaultcurrency} = $curr[0];
    chomp $form->{defaultcurrency};

    for (@curr) { $form->{selectcurrency} .= "<option>$_\n" }

    if ( @{ $form->{all_customer} } ) {
        unless ( $form->{customer_id} ) {
            $form->{customer_id} = $form->{all_customer}->[0]->{id};
        }
    }

    AA->get_name( \%myconfig, \%$form );
    delete $form->{notes};
    IS->retrieve_invoice( \%myconfig, \%$form );

    $form->{oldlanguage_code} = $form->{language_code};

    $form->get_partsgroup( \%myconfig, { all => 1} );

    if ( @{ $form->{all_partsgroup} } ) {
        $form->{selectpartsgroup} = "<option>\n";
        foreach $ref ( @{ $form->{all_partsgroup} } ) {
            if ( $ref->{translation} ) {
                $form->{selectpartsgroup} .=
qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{translation}\n|;
            }
            else {
                $form->{selectpartsgroup} .=
qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{partsgroup}\n|;
            }
        }
    }

    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option>\n";
        for ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n|;
        }
    }

    $form->{oldcustomer}  = "$form->{customer}--$form->{customer_id}";
    $form->{oldtransdate} = $form->{transdate};

    $form->{selectcustomer} = "";
    if ( @{ $form->{all_customer} } ) {
        $form->{customer} = "$form->{customer}--$form->{customer_id}";
        for ( @{ $form->{all_customer} } ) {
            $form->{selectcustomer} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }
    }

    # departments
    if ( @{ $form->{all_department} } ) {
        $form->{selectdepartment} = "<option>\n";
        $form->{department} = "$form->{department}--$form->{department_id}"
          if $form->{department_id};

        for ( @{ $form->{all_department} } ) {
            $form->{selectdepartment} .=
qq|<option value="$_->{description}--$_->{id}">$_->{description}\n|;
        }
    }

    $form->{employee} = "$form->{employee}--$form->{employee_id}";

    # sales staff
    if ( @{ $form->{all_employee} } ) {
        $form->{selectemployee} = "";
        for ( @{ $form->{all_employee} } ) {
            $form->{selectemployee} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }
    }

    if ( @{ $form->{all_language} } ) {
        $form->{selectlanguage} = "<option>\n";
        for ( @{ $form->{all_language} } ) {
            $form->{selectlanguage} .=
              qq|<option value="$_->{code}">$_->{description}\n|;
        }
    }

    # forex
    $form->{forex} = $form->{exchangerate};
    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

    foreach $key ( keys %{ $form->{AR_links} } ) {

        $form->{"select$key"} = "";
        foreach $ref ( @{ $form->{AR_links}{$key} } ) {
            $form->{"select$key"} .=
              "<option>$ref->{accno}--$ref->{description}\n";
        }

        if ( $key eq "AR_paid" ) {
            for $i ( 1 .. scalar @{ $form->{acc_trans}{$key} } ) {
                $form->{"AR_paid_$i"} =
"$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";

                # reverse paid
                $form->{"paid_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * -1;
                $form->{"datepaid_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{transdate};
                $form->{"forex_$i"} = $form->{"exchangerate_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{exchangerate};
                $form->{"source_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{source};
                $form->{"memo_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{memo};
                $form->{"cleared_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{cleared};

                $form->{paidaccounts} = $i;
            }
        }
        else {
            $form->{$key} =
"$form->{acc_trans}{$key}->[0]->{accno}--$form->{acc_trans}{$key}->[0]->{description}"
              if $form->{acc_trans}{$key}->[0]->{accno};
        }

    }

    for (qw(AR_links acc_trans)) { delete $form->{$_} }

    $form->{paidaccounts} = 1 unless ( exists $form->{paidaccounts} );

    $form->{AR} = $form->{AR_1} unless $form->{id};
    $form->{transdate} = $form->{current_date} if (!$form->{transdate});
    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );

    if ( !$form->{readonly} ) {
        $form->{readonly} = 1 if $myconfig{acs} =~ /AR--Sales Invoice/;
    }

}

sub prepare_invoice {

    $form->{type}     = "invoice";
    $form->{formname} = "invoice";
    $form->{sortby} ||= "runningnumber";
    $form->{format} = "postscript" if $myconfig{printer};
    $form->{media} = $myconfig{printer};

    $form->{selectformname} =
      qq|<option value="invoice">|
      . $locale->text('Invoice') . qq|
<option value="pick_list">| . $locale->text('Pick List') . qq|
<option value="packing_list">| . $locale->text('Packing List');

    $i = 0;
    $form->{currency} =~ s/ //g;
    $form->{oldcurrency} = $form->{currency};

    if ( $form->{id} ) {

        for (
            qw(invnumber ordnumber ponumber quonumber shippingpoint shipvia notes intnotes)
          )
        {
            $form->{$_} = $form->quote( $form->{$_} );
        }

        foreach $ref ( @{ $form->{invoice_details} } ) {
            $i++;
            for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }

            $form->{"projectnumber_$i"} =
              qq|$ref->{projectnumber}--$ref->{project_id}|
              if $ref->{project_id};
            $form->{"partsgroup_$i"} =
              qq|$ref->{partsgroup}--$ref->{partsgroup_id}|
              if $ref->{partsgroup_id};

            $form->{"discount_$i"} =
              $form->format_amount( \%myconfig, $form->{"discount_$i"} * 100 );

            my $moneyplaces = $LedgerSMB::Sysconfig::decimal_places;
            my ($dec) = ($form->{"sellprice_$i"} =~/\.(\d*)/);
            $dec = length $dec;
            $form->{"precision_$i"} = $dec;
            $decimalplaces = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;

            $form->{"sellprice_$i"} =
              $form->format_amount( \%myconfig, $form->{"sellprice_$i"},
                $decimalplaces );
            $form->{"qty_$i"} =
              $form->format_amount( \%myconfig, $form->{"qty_$i"} );
            $form->{"oldqty_$i"} = $form->{"qty_$i"};
	    
	    $form->{"taxformcheck_$i"}=1 if(IS->get_taxcheck($form,$form->{"invoice_id_$i"},$form->{dbh}));


	    for (qw(partnumber sku description unit)) {
                $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
            }
            $form->{rowcount} = $i;
        }
    }

}

sub form_header {

    # set option selected
    for (qw(AR currency)) {
        $form->{"select$_"} =~ s/ selected//;
        $form->{"select$_"} =~
          s/option>\Q$form->{$_}\E/option selected>$form->{$_}/;
    }

    for (qw(customer department employee)) {
        $form->{"select$_"} = $form->unescape( $form->{"select$_"} );
        $form->{"select$_"} =~ s/ selected//;
        $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
    }

    $form->{exchangerate} =
      $form->format_amount( \%myconfig, $form->{exchangerate} );

    $exchangerate = qq|<tr>|;
    $exchangerate .= qq|
		<th align=right nowrap>| . $locale->text('Currency') . qq|</th>
		<td><select name=currency>$form->{selectcurrency}</select></td>
| if $form->{defaultcurrency};
    $exchangerate .= qq|
		<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
|;

    if (   $form->{defaultcurrency}
        && $form->{currency} ne $form->{defaultcurrency} )
    {
        if ( $form->{forex} ) {
            $exchangerate .=
                qq|<th align=right>|
              . $locale->text('Exchange Rate')
              . qq|</th><td>$form->{exchangerate}<input type=hidden name=exchangerate value=$form->{exchangerate}></td>|;
        }
        else {
            $exchangerate .=
                qq|<th align=right>|
              . $locale->text('Exchange Rate')
              . qq|</th><td><input name=exchangerate size=10 value=$form->{exchangerate}></td>|;
        }
    }
    $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
</tr>
|;

    if ( $form->{selectcustomer} ) {
        $customer = qq|<select name=customer>$form->{selectcustomer}</select>
                   <input type=hidden name="selectcustomer" value="|
          . $form->escape( $form->{selectcustomer}, 1 ) . qq|">|;
    }
    else {
        $customer = qq|<input name=customer value="$form->{customer}" size=35>|;
    }

    $department = qq|
              <tr>
	        <th align="right" nowrap>| . $locale->text('Department') . qq|</th>
		<td colspan=3><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|
      . $form->escape( $form->{selectdepartment}, 1 ) . qq|">
		</td>
	      </tr>
| if $form->{selectdepartment};

    $n = ( $form->{creditremaining} < 0 ) ? "0" : "1";

    if ( $form->{business} ) {
        $business = qq|
	      <tr>
		<th align=right nowrap>| . $locale->text('Business') . qq|</th>
		<td>$form->{business}</td>
		<td width=10></td>
		<th align=right nowrap>| . $locale->text('Trade Discount') . qq|</th>
		<td>|
          . $form->format_amount( \%myconfig, $form->{tradediscount} * 100 )
          . qq| %</td>
	      </tr>
|;
    }

    $employee = qq|
                <input type=hidden name=employee value="$form->{employee}">
|;

    $employee = qq|
	      <tr>
	        <th align=right nowrap>| . $locale->text('Salesperson') . qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|
      . $form->escape( $form->{selectemployee}, 1 ) . qq|">
	      </tr>
| if $form->{selectemployee};

    $i     = $form->{rowcount} + 1;
    $focus = "partnumber_$i";

    $form->header;

    print qq|
<body onLoad="document.forms[0].${focus}.focus()" />

<form method=post action="$form->{script}">
|;

    $form->hide_form(
        qw(id type printed emailed queued title vc terms discount 
           creditlimit creditremaining tradediscount business closedto locked 
           shipped oldtransdate recurring reverse batch_id subtype)
    );

    print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>| . $locale->text('Customer') . qq|</th>
		<td colspan=3>$customer</td>
		<input type=hidden name=customer_id value=$form->{customer_id}>
		<input type=hidden name=oldcustomer value="$form->{oldcustomer}"> 
	      </tr>
	      <tr>
		<td></td>
		<td colspan=3>
		  <table>
		    <tr>
		      <th align=right nowrap>| . $locale->text('Credit Limit') . qq|</th>
		      <td>|
      . $form->format_amount( \%myconfig, $form->{creditlimit}, 0, "0" )
      . qq|</td>
		      <td width=10></td>
		      <th align=right nowrap>| . $locale->text('Remaining') . qq|</th>
		      <td class="plus$n" nowrap>|
      . $form->format_amount( \%myconfig, $form->{creditremaining}, 0, "0" )
      . qq|</td>
		    </tr>
		    $business
		  </table>
		</td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Record in') . qq|</th>
		<td colspan=3><select name=AR>$form->{selectAR}</select></td>
		<input type=hidden name=selectAR value="$form->{selectAR}">
	      </tr>
	      $department
	      $exchangerate
	      <tr>
		<th align=right nowrap>| . $locale->text('Shipping Point') . qq|</th>
		<td colspan=3><input name=shippingpoint size=35 value="$form->{shippingpoint}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Ship via') . qq|</th>
		<td colspan=3><input name=shipvia size=35 value="$form->{shipvia}"></td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $employee
	      <tr>
		<th align=right nowrap>| . $locale->text('Invoice Number') . qq|</th>
		<td><input name=invnumber size=20 value="$form->{invnumber}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Order Number') . qq|</th>
		<td><input name=ordnumber size=20 value="$form->{ordnumber}"></td>
<input type=hidden name=quonumber value="$form->{quonumber}">
	      </tr>
	      <tr>
		<th align=right>| . $locale->text('Invoice Date') . qq|</th>
		<td><input class="date" name=transdate size=11 title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right>| . $locale->text('Due Date') . qq|</th>
		<td><input class="date" name=duedate size=11 title="$myconfig{dateformat}" value=$form->{duedate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('PO Number') . qq|</th>
		<td><input name=ponumber size=20 value="$form->{ponumber}"></td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
    </td>
  </tr>
|;

    $form->hide_form(
        qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts)
    );

    foreach $item ( split / /, $form->{taxaccounts} ) {
        $form->hide_form( "${item}_rate", "${item}_description",
            "${item}_taxnumber" );
    }

}

sub void {
    for my $i (1 .. $form->{rowcount}){
        $form->{"qty_$_"} *= -1;
    }
    $form->{invnumber} .= '-VOID';
    $form->{reverse} = 1;
    &post_as_new;
}

sub form_footer {
    _calc_taxes();
    $form->{invtotal} = $form->{invsubtotal};

    if ( ( $rows = $form->numtextrows( $form->{notes}, 35, 8 ) ) < 2 ) {
        $rows = 2;
    }
    if ( ( $introws = $form->numtextrows( $form->{intnotes}, 35, 8 ) ) < 2 ) {
        $introws = 2;
    }
    $rows = ( $rows > $introws ) ? $rows : $introws;
    $notes =
qq|<textarea name=notes rows=$rows cols=35 wrap=soft>$form->{notes}</textarea>|;
    $intnotes =
qq|<textarea name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;

    $form->{taxincluded} = ( $form->{taxincluded} ) ? "checked" : "";

    $taxincluded = "";
    if ( $form->{taxaccounts} ) {
        $taxincluded = qq|
              <tr height="5"></tr>
              <tr>
	        <td align=right>
	        <input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td><th align=left>|
          . $locale->text('Tax Included')
          . qq|</th>
	     </tr>
|;
    }

    if ( !$form->{taxincluded} ) {
        foreach $item (keys %{$form->{taxes}}) {
            my $taccno = $item;
	    $form->{invtotal} += $form->round_amount($form->{taxes}{$item}, 2);
            $form->{"${taccno}_total"} =
                  $form->format_amount( \%myconfig,
                    $form->round_amount( $form->{taxes}{$item}, 2 ), 2 );
            next if !$form->{"${taccno}_total"};
            $tax .= qq|
        <tr>
      	<th align=right>$form->{"${taccno}_description"}</th>
      	<td align=right>$form->{"${taccno}_total"}</td>
        </tr>|;
        }

        $form->{invsubtotal} =
          $form->format_amount( \%myconfig, $form->{invsubtotal}, 2, 0 );

        $subtotal = qq|
	      <tr>
		<th align=right>| . $locale->text('Subtotal') . qq|</th>
		<td align=right>$form->{invsubtotal}</td>
	      </tr>
|;

    }

    $form->{oldinvtotal} = $form->{invtotal};
    $form->{invtotal} =
    $form->format_amount( \%myconfig, $form->{invtotal}, 2, 0 );
    
    my $hold;
    
    if ($form->{on_hold}) {
        
        $hold = qq| <font size="17"><b> This invoice is On Hold </b></font> |;
    }

    print qq|
  <tr>
    <td>
      <table width=100%>
	<tr valign=bottom>
	    | . $hold . qq|
	  <td>
	    <table>
	      <tr>
		<th align=left>| . $locale->text('Notes') . qq|</th>
		<th align=left>| . $locale->text('Internal Notes') . qq|</th>
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
		<th align=right>| . $locale->text('Total') . qq|</th>
		<td align=right>$form->{invtotal}</td>
	      </tr>
	      $taxincluded
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
	  <th colspan=6 class=listheading>| . $locale->text('Payments') . qq|</th>
	</tr>
|;

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        @column_index = qw(datepaid source memo paid AR_paid);
    }
    else {
        @column_index = qw(datepaid source memo paid exchangerate AR_paid);
    }

    $column_data{datepaid}     = "<th>" . $locale->text('Date') . "</th>";
    $column_data{paid}         = "<th>" . $locale->text('Amount') . "</th>";
    $column_data{exchangerate} = "<th>" . $locale->text('Exch') . "</th>";
    $column_data{AR_paid}      = "<th>" . $locale->text('Account') . "</th>";
    $column_data{source}       = "<th>" . $locale->text('Source') . "</th>";
    $column_data{memo}         = "<th>" . $locale->text('Memo') . "</th>";

    print "
	<tr>
";
    for (@column_index) { print "$column_data{$_}\n" }
    print "
        </tr>
";

    $form->{paidaccounts}++ if ( $form->{"paid_$form->{paidaccounts}"} );
    for $i ( 1 .. $form->{paidaccounts} ) {

        $form->hide_form("cleared_$i");

        print "
        <tr>\n";

        $form->{"selectAR_paid_$i"} = $form->{selectAR_paid};
        $form->{"selectAR_paid_$i"} =~
s/option>\Q$form->{"AR_paid_$i"}\E/option selected>$form->{"AR_paid_$i"}/;

        # format amounts
        $totalpaid += $form->{"paid_$i"};
        $form->{"paid_$i"} =
          $form->format_amount( \%myconfig, $form->{"paid_$i"}, 2 );
        $form->{"exchangerate_$i"} =
          $form->format_amount( \%myconfig, $form->{"exchangerate_$i"} );

        $exchangerate = qq|&nbsp;|;
        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            if ( $form->{"forex_$i"} ) {
                $exchangerate =
qq|<input type=hidden name="exchangerate_$i" value=$form->{"exchangerate_$i"}>$form->{"exchangerate_$i"}|;
            }
            else {
                $exchangerate =
qq|<input name="exchangerate_$i" size=10 value=$form->{"exchangerate_$i"}>|;
            }
        }

        $exchangerate .= qq|
<input type=hidden name="forex_$i" value=$form->{"forex_$i"}>
|;

        $column_data{paid} =
qq|<td align=center><input name="paid_$i" size=11 value=$form->{"paid_$i"}></td>|;
        $column_data{exchangerate} = qq|<td align=center>$exchangerate</td>|;
        $column_data{AR_paid} =
qq|<td align=center><select name="AR_paid_$i">$form->{"selectAR_paid_$i"}</select></td>|;
        $column_data{datepaid} =
qq|<td align=center><input class="date" name="datepaid_$i" size=11 title="$myconfig{dateformat}" value=$form->{"datepaid_$i"}></td>|;
        $column_data{source} =
qq|<td align=center><input name="source_$i" size=11 value="$form->{"source_$i"}"></td>|;
        $column_data{memo} =
qq|<td align=center><input name="memo_$i" size=11 value="$form->{"memo_$i"}"></td>|;

        for (@column_index) { print qq|$column_data{$_}\n| }
        print "
        </tr>\n";
    }

    $form->{oldtotalpaid} = $totalpaid;
    $form->hide_form(qw(paidaccounts selectAR_paid oldinvtotal oldtotalpaid));

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

    my $printops = &print_options;
    my $formname = { name => 'formname',
                     options => [
                                  {text=> 'Sales Invoice', value => 'invoice'},
                                ]
                   };
    print_select($form, $formname);
    print_select($form, $printops->{format});
    print_select($form, $printops->{media});
    print qq|
    </td>
  </tr>
</table>
<br>
|;

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Print')
    # type=submit $locale->text('Post')
    # type=submit $locale->text('Print and Post')
    # type=submit $locale->text('Schedule')
    # type=submit $locale->text('Ship to')
    # type=submit $locale->text('Post as new')
    # type=submit $locale->text('Print and Post as new')
    # type=submit $locale->text('E-mail')
    # type=submit $locale->text('Delete')
    # type=submit $locale->text('Sales Order')

    if ( !$form->{readonly} ) {
        
        # changes by Aurynn to add an On Hold button

        %button = (
            'update' =>
              { ndx => 1, key => 'U', value => $locale->text('Update') },
            'print' =>
              { ndx => 2, key => 'P', value => $locale->text('Print') },
            'post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
            'ship_to' =>
              { ndx => 4, key => 'T', value => $locale->text('Ship to') },
            'e_mail' =>
              { ndx => 5, key => 'E', value => $locale->text('E-mail') },
            'print_and_post' => {
                ndx   => 6,
                key   => 'R',
                value => $locale->text('Print and Post')
            },
            'post_as_new' =>
              { ndx => 7, key => 'N', value => $locale->text('Post as new') },
            'print_and_post_as_new' => {
                ndx   => 8,
                key   => 'W',
                value => $locale->text('Print and Post as new')
            },
            'sales_order' =>
              { ndx => 9, key => 'L', value => $locale->text('Sales Order') },
            'schedule' =>
              { ndx => 10, key => 'H', value => $locale->text('Schedule') },
            'delete' =>
              { ndx => 11, key => 'D', value => $locale->text('Delete') },
            'on_hold' =>
              { ndx => 12, key => 'O', value => $locale->text('On Hold') },
             'void'  => 
                { ndx => 12, key => 'V', value => $locale->text('Void') },
             'save_info'  => 
                { ndx => 13, key => 'I', value => $locale->text('Save Info') },

        );




        if ( $form->{id} ) {

            if ( $form->{locked} || $transdate <= $closedto ) {
                for ( "post", "print_and_post", "delete" ) {
                    delete $button{$_};
                }
            }

            if ( !${LedgerSMB::Sysconfig::latex} ) {
                for ( "print_and_post", "print_and_post_as_new" ) {
                    delete $button{$_};
                }
            }

        }
        else {

            if ( $transdate > $closedto ) {
                # Added on_hold, by Aurynn.
                for ( "update", "ship_to", "post",
                    "schedule", "on_hold" )
                {
                    $allowed{$_} = 1;
                }
                $a{'print_and_post'} = 1 if ${LedgerSMB::Sysconfig::latex};

                for ( keys %button ) { delete $button{$_} if !$allowed{$_} }
            }
            elsif ($closedto) {
                %button = ();
            }
        }

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            $form->print_button( \%button, $_ );
        }

    }

    if ( $form->{lynx} ) {
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
    on_update();
    $form->{taxes} = {};
    $form->{exchangerate} =
      $form->parse_amount( \%myconfig, $form->{exchangerate} );

    if ( $newname = &check_name(customer) ) {
        &rebuild_vc( customer, AR, $form->{transdate}, 1 );
    }
    if ( $form->{transdate} ne $form->{oldtransdate} ) {
        $form->{duedate} =
          ( $form->{terms} )
          ? $form->current_date( \%myconfig, $form->{transdate},
            $form->{terms} * 1 )
          : $form->{duedate};
        $form->{oldtransdate} = $form->{transdate};
        
	&rebuild_vc( customer, AR, $form->{transdate}, 1 ) if !$newname;

        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            delete $form->{exchangerate};
            $form->{exchangerate} = $exchangerate
              if (
                $form->{forex} = (
                    $exchangerate = $form->check_exchangerate(
                        \%myconfig,$form->{currency},
                        $form->{transdate}, 'buy'
                    )
                )
              );
        }

        $form->{selectemployee} = "";
        if ( @{ $form->{all_employee} } ) {
            for ( @{ $form->{all_employee} } ) {
                $form->{selectemployee} .=
                  qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
            }
        }
    }

    if ( $form->{currency} ne $form->{oldcurrency} ) {
        delete $form->{exchangerate};
        $form->{exchangerate} = $exchangerate
          if (
            $form->{forex} = (
                $exchangerate = $form->check_exchangerate(
                    \%myconfig,         $form->{currency},
                    $form->{transdate}, 'buy'
                )
            )
          );
    }

    $j = 1;
    for $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} ) {
            for (qw(datepaid source memo cleared)) {
                $form->{"${_}_$j"} = $form->{"${_}_$i"};
            }
            for (qw(paid exchangerate)) {
                $form->{"${_}_$j"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }

            $form->{"exchangerate_$j"} = $exchangerate
              if (
                $form->{"forex_$j"} = (
                    $exchangerate = $form->check_exchangerate(
                        \%myconfig,             $form->{currency},
                        $form->{"datepaid_$j"}, 'buy'
                    )
                )
              );
            if ( $j++ != $i ) {
                for (qw(datepaid source memo cleared paid exchangerate forex)) {
                    delete $form->{"${_}_$i"};
                }
            }
        }
        else {
            for (qw(datepaid source memo cleared paid exchangerate forex)) {
                delete $form->{"${_}_$i"};
            }
        }
    }
    $form->{paidaccounts} = $j;

    $i = $form->{rowcount};
    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

    for (qw(partsgroup projectnumber)) {
        $form->{"select$_"} = $form->unescape( $form->{"select$_"} )
          if $form->{"select$_"};
    }

    # if last row empty, check the form otherwise retrieve new item
    if (   ( $form->{"partnumber_$i"} eq "" )
        && ( $form->{"description_$i"} eq "" )
        && ( $form->{"partsgroup_$i"}  eq "" ) )
    {

        $form->{creditremaining} +=
          ( $form->{oldinvtotal} - $form->{oldtotalpaid} );
        &check_form;

    }
    else {

        IS->retrieve_item( \%myconfig, \%$form );

        $rows = scalar @{ $form->{item_list} };

        if ( $form->{language_code} && $rows == 0 ) {
            $language_code = $form->{language_code};
            $form->{language_code} = "";
            IS->retrieve_item( \%myconfig, \%$form );
            $form->{language_code} = $language_code;
            $rows = scalar @{ $form->{item_list} };
        }

        if ($rows) {

            if ( $rows > 1 ) {

                &select_item;
                $form->finalize_request();

            }
            else {

                $form->{"qty_$i"} =
                  ( $form->{"qty_$i"} * 1 ) ? $form->{"qty_$i"} : 1;

                $sellprice =
                  $form->parse_amount( \%myconfig, $form->{"sellprice_$i"} );

                for (qw(partnumber description unit)) {
                    $form->{item_list}[$i]{$_} =
                      $form->quote( $form->{item_list}[$i]{$_} );
                }
                for ( keys %{ $form->{item_list}[0] } ) {
                    $form->{"${_}_$i"} = $form->{item_list}[0]{$_};
                }
                if (! defined $form->{"discount_$i"}){
                    $form->{"discount_$i"} = $form->{discount} * 100;
                }
                if ($sellprice) {
                    $form->{"sellprice_$i"} = $sellprice;

                    ($dec) = ( $form->{"sellprice_$i"} =~ /\.(\d+)/ );
                    $dec = length $dec;
                    $decimalplaces1 = ( $dec > 2 ) ? $dec : 2;
                }
                else {
                    ($dec) = ( $form->{"sellprice_$i"} =~ /\.(\d+)/ );
                    $dec = length $dec;
                    $decimalplaces1 = ( $dec > 2 ) ? $dec : 2;

                    $form->{"sellprice_$i"} /= $exchangerate;
                }

                ($dec) = ( $form->{"lastcost_$i"} =~ /\.(\d+)/ );
                $dec = length $dec;
                $decimalplaces2 = ( $dec > 2 ) ? $dec : 2;

                # if there is an exchange rate adjust sellprice
                for (qw(listprice lastcost)) {
                    $form->{"${_}_$i"} /= $exchangerate;
                }

                $amount =
                  $form->{"sellprice_$i"} * $form->{"qty_$i"} *
                  ( 1 - $form->{"discount_$i"} / 100 );
                for ( split / /, $form->{taxaccounts} ) {
                    $form->{"${_}_base"} = 0;
                }
                for ( split / /, $form->{"taxaccounts_$i"} ) {
                    $form->{"${_}_base"} += $amount;
                }



                $form->{creditremaining} -= $amount;

                for (qw(sellprice listprice)) {
                    $form->{"${_}_$i"} =
                      $form->format_amount( \%myconfig, $form->{"${_}_$i"},
                        $decimalplaces1 );
                }
                $form->{"lastcost_$i"} =
                  $form->format_amount( \%myconfig, $form->{"lastcost_$i"},
                    $decimalplaces2 );

                $form->{"oldqty_$i"} = $form->{"qty_$i"};
                for (qw(qty discount)) {
                    $form->{"{_}_$i"} =
                      $form->format_amount( \%myconfig, $form->{"${_}_$i"} );
                }

            }

            &display_form;

        }
        else {

            # ok, so this is a new part
            # ask if it is a part or service item

            if (   $form->{"partsgroup_$i"}
                && ( $form->{"partsnumber_$i"} eq "" )
                && ( $form->{"description_$i"} eq "" ) )
            {
                $form->{rowcount}--;
                &display_form;
            }
            else {

                $form->{"id_$i"}   = 0;
                $form->{"unit_$i"} = $locale->text('ea');

                &new_item;

            }
        }
    }
}

sub post {

    $form->isblank( "transdate", $locale->text('Invoice Date missing!') );
    $form->isblank( "customer",  $locale->text('Customer missing!') );

    # if oldcustomer ne customer redo form
    if ( &check_name(customer) ) {
        &update;
        $form->finalize_request();
    }

    &validate_items;

    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );
    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    $form->error( $locale->text('Cannot post invoice for a closed period!') )
      if ( $transdate <= $closedto );

    $form->isblank( "exchangerate", $locale->text('Exchange rate missing!') )
      if ( $form->{currency} ne $form->{defaultcurrency} );

    for $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} ) {
            $datepaid = $form->datetonum( \%myconfig, $form->{"datepaid_$i"} );

            $form->isblank( "datepaid_$i",
                $locale->text('Payment date missing!') );

            $form->error(
                $locale->text('Cannot post payment for a closed period!') )
              if ( $datepaid <= $closedto );

            if ( $form->{currency} ne $form->{defaultcurrency} ) {
                $form->{"exchangerate_$i"} = $form->{exchangerate}
                  if ( $transdate == $datepaid );
                $form->isblank( "exchangerate_$i",
                    $locale->text('Exchange rate for payment missing!') );
            }
        }
    }

    $form->{label} = $locale->text('Invoice');

    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            &repost;
            $form->finalize_request();
        }
    }

    ( $form->{AR} )      = split /--/, $form->{AR};
    ( $form->{AR_paid} ) = split /--/, $form->{AR_paid};

    if ( IS->post_invoice( \%myconfig, \%$form ) ) {
        $form->redirect(
            $locale->text( 'Invoice [_1] posted!', $form->{invnumber} ) );
    }
    else {
        $form->error( $locale->text('Cannot post invoice!') );
    }

}

sub print_and_post {

    $form->error( $locale->text('Select postscript or PDF!') )
      if $form->{format} !~ /(postscript|pdf)/;
    $form->error( $locale->text('Select a Printer!') )
      if $form->{media} eq 'screen';

    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            $form->{print_and_post} = 1;
            &repost;
            $form->finalize_request();
        }
    }

    $old_form = new Form;
    $form->{display_form} = "post";
    for ( keys %$form ) { $old_form->{$_} = $form->{$_} }
    $old_form->{rowcount}++;

    &print_form($old_form);

}

sub delete {

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>
|;

    $form->{action} = "yes";
    $form->hide_form;

    print qq|
<h2 class=confirm>| . $locale->text('Confirm!') . qq|</h2>

<h4>|
      . $locale->text( 'Are you sure you want to delete Invoice Number [_1]?',
        $form->{invnumber} )
      . qq|
</h4>

<p>
<button name="action" class="submit" type="submit" value="yes">|
      . $locale->text('Yes')
      . qq|</button>
</form>
|;

}

sub yes {

    if (
        IS->delete_invoice(
            \%myconfig, \%$form, ${LedgerSMB::Sysconfig::spool}
        )
      )
    {
        $form->redirect( $locale->text('Invoice deleted!') );
    }
    else {
        $form->error( $locale->text('Cannot delete invoice!') );
    }

}

sub on_hold {
    
    if ($form->{id}) {
        
        my $toggled = IS->toggle_on_old($form);
    
        #&invoice_links(); # is that it?
        &edit(); # it was already IN edit for this to be reached.
    }    
}



sub save_info {
    
	    my $taxformfound=0;

	    $taxformfound=IS->taxform_exist($form,$form->{"customer_id"});
	    
        #print STDERR qq|___Rowcount=$form->{rowcount} _______|;
            $form->{arap} = 'ar';
            AA->save_intnotes($form);

	    foreach my $i(1..($form->{rowcount}))
	    {
            #print STDERR qq| taxformcheck_$i = $form->{"taxformcheck_$i"} and taxformfound= $taxformfound ___________|;
		
		if($form->{"taxformcheck_$i"} and $taxformfound)
		{
			
		  IS->update_invoice_tax_form($form,$form->{dbh},$form->{"invoice_id_$i"},"true") if($form->{"invoice_id_$i"});

		}
		else
		{

		    IS->update_invoice_tax_form($form,$form->{dbh},$form->{"invoice_id_$i"},"false") if($form->{"invoice_id_$i"});

		}
		
	    }    

	    if ($form->{callback}){
		print "Location: $form->{callback}\n";
		print "Status: 302 Found\n\n";
		print "<html><body>";
		my $url = $form->{callback};
		print qq|If you are not redirected automatically, click <a href="$url">|
			. qq|here</a>.</body></html>|;

	    } else {
		$form->info($locale->text('Draft Posted'));
	    }

}



