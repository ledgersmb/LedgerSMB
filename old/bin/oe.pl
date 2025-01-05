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

package lsmb_legacy;

use List::Util qw(max min);
use LedgerSMB::OE;
use LedgerSMB::IIAA;
use LedgerSMB::IR;
use LedgerSMB::IS;
use LedgerSMB::Magic qw(OEC_SALES_ORDER OEC_PURCHASE_ORDER);
use LedgerSMB::PE;
use LedgerSMB::Tax;
use LedgerSMB::Legacy_Util;


require "old/bin/arap.pl";
require "old/bin/io.pl";

# end of main

sub add {

    if ( $form->{type} eq 'purchase_order' ) {
        $form->{title} = $locale->text('Add Purchase Order');
        $form->{vc}    = 'vendor';
    }
    if ( $form->{type} eq 'sales_order' ) {
        $form->{title} = $locale->text('Add Sales Order');
        $form->{vc}    = 'customer';
    }
    if ( $form->{type} eq 'request_quotation' ) {
        $form->{title} = $locale->text('Add Request for Quotation');
        $form->{vc}    = 'vendor';
    }
    if ( $form->{type} eq 'sales_quotation' ) {
        $form->{title} = $locale->text('Add Quotation');
        $form->{vc}    = 'customer';
    }

    $form->{callback} = "$form->{script}?__action=add&type=$form->{type}&vc=$form->{vc}"
      unless $form->{callback};

    $form->{rowcount} = 0;

    &order_links;
    &prepare_order;
    &display_form;

}

sub edit {
    if (not $form->{id} and $form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
        $form->{id} = $wf->context->param( '_extra' )->{id};
        delete $form->{workflow_id};
    }

    OE->get_type($form);
    if ( $form->{type} =~ /(purchase_order|bin_list)/ ) {
        $form->{title} = $locale->text('Edit Purchase Order');
        $form->{vc}    = 'vendor';
        $form->{type}  = 'purchase_order';
    }
    if ( $form->{type} =~ /((sales|work)_order|(packing|pick)_list)/ ) {
        $form->{title} = $locale->text('Edit Sales Order');
        $form->{vc}    = 'customer';
        $form->{type}  = 'sales_order';
    }
    if ( $form->{type} eq 'request_quotation' ) {
        $form->{title} = $locale->text('Edit Request for Quotation');
        $form->{vc}    = 'vendor';
    }
    if ( $form->{type} eq 'sales_quotation' ) {
        $form->{title} = $locale->text('Edit Quotation');
        $form->{vc}    = 'customer';
    }

    &order_links;
    &prepare_order;
    &display_form;

}

sub order_links {


    # create links
    # $form->create_links( module => "OE", # effectively 'none'
    #          myconfig => \%myconfig,
    #          vc => $form->{vc},
    #          billing => 0,
    #          job => 1 );

    # retrieve order/quotation
    OE->retrieve( \%myconfig, \%$form );

    $form->{oldlanguage_code} = $form->{language_code};

    $l{language_code} = $form->{language_code};
    $l{searchitems} = 'nolabor' if $form->{vc} eq 'customer';

    $form->get_partsgroup(\%l);

    for (qw(terms taxincluded)) { $temp{$_} = $form->{$_} }
    $form->{shipto} = 1 if $form->{id};

    # get customer / vendor
    AA->get_name( \%myconfig, \%$form );

    if ( $form->{id} ) {
        for (qw(terms taxincluded)) { $form->{$_} = $temp{$_} }
    }

    ( $form->{ $form->{vc} } ) = split /--/, $form->{ $form->{vc} };
    $form->{"old$form->{vc}"} =
      qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;

    $form->{employee} = "$form->{employee}--$form->{employee_id}";

    @curr = split /:/, $form->{currencies};
    $form->{defaultcurrency} = $curr[0];
    chomp $form->{defaultcurrency};
    # forex
    $form->{forex} = $form->{exchangerate};

}

sub prepare_order {
    my %args          = @_;
    $form->{format}   //= "postscript" if $myconfig{printer};
    $form->{media}    //= $myconfig{printer};
    $form->{formname} //= $form->{type};
    $form->{sortby} ||= "runningnumber";
    $form->{currency} =~ s/ //g;
    $form->{oldcurrency} = $form->{currency};

    if ( $form->{id} ) {

        unless ($args{unquoted}) {
            for(qw(ordnumber quonumber shippingpoint shipvia notes intnotes
                   shiptoname shiptoaddress1 shiptoaddress2 shiptocity
                   shiptostate shiptozipcode shiptocountry shiptocontact)) {
                $form->{$_} = $form->quote( $form->{$_} );
            }
        }

        my $i;
        foreach my $ref ( @{ $form->{form_details} } ) {
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

            ($dec) = ( $form->{"sellprice_$i"} =~ /\.(\d+)/ );
            $dec = length $dec;
            $decimalplaces = ( $dec > 2 ) ? $dec : 2;
            $form->{"precision_$i"} = $decimalplaces;

            for ( map { "${_}_$i" } qw(sellprice listprice) ) {
                $form->{$_} =
                  $form->format_amount( \%myconfig, $form->{$_},
                    $decimalplaces );
            }

            ($dec) = ( $form->{"lastcost_$i"} =~ /\.(\d+)/ );
            $dec = length $dec;
            $decimalplaces = ( $dec > 2 ) ? $dec : 2;

            $form->{"lastcost_$i"} =
              $form->format_amount( \%myconfig, $form->{"lastcost_$i"},
                $decimalplaces );

            $form->{"qty_$i"} =
              $form->format_amount( \%myconfig, $form->{"qty_$i"} );
            $form->{"oldqty_$i"} = $form->{"qty_$i"};

            unless ($args{unquoted}) {
                for (qw(partnumber sku description unit)) {
                    $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
                }
            }
            $form->{rowcount} = $i;
        }
    }

    $form->{oldtransdate} = $form->{transdate};

    if ( $form->{type} eq 'sales_quotation' ) {
        $form->{selectformname} =
          qq|<option value="sales_quotation">| . $locale->text('Quotation');
    }

    if ( $form->{type} eq 'request_quotation' ) {
        $form->{selectformname} =
          qq|<option value="request_quotation">| . $locale->text('RFQ');
    }

    if ( $form->{type} eq 'sales_order' ) {
        $form->{selectformname} =
          qq|<option value="sales_order">|
          . $locale->text('Sales Order') . qq|
    <option value="work_order">| . $locale->text('Work Order') . qq|
    <option value="pick_list">| . $locale->text('Pick List') . qq|
    <option value="packing_list">| . $locale->text('Packing List');
    }

    if ( $form->{type} eq 'purchase_order' ) {
        $form->{selectformname} =
          qq|<option value="purchase_order">|
          . $locale->text('Purchase Order') . qq|
    <option value="bin_list">| . $locale->text('Bin List');
    }

    if ( $form->{type} eq 'ship_order' ) {
        $form->{selectformname} =
          qq|<option value="pick_list">|
          . $locale->text('Pick List') . qq|
    <option value="packing_list">| . $locale->text('Packing List');
    }

    if ( $form->{type} eq 'receive_order' ) {
        $form->{selectformname} =
          qq|<option value="bin_list">| . $locale->text('Bin List');
    }

}

sub form_header {

    my $ordnumber;
    my $numberfld;
    my $status_div_id = $form->{type};
    $status_div_id =~ s/_/-/g;
    my $wf;
    my $class_id;
    $form->{vc} = ( $form->{vc} eq 'customer' ) ? 'customer' : 'vendor';
    if ( $form->{type} =~ /_order$/ ) {
        $quotation = "0";
        $ordnumber = "ordnumber";
        if ($form->{vc} eq 'customer'){
            $numberfld = "sonumber";
            $class_id = 1;
        } else {
            $numberfld = "ponumber";
            $class_id = 2;
        }
    }
    else {
        $quotation = "1";
        $ordnumber = "quonumber";
        if ( $form->{vc} eq 'customer' ) {
            $numberfld = "sqnumber";
            $class_id = OEC_QUOTATION;
        } else {
            $numberfld = "rfqnumber";
            $class_id = OEC_RFQ;
        }
    }
    if($form->{workflow_id}) {
        $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
    }
    else {
        $wf = $form->{_wire}->get('workflows')
            ->create_workflow( 'Order/Quote',
                               Workflow::Context->new(
                                   'batch-id' => $form->{batch_id},
                                   '_extra' => {
                                       oe_class_id => $class_id
                                   }
                               ) );
        $form->{workflow_id} = $wf->id;
    }
    if ( $form->{type} =~ /_order$/ ) {
        $quotation = "0";
        $ordnumber = "ordnumber";
        if ($form->{vc} eq 'customer'){
            $numberfld = "sonumber";
        } else {
            $numberfld = "ponumber";
        }
    }
    else {
        $quotation = "1";
        $ordnumber = "quonumber";
        if ( $form->{vc} eq 'customer' ) {
            $numberfld = "sqnumber";
        } else {
            $numberfld = "rfqnumber";
        }
    }
    $form->{nextsub} = 'update';

    $sequences = $form->sequence_dropdown($numberfld) unless $form->{id};

    $checkedopen   = ( $form->{closed} ) ? ""        : "checked";
    $checkedclosed = ( $form->{closed} ) ? "checked" : "";

    if ( $form->{id} ) {
        $openclosed = qq|
      <tr>
    <th nowrap align=right><input id="closed-open" id="closed-open" name=closed type=radio data-dojo-type="dijit/form/RadioButton" class=radio value=0 $checkedopen> |
          . $locale->text('Open')
          . qq|</th>
    <th nowrap align=left><input id="closed-closed" id="closed-closed" name=closed type=radio data-dojo-type="dijit/form/RadioButton" class=radio value=1 $checkedclosed> |
          . $locale->text('Closed')
          . qq|</th>
      </tr>
|;
    }

    $form->{exchangerate} =
      $form->format_amount( \%myconfig, $form->{exchangerate} );

    $exchangerate = qq|<tr id="exchangerate-row">|;
    $exchangerate .= qq|
                <th align=right nowrap>| . $locale->text('Currency') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" name=currency id=currency>$form->{selectcurrency}</select></td> |
      if $form->{defaultcurrency};

    if (   $form->{defaultcurrency}
        && $form->{currency} ne $form->{defaultcurrency} )
    {
        if ( $form->{forex} ) {
            $exchangerate .=
                qq|<th align=right>|
              . $locale->text('Exchange Rate')
              . qq|</th><td>$form->{exchangerate}
      <input type=hidden name=exchangerate value=$form->{exchangerate}></td>
|;
        }
        else {
            $exchangerate .=
                qq|<th align=right>|
              . $locale->text('Exchange Rate')
              . qq|</th><td><input data-dojo-type="dijit/form/TextBox" id=exchangerate name=exchangerate size=10 value=$form->{exchangerate}></td>|;
        }
    }
    $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
</tr>
|;

    $vclabel = ucfirst $form->{vc};
    $vclabel = $locale->maketext($vclabel);

    $terms = qq|
                    <tr id="terms-row">
              <th align=right nowrap>| . $locale->text('Terms') . qq|</th>
              <td nowrap><input data-dojo-type="dijit/form/TextBox" id=name name=terms size="3" maxlength="3" value=$form->{terms}> |
      . $locale->text('days')
      . qq|</td>
                    </tr>
|;

    if ( $form->{business} ) {
        $business = qq|
          <tr class="business-row">
        <th align=right nowrap>| . $locale->text('Business') . qq|</th>
        <td colspan=3>$form->{business}
        &nbsp;&nbsp;&nbsp;|;
        $business .= qq|
        <b>| . $locale->text('Trade Discount') . qq|</b>
        | . $form->format_amount( \%myconfig, $form->{tradediscount} * 100 ) . qq| %|
          if $form->{vc} eq 'customer';
        $business .= qq|</td>
          </tr>
|;
    }

    if ( $form->{type} !~ /_quotation$/ ) {
        $ordnumber = qq|
          <tr class="ordnumber-row">
        <th width=70% align=right nowrap>| . $locale->text('Order Number') . qq|</th>
                <td><input data-dojo-type="dijit/form/TextBox" id=ordnumber name=ordnumber size=20 value="$form->{ordnumber}">
                     $sequences
        <input type=hidden name=quonumber value="$form->{quonumber}"></td>
          </tr>
          <tr class="transdate-row">
        <th align=right nowrap>| . $locale->text('Order Date') . qq|</th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox"name=transdate size=11 title="$myconfig{dateformat}" value="$form->{transdate}" id="transdate" data-dojo-props="defaultIsToday:true"></td>
          </tr>
          <tr class="reqdate-row">
        <th align=right nowrap=true>| . $locale->text('Required by') . qq|</th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name=reqdate size=11 title="$myconfig{dateformat}" value="$form->{reqdate}" id="reqdate"></td>
          </tr>
          <tr class="ponunber-row">
        <th align=right nowrap>| . ($form->{type} =~ /purchase_/ ?
                        $locale->text('SO Number') : $locale->text('PO Number')) . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" id=ponumber name=ponumber size=20 value="$form->{ponumber}"></td>
          </tr>
|;

        $n = ( $form->{creditremaining} < 0 ) ? "0" : "1";

        if ($form->setting->get('show_creditlimit')){
        $creditremaining = qq|
          <tr>
        <td></td>
        <td>
          <table class="creditlimit">
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
    |;
    } else {
         $creditremaining = qq|<tr><td colspan="2"><table><tr>|;
    }
         if ($form->{entity_control_code}){
            $creditremaining .= qq|
            <tr class="control-code-field">
        <th align="right" nowrap>| .
            $locale->text('Entity Code') . qq|</th>
        <td colspan="2">$form->{entity_control_code}</td>
        <th align="right" nowrap>| .
            $locale->text('Account') . qq|</th>
        <td colspan=3>$form->{meta_number}</td>
          </tr>
              <tr class="address_row">
                <th align="right" nowrap>| .
                        $locale->text('Address'). qq|</th>
                <td colspan=3>$form->{address}, $form->{city}</td>
              </tr>
        |;
           }
    $creditremaining .= qq|
                 </table>
        </td>
          </tr>
|;
    }
    else {
        $reqlabel =
          ( $form->{type} eq 'sales_quotation' )
          ? $locale->text('Valid until')
          : $locale->text('Required by');
        if ( $form->{type} eq 'sales_quotation' ) {
            $ordnumber = qq|
          <tr class="quonumber-row">
        <th width=70% align=right nowrap>|
              . $locale->text('Quotation Number')
              . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" id=quonumber name=quonumber size=20 value="$form->{quonumber}">
                    $sequences
        <input type=hidden name=ordnumber value="$form->{ordnumber}"></td>
          </tr>
|;
        }
        else {
            $ordnumber = qq|
          <tr class="rfqnumber-row">
        <th width=70% align=right nowrap>| . $locale->text('RFQ Number') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" id=quonumber name=quonumber size=20 value="$form->{quonumber}">
                    $sequences
        <input type=hidden name=ordnumber value="$form->{ordnumber}"></td>
          </tr>
|;

            $terms = "";
        }

        $ordnumber .= qq|
          <tr class="transdate-row">
        <th align=right nowrap>| . $locale->text('Quotation Date') . qq|</th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name=transdate size=11 title="$myconfig{dateformat}" value="$form->{transdate}" id="transdate" data-dojo-props="defaultIsToday:true"></td>
          </tr>
          <tr>
        <th align=right nowrap=true>$reqlabel</th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name=reqdate size=11 title="$myconfig{dateformat}" value="$form->{reqdate}" id="reqdate"></td>
          </tr>
|;

    }

    $ordnumber .= qq|
<input type=hidden name=oldtransdate value=$form->{oldtransdate}>|;

    if ( $form->{"select$form->{vc}"} ) {
        $vc = qq|<select data-dojo-type="lsmb/FilteringSelect" name="$form->{vc}" id="$form->{vc}"><option></option>$form->{"select$form->{vc}"}</select>|;
    }
    else {
        if ($form->{vc} eq 'vendor'){
            $eclass = 1;
        } elsif ($form->{vc} eq 'customer'){
            $eclass = 2
        }
        $vc = qq|<input data-dojo-type="dijit/form/TextBox" id=$form->{vc} name=$form->{vc} value="$form->{$form->{vc}}" size=35>
             <a id="new-contact" target="_blank"
                 href="erp.pl?__action=root#contact.pl?__action=add&entity_class=$eclass">
                 [| . $locale->text('New') . qq|]</a>|;
    }

    $department = qq|
              <tr class="department-row">
            <th align="right" nowrap>| . $locale->text('Department') . qq|</th>
        <td colspan=3><select data-dojo-type="dijit/form/Select" name=department id=department>$form->{selectdepartment}</select>
        </td>
          </tr>
| if $form->{selectdepartment};

    $employee = qq|
              <input type=hidden name=employee value="$form->{employee}">
|;

    if ( $form->{type} eq 'sales_order' ) {
        if ( $form->{selectemployee} ) {
            $employee = qq|
           <tr class="employee-row">
            <th align=right nowrap>| . $locale->text('Salesperson') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" name=employee id=employee>$form->{selectemployee}</select></td>
          </tr>
|;
        }
    }
    else {
        if ( $form->{selectemployee} ) {
            $employee = qq|
           <tr class="employee-row">
            <th align=right nowrap>| . $locale->text('Employee') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" name=employee id=employee>$form->{selectemployee}</select></td>
          </tr>
|;
        }
    }

    $i     = $form->{rowcount} + 1;
    $focus = $form->{barcode} ? "barcode" : "partnumber_$i";

    $form->header;

    print qq|
<body>
| . $form->open_status_div($status_div_id) . qq|
<form method="post"
      id="invoice"
      data-dojo-type="lsmb/Invoice"
      data-lsmb-focus="${focus}"
      action="$form->{script}" >
|;

    if ($form->{notice}){
         print qq|$form->{notice}<br/>|;
    }
    $form->hide_form(qw(entity_control_code meta_number tax_id address city zipcode state country));
    $form->hide_form(
        qw(id type printed emailed vc title discount creditlimit creditremaining tradediscount business recurring form_id nextsub
   lock_description)
    );

    $form->get_shipto( $form->{shiptolocationid} );
    print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop colspan="5">$form->{title}</th>
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
        <td colspan=3>$vc
        <input type=hidden name=$form->{vc}_id value=$form->{"$form->{vc}_id"}>
        <input type=hidden name="old$form->{vc}" value="$form->{"old$form->{vc}"}"></td>
          </tr>
          $creditremaining
          $business
          $department
          $exchangerate
          <tr class="shippingpoint-row">
        <th align=right nowrap>| . $locale->text('Shipping Point') . qq|</th>
        <td colspan=3><input data-dojo-type="dijit/form/TextBox" id=shippingpoint name=shippingpoint size=35 value="$form->{shippingpoint}"></td>
          </tr>|;
    print qq|
          <tr>
            <th align=right nowrap>| . $locale->text('Shipping Attn') . qq|</th>
            <td><input name=shiptoattn id=shiptoattn data-dojo-type="dijit/form/TextBox" value="$form->{shiptoattn}"></td>
          </tr>
          <tr>
            <th align=right nowrap>| . $locale->text('Shipping Address') . qq|</th>
            <td>$form->{shiptoaddress1} <br/>
                $form->{shiptoaddress2} <br/>
                $form->{shiptocity}, $form->{shiptostate} <br/>
                $form->{shiptozipcode} <br/>
                $form->{shiptocountry}
                </td>
          </tr>|
        if $form->{vc} eq 'customer';
    print qq|
          <tr class="shipvia-row">
        <th align=right>| . $locale->text('Ship via') . qq|</th>
        <td colspan=3><textarea data-dojo-type="dijit/form/Textarea" id="shipvia" name="shipvia" cols="35"
                                rows="3">$form->{shipvia}</textarea></td>
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
  <tr><td>

|;

    $form->hide_form(
        qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts shiptolocationid)
    );

    for ( split / /, $form->{taxaccounts} ) {
        print qq|
<input type=hidden name="${_}_rate" value=$form->{"${_}_rate"}>
<input type=hidden name="${_}_description" value="$form->{"${_}_description"}">
|;
    }
    if ( !$form->{readonly} ) {
        print "<tr><td>";

        %button_types = (
            print => 'lsmb/PrintButton'
            );
        %button = ();
        for my $action_name ( $wf->get_current_actions( 'main') ) {
            my $action = $wf->get_action( $action_name );

            next if ($action->ui // '') eq 'none';
            $button{$action_name} = {
                ndx   => $action->order,
                value => $locale->maketext($action->text),
                doing => ($action->doing ? $locale->maketext($action->doing) : ''),
                done  => ($action->done ? $locale->maketext($action->done) : ''),
                type  => $button_types{$action->ui},
                tooltip => ($action->short_help ? $locale->maketext($action->short_help) : '')
            };
        }

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} }
              keys %button ) {
            $form->print_button( \%button, $_ );
        }

        $form->hide_form(qw(defaultcurrency workflow_id));
        print "</td></tr>";
    }
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
qq|<textarea data-dojo-type="dijit/form/Textarea" id=notes name=notes rows=$rows cols=35 wrap=soft>$form->{notes}</textarea>|;
    $intnotes =
qq|<textarea data-dojo-type="dijit/form/Textarea" id=intnotes name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;

    $form->{taxincluded} = ( $form->{taxincluded} ) ? "checked" : "";

    $taxincluded = "";
    if ( $form->{taxaccounts} ) {
        $taxincluded = qq|
            <tr height="5"></tr>
            <tr>
          <td align=right>
          <input name=taxincluded id=taxincluded class=checkbox type=checkbox data-dojo-type="dijit/form/CheckBox" value=1 $form->{taxincluded}></td>
          <th align=left>| . $locale->text('Tax Included') . qq|</th>
        </tr>
|;
    }

    $form->{_setting_decimal_places} = $form->setting->get('decimal_places');
    if ( !$form->{taxincluded} ) {
        foreach my $item (keys %{$form->{taxes}}) {
            my $taccno = $item;
        $form->{invtotal} += $form->round_amount($form->{taxes}{$item}, 2);
            $form->{"${taccno}_total"} = $form->format_amount(
                \%myconfig,
                $form->round_amount( $form->{taxes}{$item}, 2 ),
                $form->{_setting_decimal_places}
            );
            next if !$form->{"${taccno}_total"};
            $tax .= qq|
        <tr>
          <th align="right">$form->{"${taccno}_description"}</th>
          <td align="right">$form->{"${taccno}_total"}</td>
        </tr>|;
        }

        $form->{invsubtotal} =
          $form->format_amount( \%myconfig, $form->{invsubtotal}, $form->{_setting_decimal_places}, 0 );

        $subtotal = qq|
          <tr>
        <th align="right">| . $locale->text('Subtotal') . qq|</th>
        <td align="right">$form->{invsubtotal}</td>
          </tr>
|;

    }
    $form->{oldinvtotal} = $form->{invtotal};
    $form->{invtotal} =
      $form->format_amount( \%myconfig, $form->{invtotal}, $form->{_setting_decimal_places}, 0 );

    my $display_barcode = $form->get_setting('have_barcodes') ? "initial" : "none";
    print qq|
  <tr style="display:$display_barcode">
   <td colspan="5"><b><label for="barcode">Barcode</label></b>: <input data-dojo-type="dijit/form/TextBox" id=barcode name=barcode></td>
  </tr>
  <tr>
    <td>
      <table width=100%>
    <tr valign=top>
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
<input type=hidden name=oldinvtotal value=$form->{oldinvtotal}>
<input type=hidden name=oldtotalpaid value=$totalpaid>
    </td>
  </tr>
  <tr>
    <td>
|;

    IIAA->print_wf_history_table($form, 'Order/Quote');

    print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;


    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
    {
        $form->print_button( \%button, $_ );
    }

    my $wf = $form->{_wire}->get( 'workflows' )->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
    if ( $wf and grep { $_ eq 'print' } $wf->get_current_actions ) {
        my $printops = &print_options;

        print "<br /><br />";
        print_select($form, $printops->{formname});
        print_select($form, $printops->{lang});
        print_select($form, $printops->{format});
        print_select($form, $printops->{media});

        %button_types = (
            print => 'lsmb/PrintButton'
            );
        %button = ();
        for my $action_name ( $wf->get_current_actions( 'output') ) {
            my $action = $wf->get_action( $action_name );

            next if ($action->ui // '') eq 'none';
            $button{$action_name} = {
                ndx   => $action->order,
                value => $locale->maketext($action->text),
                doing => ($action->doing ? $locale->maketext($action->doing) : ''),
                done  => ($action->done ? $locale->maketext($action->done) : ''),
                type  => $button_types{$action->ui},
                tooltip => ($action->short_help ? $locale->maketext($action->short_help) : '')
            };
        }

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} }
              keys %button ) {
            $form->print_button( \%button, $_ );
        }
    }
    if ($form->{id}){
        OE->get_files($form, $locale);
        print qq|
<table width="100%">
<tr class="listtop">
<th colspan="4">| . $locale->text('Attached and Linked Files') . qq|</th>
<tr class="listheading">
<th>| . $locale->text('File name') . qq|</th>
<th>| . $locale->text('File type') . qq|</th>
<th>| . $locale->text('Attached at') . qq|</th>
<th>| . $locale->text('Attached by') . qq|</th>
</tr> |;
        foreach my $file (@{$form->{files}}){
              print qq|
<tr>
<td><a href="file.pl?__action=get&file_class=2&ref_key=$form->{id}&id=$file->{id}&type=sales_quotation&additional=type"
       target="_download">$file->{file_name}</a></td>
<td>$file->{mime_type}</td>
<td>|.$file->{uploaded_at}.qq|</td>
<td>$file->{uploaded_by_name}</td>
</tr>
              |;
        }
        print qq|
<table width="100%">
<tr class="listheading">
<th>| . $locale->text('File name') . qq|</th>
<th>| . $locale->text('File type') . qq|</th>
<th>| . $locale->text('Attached To Type') . qq|</th>
<th>| . $locale->text('Attached To') . qq|</th>
<th>| . $locale->text('Attached at') . qq|</th>
<th>| . $locale->text('Attached by') . qq|</th>
</tr>|;
       foreach my $link (@{$form->{file_links}}){
            $aclass="&nbsp;";
            if ($link.src_class == 1){
                $aclass="Transaction";
            } elsif ($link.src_class == 2){
                $aclass="Order";
            }
            print qq|
<tr>
<td> $file->{file_name} </td>
<td> $file->{mime_type} </td>
<td> $aclass </td>
<td> $file->{reference} </td>
<td> $file->{attached_at} </td>
<td> $file->{attached_by} </td>
</tr>|;
       }
       print qq|
</table>|;
       $callback = $form->escape("oe.pl?__action=edit&id=".$form->{id});
       print qq|
<a href="file.pl?__action=show_attachment_screen&ref_key=$form->{id}&file_class=2&callback=$callback"
   >[| . $locale->text('Attach') . qq|]</a>|;
    }

    $form->hide_form(qw(rowcount callback path login sessionid));

    print qq|
</form>
| . $form->close_status_div . qq|
</body>
</html>
|;

}

sub update {
    $form->{nextsub} = 'update';

    # $form->create_links( module => "OE", # effectively 'none'
    #          myconfig => \%myconfig,
    #          vc => $form->{vc},
    #          billing => 0,
    #          job => 1 );

    $form->get_regular_metadata(
        \%myconfig,
        $form->{vc},
        $form->{transdate},
        1,
    );
    $form->{$_} = $form->parse_date( \%myconfig, $form->{$_} )->to_output()
       for qw(transdate reqdate);


    delete $form->{"partnumber_$form->{delete_line}"} if $form->{delete_line};
    if ( $form->{type} eq 'generate_purchase_order' ) {

        for ( 1 .. $form->{rowcount} ) {
            if ( $form->{"ndx_$_"} ) {
                $form->{"$form->{vc}_id_$_"} = $form->{"$form->{vc}_id"};
                $form->{"$form->{vc}_$_"} =
                  qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
            }
        }

        &po_orderitems;
        $form->finalize_request();
    }

    $form->{exchangerate} =
      $form->parse_amount( \%myconfig, $form->{exchangerate} );

    if ( $form->{vc} eq 'customer' ) {
        $buysell = "buy";
        $ARAP    = "AR";
    }
    else {
        $buysell = "sell";
        $ARAP    = "AP";
    }

    ( $form->{employee}, $form->{employee_id} ) = split /--/, $form->{employee}
        if $form->{employee} && ! $form->{employee_id};
    if ( $newname = &check_name( $form->{vc} ) ) {
        $form->rebuild_vc($form->{vc}, $form->{transdate}, 1);
    }

    # I think this is safe because the shipping or receiving is tied to the
    # order which is tied to the customer or vendor.  -CT
    $newname = 1 if $form->{type} =~ /(ship|receive)/;

    if ( $form->{transdate} ne $form->{oldtransdate} ) {
        $form->{reqdate} =
          ( $form->{terms} )
          ? $form->current_date( \%myconfig, $form->{transdate},
            $form->{terms} * 1 )
          : $form->{reqdate};
        $form->{oldtransdate} = $form->{transdate};
        $form->rebuild_vc($form->{vc}, $form->{transdate}, 1) if !$newname;

        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            delete $form->{exchangerate};
        }
    }

    if ( $form->{currency} ne $form->{oldcurrency} ) {
        delete $form->{exchangerate};
    }

    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

    for (qw(partsgroup projectnumber)) {
        $form->{"select$_"} = $form->unescape( $form->{"select$_"} )
          if $form->{"select$_"};
    }

    my $non_empty_rows = 0;
    for my $i (1 .. $form->{rowcount}) {
        $non_empty_rows++
            if $form->{"id_$i"}
               || ! ( ( $form->{"partnumber_$i"} eq "" )
                      && ( $form->{"description_$i"} eq "" )
                      && ( $form->{"partsgroup_$i"}  eq "" ) );
    }
    if ($form->{barcode}) {
        $non_empty_rows++;
        IIAA->process_form_barcode(\%myconfig, $form, $non_empty_rows, $form->{barcode});
    }

    my $current_empties = $form->{rowcount} - $non_empty_rows;
    my $new_empties =
        max(0,
            max($form->get_setting('min_empty'),1)
            - $current_empties);


    $form->{rowcount} += $new_empties;
    for my $i (1 .. $form->{rowcount}){
        $form->{rowcount} = $i;
        next if $form->{"id_$i"};

        if (   ( $form->{"partnumber_$i"} eq "" )
            && ( $form->{"description_$i"} eq "" )
            && ( $form->{"partsgroup_$i"}  eq "" ) )
        {

            $form->{creditremaining} +=
              ( $form->{oldinvtotal} - $form->{oldtotalpaid} );

        }
        else {
            ($form->{"partnumber_$i"}) = split(/--/, $form->{"partnumber_$i"});

            $retrieve_item = "";
            if (   $form->{type} eq 'purchase_order'
                || $form->{type} eq 'request_quotation' )
            {
                $retrieve_item = "IR::retrieve_item";
            }
            if (   $form->{type} eq 'sales_order'
                || $form->{type} eq 'sales_quotation' )
            {
                $retrieve_item = "IS::retrieve_item";
            }

            &{"$retrieve_item"}( "", \%myconfig, \%$form );

            $rows = scalar @{ $form->{item_list} };
            if ($form->{type} eq 'request_quotation'){
               for my $ref (@{ $form->{item_list} }){
                   $ref->{sellprice} = 0;
                   $ref->{lastcost} = 0;
               }
            }

            if ( $form->{language_code} && $rows == 0 ) {
                $language_code = $form->{language_code};
                $form->{language_code} = "";
                if ($retrieve_item) {
                    &{"$retrieve_item"}( "", \%myconfig, \%$form );
                }
                $form->{language_code} = $language_code;
                $rows = scalar @{ $form->{item_list} };
            }

            if ($rows) {

                $form->{"qty_$i"} =
                  ( $form->{"qty_$i"} * 1 ) ? $form->{"qty_$i"} : 1;
                $form->{"reqdate_$i"} = $form->{reqdate}
                  if $form->{type} ne 'sales_quotation';
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
                    $form->{"${_}_base"} //= LedgerSMB::PGNumber->from_db(0);
                    $form->{"${_}_base"} += $amount if $amount;
                }
                $form->{creditremaining} -= $amount if $amount;

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
        }
    }
    $form->all_vc(\%myconfig, $form->{vc}, $form->{transdate}, 1) if ! @{$form->{"all_$form->{vc}"}};
    $form->generate_selects;
    check_form();

    $form->{rowcount}--;
    display_form();
}

sub save {
    &_save;
}

sub _save {
    delete $form->{display_form};


    if ( $form->{type} =~ /_order$/ ) {
        $msg = $locale->text('Order Date missing!');
    }
    else {
        $msg = $locale->text('Quotation Date missing!');
    }

    $form->isblank( "transdate", $msg );

    $msg = ucfirst $form->{vc};

    # $locale->text('Customer missing!');
    # $locale->text('Vendor missing!');
    $form->isblank( $form->{vc}, $locale->maketext( $msg . " missing!" ) );

    $form->isblank( "exchangerate", $locale->text('Exchange rate missing!') )
      if ( $form->{currency} ne $form->{defaultcurrency} );

    $form->check_form(1);
#    ++$form->{rowcount};


    # if the name changed get new values
    if ( &check_name( $form->{vc} ) ) {
        &update;
        $form->finalize_request();
    }

    # this is for the internal notes section for the [email] Subject
    if ( $form->{type} =~ /_order$/ ) {
        if ( $form->{type} eq 'sales_order' ) {
            $form->{label} = $locale->text('Sales Order');

            $numberfld = "sonumber";
            $ordnumber = "ordnumber";
        }
        else {
            $form->{label} = $locale->text('Purchase Order');

            $numberfld = "ponumber";
            $ordnumber = "ordnumber";
        }

        $err = $locale->text('Cannot save order!');

    }
    else {
        if ( $form->{type} eq 'sales_quotation' ) {
            $form->{label} = $locale->text('Quotation');

            $numberfld = "sqnumber";
            $ordnumber = "quonumber";
        }
        else {
            $form->{label} = $locale->text('Request for Quotation');

            $numberfld = "rfqnumber";
            $ordnumber = "quonumber";
        }

        $err = $locale->text('Cannot save quotation!');

    }

    if ( !$form->{repost}  && $form->{id}) {
        $form->{repost} = 1;
        my $template = $form->{_wire}->get('ui');
        return LedgerSMB::Legacy_Util::render_psgi(
            $form,
            $template->render($form, 'oe-save-warn',
                              {
                                  hiddens => $form,
                              }));
    }
    if (!$form->close_form()){
       $form->{notice} = $locale->text(
                'Could not save the data.  Please try again'
       );
       &update;
       $form->finalize_request();
    }

    if ( OE->save( \%myconfig, \%$form ) ) {
       # the old workflow is being saved-as. the new workflow has its id
       # set in workflow_id, because the form was saved already...
       my $id  = $form->{old_workflow_id} // $form->{workflow_id};
       my $wf  = $form->{_wire}->get('workflows')
           ->fetch_workflow( 'Order/Quote', $id );
       my $ctx = $wf->context;
       $ctx->param( spawned_type => 'Order/Quote' );
       $ctx->param( spawned_id   => $form->{workflow_id} );

       # m/save_as/ matches both print_and_save_as_new as well as save_as_new
       $wf->execute_action( ($form->{__action} =~ m/save_as/
                             ? 'save_as_new' : 'save') );

       delete $form->{old_workflow_id};

       edit();
    }
    else {
        $form->error($err);
    }

}

sub print_and_save {

    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
    $wf->execute_action( 'print_and_save' );

    &_print_and_save;
}

sub _print_and_save {
    $form->error( $locale->text('Select postscript or PDF!') )
      if $form->{format} !~ /(postscript|pdf)/;
    $form->error( $locale->text('Select a Printer!') )
      if $form->{media} eq 'screen';

    $old_form = Form->new;
    $form->{display_form} = "save";
    for ( keys %$form ) { $old_form->{$_} = $form->{$_} }
    $old_form->{rowcount}++;

    my $wf =
        $form->{_wire}->get('workflows')
        ->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
    $wf->execute_action( 'print' );
    &print_form($old_form);

}

sub delete {

    # The actual deletion in executed in the "yes" function below;
    # if we execute the "delete" action here, we'll land the order/quote
    # in limbo if the "yes" action isn't performed on the UI side (the
    # workflow has a DELETED state whereas the quote still exists...)
    #
    # my $wf = $form->{_wire}->get('workflows')
    #     ->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
    # $wf->execute_action( 'delete' );
    # $form->header;

    if ( $form->{type} =~ /_order$/ ) {
        $msg = $locale->text('Are you sure you want to delete Order Number?');
        $ordnumber = 'ordnumber';
    }
    else {
        $msg =
          $locale->text('Are you sure you want to delete Quotation Number?');
        $ordnumber = 'quonumber';
    }

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">
|;

    $form->{__action} = "yes";
    $form->hide_form;

    print qq|
<h2 class=confirm>| . $locale->text('Confirm!') . qq|</h2>

<h4>$msg $form->{$ordnumber}</h4>
<p>
<button data-dojo-type="dijit/form/Button" id="action-yes" name="__action" class="submit" type="submit" value="yes">|
      . $locale->text('Yes')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub yes {

    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
    $wf->execute_action( 'delete' );
    $form->header;

    if ( $form->{type} =~ /_order$/ ) {
        $msg = $locale->text('Order deleted!');
        $err = $locale->text('Cannot delete order!');
    }
    else {
        $msg = $locale->text('Quotation deleted!');
        $err = $locale->text('Cannot delete quotation!');
    }

    if ( OE->delete( \%myconfig, \%$form ) ) {
        $form->redirect($msg);
    }
    else {
        $form->error($err);
    }

}

sub vendor_invoice { &invoice }
sub sales_invoice  { &invoice }

sub invoice {
    if ( $form->{type} =~ /_order$/ ) {
        $form->isblank( "ordnumber", $locale->text('Order Number missing!') );
        $form->isblank( "transdate", $locale->text('Order Date missing!') );

    }
    else {
        $form->isblank( "quonumber",
            $locale->text('Quotation Number missing!') );
        $form->isblank( "transdate", $locale->text('Quotation Date missing!') );
        $form->{ordnumber} = "";
    }

    # if the name changed get new values
    if ( &check_name( $form->{vc} ) ) {
        &update;
        $form->finalize_request();
    }

    if (   $form->{type} =~ /_order/
        && $form->{currency} ne $form->{defaultcurrency} )
    {

        # check if we need a new exchangerate
        $buysell = ( $form->{type} eq 'sales_order' ) ? "buy" : "sell";

        $exchangerate = "";

        if ( !$exchangerate ) {
            &backorder_exchangerate( $orddate, $buysell );
            $form->finalize_request();
        }
    }

    # close orders/quotations
    $form->{closed} = 1;

    OE->save( \%myconfig, \%$form );
    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'Order/Quote', $form->{workflow_id} );
    my $action;

    $form->{transdate} = '';
    $form->{duedate} = '';
    $form->{id}     = '';
    $form->{closed} = 0;
    $form->{rowcount}--;
    $form->{shipto} = 1;

    if ( $form->{type} =~ /_order$/ ) {
        $form->{exchangerate} = $exchangerate;
        &create_backorder;
        $form->{transdate} = '';
        $form->{duedate} = '';
        $form->{crdate} = '';
    }
    $form->{workflow_id} = '';

    if (   $form->{type} eq 'purchase_order'
        || $form->{type} eq 'request_quotation' )
    {
        $form->{title}  = $locale->text('Add Vendor Invoice');
        $form->{script} = 'ir.pl';

        $script  = "ir";
        $buysell = 'sell';
        $action  = 'vendor_invoice';
    }
    if ( $form->{type} eq 'sales_order' || $form->{type} eq 'sales_quotation' )
    {
        $form->{title}  = $locale->text('Add Sales Invoice');
        $form->{script} = 'is.pl';
        $script         = "is";
        $buysell        = 'buy';
        $action         = 'sales_invoice';
    }
    my $lib = uc($script);

    for (qw(id subject message printed emailed)) { delete $form->{$_} }
    $form->{ $form->{vc} } =~ s/--.*//g;
    $form->{type} = "invoice";

    #$form->{charset} = $locale->encoding;
    $form->{charset} = 'UTF-8';
    $locale->encoding('UTF-8');

    require "old/bin/$form->{script}";

    # customized scripts
    if ( -f "old/bin/custom/$form->{script}" ) {
        eval { require "old/bin/custom/$form->{script}"; };
    }

    for ( "$form->{vc}", "currency" ) { $form->{"select$_"} = "" }
    for (
        qw(currency oldcurrency employee department intnotes notes taxincluded))
    {
        $temp{$_} = $form->{$_};
    }

    &invoice_links;

    $form->{creditremaining} -= ( $form->{oldinvtotal} - $form->{ordtotal} );

    &prepare_invoice;

    for ( keys %temp ) { $form->{$_} = $temp{$_} }

    $form->{exchangerate} = "";
    $form->{forex}        = "";

    for my $i ( 1 .. $form->{rowcount} ) {
        $form->{"deliverydate_$i"} = $form->{"reqdate_$i"};
        for (qw(qty sellprice discount)) {
            $form->{"${_}_$i"} =
              $form->format_amount( \%myconfig, $form->{"${_}_$i"} );
        }
    }
    $form->{duedate} = $form->current_date( \%myconfig, $form->{transdate},
                                            $form->{terms} * 1 );

    for (qw(id subject message printed emailed audittrail)) {
        delete $form->{$_};
    }

    {
        # force the invoice to be saved, not posted!
        local $form->{separate_duties} = 1;
        local $form->{approved} = undef;

        my $wf = $form->{_wire}->get('workflows')
            ->create_workflow( 'AR/AP' );
        $form->{workflow_id} = $wf->id;

        $wf->execute_action( 'post' );
        # $lib contains either 'IS' or 'IR': the sales and purchase invoice libs
        $lib->post_invoice(\%myconfig, $form);
        $lib->retrieve_invoice(\%myconfig, $form);
        &prepare_invoice;
    }
    $wf->context->param( 'spawned_id'   => $form->{workflow_id} );
    $wf->context->param( 'spawned_type' => 'AR/AP' );
    $wf->context->param( '_extra' => {
        oe_class_id => ($action eq 'sales_invoice') ? OEC_SALES_ORDER() : OEC_PURCHASE_ORDER()
                         } );
    $wf->execute_action( $action );

    &display_form;
}

sub backorder_exchangerate {
    my ( $orddate, $buysell ) = @_;

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">
|;

    # delete action variable
    for (qw(nextsub exchangerate)) { delete $form->{$_} }

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
      <th align=right>| . $locale->text('Currency') . qq|</th>
      <td>$form->{currency}</td>
    </tr>
    <tr>
      <th align=right>| . $locale->text('Date') . qq|</th>
      <td>$orddate</td>
    </tr>
        <tr>
      <th align=right>| . $locale->text('Exchange Rate') . qq|</th>
      <td><input data-dojo-type="dijit/form/TextBox" id=exchangerate name=exchangerate size=11></td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>

<button data-dojo-type="dijit/form/Button" id="action-continue" name="__action" class="submit" type="submit" value="continue">|
      . $locale->text('Continue')
      . qq|</button>

</form>

</body>
</html>
|;

}


sub create_backorder {

    $form->{shipped} = 1;

    # figure out if we need to create a backorder
    # items aren't saved if qty != 0

    $dec1 = $dec2 = 0;
    foreach my $i ( 1 .. $form->{rowcount} ) {
        ($dec) = ( $form->{"qty_$i"} =~ /\.(\d+)/ );
        $dec = length $dec;
        $dec1 = ( $dec > $dec1 ) ? $dec : $dec1;

        ($dec) = ( $form->{"ship_$i"} =~ /\.(\d+)/ );
        $dec = length $dec;
        $dec2 = ( $dec > $dec2 ) ? $dec : $dec2;

        $totalqty  += $qty  = $form->{"qty_$i"};
        $totalship += $ship = $form->{"ship_$i"};

        $form->{"qty_$i"} = $qty - $ship;
    }

    $totalqty  = $form->round_amount( $totalqty,  $dec1 );
    $totalship = $form->round_amount( $totalship, $dec2 );

    if ( $totalship == 0 ) {
        for ( 1 .. $form->{rowcount} ) {
            $form->{"ship_$_"} = $form->{"qty_$_"};
        }
        $form->{ordtotal} = 0;
        $form->{shipped}  = 0;
        return;
    }

    if ( $totalqty == $totalship ) {
        for ( 1 .. $form->{rowcount} ) {
            $form->{"qty_$_"} = $form->{"ship_$_"};
        }
        $form->{ordtotal} = 0;
        return;
    }

    @flds =
      qw(partnumber description qty ship unit sellprice discount oldqty orderitems_id id bin weight listprice lastcost taxaccounts pricematrix sku onhand deliverydate reqdate projectnumber partsgroup assembly notes serialnumber);

    foreach my $i ( 1 .. $form->{rowcount} ) {
        for (qw(qty sellprice discount)) {
            $form->{"${_}_$i"} =
              $form->format_amount( \%myconfig, $form->{"${_}_$i"} );
        }

        $form->{"oldship_$i"} = $form->{"ship_$i"};
        $form->{"ship_$i"}    = 0;
    }

    # clear flags
    for (qw(id subject message cc bcc printed emailed audittrail)) {
        delete $form->{$_};
    }

    OE->save( \%myconfig, \%$form );

    # rebuild rows for invoice
    @a     = ();
    $count = 0;

    foreach my $i ( 1 .. $form->{rowcount} ) {
        $form->{"qty_$i"}    = $form->{"oldship_$i"};
        $form->{"oldqty_$i"} = $form->{"qty_$i"};

        $form->{"orderitems_id_$i"} = "";

        if ( $form->{"qty_$i"} ) {
            push @a, {};
            $j = $#a;
            for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
            $count++;
        }
    }

    $form->redo_rows( \@flds, \@a, $count, $form->{rowcount} );
    $form->{rowcount} = $count;

}

sub save_as_new {

    # orders don't have a quonumber
    # quotes don't have an ordnumber
    $form->{old_workflow_id} = $form->{workflow_id};
    for (qw(closed id printed emailed ordnumber quonumber workflow_id)) {
        delete $form->{$_}
    }
    &_save;
}

sub print_and_save_as_new {

    # orders don't have a quonumber
    # quotes don't have an ordnumber
    $form->{old_workflow_id} = $form->{workflow_id};
    for (qw(closed id printed emailed ordnumber quonumber workflow_id)) {
        delete $form->{$_}
    }
    &_print_and_save;

}

sub ship_receive {

    &order_links;

    &prepare_order;

    OE->get_warehouses( \%myconfig, \%$form );

    $form->{shippingdate} = $form->current_date( \%myconfig );
    $form->{"$form->{vc}"} =~ s/--.*//;
    $form->{"old$form->{vc}"} =
      qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;

    @flds  = ();
    @a     = ();
    $count = 0;
    foreach my $key ( keys %$form ) {
        if ( $key =~ /_1$/ ) {
            $key =~ s/_1//;
            push @flds, $key;
        }
    }

    foreach my $i ( 1 .. $form->{rowcount} ) {

        # undo formatting from prepare_order
        for (qw(qty ship)) {
            $form->{"${_}_$i"} =
              $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
        }
        $n = ( $form->{"qty_$i"} -= $form->{"ship_$i"} );
        if ( abs($n) > 0 ) {
            $form->{"ship_$i"}         = "";
            $form->{"serialnumber_$i"} = "";

            push @a, {};
            $j = $#a;

            for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
            $count++;
        }
    }

    $form->redo_rows( \@flds, \@a, $count, $form->{rowcount} );
    $form->{rowcount} = $count;

    &display_ship_receive;

}

sub display_ship_receive {
    &order_links;
     $form->generate_selects(\%myconfig);

    $vclabel = ucfirst $form->{vc};
    $vclabel = $locale->maketext($vclabel);

    $form->{rowcount}++;

    if ( $form->{vc} eq 'customer' ) {
        $form->{title} = $locale->text('Ship Merchandise');
        $form->{type} = "ship_order";
        $shipped = $locale->text('Shipping Date');
    }
    else {
        $form->{title} = $locale->text('Receive Merchandise');
        $form->{type} = "receive_order";
        $shipped = $locale->text('Date Received');
    }

    $warehouse = qq|
          <tr>
        <th align=right>| . $locale->text('Warehouse') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" name=warehouse id=warehouse>$form->{selectwarehouse}</select></td>
          </tr>
| if $form->{selectwarehouse};

    $employee = qq|
           <tr><td>&nbsp;</td>
          </tr>
|;

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

<input type=hidden name=display_form value=display_ship_receive>
|;

    $form->hide_form(qw(id type media format printed emailed vc));

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
        <td colspan=3>$form->{$form->{vc}}
        <input type=hidden name=$form->{vc} value="$form->{$form->{vc}}">
        <input type=hidden name="$form->{vc}_id" value=$form->{"$form->{vc}_id"}></td>
          </tr>
          $department
          <tr>
        <th align=right>| . $locale->text('Shipping Point') . qq|</th>
        <td colspan=3>
        <input data-dojo-type="dijit/form/TextBox" id=shippingpoint name=shippingpoint size=35 value="$form->{shippingpoint}">
          </tr>
          <tr>
        <th align=right>| . $locale->text('Ship via') . qq|</th>
        <td colspan=3>
        <input data-dojo-type="dijit/form/TextBox" id=shipvia name=shipvia size=35 value="$form->{shipvia}">
          </tr>
          $warehouse
        </table>
      </td>
      <td align=right>
        <table>
          $employee
          <tr>
        <th align=right nowrap>| . $locale->text('Order Number') . qq|</th>
        <td>$form->{ordnumber}
        <input type=hidden name=ordnumber value="$form->{ordnumber}"></td>
          </tr>
          <tr>
        <th align=right nowrap>| . $locale->text('Order Date') . qq|</th>
        <td>$form->{transdate}
        <input type=hidden name=transdate value=$form->{transdate}></td>
          </tr>
          <tr>
        <th align=right nowrap>| . ($form->{type} =~ /purchase_/ ?
            $locale->text('SO Number') : $locale->text('PO Number')) . qq|</th>
        <td>$form->{ponumber}
        <input type=hidden name=ponumber value="$form->{ponumber}"></td>
          </tr>
          <tr>
        <th align=right nowrap>$shipped</th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name=shippingdate id=shippingdate size=11 value=$form->{shippingdate}></td>
          </tr>
        </table>
      </td>
    </tr>
      </table>
    </td>
  </tr>

|;

    $form->hide_form(
        qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc)
    );

    @column_index = qw(partnumber);

    if ( $form->{type} eq "ship_order" ) {
        $column_data{ship} =
          qq|<th class=listheading>| . $locale->text('Ship') . qq|</th>|;
    }
    if ( $form->{type} eq "receive_order" ) {
        $column_data{ship} =
          qq|<th class=listheading>| . $locale->text('Recd') . qq|</th>|;
        $column_data{sku} =
          qq|<th class=listheading>| . $locale->text('SKU') . qq|</th>|;
        push @column_index, "sku";
    }
    push @column_index, qw(description qty ship unit bin serialnumber);

    my $colspan = $#column_index + 1;

    $column_data{partnumber} =
      qq|<th class=listheading nowrap>| . $locale->text('Number') . qq|</th>|;
    $column_data{description} =
        qq|<th class=listheading nowrap>|
      . $locale->text('Description')
      . qq|</th>|;
    $column_data{qty} =
      qq|<th class=listheading nowrap>| . $locale->text('Qty') . qq|</th>|;
    $column_data{unit} =
      qq|<th class=listheading nowrap>| . $locale->text('Unit') . qq|</th>|;
    $column_data{bin} =
      qq|<th class=listheading nowrap>| . $locale->text('Bin') . qq|</th>|;
    $column_data{serialnumber} =
        qq|<th class=listheading nowrap>|
      . $locale->text('Serial No.')
      . qq|</th>|;

    print qq|
  <tr>
    <td>
      <table width=100%>
    <tr class=listheading>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    foreach my $i ( 1 .. $form->{rowcount} - 1 ) {

        # undo formatting
        $form->{"ship_$i"} =
          $form->parse_amount( \%myconfig, $form->{"ship_$i"} );

        for (qw(partnumber sku description unit bin serialnumber)) {
            $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
        }

        $description = $form->{"description_$i"};
        $description =~ s/\r?\n/<br>/g;

        $column_data{partnumber} =
qq|<td>$form->{"partnumber_$i"}<input type=hidden name="partnumber_$i" value="$form->{"partnumber_$i"}"></td>|;
        $column_data{sku} =
qq|<td>$form->{"sku_$i"}<input type=hidden name="sku_$i" value="$form->{"sku_$i"}"></td>|;
        $column_data{description} =
qq|<td>$description<input type=hidden name="description_$i" value="$form->{"description_$i"}"></td>|;
        $column_data{qty} =
            qq|<td align=right>|
          . $form->format_amount( \%myconfig, $form->{"qty_$i"} )
          . qq|<input type=hidden name="qty_$i" value="$form->{"qty_$i"}"></td>|;
        $column_data{ship} =
            qq|<td align=right><input data-dojo-type="dijit/form/TextBox" id="ship_$i" name="ship_$i" size=5 value="|
          . $form->format_amount( \%myconfig, $form->{"ship_$i"} )
          . qq|"></td>|;
        $column_data{unit} =
qq|<td>$form->{"unit_$i"}<input type=hidden name="unit_$i" value="$form->{"unit_$i"}"></td>|;
        $column_data{bin} =
qq|<td>$form->{"bin_$i"}<input type=hidden name="bin_$i" value="$form->{"bin_$i"}"></td>|;

        $column_data{serialnumber} =
qq|<td><input data-dojo-type="dijit/form/TextBox" id="serialnumber_$i" name="serialnumber_$i" size=15 value="$form->{"serialnumber_$i"}"></td>|;

        print qq|
        <tr valign=top>|;

        for (@column_index) { print "\n$column_data{$_}" }

        print q|
        <td style="display:none">
|;
        $form->hide_form( "orderitems_id_$i", "id_$i", "partsgroup_$i" );
        print q|
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
  <tr>
    <td>
|;

    $form->{copies} = 1;

    $printops = &print_options;
    print_select($form, $printops->{formname});
    print_select($form, $printops->{format});
    print_select($form, $printops->{media});

    print qq|
    </td>
  </tr>
</table>
<br>
|;

    # type=submit $locale->text('Done')

    %button = (
        'update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
        'print'  => { ndx => 2, key => 'P', value => $locale->text('Print') },
        'ship_to' =>
          { ndx => 4, key => 'T', value => $locale->text('Ship to') },
        'e_mail' => { ndx => 5,  key => 'E', value => $locale->text('E-mail') },
        'done'   => { ndx => 11, key => 'D', value => $locale->text('Done') },
    );

    for ( "update", "print" ) { $form->print_button( \%button, $_ ) }

    if ( $form->{type} eq 'ship_order' ) {
        for ( 'ship_to', 'e_mail' ) { $form->print_button( \%button, $_ ) }
    }

    $form->print_button( \%button, 'done' );

    $form->hide_form(qw(rowcount callback path login sessionid));

    print qq|

</form>

</body>
</html>
|;

}

sub done {

    if ( $form->{type} eq 'ship_order' ) {
        $form->isblank( "shippingdate",
            $locale->text('Shipping Date missing!') );
    }
    else {
        $form->isblank( "shippingdate",
            $locale->text('Date received missing!') );
    }

    $total = 0;
    for ( 1 .. $form->{rowcount} - 1 ) {
        $total += $form->{"ship_$_"} =
          $form->parse_amount( \%myconfig, $form->{"ship_$_"} );
    }

    $form->error( $locale->text('Nothing entered!') ) unless $total;

    if ( OE->save_inventory( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Inventory saved!') );
    }
    else {
        $form->error( $locale->text('Could not save!') );
    }

}

sub search_transfer {

    OE->get_warehouses( \%myconfig, \%$form );

    # warehouse
    if ( ! @{ $form->{all_warehouse} } ) {
        $form->error( $locale->text('Nothing to transfer!') );
    }

    $form->get_partsgroup({ searchitems => 'part' });

     $form->generate_selects();

    $form->{title} = $locale->text('Transfer Inventory');

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
          <th align=right nowrap>| . $locale->text('Transfer from') . qq|</th>
          <td><select data-dojo-type="dijit/form/Select" name=fromwarehouse id=fromwarehouse>$form->{selectwarehouse}</select></td>
        </tr>
        <tr>
          <th align=right nowrap>| . $locale->text('Transfer to') . qq|</th>
          <td><select data-dojo-type="dijit/form/Select" name=towarehouse id=towarehouse>$form->{selectwarehouse}</select></td>
        </tr>
    <tr>
      <th align="right" nowrap="true">| . $locale->text('Part Number') . qq|</th>
      <td><input data-dojo-type="dijit/form/TextBox" id=partnumber name=partnumber size=20></td>
    </tr>
    <tr>
      <th align="right" nowrap="true">| . $locale->text('Description') . qq|</th>
      <td><input data-dojo-type="dijit/form/TextBox" id=description name=description size=40></td>
    </tr>
    <tr>
      <th align=right nowrap>| . $locale->text('Group') . qq|</th>
      <td><select data-dojo-type="dijit/form/Select" name=partsgroup id=partsgroup>$form->{selectpartsgroup}</select></td>
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

<button data-dojo-type="dijit/form/Button" class="submit" type="submit" id="action-continue" name="__action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>|;

    $form->hide_form(qw(path login sessionid));

    print qq|
</form>
|;

    print qq|

</body>
</html>
|;

}

sub list_transfer {

    $form->{sort} = "partnumber" unless $form->{sort};

    OE->get_inventory( \%myconfig, \%$form );

    # construct href
    $href = "$form->{script}?__action=list_transfer";
    for (qw(direction oldsort path login sessionid)) {
        $href .= "&$_=$form->{$_}";
    }
    for (qw(partnumber fromwarehouse towarehouse description partsgroup)) {
        $href .= "&$_=" . $form->escape( $form->{$_} );
    }

    $form->sort_order();

    # construct callback
    $callback = "$form->{script}?__action=list_transfer";
    for (qw(direction oldsort path login sessionid)) {
        $callback .= "&$_=$form->{$_}";
    }
    for (qw(partnumber fromwarehouse towarehouse description partsgroup)) {
        $callback .= "&$_=" . $form->escape( $form->{$_}, 1 );
    }

    @column_index =
      $form->sort_columns(
        qw(partnumber description partsgroup make model fromwarehouse qty towarehouse transfer)
      );

    $column_header{partnumber} =
        qq|<th><a class=listheading href=$href&sort=partnumber>|
      . $locale->text('Part Number')
      . qq|</a></th>|;
    $column_header{description} =
        qq|<th><a class=listheading href=$href&sort=description>|
      . $locale->text('Description')
      . qq|</a></th>|;
    $column_header{partsgroup} =
        qq|<th><a class=listheading href=$href&sort=partsgroup>|
      . $locale->text('Group')
      . qq|</a></th>|;
    $column_header{fromwarehouse} =
        qq|<th><a class=listheading href=$href&sort=warehouse>|
      . $locale->text('From')
      . qq|</a></th>|;
    $column_header{towarehouse} =
      qq|<th class=listheading>| . $locale->text('To') . qq|</th>|;
    $column_header{qty} =
      qq|<th class=listheading>| . $locale->text('Qty') . qq|</a></th>|;
    $column_header{transfer} =
      qq|<th class=listheading>| . $locale->text('Transfer') . qq|</a></th>|;

    ( $warehouse, $warehouse_id ) = split /--/, $form->{fromwarehouse};

    if ( $form->{fromwarehouse} ) {
        $option .= "\n<br>";
        $option .= $locale->text('From Warehouse') . " : $warehouse";
    }
    ( $warehouse, $warehouse_id ) = split /--/, $form->{towarehouse};
    if ( $form->{towarehouse} ) {
        $option .= "\n<br>";
        $option .= $locale->text('To Warehouse') . " : $warehouse";
    }
    if ( $form->{partnumber} ) {
        $option .= "\n<br>" if ($option);
        $option .= $locale->text('Part Number') . " : $form->{partnumber}";
    }
    if ( $form->{description} ) {
        $option .= "\n<br>" if ($option);
        $option .= $locale->text('Description') . " : $form->{description}";
    }
    if ( $form->{partsgroup} ) {
        ($partsgroup) = split /--/, $form->{partsgroup};
        $option .= "\n<br>" if ($option);
        $option .= $locale->text('Group') . " : $partsgroup";
    }

    $form->{title} = $locale->text('Transfer Inventory');

    $callback .= "&sort=$form->{sort}";

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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

    if ( @{ $form->{all_inventory} } ) {
        $sameitem = $form->{all_inventory}->[0]->{ $form->{sort} };
    }

    $i = 0;
    foreach my $ref ( @{ $form->{all_inventory} } ) {

        $i++;

        $column_data{partnumber} =
qq|<td><input type=hidden name="id_$i" value=$ref->{id}>$ref->{partnumber}</td>|;
        $column_data{description} = "<td>$ref->{description}&nbsp;</td>";
        $column_data{partsgroup}  = "<td>$ref->{partsgroup}&nbsp;</td>";
        $column_data{fromwarehouse} =
qq|<td><input type=hidden name="warehouse_id_$i" value="$ref->{warehouse_id}">$ref->{warehouse}&nbsp;</td>|;
        $column_data{towarehouse} = qq|<td>$warehouse&nbsp;</td>|;
        $column_data{qty} =
            qq|<td><input type=hidden name="qty_$i" value="$ref->{qty}">|
          . $form->format_amount( \%myconfig, $ref->{qty} )
          . qq|</td>|;
        $column_data{transfer} = qq|<td><input data-dojo-type="dijit/form/TextBox" id="transfer_$i" name="transfer_$i" size=4></td>|;

        $j++;
        $j %= 2;
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

    $form->{__action} = "transfer";
    $form->hide_form(qw(path login sessionid));

    print qq|
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" id="action-transfer" name="__action" value="transfer">|
      . $locale->text('Transfer')
      . qq|</button>|;

    print qq|
</form>

</body>
</html>
|;

}

sub transfer {

    if ( OE->transfer( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Inventory transferred!') );
    }
    else {
        $form->error( $locale->text('Could not transfer Inventory!') );
    }

}

sub generate_purchase_orders {
    ($form, $locale) = @_;

    for ( 1 .. $form->{rowcount_} ) {
        if ( $form->{"select_$_"} ) {
            $ok = 1;
            last;
        }
    }

    $form->error( $locale->text('Nothing selected!') ) unless $ok;

    ( $null, $argv ) = split /\?/, $form->{callback};

    for ( split /\&/, $argv ) {
        ( $key, $value ) = split /=/, $_;
        $form->{$key} = $value;
    }

    $form->{vc} = "vendor";

    OE->get_soparts( \%myconfig, \%$form );

    # flatten array
    $i = 0;
    $form->{_setting_decimal_places} = $form->setting->get('decimal_places');
    foreach my $parts_id (
        sort {
            $form->{orderitems}{$a}{partnumber}
              cmp $form->{orderitems}{$b}{partnumber}
        } keys %{ $form->{orderitems} }
      )
    {

        $required = $form->{orderitems}{$parts_id}{required};
        next if $required <= 0;

        $i++;

        $form->{"required_$i"} = $form->format_amount( \%myconfig, $required );
        $form->{"id_$i"}       = $parts_id;
        $form->{"sku_$i"}      = $form->{orderitems}{$parts_id}{partnumber};

        $form->{"curr_$i"}        = $form->{defaultcurrency};
        $form->{"description_$i"} = $form->{orderitems}{$parts_id}{description};

        $form->{"lastcost_$i"} =
          $form->format_amount( \%myconfig,
            $form->{orderitems}{$parts_id}{lastcost}, $form->{_setting_decimal_places} );

        $form->{"qty_$i"} = $required;

        if ( exists $form->{orderitems}{$parts_id}{"parts$form->{vc}"} ) {
            $form->{"qty_$i"} = "";

            foreach my $id (
                sort {
                    $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$a}
                      {lastcost} * $form->{ $form->{orderitems}{$parts_id}
                          {"parts$form->{vc}"}{$a}{curr} } <=>
                      $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$b}
                      {lastcost} * $form->{ $form->{orderitems}{$parts_id}
                          {"parts$form->{vc}"}{$b}{curr} }
                } keys %{ $form->{orderitems}{$parts_id}{"parts$form->{vc}"} }
              )
            {
                $i++;

                $form->{"qty_$i"} =
                  $form->format_amount( \%myconfig, $required );

                $form->{"description_$i"} = "";
                for (qw(partnumber curr)) {
                    $form->{"${_}_$i"} =
                      $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}
                      {$_};
                }

                $form->{"lastcost_$i"} = $form->format_amount(
                    \%myconfig,
                    $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}
                      {lastcost}, $form->{_setting_decimal_places}

                );
                $form->{"leadtime_$i"} = $form->format_amount( \%myconfig,
                    $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}
                      {leadtime} );
                $form->{"fx_$i"} = $form->format_amount(
                    \%myconfig,
                    $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}
                      {lastcost} * $form->{
                        $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}
                          {curr}
                    },
                    $form->{_setting_decimal_places}
                );

                $form->{"id_$i"} = $parts_id;

                $form->{"$form->{vc}_$i"} =
qq|$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{name}--$id|;
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

    @column_index =
      qw(sku description partnumber leadtime fx lastcost curr required qty name);

    $column_header{sku} =
      qq|<th class=listheading>| . $locale->text('SKU') . qq|</th>|;
    $column_header{partnumber} =
      qq|<th class=listheading>| . $locale->text('Part Number') . qq|</th>|;
    $column_header{description} =
      qq|<th class=listheading>| . $locale->text('Description') . qq|</th>|;
    $column_header{name} =
      qq|<th class=listheading>| . $locale->text('Vendor') . qq|</th>|;
    $column_header{qty} =
      qq|<th class=listheading>| . $locale->text('Order') . qq|</th>|;
    $column_header{required} =
      qq|<th class=listheading>| . $locale->text('Req') . qq|</th>|;
    $column_header{lastcost} =
      qq|<th class=listheading>| . $locale->text('Cost') . qq|</th>|;
    $column_header{fx} = qq|<th class=listheading>&nbsp;</th>|;
    $column_header{leadtime} =
      qq|<th class=listheading>| . $locale->text('Lead') . qq|</th>|;
    $column_header{curr} =
      qq|<th class=listheading>| . $locale->text('Curr') . qq|</th>|;

    $form->{title} = $locale->text('Generate Purchase Orders');

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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

    foreach my $i ( 1 .. $form->{rowcount} ) {

        for (qw(sku partnumber description curr)) {
            $column_data{$_} = qq|<td>$form->{"${_}_$i"}&nbsp;</td>|;
        }

        for (qw(required leadtime lastcost fx)) {
            $column_data{$_} = qq|<td align=right>$form->{"${_}_$i"}</td>|;
        }

        $column_data{qty} =
qq|<td align=right><input data-dojo-type="dijit/form/TextBox" id="qty_$i" name="qty_$i" size="6" value="$form->{"qty_$i"}"></td>|;

        if ( $form->{"$form->{vc}_id_$i"} ) {
            $name = $form->{"$form->{vc}_$i"};
            $name =~ s/--.*//;
            $column_data{name} = qq|<td>$name</td>|;
            $form->hide_form( "$form->{vc}_id_$i", "$form->{vc}_$i" );
        }
        else {
            $column_data{name} =
qq|<td><input name="ndx_$i" id="ndx_$i" class=checkbox type=checkbox data-dojo-type="dijit/form/CheckBox" value="1"></td>|;
        }

        $form->hide_form( map { "${_}_$i" }
              qw(id sku partnumber description curr required leadtime lastcost fx name blankrow)
        );

        $blankrow = $form->{"blankrow_$i"};

      BLANKROW:
        $j++;
        $j %= 2;
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

    $form->hide_form(
        qw(callback department ponumber path login sessionid employee_id vc nextsub rowcount type)
    );

    print qq|
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" id="action-generate-orders" name="__action" value="generate_orders">|
      . $locale->text('Generate Orders')
      . qq|</button>|;

    print qq|
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" id="action-select-vendor" name="__action" value="select_vendor">|
      . $locale->text('Select Vendor')
      . qq|</button>|;

    print qq|
</form>

</body>
</html>
|;

}

sub generate_orders {

    if ( OE->generate_orders( \%myconfig, \%$form ) ) {
        $form->redirect;
    }
    else {
        $form->error( $locale->text('Order generation failed!') );
    }

}

sub select_vendor {

    for ( 1 .. $form->{rowcount} ) {
        last if ( $ok = $form->{"ndx_$_"} );
    }

    $form->error( $locale->text('Nothing selected!') ) unless $ok;

    $form->header;

    print qq|
<body class="lsmb $form->{dojo_theme}" onload="document.forms[0].vendor.focus()" />

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

<b>| . $locale->text('Vendor') . qq|</b> <input data-dojo-type="dijit/form/TextBox" id=vendor name=vendor size=40>

|;

    $form->{nextsub} = "vendor_selected";
    $form->{__action}  = "vendor_selected";

    $form->hide_form;

    print qq|
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" id="action-continue" name="__action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>

</form>
|;

    print qq|

</body>
</html>
|;

}

sub vendor_selected {

    if (
        (
            $rv = $form->get_name( \%myconfig, $form->{vc}, $form->{transdate} )
        ) > 1
      )
    {
        &select_name( $form->{vc} );
        $form->finalize_request();
    }

    if ( $rv == 1 ) {
        for ( 1 .. $form->{rowcount} ) {
            if ( $form->{"ndx_$_"} ) {
                $form->{"$form->{vc}_id_$_"} = $form->{name_list}[0]->{id};
                $form->{"$form->{vc}_$_"} =
                  "$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}";
            }
        }
    }
    else {
        $msg = ucfirst $form->{vc} . " not on file!" unless $msg;
        $form->error( $locale->maketext($msg) );
    }

    &po_orderitems;

}

1;
