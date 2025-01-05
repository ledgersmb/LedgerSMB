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
# Contributors:
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
# Inventory Control module
#
#======================================================================

package lsmb_legacy;
use LedgerSMB::IC;
use LedgerSMB::Tax;

require "old/bin/io.pl";

# end of main

sub add {

    %label = (
        part     => $locale->text( 'Add Part' ),
        service  => $locale->text( 'Add Service' ),
        assembly => $locale->text( 'Add Assembly' ),
        labor    => $locale->text( 'Add Labor/Overhead' ),
    );
    $form->{title} = $label{$form->{item}};

    $form->{callback} = "$form->{script}?__action=add&item=$form->{item}"
      unless $form->{callback};

    $form->{orphaned} = 1;

    if ( $form->{previousform} ) {
        $form->{callback} = "";
    }

    &link_part;
    $form->generate_selects(\%myconfig);


    &display_form;

}

sub edit {

    %label = (
        part     => $locale->text( 'Edit Part' ),
        service  => $locale->text( 'Edit Service' ),
        assembly => $locale->text( 'Edit Assembly' ),
        labor    => $locale->text( 'Edit Labor/Overhead' ),
    );
    $form->{title} = $label{$form->{item}};

    IC->get_part( \%myconfig, \%$form );

    $form->{previousform} = $form->escape( $form->{previousform}, 1 )
      if $form->{previousform};

    &link_part;

    &display_form;

}

sub link_part {

    IC->create_links( "IC", \%myconfig, \%$form );

    # readonly
    if ( $form->{item} eq 'part' or $form->{item} eq 'assembly') {
        $form->error(
            $locale->text(
                'Cannot create Part; Inventory account does not exist!')
        ) if !@{ $form->{IC_links}{IC} };
        $form->error(
            $locale->text('Cannot create Part; Income account does not exist!')
        ) if !@{ $form->{IC_links}{IC_sale} };
        $form->error(
            $locale->text('Cannot create Part; COGS account does not exist!') )
          if !@{ $form->{IC_links}{IC_cogs} };
    }

    if ( $form->{item} eq 'service' ) {
        $form->error(
            $locale->text(
                'Cannot create Service; Income account does not exist!')
        ) if !@{ $form->{IC_links}{IC_income} };
        $form->error(
            $locale->text(
                'Cannot create Service; Expense account does not exist!')
        ) if !@{ $form->{IC_links}{IC_expense} };
    }

    if ( $form->{item} eq 'labor' ) {
        $form->error(
            $locale->text(
                'Cannot create Labor; Inventory account does not exist!')
        ) if !@{ $form->{IC_links}{IC} };
        $form->error(
            $locale->text('Cannot create Labor; COGS account does not exist!') )
          if !@{ $form->{IC_links}{IC_cogs} };
    }

    # parts, assemblies , labor and overhead have the same links
    $taxpart = ( $form->{item} eq 'service' ) ? "service" : "part";

    # build the popup menus
    $form->{taxaccounts} = "";
    foreach my $key ( keys %{ $form->{IC_links} } ) {

        $form->{"select$key"} = "";
        foreach my $ref ( @{ $form->{IC_links}{$key} } ) {

            # if this is a tax field
            if ( $key =~ /IC_tax/ ) {
                if ( $key =~ /$taxpart/ ) {

                    $form->{taxaccounts} .= "$ref->{accno} ";
                    $form->{"IC_tax_$ref->{accno}_description"} =
                      "$ref->{accno}--$ref->{description}";

                    if ( $form->{id} ) {
                        if ( $form->{amount}{ $ref->{accno} } ) {
                            $form->{"IC_tax_$ref->{accno}"} = "checked";
                        }
                    }
                    else {
                        $form->{"IC_tax_$ref->{accno}"} = "checked";
                    }

                }
            }
            else {

                $form->{"select$key"} .=
                  qq|<option id="$key-$ref->{accno}" value="$ref->{accno}--$ref->{description}">$ref->{accno}--$ref->{description}</option>\n|;

            }
        }
    }
    chop $form->{taxaccounts};

    if ( $form->{item} !~ /service/ ) {
        $form->{selectIC_inventory} = $form->{selectIC};
        $form->{selectIC_income}    = $form->{selectIC_sale};
        $form->{selectIC_expense}   = $form->{selectIC_cogs};
        $form->{selectIC_returns}   = $form->{selectIC_returns};
    }

    # set option
    for (qw(IC_inventory IC_income IC_expense IC_returns)) {
        $form->{$_} =
          "$form->{amount}{$_}{accno}--$form->{amount}{$_}{description}"
          if (! $form->{$_}) && $form->{amount}{$_}{accno};
    }

    delete $form->{IC_links};
    delete $form->{amount};

    $form->get_partsgroup({ all => 1 });
    if ( $form->{all_partsgroups} and @{ $form->{all_partsgroup} } ) {
        $form->{selectpartsgroup} = qq|<option></option>\n|;

        for ( @{ $form->{all_partsgroup} } ) {
            $form->{selectpartsgroup} .=
                qq|<option value="|
              . $form->quote( $_->{partsgroup} )
              . qq|--$_->{id}">$_->{partsgroup}</option>\n|;
        }
        delete $form->{all_partsgroup};
    }

    if ( $form->{item} eq 'assembly' ) {

        for ( 1 .. $form->{assembly_rows} ) {
            if ( $form->{"partsgroup_id_$_"} ) {
                $form->{"partsgroup_$_"} =
                  qq|$form->{"partsgroup_$_"}--$form->{"partsgroup_id_$_"}|;
            }
        }

        $form->get_partsgroup();

        if ( @{ $form->{all_partsgroup} } ) {
            $form->{selectassemblypartsgroup} = qq|<option></option>\n|;

            for ( @{ $form->{all_partsgroup} } ) {
                $form->{selectassemblypartsgroup} .=
qq|<option value="$_->{partsgroup}--$_->{id}">$_->{partsgroup}</option>\n|;
            }
            delete $form->{all_partsgroup};
        }
    }

    # setup make and models
    if ($form->{makemodels}) {
        $i = 1;
        foreach my $ref ( @{ $form->{makemodels} } ) {
            for (qw(make model barcode)) { $form->{"${_}_$i"} = $ref->{$_} }
            $i++;
        }
        $form->{makemodel_rows} = $i - 1;
        delete $form->{makemodels};
    }

    # setup vendors
    if ( $form->{all_vendor} and @{ $form->{all_vendor} } ) {
        $form->{selectvendor} = "<option></option>\n";
        for ( @{ $form->{all_vendor} } ) {
            $form->{selectvendor} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}</option>\n|;
        }
        delete $form->{all_vendor};
    }

    # vendor matrix (on update, we don't have a price matrix)
    $i = 1;
    foreach my $ref ( @{ $form->{vendormatrix} } ) {
        $form->{"vendor_$i"} = qq|$ref->{name}--$ref->{id}|;
        $form->{"vendor_mn_$i"} = $ref->{meta_number};


        for (qw(partnumber lastcost leadtime vendorcurr)) {
            $form->{"${_}_$i"} = $ref->{$_};
        }
        $i++;
    }
    $form->{vendor_rows} //= $i - 1;
    delete $form->{vendormatrix};

    # setup customers and groups
    if ( $form->{all_customer} and @{ $form->{all_customer} } ) {
        $form->{selectcustomer} = "<option></option>\n";
        for ( @{ $form->{all_customer} } ) {
            $form->{selectcustomer} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}</option>\n|;
        }
        delete $form->{all_customer};
    }

    if ( $form->{all_pricegroup} and @{ $form->{all_pricegroup} } ) {
        $form->{selectpricegroup} = "<option>\n";
        for ( @{ $form->{all_pricegroup} } ) {
            $form->{selectpricegroup} .=
              qq|<option value="$_->{pricegroup}--$_->{id}">$_->{pricegroup}</option>\n|;
        }
        delete $form->{all_pricegroup};
    }


    # customer matrix (on update, we don't have a price matrix)
    $i = 1;
    foreach my $ref ( @{ $form->{customermatrix} } ) {

        $form->{"customer_$i"} = "$ref->{name}--$ref->{cid}" if $ref->{cid};
        $form->{"customer_mn_$i"} = $ref->{meta_number};
        $form->{"pricegroup_$i"} = "$ref->{pricegroup}--$ref->{gid}"
          if $ref->{gid};
        $form->{"customerqty_$i"} = $ref->{qty};

        for (qw(validfrom validto pricebreak customerprice customercurr)) {
            $form->{"${_}_$i"} = $ref->{$_};
        }

        $i++;

    }
    $form->{customer_rows} //= $i - 1;
    delete $form->{customermatrix};

}

sub form_header {
    link_part();


    $status_div_id = $form->{item};
    $markup = '';
    if ( $form->{lastcost} > 0 ) {
        $markup =
          $form->round_amount(
            ( ( $form->{sellprice} / $form->{lastcost} - 1 ) * 100 ), 1 );
        $form->{markup} = $form->format_amount( \%myconfig, $markup, 1 );
    }

    ($dec) = ( $form->{sellprice} =~ /\.(\d+)/ );
    $dec = length $dec;
    $decimalplaces = ( $dec > 2 ) ? $dec : 2;

    for (qw(listprice sellprice)) {
        $form->{$_} =
          $form->format_amount( \%myconfig, $form->{$_}, $decimalplaces );
    }

    ($dec) = ( $form->{lastcost} =~ /\.(\d+)/ );
    $dec = length $dec;
    $decimalplaces = ( $dec > 2 ) ? $dec : 2;

    for (qw(lastcost avgcost)) {
        $form->{$_} =
          $form->format_amount( \%myconfig, $form->{$_}, $decimalplaces );
    }

    for (qw(weight rop stock)) {
        $form->{$_} = $form->format_amount( \%myconfig, $form->{$_} );
    }

    for (qw(partnumber description unit notes)) {
        $form->{$_} = $form->quote( $form->{$_} );
    }

    if ( ( $rows = $form->numtextrows( $form->{notes}, 40 ) ) < 2 ) {
        $rows = 2;
    }

    $notes =
qq|<textarea data-dojo-type="dijit/form/Textarea" name="notes" rows="$rows" cols="40" wrap="soft">$form->{notes}</textarea>|;

    if ( ( $rows = $form->numtextrows( $form->{description}, 40 ) ) > 1 ) {
        $description =
qq|<textarea data-dojo-type="dijit/form/Textarea" name="description" rows="$rows" cols="40" wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input data-dojo-type="dijit/form/TextBox" name="description" size="40" value="$form->{description}" />|;
    }

    for ( split / /, $form->{taxaccounts} ) {
        $form->{"IC_tax_$_"} = ( $form->{"IC_tax_$_"} ) ? "checked" : "";
    }

    $form->{selectIC_inventory} = $form->{selectIC};

    # set option
    for (qw(IC_inventory IC_income IC_expense IC_returns)) {
        if ( $form->{$_} ) {
            if ( $form->{orphaned} ) {
                $form->{"select$_"} =~ s/ selected="selected"//;
                $form->{"select$_"} =~
                  s/option([^>]*)>\Q$form->{$_}\E/option $1 selected="selected">$form->{$_}/;
            }
            else {
                $form->{"select$_"} = qq|<option value="$form->{$_}" selected="selected">$form->{$_}</option>|;
            }
        }
    }

    if ( $form->{selectpartsgroup} ) {
        $form->{selectpartsgroup} =
          $form->unescape( $form->{selectpartsgroup} );

        $partsgroup =
          qq|<input type="hidden" name="selectpartsgroup" value="|
          . $form->escape( $form->{selectpartsgroup}, 1 ) . qq|">|;

        $form->{partsgroup} = $form->quote( $form->{partsgroup} );
        $form->{selectpartsgroup} =~
          s/(<option value="\Q$form->{partsgroup}\E")/$1 selected="SELECTED"/;

        $partsgroup .=
          qq|\n<select data-dojo-type="dijit/form/Select" id="partsgroup" name="partsgroup">$form->{selectpartsgroup}</select>|;
        $group = $locale->text('Group');
    }

    # tax fields
    foreach my $item ( split / /, $form->{taxaccounts} ) {
        $tax .= qq|
      <input class="checkbox" type="checkbox" data-dojo-type="dijit/form/CheckBox" name="IC_tax_$item" value=1 $form->{"IC_tax_$item"}>&nbsp;<b>$form->{"IC_tax_${item}_description"}</b>
      <br><input type="hidden" name="IC_tax_${item}_description" value="$form->{"IC_tax_${item}_description"}">
|;
    }

    $sellprice = qq|
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Sell Price') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=sellprice size=11 value=$form->{sellprice}></td>
          </tr>
          <tr>
        <th align="right" nowrap="true">| . $locale->text('List Price') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=listprice size=11 value=$form->{listprice}></td>
          </tr>
|;

    $avgcost = qq|
           <tr>
                <th align="right" nowrap="true">|
      . $locale->text('Average Cost')
      . qq|</th>
                <td><input type=hidden name=avgcost value=$form->{avgcost}>$form->{avgcost}</td>
              </tr>
|;

    $lastcost = qq|
           <tr>
                <th align="right" nowrap="true">|
      . $locale->text('Last Cost')
      . qq|</th>
                <td><input data-dojo-type="dijit/form/TextBox" name=lastcost size=11 value=$form->{lastcost}></td>
              </tr>
          <tr>
            <th align="right" nowrap="true">|
      . $locale->text('Markup')
      . qq| %</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=markup size=5 value=$form->{markup}></td>
        <input type=hidden name=oldmarkup value=$markup>
          </tr>
|;

    if ( $form->{item} =~ /(part|assembly)/ ) {
        $n = ( $form->{onhand} > 0 ) ? "1" : "0";
        $onhand = qq|
          <tr>
        <th align="right" nowrap>| . $locale->text('On Hand') . qq|</th>
        <th align=left nowrap class="plus$n">&nbsp;| # onhand exists as hidden INPUT
          . $form->format_amount( \%myconfig, $form->{onhand} )
          . qq|</th>
          </tr>
|;

        $rop = qq|
          <tr>
        <th align="right" nowrap="true">| . $locale->text('ROP') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=rop size=10 value=$form->{rop}></td>
          </tr>
|;

        $bin = qq|
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Bin') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=bin size=10 value="$form->{bin}"></td>
          </tr>
|;

        $form->{$_} //= '' for (qw(image microfiche drawing));
        $imagelinks = qq|
  <tr>
    <td>
      <table width=100%>
        <tr>
      <th align=right nowrap>| . $locale->text('Image') . qq|</th>
      <td><input data-dojo-type="dijit/form/TextBox" name=image size=40 value="$form->{image}"></td>
      <th align=right nowrap>| . $locale->text('Microfiche') . qq|</th>
      <td><input data-dojo-type="dijit/form/TextBox" name=microfiche size=20 value="$form->{microfiche}"></td>
    </tr>
    <tr>
      <th align=right nowrap>| . $locale->text('Drawing') . qq|</th>
      <td><input data-dojo-type="dijit/form/TextBox" name=drawing size=40 value="$form->{drawing}"></td>
    </tr>
      </table>
    </td>
  </tr>
|;
    }

    if ( $form->{item} eq "part" or $form->{item} eq "assembly") {

        $linkaccounts = qq|
          <tr>
        <th align=right>| . $locale->text('Inventory') . qq|</th>
        <td><select id="IC-inventory" data-dojo-type="dijit/form/Select" name="IC_inventory">$form->{selectIC_inventory}</select></td>
          </tr>
          <tr>
        <th align=right>| . $locale->text('Income') . qq|</th>
        <td><select id="IC-income" data-dojo-type="dijit/form/Select" name="IC_income">$form->{selectIC_income}</select></td>
          </tr>
          <tr>
        <th align=right>| . $locale->text('COGS') . qq|</th>
        <td><select id="IC-expense" data-dojo-type="dijit/form/Select" name="IC_expense">$form->{selectIC_expense}</select></td>
          </tr>
          <tr>
        <th align=right>| . $locale->text('Returns') . qq|</th>
        <td><select id="IC-returns" data-dojo-type="dijit/form/Select" name=IC_returns>$form->{selectIC_returns}</select></td>
          </tr>
|;

        if ($tax) {
            $linkaccounts .= qq|
          <tr>
        <th align=right>| . $locale->text('Tax') . qq|</th>
        <td>$tax</td>
          </tr>
|;
        }

        $weight = qq|
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Weight') . qq|</th>
        <td>
          <table>
            <tr>
              <td>
            <input data-dojo-type="dijit/form/TextBox" name=weight size=10 value=$form->{weight}>
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

    if ( $form->{item} eq "assembly" ) {

        $avgcost = "";

        if ( $form->{project_id} ) {
            $weight = qq|
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Weight') . qq|</th>
        <td>
          <table>
            <tr>
              <td>
            <input data-dojo-type="dijit/form/TextBox" name=weight size=10 value=$form->{weight}>
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
        else {

            $weight = qq|
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Weight') . qq|</th>
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

        if ( $form->{project_id} ) {
            $lastcost               = "";
            $avgcost                = "";
            $onhand                 = "";
            $rop                    = "";
            $form->{isassemblyitem} = 1;

        }
        else {
            $stock = qq|
              <tr>
            <th align="right" nowrap>| . $locale->text('Stock') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=stock size=10 value=$form->{stock}></td>
          </tr>
|;

            $lastcost = qq|
              <tr>
            <th align="right" nowrap="true">|
              . $locale->text('Last Cost')
              . qq|</th>
        <td><input type=hidden name=lastcost value=$form->{lastcost}>$form->{lastcost}</td>
          </tr>
          <tr>
            <th align="right" nowrap="true">|
              . $locale->text('Markup')
              . qq| %</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=markup size=5 value=$form->{markup}></td>
        <input type=hidden name=oldmarkup value=$markup>
          </tr>
|;

        }

    }

    if ( $form->{item} eq "service" ) {
        $avgcost      = "";
        $linkaccounts = qq|
          <tr>
        <th align=right>| . $locale->text('Income') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" id="IC-income" name=IC_income>$form->{selectIC_income}</select></td>
          </tr>
          <tr>
        <th align=right>| . $locale->text('Expense') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" id="IC-expense" name=IC_expense>$form->{selectIC_expense}</select></td>
          </tr>
|;

        if ($tax) {
            $linkaccounts .= qq|
          <tr>
        <th align=right>| . $locale->text('Tax') . qq|</th>
        <td>$tax</td>
          </tr>
|;
        }

    }

    if ( $form->{item} eq 'labor' ) {
        $avgcost = "";

        $n = ( $form->{onhand} > 0 ) ? "1" : "0";
        $onhand = qq|
              <tr>
            <th align="right" nowrap>| . $locale->text('On Hand') . qq|</th>
        <th align=left nowrap class="plus$n">&nbsp;|
          . $form->format_amount( \%myconfig, $form->{onhand} )
          . qq|</th>
              </tr>
|;

        $linkaccounts = qq|
          <tr>
        <th align=right>| . $locale->text('Labor/Overhead') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" id="IC-inventory" name="IC_inventory">$form->{selectIC_inventory}</select></td>
          </tr>

          <tr>
        <th align=right>| . $locale->text('COGS') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" id="IC-expense" name="IC_expense">$form->{selectIC_expense}</select></td>
          </tr>
|;

    }

    if ( $form->{id} ) {
        $checked = ( $form->{obsolete} ) ? "checked='CHECKED'" : "";
        $obsolete = qq|
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Obsolete') . qq|</th>
        <td><input name="obsolete" type="checkbox" data-dojo-type="dijit/form/CheckBox" class="checkbox" value="1" $checked /></td>
          </tr>
|;
        $obsolete = "<input type=hidden name=='obsolete' value='$form->{obsolete}' />"
          if $form->{project_id};
    }

    # type=submit $locale->text('Edit Part')
    # type=submit $locale->text('Edit Service')
    # type=submit $locale->text('Edit Assembly')

    $form->header;

    print qq|
<body class="lsmb">
| . $form->open_status_div($status_div_id) . qq|

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">
|;

    $form->hide_form(
        qw(id item title makemodel alternate onhand orphaned taxaccounts rowcount baseassembly project_id)
    );

    $weight //= '';
    $onhand //= '';
    $stock //= '';
    $rop //= '';
    $bin //= '';
    $obsolete //= '';
    $imagelinks //= '';
    print qq|
<table style="width: 100%">
  <tr>
    <th class="listtop">$form->{title}</th>
  </tr>
  <tr><th>&nbsp;</th></tr>
  <tr>
    <td>
      <table style="width: 100%">
        <tr valign="top">
          <th align="left">| . $locale->text('Number') . qq|</th>
          <th align="left">| . $locale->text('Description') . qq|</th>
      <th align="left">$group</th>
    </tr>
    <tr valign="top">
          <td><input data-dojo-type="dijit/form/TextBox" name="partnumber" value="$form->{partnumber}" size="20"/>
              | . $form->sequence_dropdown('partnumber') . qq| </td>
          <td>$description</td>
      <td>$partsgroup</td>
    </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign="top">
          <td width="70%">
            <table width="100%">
              <tr class="listheading">
                <th class="listheading" align="center" colspan="2">|
      . $locale->text('Link Accounts')
      . qq|</th>
              </tr>
              $linkaccounts
              <tr>
                <th align="left">| . $locale->text('Notes') . qq|</th>
              </tr>
              <tr>
                <td colspan="2">
                  $notes
                </td>
              </tr>
            </table>
          </td>
      <td width="30%">
        <table width="100%">
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Updated') . qq|</th>
        <td><input name="priceupdate" size="11" title="$myconfig{dateformat}" class="date" data-dojo-type="lsmb/DateTextBox" id="priceupdate" value="$form->{priceupdate}"></td>
          </tr>
          $sellprice
          $lastcost
          $avgcost
          <tr>
        <th align="right" nowrap="true">| . $locale->text('Unit') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=unit size=5 value="$form->{unit}"></td>
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
    if ($form->{id}){
        IC->get_files($form, $locale);
    }


    print qq|
  <tr>
    <td><hr size="3" noshade></td>
  </tr>
</table>
|;

    $form->hide_form(qw(customer_rows));

    if ( $form->{item} =~ /(part|assembly)/ ) {
        $form->hide_form(qw(makemodel_rows));
    }

    if ( $form->{item} =~ /(part|service)/ ) {
        $form->hide_form(qw(vendor_rows));
    }

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Save')
    # type=submit $locale->text('Save as new')
    # type=submit $locale->text('Delete')

    if ( !$form->{readonly} ) {

        %button = (
            'update' =>
              { ndx => 1, key => 'U', value => $locale->text('Update') },
            'save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
        );

        if ( $form->{id} ) {

            if ( !$form->{isassemblyitem} ) {
                $button{'save_as_new'} = {
                    ndx   => 7,
                    key   => 'N',
                    value => $locale->text('Save as new')
                };
            }

            if ( $form->{orphaned} ) {
                $button{'delete'} =
                  { ndx => 16, key => 'D', value => $locale->text('Delete') };
            }
        }
        %button = () if $form->{isassemblyitem} && $form->{item} eq 'assembly';

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            $form->print_button( \%button, $_ );
        }

    }
    if ($form->{callback} and $form->{id}){
        print qq|<div class='returnlink'><a href='$form->{callback}'>|
              . $locale->text('Continue Previous Workflow')
                . qq|</a></div>|;
    }
    if ($form->{id}){
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
<td><a href="file.pl?__action=get&file_class=3&ref_key=$form->{id}&id=$file->{id}"
       target="_download">$file->{file_name}</a></td>
<td>$file->{mime_type}</td>
<td>|.$file->{uploaded_at} . qq|</td>
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
       $callback = $form->escape(
               "ic.pl?__action=edit&id=".$form->{id}
       );
       print qq|
<a href="file.pl?__action=show_attachment_screen&ref_key=$form->{id}&file_class=3&callback=$callback"
   >[| . $locale->text('Attach') . qq|]</a>|;
    }

    &assembly_row( ++$form->{assembly_rows} ) if $form->{item} eq 'assembly';

    $form->hide_form(
        qw(login path sessionid callback previousform isassemblyitem));

    print qq|
</form> |;
    if ($form->{id}){
        print qq|<form data-dojo-type="lsmb/Form" action="pnl.pl" method="GET">
        <input type="hidden" name="id" value="$form->{id}">
        <input type="hidden" name="pnl_type" value="product">
        <table width="100%">
        <col width="20em"><col>
        <tr class="listtop"><th colspan=2>| . $locale->text('Profit/Loss') . qq|
                    </th>
        </tr>
        <tr><th>| . $locale->text('Date From') . qq|</th>
            <td><input data-dojo-type="dijit/form/TextBox" type="text" size="12" name="date_from" class="date"></td>
        </tr><tr>
            <th>| . $locale->text('Date To') . qq|</th>
            <td><input data-dojo-type="dijit/form/TextBox" type="text" size="12" name="date_to" class="date"></td>
        </tr><tr>
            <td><button data-dojo-type="dijit/form/Button" type="submit" name="__action"
                        value="generate_income_statement"
                        class="submit">| . $locale->text('Continue') .
                        qq|</button><td>
        </tr>
        </table>
        </form>|;
    }
    print $form->close_status_div . qq|
</body>
</html>
|;

}

sub makemodel_row {
    my ($numrows) = @_;

    for (qw(make model)) {
        $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
    }

    print qq|
  <tr>
    <td>
      <table width=100%>
    <tr>
      <th class="listheading">| . $locale->text('Make') . qq|</th>
      <th class="listheading">| . $locale->text('Model') . qq|</th>
      <th class="listheading">| . $locale->text('Bar Code') . qq|</th>
    </tr>
|;

     foreach my $i ( 1 .. $numrows ) {
       $form->{"${_}_$i"} //= '' for (qw(make model barcode));
       print qq|
    <tr>
      <td><input data-dojo-type="dijit/form/TextBox" name="make_$i" size=30 value="$form->{"make_$i"}"></td>
      <td><input data-dojo-type="dijit/form/TextBox" name="model_$i" size=30 value="$form->{"model_$i"}"></td>
          <td><input data-dojo-type="dijit/form/TextBox" name="barcode_$i" size=30 value="$form->{"barcode_$i"}">
          </td>
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

    $form->{selectvendor} = $form->unescape( $form->{selectvendor} );

    $currency = qq|
      <th class="listheading">| . $locale->text('Curr') . qq|</th>|
      if $form->{selectcurrency};

    print qq|
  <tr>
    <td>
      <table width=100%>
    <tr>
      <th class="listheading">| . $locale->text('Vendor') . qq|</th>
      <th class="listheading">| . $locale->text('Account Number') . qq|</th>
      <th class="listheading">| . $locale->text('Vendor Reference Number') . qq|</th>
      <th class="listheading">| . $locale->text('Cost') . qq|</th>
      $currency
      <th class="listheading">| . $locale->text('Leadtime') . qq|</th>
    </tr>
|;

    $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    foreach my $i ( 1 .. $numrows ) {

        if ( $form->{selectcurrency} ) {
            my $options = $form->{selectcurrency};
            if ($form->{"vendorcurr_$i"}) {
                $options =~ s/ selected="selected"//;
                $form->{selectcurrency} =~
                    s/(value="$form->{"vendorcurr_$i"}")/$1 selected="selected"/;
            }
            $currency = qq|
      <td><select data-dojo-type="dijit/form/Select" id="vendorcurr-$i" name="vendorcurr_$i">$options</select></td>|;
        }

        if ( $i == $numrows ) {

            $vendor = qq|
          <td><input data-dojo-type="dijit/form/TextBox" name="vendor_$i" size=35 value="$form->{"vendor_$i"}"></td>
          <td><input data-dojo-type="dijit/form/TextBox" name="vendor_mn_$i" size=35 value="$form->{"vendor_mn_$i"}"></td>
|;

            if ( $form->{selectvendor} ) {
                $vendor = qq|
      <td><select data-dojo-type="dijit/form/Select" id="vendor-$i" name="vendor_$i">$form->{selectvendor}</select></td><td></td>
|;
            }

        }
        else {

            ($vendor) = split /--/, $form->{"vendor_$i"};
            $vendor = qq|
          <td>$vendor
      <input type=hidden name="vendor_$i" value="$form->{"vendor_$i"}">
      </td>
          <td>$form->{"vendor_mn_$i"}
      <input type=hidden name="vendor_mn_$i" value="$form->{"vendor_mn_$i"}">
      </td>
|;
        }

        $form->{"partnumber_$i"} = $form->quote( $form->{"partnumber_$i"} );
        print qq|
    <tr>
      $vendor
      <td><input data-dojo-type="dijit/form/TextBox" name="partnumber_$i" size=20 value="$form->{"partnumber_$i"}"></td>
      <td><input data-dojo-type="dijit/form/TextBox" name="lastcost_$i" size=10 value=|
          . $form->format_amount( \%myconfig, $form->{"lastcost_$i"}, $form->{_setting_decimal_places} )
          . qq|></td>
      $currency
      <td nowrap><input data-dojo-type="dijit/form/TextBox" name="leadtime_$i" size=5 value=|
          . $form->format_amount( \%myconfig, $form->{"leadtime_$i"} )
          . qq|> <b>|
          . $locale->text('days')
          . qq|</b></td>
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

    if ( $form->{selectpricegroup} ) {
        $pricegroup = qq|
          <th class="listheading">| . $locale->text('Pricegroup') . qq|
          </th>
|;
    }

    $currency = qq|<th class="listheading">| . $locale->text('Curr') . qq|</th>|
      if $form->{selectcurrency};

    $currency //= '';
    $pricegroup //= '';
    print qq|
  <tr>
    <td>
      <table width=100%>
    <tr>
      <th class="listheading">| . $locale->text('Customer') . qq|</th>
      <th class="listheading">| . $locale->text('Account') . qq|</th>
      $pricegroup
      <th class="listheading">| . $locale->text('Discount') . qq|</th>
      <th class="listheading">| . $locale->text('Sell Price') . qq|</th>
      $currency
      <th class="listheading">| . $locale->text('From') . qq|</th>
      <th class="listheading">| . $locale->text('To') . qq|</th>
      <th class="listheading">| . $locale->text('Min Qty') . qq|</th>
    </tr>
|;

    $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    foreach my $i ( 1 .. $numrows ) {

        if ( $form->{selectcurrency} ) {
            my $options = $form->{selectcurrency};
            if ($form->{"customercurr_$i"}) {
                $options =~ s/ selected="selected"//;
                $options =~
                    s/(value="$form->{"customercurr_$i"}")/$1 selected="selected"/;
            }
            $currency = qq|
      <td><select data-dojo-type="dijit/form/Select" id="customercurr-$i" name="customercurr_$i">$options</select></td>|;
        }

        if ( $i == $numrows ) {
            $form->{"${_}_$i"} //= '' for (qw(customer customer_mn));
            $customer = qq|
          <td><input data-dojo-type="dijit/form/TextBox" name="customer_$i" size=35 value="$form->{"customer_$i"}"></td>
          <td>
         <input data-dojo-type="dijit/form/TextBox" name="customer_mn_$i" size=35 value="$form->{"customer_mn_$i"}">
         </td>
      |;

            if ( $form->{selectcustomer} ) {
                $customer = qq|
      <td><select data-dojo-type="dijit/form/Select" id="customer-$i" name="customer_$i">$form->{selectcustomer}</select></td><td></td>
|;
            }

            if ( $form->{selectpricegroup} ) {
                $pricegroup = qq|
      <td><select data-dojo-type="dijit/form/Select" id="pricegroup-$i" name="pricegroup_$i">$form->{selectpricegroup}</select></td>
|;
            }

        }
        else {
            ($customer) = split /--/, $form->{"customer_$i"};
            $customer = qq|
          <td>$customer</td>
      <input type=hidden name="customer_$i" value="$form->{"customer_$i"}">
          <td>$form->{"customer_mn_$i"}</td>
      <input type=hidden name="customer_mn_$i" value="$form->{"customer_mn_$i"}">
      |;

            if ( $form->{selectpricegroup} ) {
                ($pricegroup) = split /--/, $form->{"pricegroup_$i"};
                $pricegroup = qq|
      <td>$pricegroup</td>
      <input type=hidden name="pricegroup_$i" value="$form->{"pricegroup_$i"}">
|;
            }
        }

        $form->{"${_}_$i"} //= '' for (qw(validfrom validto pricebreak
                                       customerprice customerqty));
        print qq|
    <tr>
      $customer
      $pricegroup

      <td><input data-dojo-type="dijit/form/TextBox" name="pricebreak_$i" size=5 value=|
          . $form->format_amount( \%myconfig, $form->{"pricebreak_$i"} )
          . qq|></td>
      <td><input data-dojo-type="dijit/form/TextBox" name="customerprice_$i" size=10 value=|
          . $form->format_amount( \%myconfig, $form->{"customerprice_$i"}, $form->{_setting_decimal_places} )
          . qq|></td>
      $currency
      <td><input class="date" data-dojo-type="lsmb/DateTextBox" name="validfrom_$i" size=11 title="$myconfig{dateformat}" value="$form->{"validfrom_$i"}"></td>
      <td><input class="date" data-dojo-type="lsmb/DateTextBox" name="validto_$i" size=11 title="$myconfig{dateformat}" value="$form->{"validto_$i"}"></td>
      <td><input class="date" data-dojo-type="dijit/form/TextBox" name="customerqty_$i" size=11 value="$form->{"customerqty_$i"}"></td>
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

    @column_index =
      qw(runningnumber qty unit bom adj partnumber description sellprice listprice lastcost);

    if ( $form->{selectassemblypartsgroup} ) {
        $form->{selectassemblypartsgroup} =
          $form->unescape( $form->{selectassemblypartsgroup} );
        @column_index =
          qw(runningnumber qty unit bom adj partnumber description partsgroup sellprice listprice lastcost);
    }

    delete $form->{previousform};

    # change callback
    $form->{old_callback} = $form->{callback};
    $callback             = $form->{callback};
    $form->{callback}     = "$form->{script}?__action=display_form";

    # delete action
    for (qw(header)) { delete $form->{$_} }

    $form->{baseassembly} = 0;
    $previousform = "";

    # save form variables in a previousform variable
    $form->{selectcustomer} = "";    # we seem to have run into a 40kb limit
    foreach my $key ( sort keys %$form ) {

        next if grep { $_ eq $key } qw/ currencies version /;
        # escape ampersands
        $form->{$key} =~ s/&/%26/g;
        $previousform .= qq|$key=$form->{$key}&| if $form->{$key} && ! ref $form->{$key};
    }
    chop $previousform;
    $form->{previousform} = $form->escape( $previousform, 1 );

    $form->{sellprice} = 0;
    $form->{listprice} = 0;
    $form->{lastcost}  = 0;
    $form->{weight}    = 0;

    $form->{callback} = $callback;

    $column_header{runningnumber} =
      qq|<th nowrap width=5%>| . $locale->text('Item') . qq|</th>|;
    $column_header{qty} =
      qq|<th align=left nowrap width=10%>| . $locale->text('Qty') . qq|</th>|;
    $column_header{unit} =
      qq|<th align=left nowrap width=5%>| . $locale->text('Unit') . qq|</th>|;
    $column_header{partnumber} =
        qq|<th align=left nowrap width=20%>|
      . $locale->text('Number')
      . qq|</th>|;
    $column_header{description} =
      qq|<th nowrap width=50%>| . $locale->text('Description') . qq|</th>|;
    $column_header{sellprice} =
      qq|<th align=right nowrap>| . $locale->text('Sell') . qq|</th>|;
    $column_header{listprice} =
      qq|<th align=right nowrap>| . $locale->text('List') . qq|</th>|;
    $column_header{lastcost} =
      qq|<th align=right nowrap>| . $locale->text('Cost') . qq|</th>|;
    $column_header{bom}        = qq|<th>| . $locale->text('BOM') . qq|</th>|;
    $column_header{adj}        = qq|<th>| . $locale->text('Adj') . qq|</th>|;
    $column_header{partsgroup} = qq|<th>| . $locale->text('Group') . qq|</th>|;

    print qq|
  <p>

  <table width=100%>
  <tr class=listheading>
    <th class=listheading>| . $locale->text('Individual Items') . qq|</th>
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

    $numrows-- if $form->{project_id};

    $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    foreach my $i ( 1 .. $numrows ) {
        for (qw(partnumber description)) {
            $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
        }

        $linetotalsellprice =
          $form->round_amount( $form->{"sellprice_$i"} * $form->{"qty_$i"}, 2 );
        $form->{sellprice} += $linetotalsellprice;

        $linetotallistprice =
          $form->round_amount( $form->{"listprice_$i"} * $form->{"qty_$i"}, 2 );
        $form->{listprice} += $linetotallistprice;

        $linetotallastcost =
          $form->round_amount( $form->{"lastcost_$i"} * $form->{"qty_$i"}, 2 );
        $form->{lastcost} += $linetotallastcost;

        $form->{"qty_$i"} =
          $form->format_amount( \%myconfig, $form->{"qty_$i"} );

        $linetotalsellprice =
          $form->format_amount( \%myconfig, $linetotalsellprice, $form->{_setting_decimal_places} );
        $linetotallistprice =
          $form->format_amount( \%myconfig, $linetotallistprice, $form->{_setting_decimal_places} );
        $linetotallastcost =
          $form->format_amount( \%myconfig, $linetotallastcost, $form->{_setting_decimal_places} );

        if ( $i == $numrows && !$form->{project_id} ) {

            for (qw(runningnumber unit bom adj)) {
                $column_data{$_} = qq|<td></td>|;
            }

            $column_data{qty} =
qq|<td><input data-dojo-type="dijit/form/TextBox" name="qty_$i" size=6 value="$form->{"qty_$i"}"></td>|;
            $column_data{partnumber} =
qq|<td><input data-dojo-type="lsmb/parts/PartSelector" name="partnumber_$i" size=15 value="$form->{"partnumber_$i"}" data-dojo-props="required:false,channel: '/part/part-select/$i'"></td>|;
            $column_data{description} =
qq|<td><div data-dojo-type="lsmb/parts/PartDescription" name="description_$i" size=30 data-dojo-props="channel: '/part/part-select/$i'">$form->{"description_$i"}</div></td>|;
            $column_data{partsgroup} =
qq|<td><select data-dojo-type="dijit/form/Select" id="partsgroup-$i" name="partsgroup_$i">$form->{selectassemblypartsgroup}</select></td>|;

        }
        else {

            $column_data{partnumber} =
qq|<td><a href="ic.pl?__action=edit&id=$form->{"id_$i"}" target="new">$form->{"partnumber_$i"}</a></td>
      <input type=hidden name="partnumber_$i" value="$form->{"partnumber_$i"}">|;

            $column_data{runningnumber} =
              qq|<td><input data-dojo-type="dijit/form/TextBox" name="runningnumber_$i" size=3 value="$i"></td>|;
            $column_data{qty} =
qq|<td><input data-dojo-type="dijit/form/TextBox" name="qty_$i" size=6 value="$form->{"qty_$i"}"></td>|;

            for (qw(bom adj)) {
                $form->{"${_}_$i"} = ( $form->{"${_}_$i"} ) ? "checked" : "";
            }
            $column_data{bom} =
qq|<td align=center><input name="bom_$i" type=checkbox data-dojo-type="dijit/form/CheckBox" class=checkbox value=1 $form->{"bom_$i"}></td>|;
            $column_data{adj} =
qq|<td align=center><input name="adj_$i" type=checkbox data-dojo-type="dijit/form/CheckBox" class=checkbox value=1 $form->{"adj_$i"}></td>|;

            ($partsgroup) = split /--/, $form->{"partsgroup_$i"};
            $column_data{partsgroup} =
qq|<td><input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">$partsgroup</td>|;

            $column_data{unit} =
qq|<td><input type=hidden name="unit_$i" value="$form->{"unit_$i"}">$form->{"unit_$i"}</td>|;
            $column_data{description} =
qq|<td><input type=hidden name="description_$i" value="$form->{"description_$i"}">$form->{"description_$i"}</td>|;

        }

        $column_data{sellprice} = qq|<td align=right>$linetotalsellprice</td>|;
        $column_data{listprice} = qq|<td align=right>$linetotallistprice</td>|;
        $column_data{lastcost}  = qq|<td align=right>$linetotallastcost</td>|;

        print qq|
        <tr>|;

        for (@column_index) { print "\n$column_data{$_}" }

        print qq|
        </tr>
|;
        $form->hide_form(
            "id_$i",     "sellprice_$i", "listprice_$i", "lastcost_$i",
            "weight_$i", "assembly_$i"
        );

    }

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{sellprice} =
      "<th align=right>"
      . $form->format_amount( \%myconfig, $form->{sellprice}, $form->{_setting_decimal_places} ) . "</th>";
    $column_data{listprice} =
      "<th align=right>"
      . $form->format_amount( \%myconfig, $form->{listprice}, $form->{_setting_decimal_places} ) . "</th>";
    $column_data{lastcost} =
      "<th align=right>"
      . $form->format_amount( \%myconfig, $form->{lastcost}, $form->{_setting_decimal_places} ) . "</th>";

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
  <input type=hidden name=selectassemblypartsgroup value="|
      . $form->escape( $form->{selectassemblypartsgroup}, 1 ) . qq|">
|;

}

sub edit_assemblyitem {

    $pn = substr( $form->{__action}, 1 );

    $i = 0;
    for ( 1 .. $form->{assembly_rows} - 1 ) {
        $i++;
        last if $form->{"partnumber_$_"} eq $pn;
    }

    $form->error( $locale->text('unexpected error!') ) unless $i;

    $form->{baseassembly} =
      ( $form->{baseassembly} )
      ? $form->{baseassembly}
      : $form->{"assembly_$i"};

    $form->{callback} =
qq|$form->{script}?__action=edit&id=$form->{"id_$i"}&rowcount=$i&baseassembly=$form->{baseassembly}&isassemblyitem=1&previousform=$form->{previousform}|;

    $form->redirect;

}

sub update {
    &link_part;
    if ( $form->{item} eq "assembly" ) {

        $i = $form->{assembly_rows};
        $i = $form->{assembly_rows} + 1 if $form->{project_id};

        # if last row is empty check the form otherwise retrieve item
        if (   ( $form->{"partnumber_$i"} eq "" )
            && ( $form->{"description_$i"} eq "" )
            && ( $form->{"partsgroup_$i"}  eq "" ) )
        {

            &check_form;

        }
        else {

            IC->assembly_item( \%myconfig, \%$form );

            $rows = scalar @{ $form->{item_list} };

            if ($rows) {
                $form->{"adj_$i"} = 1;
                for (qw(partnumber description unit)) {
                    $form->{item_list}[$i]{$_} =
                        $form->quote( $form->{item_list}[$i]{$_} );
                }
                for ( keys %{ $form->{item_list}[0] } ) {
                    $form->{"${_}_$i"} = $form->{item_list}[0]{$_};
                }
                if ( $form->{item_list}[0]{partsgroup_id} ) {
                    $form->{"partsgroup_$i"} =
                        qq|$form->{item_list}[0]{partsgroup}--$form->{item_list}[0]{partsgroup_id}|;
                }

                $form->{"runningnumber_$i"} = $form->{assembly_rows};
                $form->{assembly_rows}++;

                &check_form;

            }
            else {

                $form->{rowcount} = $i;
                $form->{assembly_rows}++;

                &new_item;

            }
        }

    }
    else {

        &check_form;

    }

}

sub check_vendor {

    @flds  = qw(vendor vendor_mn partnumber lastcost leadtime vendorcurr);
    @a     = ();
    $count = 0;

    for (qw(lastcost leadtime)) {
        $form->{"${_}_$form->{vendor_rows}"} =
          $form->parse_amount( \%myconfig,
            $form->{"${_}_$form->{vendor_rows}"} );
    }

    foreach my $i ( 1 .. $form->{vendor_rows} - 1 ) {

        for (qw(lastcost leadtime)) {
            $form->{"${_}_$i"} =
              $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
        }

        if ( $form->{"lastcost_$i"} || $form->{"partnumber_$i"} ) {

            push @a, {};
            $j = $#a;
            for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
            $count++;

        }
    }

    $i = $form->{vendor_rows};
    $form->{vendornumber} = $form->{"vendor_mn_$i"};

    if ( !$form->{selectvendor} ) {

        if ( ($form->{"vendor_$i"} || $form->{vendornumber})
              && !$form->{"vendor_id_$i"} ) {
            ( $form->{vendor} ) = split /--/, $form->{"vendor_$i"};
            if ( ( $j = $form->get_name( \%myconfig, "vendor", undef, 1) ) > 1 ) {
                &select_name( "vendor", $i );
                $form->finalize_request();
            }

            if ( $j == 1 ) {

                # we got one name
                $form->{"vendor_$i"} =
qq|$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}|;
                $form->{"vendor_nm_$1"} = $form->{name_list}[0]->{meta_number};
            }
            else {

                # name is not on file
                $form->error(
                    $locale->text(
                        '[_1]: Vendor not on file!',
                        $form->{"vendor_$i"}
                    )
                );
            }
        }
    }

    if ( $form->{"vendor_$i"} ) {
        push @a, {};
        $j = $#a;
        for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
        $count++;
    }

    $form->redo_rows( \@flds, \@a, $count, $form->{vendor_rows} );
    $form->{vendor_rows} = $count;

}

sub check_customer {

    @flds =
      qw(customer customer_mn validfrom validto pricebreak customerprice pricegroup customercurr customerqty);
    @a     = ();
    $count = 0;

    for (qw(customerprice pricebreak)) {
        $form->{"${_}_$form->{customer_rows}"} =
          $form->parse_amount( \%myconfig,
            $form->{"${_}_$form->{customer_rows}"} );
    }

    foreach my $i ( 1 .. $form->{customer_rows} - 1 ) {

        for (qw(customerprice pricebreak)) {
            $form->{"${_}_$i"} =
              $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
        }

        if ( $form->{"customerprice_$i"} || $form->{"pricebreak_$i"} ) {
            if (   $form->{"pricebreak_$i"}
                || $form->{"customer_$i"}
                || $form->{"pricegroup_$i"} )
            {

                push @a, {};
                $j = $#a;
                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                $count++;

            }
        }
    }

    $i = $form->{customer_rows};
    $form->{customernumber} = $form->{"customer_mn_$i"};

    if ( !$form->{selectcustomer} ) {

        if ( $form->{"customer_$i"} && !$form->{"customer_id_$i"} ) {
            ( $form->{customer} ) = split /--/, $form->{"customer_$i"};

            if ( ( $j = $form->get_name( \%myconfig, 'customer' ) ) > 1 ) {
                &select_name( 'customer', $i );
                $form->finalize_request();
            }
            if ( $j == 1 ) {

                # we got one name
                $form->{"customer_$i"} =
qq|$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}|;
            }
            else {

                # name is not on file
                $form->error(
                    $locale->text(
                        '[_1]: Customer not on file!',
                        $form->{customer}
                    )
                );
            }
        }
    }

    if (   $form->{"customer_$i"}
        || $form->{"pricegroup_$i"}
        || ( $form->{"customerprice_$i"} || $form->{"pricebreak_$i"} ) )
    {
        push @a, {};
        $j = $#a;
        for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
        $count++;
    }

    $form->redo_rows( \@flds, \@a, $count, $form->{customer_rows} );
    $form->{customer_rows} = $count;

}

sub select_name {
    my ( $table, $vr ) = @_;

    @column_index = qw(ndx name meta_number address);

    $label = ucfirst $table;
    $column_data{ndx} = qq|<th>&nbsp;</th>|;
    $column_data{name} =
      qq|<th class=listheading>| . $locale->maketext($label) . qq|</th>|;
    $column_data{meta_number} =
      qq|<th class=listheading>| . $locale->text('Account Number') . qq|</th>|;
    $column_data{address} =
        qq|<th class=listheading colspan=5>|
      . $locale->text('Address')
      . qq|</th>|;

    # list items with radio button on a form
    $form->header;

    $title = $locale->text('Select from one of the names below');

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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

    @column_index = qw(ndx name meta_number address city state zipcode country);

    my $i = 0;
    foreach my $ref ( @{ $form->{name_list} } ) {
        $checked = ( $i++ ) ? "" : "checked";

        $ref->{name} = $form->quote( $ref->{name} );

        $column_data{ndx} =
qq|<td><input name=ndx class=radio type=radio data-dojo-type="dijit/form/RadioButton" value=$i $checked></td>|;
        $column_data{name} =
qq|<td><input name="new_name_$i" type=hidden value="$ref->{name}">$ref->{name}</td>|;
        $column_data{meta_number} =
qq|<td>$ref->{meta_number}</td>|;
        $column_data{address} = qq|<td>$ref->{address1} $ref->{address2}&nbsp;</td>|;
        for (qw(city state zipcode country)) {
            $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>|;
        }

        $j++;
        $j %= 2;
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
    for (qw(nextsub name_list)) { delete $form->{$_} }

    $form->hide_form;

    print qq|
<input type=hidden name=nextsub value=name_selected>
<input type=hidden name=vc value=$table>
<br>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub name_selected {

    # replace the variable with the one checked

    # index for new item
    $i = $form->{ndx};

    $form->{"$form->{vc}_$form->{vr}"} =
      qq|$form->{"new_name_$i"}--$form->{"new_id_$i"}|;
    $form->{"$form->{vc}_id_$form->{vr}"} = $form->{"new_id_$i"};

    # delete all the new_ variables
    foreach my $i ( 1 .. $form->{lastndx} ) {
        for (qw(id name)) { delete $form->{"new_${_}_$i"} }
    }

    for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

    &update;

}

sub save {
    if ( $form->{obsolete} ) {
        $form->error(
            $locale->maketext(
"Inventory quantity must be zero before you can set this $form->{item} obsolete!")
        ) if ( $form->{onhand} );
    }

# expand dynamic strings
# $locale->text('Inventory quantity must be zero before you can set this part obsolete!')
# $locale->text('Inventory quantity must be zero before you can set this assembly obsolete!')

    $olditem = $form->{id};

    check_vendor();
    check_customer();
    $form->{vendor_rows} += 1 if $form->{"vendor_$form->{vendor_rows}"};
    $form->{customer_rows} += 1 if $form->{"customer_$form->{customer_rows}"};

    # save part
    $rc = IC->save( \%myconfig, \%$form );
    $rc = 1;

    $parts_id = $form->{id};

    # load previous variables
    if ( $form->{previousform} && !$form->{callback} ) {

        # save the new form variables before splitting previousform
        for ( keys %$form ) { $newform{$_} = $form->{$_} }

        $previousform = $form->unescape( $form->{previousform} );
        $baseassembly = $form->{baseassembly};

        # don't trample on previous variables
        for ( keys %newform ) { delete $form->{$_} if $_ ne 'dbh' && $_ !~ /^_/ }

        # now take it apart and restore original values
        foreach my $item ( split /&/, $previousform ) {
            ( $key, $value ) = split /=/, $item, 2;
            $value =~ s/%26/&/g;
            $form->{$key} = $value if $key ne 'dbh';
        }

        if ( $form->{item} eq 'assembly' ) {

            if ($baseassembly) {

                #redo the assembly
                $previousform =~ /\&id=(\d+)/;
                $form->{id} = $1;

                # restore original callback
                $form->{callback} = $form->unescape( $form->{old_callback} );

                &edit;
                $form->finalize_request();
            }

            # undo number formatting
            for (qw(weight listprice sellprice lastcost rop)) {
                $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
            }

            $form->{assembly_rows}-- if $olditem;
            $i = $newform{rowcount};
            $form->{"qty_$i"} = 1 unless ( $form->{"qty_$i"} );

            $form->{listprice} -= $form->{"listprice_$i"} * $form->{"qty_$i"};
            $form->{sellprice} -= $form->{"sellprice_$i"} * $form->{"qty_$i"};
            $form->{lastcost}  -= $form->{"lastcost_$i"} * $form->{"qty_$i"};
            $form->{weight}    -= $form->{"weight_$i"} * $form->{"qty_$i"};

            # change/add values for assembly item
            for (
                qw(partnumber description bin unit weight listprice sellprice lastcost)
              )
            {
                $form->{"${_}_$i"} = $newform{$_};
            }

            foreach my $item (qw(listprice sellprice lastcost)) {
                $form->{$item} += $form->{"${item}_$i"} * $form->{"qty_$i"};
                $form->{$item} = $form->round_amount( $form->{$item}, 2 );
            }

            $form->{weight} += $form->{"weight_$i"} * $form->{"qty_$i"};

            $form->{"adj_$i"} = 1 if !$olditem;

            $form->{customer_rows}--;

        }
        else {

            # set values for last invoice/order item
            $i = $form->{rowcount};
            $form->{"qty_$i"} = 1 unless ( $form->{"qty_$i"} );

            for (
                qw(partnumber description bin unit listprice sellprice partsgroup)
              )
            {
                $form->{"${_}_$i"} = $newform{$_};
            }
            for (qw(inventory income expense)) {
                $form->{"${_}_accno_id_$i"} = $newform{"IC_$_"};
                $form->{"${_}_accno_id_$i"} =~ s/--.*//;
            }
            $form->{"sellprice_$i"} = $newform{lastcost}
              if ( $form->{vendor_id} );

            if ( $form->{exchangerate} != 0 ) {
                $form->{"sellprice_$i"} =
                  $form->round_amount(
                    $form->{"sellprice_$i"} / $form->{exchangerate}, 2 );
            }

            for ( split / /, $newform{taxaccounts} ) {
                $form->{"taxaccounts_$i"} .= "$_ " if ( $newform{"IC_tax_$_"} );
            }
            chop $form->{"taxaccounts_$i"};

            # credit remaining calculation
            $amount =
              $form->{"sellprice_$i"} * ( 1 - $form->{"discount_$i"} / 100 ) *
              $form->{"qty_$i"};
            for ( split / /, $form->{"taxaccounts_$i"} ) {
                $form->{"${_}_base"} += $amount;
            }
            if ( !$form->{taxincluded} ) {
                my @taxlist = Tax::init_taxes( $form, $form->{"taxaccounts_$i"},
                    $form->{taxaccounts} );
                $amount += Tax::calculate_taxes( \@taxlist, $form, $amount, 0 );
            }

            $ml = 1;
            if ( $form->{type} =~ /invoice/ ) {
                $ml = -1 if $form->{type} =~ /_invoice/;
            }
            $form->{creditremaining} -= ( $amount * $ml );

        }

        $form->{"id_$i"} = $parts_id;
        delete $form->{__action};

        # restore original callback
        $callback = $form->unescape( $form->{callback} );
        $form->{callback} = $form->unescape( $form->{old_callback} );
        delete $form->{old_callback};

        $form->{makemodel_rows}--;

        # put callback together
        foreach my $key ( keys %$form ) {

            # do single escape for Apache 2.0
            $value = $form->escape( $form->{$key}, 1 );
            $callback .= qq|&$key=$value|;
        }
        $form->{callback} = $callback;
    }

    if ($rc) {
        my $logger = Log::Any->get_logger(category => "LedgerSMB");
        $logger->debug($parts_id);
        $form->{id} = $parts_id;
        edit();
        # redirect
        # $form->redirect("Part Saved");
    }
    else {
        $form->error;
    }

}

sub save_as_new {

    $form->{id} = 0;
    &save;

}

sub delete {

    # redirect
    if ( IC->delete( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Item deleted!') );
    }
    else {
        $form->error( $locale->text('Cannot delete item!') );
    }

}

sub stock_assembly {

    $form->{title} = $locale->text('Stock Assembly');

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

<table width="100%">
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align="right" nowrap="true">| . $locale->text('Number') . qq|</th>
          <td><input data-dojo-type="dijit/form/TextBox" name=partnumber size=20></td>
          <td>&nbsp;</td>
        </tr>
        <tr>
          <th align="right" nowrap="true">|
      . $locale->text('Description')
      . qq|</th>
          <td><input data-dojo-type="dijit/form/TextBox" name=description size=40></td>
        </tr>
        <tr>
          <td></td>
      <td><input name=checkinventory class=checkbox type=checkbox data-dojo-type="dijit/form/CheckBox" value=1>&nbsp;|
      . $locale->text('Check Inventory')
      . qq|</td>
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
<input type="hidden" name="nextsub" value="list_assemblies">

<br>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>
|;

    print qq|

</body>
</html>
|;

}

sub list_assemblies {

    IC->retrieve_assemblies( \%myconfig, \%$form );

    $callback =
"$form->{script}?__action=list_assemblies&direction=$form->{direction}&oldsort=$form->{oldsort}&checkinventory=$form->{checkinventory}";

    $form->sort_order();
    $href =
"$form->{script}?__action=list_assemblies&direction=$form->{direction}&oldsort=$form->{oldsort}&checkinventory=$form->{checkinventory}";

    if ( $form->{partnumber} ) {
        $callback .= "&partnumber=" . $form->escape( $form->{partnumber}, 1 );
        $href .= "&partnumber=" . $form->escape( $form->{partnumber} );
        $form->{sort} = "partnumber" unless $form->{sort};
    }
    if ( $form->{description} ) {
        $callback .= "&description=" . $form->escape( $form->{description}, 1 );
        $href .= "&description=" . $form->escape( $form->{description} );
        $form->{sort} = "description" unless $form->{sort};
    }

    $column_header{partnumber} =
        qq|<th><a class=listheading href=$href&sort=partnumber>|
      . $locale->text('Number')
      . qq|</th>|;
    $column_header{description} =
        qq|<th><a class=listheading href=$href&sort=description>|
      . $locale->text('Description')
      . qq|</th>|;
    $column_header{bin} =
        qq|<th><a class=listheading href=$href&sort=bin>|
      . $locale->text('Bin')
      . qq|</th>|;
    $column_header{onhand} =
      qq|<th class=listheading>| . $locale->text('Qty') . qq|</th>|;
    $column_header{rop} =
      qq|<th class=listheading>| . $locale->text('ROP') . qq|</th>|;
    $column_header{stock} =
      qq|<th class=listheading>| . $locale->text('Add') . qq|</th>|;

    @column_index =
      $form->sort_columns(qw(partnumber description bin onhand rop stock));

    $form->{title} = $locale->text('Stock Assembly');

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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
    foreach my $ref ( @{ $form->{assembly_items} } ) {

        for (qw(partnumber description)) {
            $ref->{$_} = $form->quote( $ref->{$_} );
        }

        $column_data{partnumber} =
"<td width=20%><a href=$form->{script}?__action=edit&id=$ref->{id}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";

        $column_data{description} =
          qq|<td width=50%>$ref->{description}&nbsp;</td>|;
        $column_data{bin} = qq|<td>$ref->{bin}&nbsp;</td>|;
        $column_data{onhand} =
            qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{onhand}) || '&nbsp;'
          . qq|</td>|;
        $column_data{rop} =
            qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{rop}) || "&nbsp;"
          . qq|</td>|;
        $column_data{stock} =
            qq|<td width=10%><input data-dojo-type="dijit/form/TextBox" name="qty_$i" size="10" value="|
          . $form->format_amount( \%myconfig, $ref->{stock} )
          . qq|"></td>
    <input type=hidden name="stock_$i" value="$ref->{stock}">|;

        $j++;
        $j %= 2;
        print
qq|<tr class=listrow$j><input name="id_$i" type=hidden value="$ref->{id}">\n|;

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
<input type="hidden" name="rowcount" value="$i">
<input type="hidden" name="nextsub" value="restock_assemblies">

<br>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>

</form>

</body>
</html>
|;

}

sub restock_assemblies {

    if ( $form->{checkinventory} ) {
        for ( 1 .. $form->{rowcount} ) {
            $form->error(
                $locale->text('Quantity exceeds available units to stock!') )
              if $form->parse_amount( $myconfig, $form->{"qty_$_"} ) >
              $form->{"stock_$_"};
        }
    }

    if ( IC->restock_assemblies( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Assemblies restocked!') );
    }
    else {
        $form->error( $locale->text('Cannot stock assemblies!') );
    }

}

sub continue { &{ $form->{nextsub} } }

sub add_part           { &add }
sub add_service        { &add }
sub add_assembly       { &add }
sub add_labor_overhead { &add }

1;
