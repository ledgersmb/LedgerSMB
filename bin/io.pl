######################################################################
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
# Copyright (c) 2002
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
#######################################################################
#
# common routines used in is, ir, oe
#
#######################################################################

package lsmb_legacy;
use Try::Tiny;
use LedgerSMB::Tax;
use LedgerSMB::Template;
use LedgerSMB::Sysconfig;
use LedgerSMB::Setting;
use LedgerSMB::Company_Config;
use LedgerSMB::File;
use List::Util qw(max reduce);

# any custom scripts for this one
if ( -f "bin/custom/io.pl" ) {
    eval { require "bin/custom/io.pl"; };
}
if ( -f "bin/custom/$form->{login}_io.pl" ) {
    eval { require "bin/custom/$form->{login}_io.pl"; };
}

1;

# end of main

# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May ')
# $locale->text('June')
# $locale->text('July')
# $locale->text('August')
# $locale->text('September')
# $locale->text('October')
# $locale->text('November')
# $locale->text('December')

# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')
#

sub _calc_taxes {
    $form->{subtotal} = $form->{invsubtotal};
    my $moneyplaces = $LedgerSMB::Company_Config::settings->{decimal_places};
    for $i (1 .. $form->{rowcount}){
        my $discount_amount = $form->round_amount( $form->{"sellprice_$i"}
                                      * ($form->{"discount_$i"} / 100),
                                    $decimalplaces);
        my $linetotal = $form->round_amount( $form->{"sellprice_$i"}
                                      - $discount_amount,
                                      $decimalplaces);
        $linetotal = $form->round_amount( $linetotal * $form->{"qty_$i"},
                                          $moneyplaces);
        @taxaccounts = Tax::init_taxes(
            $form, $form->{"taxaccounts_$i"},
            $form->{'taxaccounts'}
        );
        my $tax;
        my $fxtax;
        my $amount;
        if ( $form->{taxincluded} ) {
            $tax += $amount =
              Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 1 );

            $form->{"sellprice_$i"} -= $amount / $form->{"qty_$i"};
        }
        else {
            $tax += $amount =
              Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 0 );
            $fxtax +=
              Tax::calculate_taxes( \@taxaccounts, $form, $fxlinetotal, 0 )
              if $fxlinetotal;
        }
        for (@taxaccounts) {
            $form->{tax_obj}{$_->account} = $_;
            $form->{taxes}{$_->account} = 0 if ! $form->{taxes}{$_->account};
            $form->{taxes}{$_->account} += $_->value;
            if ($_->value){
               $form->{taxbasis}{$_->account} += $linetotal;
            }
        }
    }
}

sub approve {
    use LedgerSMB::DBObject::Draft;
    use LedgerSMB;
    $form->update_invnumber;
    my $lsmb = LedgerSMB->new();
    $lsmb->merge($form);

    my $draft = LedgerSMB::DBObject::Draft->new({base => $lsmb});

    $draft->approve();
    edit();
}

sub display_row {
    my $numrows = shift;
    my $min_lines = $LedgerSMB::Company_Config::settings->{min_empty};
    my $lsmb_module;
    my $desc_disabled = "";
    $desc_disabled = 'DISABLED="DISABLED"' if $form->{lock_description};
    if ($form->{vc} eq 'customer'){
       $lsmb_module = 'AR';
    } elsif ($form->{vc} eq 'vendor'){
       $lsmb_module = 'AP';
    }
    $form->all_business_units($form->{transdate},
                              $form->{"$form->{vc}_id"},
                              $lsmb_module);
    @column_index = qw(runningnumber partnumber description qty);

    if ( $form->{type} eq "sales_order" ) {
        push @column_index, "ship";
        $column_data{ship} =
            qq|<th class="listheading ship" align=center width="auto">|
          . $locale->text('Ship')
          . qq|</th>|;
    }
    if ( $form->{type} eq "purchase_order" ) {
        push @column_index, "ship";
        $column_data{ship} =
            qq|<th class="listheading ship" align=center width="auto">|
          . $locale->text('Recd')
          . qq|</th>|;
    }

    for (qw(projectnumber partsgroup)) {
        $form->{"select$_"} = $form->unescape( $form->{"select$_"} )
          if $form->{"select$_"};
    }

    if ( $form->{language_code} ne $form->{oldlanguage_code} ) {

        # rebuild partsgroup
        $l{language_code} = $form->{language_code};
        $l{searchitems} = 'nolabor' if $form->{vc} eq 'customer';

        $form->get_partsgroup( \%myconfig, \%l );
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
        $form->{oldlanguage_code} = $form->{language_code};
    }

    push @column_index, @{LedgerSMB::Sysconfig::io_lineitem_columns};
    for my $cls(@{$form->{bu_class}}){
        if (scalar @{$form->{b_units}->{"$cls->{id}"}}){
             push @column_index, "b_unit_$cls->{id}";
             $column_data{"b_unit_$cls->{id}"} =
               qq|<th class=listheading nowrap>| . $cls->{label} . qq|</th>|;
        }
    }

    push @column_index, "taxformcheck";#increase the number of elements by pushing into column_index.(Ex: NEw added element
                       # taxformcheck & check the screen AR->Sales Invoice) do everything before colspan ;

    my $colspan = $#column_index + 1;

    $form->{invsubtotal} = 0;
    for ( split / /, $form->{taxaccounts} ) { $form->{"${_}_base"} = 0 }

    $column_data{runningnumber} =
      qq|<th class="listheading runningnumber" nowrap>| . $locale->text('Item') . qq|</th>|;
    $column_data{partnumber} =
      qq|<th class="listheading partnumber" nowrap>| . $locale->text('Number') . qq|</th>|;
    $column_data{description} =
        qq|<th class="listheading description" nowrap class="description">|
      . $locale->text('Description')
      . qq|</th>|;
    $column_data{qty} =
      qq|<th class="listheading qty" nowrap>| . $locale->text('Qty') . qq|</th>|;
    $column_data{unit} =
      qq|<th class="listheading unit" nowrap>| . $locale->text('Unit') . qq|</th>|;
    $column_data{sellprice} =
      qq|<th class="listheading sellprice" nowrap>| . $locale->text('Price') . qq|</th>|;
    $column_data{discount} = qq|<th class="listheading discount">%</th>|;
    $column_data{linetotal} =
      qq|<th class="listheading linetotal" nowrap>| . $locale->text('Extended') . qq|</th>|;
    $column_data{bin} =
      qq|<th class="listheading bin" nowrap>| . $locale->text('Bin') . qq|</th>|;
    $column_data{onhand} =
      qq|<th class="listheading onhand" nowrap>| . $locale->text('OH') . qq|</th>|;
    $column_data{taxformcheck} =
      qq|<th class="listheading taxform" nowrap>| . $locale->text('TaxForm') . qq|</th>|;
    print qq|
  <tr>
    <td>
      <table width=100%>
    <tr class=listheading>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    $deliverydate  = $locale->text('Delivery Date');
    $serialnumber  = $locale->text('Serial No.');
    $projectnumber = $locale->text('Project');
    $group         = $locale->text('Group');
    $sku           = $locale->text('SKU');

    $delvar = 'deliverydate';

    if ( $form->{type} =~ /_(order|quotation)$/ ) {
        $reqdate = $locale->text('Required by');
        $delvar  = 'reqdate';
    }

    $exchangerate = $form->parse_amount( \%myconfig, $form->{exchangerate} );
    $exchangerate = ($exchangerate) ? $exchangerate : 1;

    $spc = substr( $myconfig{numberformat}, -3, 1 );
    for $i ( 1 .. max($numrows, $min_lines)) {
        $desc_disabled = '' if $i == $numrows;
        if ( $spc eq '.' ) {
            ( $null, $dec ) = split /\./, $form->{"sellprice_$i"};
        }
        else {
            ( $null, $dec ) = split /,/, $form->{"sellprice_$i"};
        }
        my $moneyplaces = LedgerSMB::Setting->get('decimal_places');
        $dec = length $dec;
        $dec ||= $moneyplaces;
        $form->{"precision_$i"} ||= $dec;
        $dec =  $form->{"precision_$i"};
        $decimalplaces = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;

        # undo formatting
        for (qw(qty oldqty ship discount sellprice)) {
            $form->{"${_}_$i"} =
              $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
        }

        if ( $form->{"qty_$i"} != $form->{"oldqty_$i"} ) {

            # check pricematrix
            @a = split / /, $form->{"pricematrix_$i"};
            if ( scalar @a > 2 ) {
                foreach $item (@a) {
                    ( $q, $p ) = split /:/, $item;
                    if ( ( $p * 1 ) && ( $form->{"qty_$i"} >= ( $q * 1 ) ) ) {
                        ($dec) = ( $p =~ /\.(\d+)/ );
                        $dec = length $dec;
                        $dec ||= $moneyplaces;
                        $decimalplaces = ( $dec > $moneyplaces )
                                        ? $dec
                                        : $moneyplaces;
                        $form->{"sellprice_$i"} =
                          $form->round_amount( $p / $exchangerate,
                            $decimalplaces );
                    }
                }
            }
        }

    my $discount_amount = $form->round_amount( $form->{"sellprice_$i"}
                              * ($form->{"discount_$i"} / 100),
                           $decimalplaces);
        $linetotal = $form->round_amount( $form->{"sellprice_$i"}
                                          - $discount_amount,
                                          $decimalplaces);
        $linetotal = $form->round_amount( $linetotal * $form->{"qty_$i"},
                                         $moneyplaces);

        $form->{"description_$i"} = $form->quote( $form->{"description_$i"} );
        if ($desc_disabled){
            $column_data{description} = qq|<td>$form->{"description_$i"} |
             . qq|<input type="hidden" name="description_$i"
                        value="$form->{"description_$i"}" /></td>|
        } else {
            if (
                ( $rows = $form->numtextrows( $form->{"description_$i"}, 46, 6 ) ) >
                1 )
            {
                    $column_data{description} =
qq|<td><textarea data-dojo-type="dijit/form/Textarea" name="description_$i" rows=$rows cols=46 wrap=soft>$form->{"description_$i"}</textarea></td>|;
            }
            else {
                 $column_data{description} =
qq|<td><input data-dojo-type="dijit/form/TextBox" name="description_$i" $desc_disabled size=48 value="$form->{"description_$i"}"></td>|;
            }
        }

        for (qw(partnumber sku unit)) {
            $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
        }

        $skunumber = qq|
                <p><b>$sku</b> $form->{"sku_$i"}|
          if ( $form->{vc} eq 'vendor' && $form->{"sku_$i"} );

        if ( $form->{selectpartsgroup} ) {
            if ( $i < $numrows ) {
                $partsgroup = qq|
          <b>$group</b>
          <input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">|;
                ( $form->{"partsgroup_$i"} ) = split /--/,
                  $form->{"partsgroup_$i"};
                $partsgroup .= $form->{"partsgroup_$i"};
                $partsgroup = "" unless $form->{"partsgroup_$i"};
            }
        }

        $delivery = qq|
          <td colspan=2 nowrap>
             <b>${$delvar}</b>
             <input class="date" data-dojo-type="lsmb/lib/DateTextBox" name="${delvar}_$i" size=11 title="$myconfig{dateformat}" value="$form->{"${delvar}_$i"}">
          </td>
|;


        $taxchecked="";
    if($form->{"taxformcheck_$i"} or ($i == $form->{rowcount} and $form->{default_reportable}))
    {
        $taxchecked="checked";

    }
        for my $cls(@{$form->{bu_class}}){
            if (scalar @{$form->{b_units}->{"$cls->{id}"}}){
                $column_data{"b_unit_$cls->{id}"} =
                   qq|<td><select data-dojo-type="dijit/form/Select" name="b_unit_$cls->{id}_$i">
                           <option></option>|;
                for my $bu (@{$form->{b_units}->{"$cls->{id}"}}){
                   my $selected = "";
                   if ($bu->{id} eq $form->{"b_unit_$cls->{id}_$i"}){
                       $selected = "SELECTED='SELECTED'";
                   }
                   $column_data{"b_unit_$cls->{id}"} .= qq|
                       <option value="$bu->{id}" $selected >
                               $bu->{control_code}
                       </option>|;
                }
                $column_data{"b_unit_$cls->{id}"} .= qq|
                     </select></td>|;

            }
        }

$column_data{runningnumber} =
          qq|<td class="runningnumber"><input data-dojo-type="dijit/form/TextBox" name="runningnumber_$i" size=3 value=$i></td>|;
        if ($form->{"partnumber_$i"}){
           $column_data{partnumber} =
           qq|<td> $form->{"partnumber_$i"}
                 <button data-dojo-type="dijit/form/Button" type="submit" class="submit" value="$i"
                         name="delete_line">X</button>
                 <input type="hidden" name="partnumber_$i"
                       value="$form->{"partnumber_$i"}" /></td>|;
        } else {
            $column_data{partnumber} =
qq|<td class="partnumber" colspan="2"><input data-dojo-type="lsmb/parts/PartSelector" data-dojo-props="required: false" name="partnumber_$i" size=15 value="$form->{"partnumber_$i"}" accesskey="$i" title="[Alt-$i]">$skunumber</td>|;
            $column_data{description} = '';
        }
        $column_data{qty} =
qq|<td align=right class="qty"><input data-dojo-type="dijit/form/TextBox" name="qty_$i" title="$form->{"onhand_$i"}" size="5" value="|
          . $form->format_amount( \%myconfig, $form->{"qty_$i"} )
          . qq|"></td>|;
        $column_data{ship} =
            qq|<td align=right class="ship"><input data-dojo-type="dijit/form/TextBox" name="ship_$i" size="5" value="|
          . $form->format_amount( \%myconfig, $form->{"ship_$i"} )
          . qq|"></td>|;
        $column_data{unit} =
          qq|<td class="unit"><input data-dojo-type="dijit/form/TextBox" name="unit_$i" size=5 value="$form->{"unit_$i"}"></td>|;
        $column_data{sellprice} =
          qq|<td align=right class="sellprice"><input data-dojo-type="dijit/form/TextBox" name="sellprice_$i" size="9" value="|
          . $form->format_amount( \%myconfig, $form->{"sellprice_$i"},
            $form->{"precision_$i"} )
          . qq|"></td>|;
        $column_data{discount} =
            qq|<td align=right class="discount"><input data-dojo-type="dijit/form/TextBox" name="discount_$i" size="3" value="|
          . $form->format_amount( \%myconfig, $form->{"discount_$i"} )
          . qq|"></td>|;
        $column_data{linetotal} =
            qq|<td align=right class="linetotal">|
          . $form->format_amount( \%myconfig, $linetotal, 2 )
          . qq|</td>|;
        $column_data{bin}    = qq|<td class="bin">$form->{"bin_$i"}</td>|;
        $column_data{onhand} = qq|<td class="onhand">$form->{"onhand_$i"}</td>|;
        $column_data{taxformcheck} = qq|<td class="taxform"><input type="checkbox" data-dojo-type="dijit/form/CheckBox" name="taxformcheck_$i" value="1" $taxchecked></td>|;
        print qq|
        <tr valign=top>|;

        for (@column_index) {
            print "\n$column_data{$_}";
        }

        print qq|
        </tr>
<input type=hidden name="oldqty_$i" value="$form->{"qty_$i"}">
|;

        for (
            qw(image orderitems_id id bin weight listprice lastcost taxaccounts pricematrix sku onhand assembly inventory_accno_id income_accno_id expense_accno_id invoice_id precision)
          )
        {
            $form->hide_form("${_}_$i");
        }

        $form->{selectprojectnumber} =~ s/ selected//;
        $form->{selectprojectnumber} =~
          s/(<option value="\Q$form->{"projectnumber_$i"}\E")/$1 selected/;

        $project = qq|
                <b>$projectnumber</b>
        <select data-dojo-type="dijit/form/Select" name="projectnumber_$i">$form->{selectprojectnumber}</select>
| if $form->{selectprojectnumber};

        if ( ( $rows = $form->numtextrows( $form->{"notes_$i"}, 36, 6 ) ) > 1 )
        {
            $form->{"notes_$i"} = $form->quote( $form->{"notes_$i"} );
            $notes =
qq|<td><textarea data-dojo-type="dijit/form/Textarea" name="notes_$i" rows=$rows cols=36 wrap=soft>$form->{"notes_$i"}</textarea></td>|;
        }
        else {
            $form->{"notes_$i"} = $form->quote( $form->{"notes_$i"} );
            $notes =
qq|<td><input data-dojo-type="dijit/form/TextBox" name="notes_$i" size=38 value="$form->{"notes_$i"}"></td>|;
        }

        $serial = qq|
                <td colspan=6 nowrap><b>$serialnumber</b> <input data-dojo-type="dijit/form/TextBox" name="serialnumber_$i" value="$form->{"serialnumber_$i"}"></td>|
          if $form->{type} !~ /_quotation/;

        if ( $i == $numrows ) {
            $partsgroup = "";
            if ( $form->{selectpartsgroup} ) {
                $partsgroup = qq|
            <b>$group</b>
        <select data-dojo-type="dijit/form/Select" name="partsgroup_$i">$form->{selectpartsgroup}</select>
|;
            }

        }

        # print second and third row
        print qq|
        <tr valign=top class="ext2">
      $delivery
      $notes
      $serial
    </tr>
        <tr valign=top class="ext3">
      <td colspan=$colspan>
      $project
      $partsgroup
      </td>
    </tr>
    <tr>
      <td colspan=$colspan><hr size=1 noshade></td>
    </tr>
|;

        $skunumber = "";

        for ( split / /, $form->{"taxaccounts_$i"} ) {
            $form->{"${_}_base"} += $linetotal;
        }

        $form->{invsubtotal} += $linetotal;
    }

    print qq|
      </table>
    </td>
  </tr>
|;

    $form->hide_form(qw(audittrail));

    print qq|

<input type=hidden name=oldcurrency value=$form->{currency}>

<input type=hidden name=selectpartsgroup value="|
      . $form->escape( $form->{selectpartsgroup}, 1 ) . qq|">
<input type=hidden name=selectprojectnumber value="|
      . $form->escape( $form->{selectprojectnumber}, 1 ) . qq|">

|;

}

sub select_item {

    if ( $form->{vc} eq "vendor" ) {
        @column_index =
          qw(ndx partnumber sku description partsgroup onhand sellprice);
    }
    else {
        @column_index =
          qw(ndx partnumber description partsgroup onhand sellprice);
    }

    $column_data{ndx} = qq|<th class="listheading runningnumber">&nbsp;</th>|;
    $column_data{partnumber} =
      qq|<th class="listheading partnumber">| . $locale->text('Number') . qq|</th>|;
    $column_data{sku} =
      qq|<th class="listheading sku">| . $locale->text('SKU') . qq|</th>|;
    $column_data{description} =
      qq|<th class="listheading description">| . $locale->text('Description') . qq|</th>|;
    $column_data{partsgroup} =
      qq|<th class="listheading partsgroup">| . $locale->text('Group') . qq|</th>|;
    $column_data{sellprice} =
      qq|<th class="listheading sellprice">| . $locale->text('Price') . qq|</th>|;
    $column_data{onhand} =
      qq|<th class="listheading onhand">| . $locale->text('Qty') . qq|</th>|;

    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

    $form->{exchangerate} =
        $form->format_amount( \%myconfig, $form->{exchangerate} );

    # list items with radio button on a form
    $form->header;

    $title = $locale->text('Select items');

    print qq|
<body class="lsmb $form->{dojo_theme}">

<form method="post" data-dojo-type="lsmb/lib/Form" action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    my $i = 0;
    foreach $ref ( @{ $form->{item_list} } ) {
        $i++;

        for (qw(sku partnumber description unit notes partsgroup)) {
            $ref->{$_} = $form->quote( $ref->{$_} );
        }

        $column_data{ndx} =
qq|<td><input name="ndx_$i" class=checkbox type=checkbox data-dojo-type="dijit/form/CheckBox" value=$i></td>|;

        for (qw(partnumber sku description partsgroup)) {
            $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>|;
        }

        $column_data{sellprice} = qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{sellprice} / $exchangerate,
            2, "&nbsp;" )
          . qq|</td>|;
        $column_data{onhand} =
            qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{onhand}, '', "&nbsp;" )
          . qq|</td>|;

        $j++;
        $j %= 2;
        print qq|
        <tr class=listrow$j>|;

        for (@column_index) {
            print "\n$column_data{$_}";
        }

        print qq|
        </tr>
|;

        for (
            qw(partnumber sku description partsgroup partsgroup_id bin weight
               sellprice listprice lastcost onhand unit assembly
               taxaccounts inventory_accno_id income_accno_id expense_accno_id
               pricematrix id image notes)
          )
        {
            print
              qq|<input type=hidden name="new_${_}_$i" value="$ref->{$_}">\n|;
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

<input name=lastndx type=hidden value=$i>

|;

    # delete variables
    for (qw(nextsub item_list)) { delete $form->{$_} }

    $form->{action} = "item_selected";

    $form->hide_form;

    print qq|
<input type="hidden" name="nextsub" value="item_selected">

<br>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub item_selected {

    $i = $form->{rowcount} - 1;
    $i = $form->{assembly_rows} - 1 if ( $form->{item} eq 'assembly' );
    $qty =
      ( $form->{"qty_$form->{rowcount}"} )
      ? $form->{"qty_$form->{rowcount}"}
      : 1;

    for $j ( 1 .. $form->{lastndx} ) {

        if ( $form->{"ndx_$j"} ) {

            $i++;

            $form->{"qty_$i"}      = $qty;
            # We should unset this since it is pulling from the customer/vendor
            # $form->{"discount_$i"} = $form->{discount};
            $form->{"reqdate_$i"}  = $form->{reqdate}
              if $form->{type} !~ /_quotation/;

            for (
                qw(id partnumber sku description listprice lastcost sellprice
                  bin unit weight assembly taxaccounts pricematrix onhand notes
                  inventory_accno_id image income_accno_id expense_accno_id)
              )
            {
                $form->{"${_}_$i"} = $form->{"new_${_}_$j"};
            }
            $form->{"sellprice_$i"} = $form->{"new_sellprice_$j"}
              if not $form->{"sellprice_$i"};

            $form->{"partsgroup_$i"} =
              qq|$form->{"new_partsgroup_$j"}--$form->{"new_partsgroup_id_$j"}|;

            my $moneyplaces = LedgerSMB::Setting->get('decimal_places');
            ($dec) = ( $form->{"sellprice_$i"} =~ /\.(\d+)/ );
            $dec = length $dec;
            $dec ||=$moneyplaces;
            $decimalplaces1 = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;

            ($dec) = ( $form->{"lastcost_$i"} =~ /\.(\d+)/ );
            $dec = length $dec;
            $dec ||=$moneyplaces;
            $decimalplaces2 = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;

            # if there is an exchange rate adjust sellprice
            if ( ( $form->{exchangerate} * 1 ) ) {
                for (qw(sellprice listprice lastcost)) {
                    $form->{"${_}_$i"} /= $form->{exchangerate};
                }

                # don't format list and cost
                $form->{"sellprice_$i"} =
                  $form->round_amount( $form->{"sellprice_$i"},
                    $decimalplaces1 );
            }

            # this is for the assembly
            if ( $form->{item} eq 'assembly' ) {
                $form->{"adj_$i"} = 1;

                for (qw(sellprice listprice weight)) {
                    $form->{$_} =
                      $form->parse_amount( \%myconfig, $form->{$_} );
                }

                $form->{sellprice} +=
                  ( $form->{"sellprice_$i"} * $form->{"qty_$i"} );
                $form->{weight} += ( $form->{"weight_$i"} * $form->{"qty_$i"} );
            }

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

            $form->{creditremaining} -= $amount;

            $form->{"runningnumber_$i"} = $i;

            # format amounts
            if ( $form->{item} ne 'assembly' ) {
                for (qw(sellprice listprice)) {
                    $form->{"${_}_$i"} =
                      $form->format_amount( \%myconfig, $form->{"${_}_$i"},
                        $decimalplaces1 );
                }
                $form->{"lastcost_$i"} =
                  $form->format_amount( \%myconfig, $form->{"lastcost_$i"},
                    $decimalplaces2 );
            }
            $form->{"discount_$i"} =
              $form->format_amount( \%myconfig, $form->{"discount_$i"} );

        }
    }

    $form->{rowcount} = $i;
    $form->{assembly_rows} = $i if ( $form->{item} eq 'assembly' );

    $form->{focus} = "description_$i";

    # delete all the new_ variables
    for $i ( 1 .. $form->{lastndx} ) {
        for (
            qw(id partnumber sku description sellprice listprice lastcost
               bin unit weight assembly taxaccounts pricematrix onhand
               notes inventory_accno_id income_accno_id expense_accno_id image)
          )
        {
            delete $form->{"new_${_}_$i"};
        }
    }

    for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

    &display_form;

}

sub new_item {

    # change callback
    $form->{old_callback} = $form->escape( $form->{callback}, 1 );
    $form->{callback} =
      $form->escape( "$form->{script}?action=display_form", 1 );

    # delete action
    delete $form->{action};

    # save all other form variables in a previousform variable
    if ( !$form->{previousform} ) {
        foreach $key ( keys %$form ) {

            # escape ampersands
            $form->{$key} =~ s/&/%26/g;
            $form->{previousform} .= qq|$key=$form->{$key}&|;
        }
        chop $form->{previousform};
        $form->{previousform} = $form->escape( $form->{previousform}, 1 );
    }

    $i = $form->{rowcount};
    for (qw(partnumber description)) {
        $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
    }

    $form->header;

    print qq|
<body class="lsmb $form->{dojo_theme}">

<h4 class=error>| . $locale->text('Item not on file!') . qq|</h4>|;

    if ( $myconfig{acs} !~
        /(Goods \& Services--Add Part|Goods \& Services--Add Service)/ )
    {

        print qq|
<h4>| . $locale->text('What type of item is this?') . qq|</h4>

<form method="post" data-dojo-type="lsmb/lib/Form" action=ic.pl>

<p>

  <input class=radio type=radio data-dojo-type="dijit/form/RadioButton" name=item value=part checked>&nbsp;|
          . $locale->text('Part') . qq|<br>
  <input class=radio type=radio data-dojo-type="dijit/form/RadioButton" name=item value=service>&nbsp;|
          . $locale->text('Service')

          . qq|
<input type=hidden name=partnumber value="$form->{"partnumber_$i"}">
<input type=hidden name=description value="$form->{"description_$i"}">
<input type=hidden name=nextsub value=add>
<input type=hidden name=action value=add>
|;

        $form->hide_form(qw(previousform rowcount path login sessionid));

        print qq|
<p>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="action" value="continue">|
          . $locale->text('Continue')
          . qq|</button>
</form>
|;
    }

    print qq|
</body>
</html>
|;

    $form->finalize_request();

}

sub display_form {
    $form->close_form();
     $form->generate_selects();
    $form->open_form();

    # if we have a display_form
    if ( $form->{display_form} ) {

    &{"$form->{display_form}"};
        $form->finalize_request();
    }


    &form_header;

    $numrows    = ++$form->{rowcount};
    $subroutine = "display_row";

    if ( $form->{item} eq 'part' ) {

        # create makemodel rows
        &makemodel_row( ++$form->{makemodel_rows} );

        &vendor_row( ++$form->{vendor_rows} );

        $numrows    = ++$form->{customer_rows};
        $subroutine = "customer_row";
    }
    if ( $form->{item} eq 'assembly' ) {

        # create makemodel rows
        &makemodel_row( ++$form->{makemodel_rows} );

        $numrows    = ++$form->{customer_rows};
        $subroutine = "customer_row";
    }
    if ( $form->{item} eq 'service' ) {
        &vendor_row( ++$form->{vendor_rows} );

        $numrows    = ++$form->{customer_rows};
        $subroutine = "customer_row";
    }
    if ( $form->{item} eq 'labor' ) {
        $numrows = 0;
    }

    # create rows

    &{$subroutine}($numrows) if $numrows;

    $form->hide_form(qw|locationid|);

    &form_footer;
    $form->finalize_request;

}





sub check_form {
    my $nodisplay = shift;
    my @a     = ();
    my $count = 0;
    my $i;
    my $j;
    my @flds =
      qw(id runningnumber partnumber description partsgroup qty ship unit
         sellprice discount oldqty orderitems_id bin weight listprice
         lastcost taxaccounts pricematrix sku onhand assembly
         inventory_accno_id income_accno_id expense_accno_id notes reqdate
         deliverydate serialnumber projectnumber image);

    # remove any makes or model rows
    if ( $form->{item} eq 'part' ) {
        for (qw(listprice sellprice lastcost avgcost weight rop markup)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        &calc_markup;

        @flds  = qw(make model);
        $count = 0;
        @a     = ();
        for $i ( 1 .. $form->{makemodel_rows} ) {
            if ( ( $form->{"make_$i"} ne "" ) || ( $form->{"model_$i"} ne "" ) )
            {
                push @a, {};
                $j = $#a;

                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                $count++;
            }
        }

        $form->redo_rows( \@flds, \@a, $count, $form->{makemodel_rows} );
        $form->{makemodel_rows} = $count;

        &check_vendor;
        &check_customer;

    }

    if ( $form->{item} eq 'service' ) {

        for (qw(sellprice listprice lastcost avgcost markup)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        &calc_markup;
        &check_vendor;
        &check_customer;

    }

    if ( $form->{item} eq 'assembly' ) {

        if ( !$form->{project_id} ) {
            $form->{sellprice} = 0;
            $form->{listprice} = 0;
            $form->{lastcost}  = 0;
            $form->{weight}    = 0;
        }

        for (qw(rop stock markup)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        @flds =
          qw(id qty unit bom adj partnumber description sellprice listprice lastcost weight assembly runningnumber partsgroup);
        $count = 0;
        @a     = ();

        for $i ( 1 .. ( $form->{assembly_rows} - 1 ) ) {
            if ( $form->{"qty_$i"} ) {
                push @a, {};
                my $j = $#a;

                $form->{"qty_$i"} =
                  $form->parse_amount( \%myconfig, $form->{"qty_$i"} );

                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }

                if ( !$form->{project_id} ) {
                    for (qw(sellprice listprice weight lastcost)) {
                        $form->{$_} +=
                          ( $form->{"${_}_$i"} * $form->{"qty_$i"} );
                    }
                }

                $count++;
            }
        }

        if ( $form->{markup} && $form->{markup} != $form->{oldmarkup} ) {
            $form->{sellprice} = 0;
            &calc_markup;
        }

        for (qw(sellprice lastcost listprice)) {
            $form->{$_} = $form->round_amount( $form->{$_}, 2 );
        }

        $form->redo_rows( \@flds, \@a, $count, $form->{assembly_rows} );
        $form->{assembly_rows} = $count;

        $count = 0;
        @flds  = qw(make model);
        @a     = ();

        for $i ( 1 .. ( $form->{makemodel_rows} ) ) {
            if ( ( $form->{"make_$i"} ne "" ) || ( $form->{"model_$i"} ne "" ) )
            {
                push @a, {};
                my $j = $#a;

                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                $count++;
            }
        }

        $form->redo_rows( \@flds, \@a, $count, $form->{makemodel_rows} );
        $form->{makemodel_rows} = $count;

        &check_customer;

    }

    if ( $form->{type} ) {

        # this section applies to invoices and orders
        # remove any empty numbers

        $count = 0;
        @a     = ();
        if ( $form->{rowcount} ) {
            for $i ( 1 .. $form->{rowcount} - 1 ) {
                if ( $form->{"partnumber_$i"} ) {
                    push @a, {};
                    my $j = $#a;

                    for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                    $count++;
                }
            }

            $form->redo_rows( \@flds, \@a, $count, $form->{rowcount} );
            $form->{rowcount} = $count;

            $form->{creditremaining} -= &invoicetotal;

        }
    }
    return if $form->{action} =~ /(save|post)/ or $nodisplay;
    &display_form;
    $form->finalize_request;
}

sub calc_markup {

    if ( $form->{markup} ) {
        if ( $form->{markup} != $form->{oldmarkup} ) {
            if ( $form->{lastcost} ) {
                $form->{sellprice} =
                  $form->{lastcost} * ( 1 + $form->{markup} / 100 );
                $form->{sellprice} =
                  $form->round_amount( $form->{sellprice}, 2 );
            }
            else {
                $form->{lastcost} =
                  $form->{sellprice} / ( 1 + $form->{markup} / 100 );
                $form->{lastcost} = $form->round_amount( $form->{lastcost}, 2 );
            }
        }
    }
    else {
        if ( $form->{lastcost} ) {
            $form->{markup} =
              $form->round_amount(
                ( ( 1 - $form->{sellprice} / $form->{lastcost} ) * 100 ), 1 );
        }
        $form->{markup} = "" if $form->{markup} == 0;
    }

}

sub invoicetotal {

    $form->{oldinvtotal} = 0;

    # add all parts and deduct paid
    for ( split / /, $form->{taxaccounts} ) { $form->{"${_}_base"} = 0 }

    my ( $amount, $sellprice, $discount, $qty );

    for $i ( 1 .. $form->{rowcount} ) {
        $sellprice = $form->parse_amount( \%myconfig, $form->{"sellprice_$i"} );
        $discount  = $form->parse_amount( \%myconfig, $form->{"discount_$i"} );
        $qty       = $form->parse_amount( \%myconfig, $form->{"qty_$i"} );

        $amount = $sellprice * ( 1 - $discount / 100 ) * $qty;
        for ( split / /, $form->{"taxaccounts_$i"} ) {
            $form->{"${_}_base"} += $amount;
        }
        $form->{oldinvtotal} += $amount;
    }

    if ( !$form->{taxincluded} ) {
        my @taxlist = Tax::init_taxes( $form, $form->{taxaccounts} );
        $form->{oldinvtotal} +=
          Tax::calculate_taxes( \@taxlist, $form, $amount, 0 );
    }

    $form->{oldtotalpaid} = 0;
    for $i ( 1 .. $form->{paidaccounts} ) {
        $form->{oldtotalpaid} += $form->{"paid_$i"};
    }

    # return total
    ( $form->{oldinvtotal} - $form->{oldtotalpaid} );

}

sub validate_items {

    # check if items are valid
    if ( $form->{rowcount} == 1 ) {
        &update;
        $form->finalize_request();
    }

    for $i ( 1 .. $form->{rowcount} - 1 ) {
        $form->isblank( "partnumber_$i",
            $locale->text( 'Number missing in Row [_1]', $i ) );
    }

}

sub purchase_order {

    $form->{title} = $locale->text('Add Purchase Order');
    $form->{vc}    = 'vendor';
    $form->{type}  = 'purchase_order';
    $buysell       = 'sell';

    &create_form;

}

sub sales_order {

    $form->{title} = $locale->text('Add Sales Order');
    $form->{vc}    = 'customer';
    $form->{type}  = 'sales_order';
    $buysell       = 'buy';

    &create_form;

}

sub rfq {

    $form->{title} = $locale->text('Add Request for Quotation');
    $form->{vc}    = 'vendor';
    $form->{type}  = 'request_quotation';
    $buysell       = 'sell';

    &create_form;

}

sub quotation {

    $form->{title} = $locale->text('Add Quotation');
    $form->{vc}    = 'customer';
    $form->{type}  = 'sales_quotation';
    $buysell       = 'buy';

    &create_form;

}

sub create_form {

    for (qw(id printed emailed queued)) { delete $form->{$_} }

    $form->{script} = 'oe.pl';

    $form->{shipto} = 1;

    $form->{rowcount}-- if $form->{rowcount};
    $form->{rowcount} = 0 if !$form->{"$form->{vc}_id"};

    do "bin/$form->{script}";

    for ( "$form->{vc}", "currency" ) { $form->{"select$_"} = "" }

    for (
        qw(currency employee department intnotes notes language_code taxincluded)
      )
    {
        $temp{$_} = $form->{$_};
    }

    &order_links;

    for ( keys %temp ) { $form->{$_} = $temp{$_} if $temp{$_} }

    $form->{exchangerate} = "";
    $form->{forex}        = "";
    if ( $form->{currency} ne $form->{defaultcurrency} ) {
        $form->{exchangerate} = $exchangerate
          if (
            $form->{forex} = (
                $exchangerate = $form->check_exchangerate(
                    \%myconfig,         $form->{currency},
                    $form->{transdate}, $buysell
                )
            )
          );
    }

    &prepare_order;

    &display_form;

}

sub e_mail {

    my %hiddens;
    if ( $myconfig{role} !~ /(admin|manager)/ ) {
      #  $hiddens{bcc} = $form->{bcc};
    }

    if ( $form->{formname} =~ /(pick|packing|bin)_list/ ) {
        $form->{email} = $form->{shiptoemail} if $form->{shiptoemail};
    }
    $form->{oldlanguage_code} = $form->{language_code};

    $form->{oldmedia} = $form->{media};
    $form->{media}    = "email";
    $form->{format}   = "pdf";

    my $print_options = &print_options(\%hiddens);

    for (
        qw(subject message sendmode format language_code action nextsub)
      )
    {
        delete $form->{$_};
    }

    $hiddens{$_} = $form->{$_} for keys %$form;

    delete $hiddens{email};
    delete $hiddens{cc};
    delete $hiddens{bcc};
    delete $hiddens{message};

    $hiddens{nextsub} = 'send_email';

    my @buttons = ({
        name => 'action',
        value => 'send_email',
        text => $locale->text('Continue'),
        });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'io-email',
        );
    $template->render({
        form => $form,
        print => $print_options,
        hiddens => \%hiddens,
        buttons => \@buttons,
    });
}

sub send_email {

    $old_form = new Form;

    for ( keys %$form ) { $old_form->{$_} = $form->{$_} }
    $old_form->{media} = $old_form->{oldmedia};

    &print_form($old_form);

}

sub print_options {

    my $hiddens = shift;
    my %options;
    $form->{format} = $form->get_setting('format') unless $form->{format};
    $form->{sendmode} = "attachment";
    $form->{copies} = 1 unless $form->{copies};

    $form->{SM}{ $form->{sendmode} } = "selected";

    delete $form->{all_language};
    $form->all_languages;
    if ( ref $form->{all_language} eq 'ARRAY') {
        $options{lang} = {
            name => 'language_code',
            default_values => $form->{oldlanguage_code},
            options => [{text => ' ', value => ''}],
            };
        for my $lang (@{$form->{all_language}}) {
            push @{$options{lang}{options}}, {
                text => $lang->{description},
                value => $lang->{code},
                };
        }
        $hiddens->{oldlanguage_code} = $form->{oldlanguage_code};
    }

    $options{formname} = {
        name => 'formname',
        default_values => $form->{formname},
        options => [],
        };

    # SC: Option values extracted from other bin/ scripts
    if ($form->{type} eq 'invoice') {
    push @{$options{formname}{options}}, {
        text => $locale->text('Invoice'),
        value => 'invoice',
        };
    }
    if ($form->{type} eq 'sales_quotation') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Quotation'),
            value => 'sales_quotation',
            };
    } elsif ($form->{type} eq 'request_quotation') {
        push @{$options{formname}{options}}, {
            text => $locale->text('RFQ'),
            value => 'request_quotation',
            };
    } elsif ($form->{type} eq 'sales_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Sales Order'),
            value => 'sales_order',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Work Order'),
            value => 'work_order',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Pick List'),
            value => 'pick_list',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Packing List'),
            value => 'packing_list',
            };
    } elsif ($form->{type} eq 'purchase_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Purchase Order'),
            value => 'purchase_order',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Bin List'),
            value => 'bin_list',
            };
    } elsif ($form->{type} eq 'ship_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Pick List'),
            value => 'pick_list',
            };
        push @{$options{formname}{options}}, {
            text => $locale->text('Packing List'),
            value => 'packing_list',
            };
    } elsif ($form->{type} eq 'receive_order') {
        push @{$options{formname}{options}}, {
            text => $locale->text('Bin List'),
            value => 'bin_list',
            };
    }
    push @{$options{formname}{options}}, {
            text => $locale->text('Envelope'),
            value => 'envelope',
            };
    push @{$options{formname}{options}}, {
            text => $locale->text('Shipping Label'),
            value => 'shipping_label',
            };

    if ( $form->{media} eq 'email' ) {
        $options{media} = {
            name => 'sendmode',
            options => [{
                text => $locale->text('Attachment'),
                value => 'attachment'}, {
                text => $locale->text('In-line'),
                value => 'inline'}
                ]};
        $options{media}{default_values} = 'attachment' if $form->{SM}{attachment};
        $options{media}{default_values} = 'inline' if $form->{SM}{inline};
    } else {
        $options{media} = {
            name => 'media',
            default_values => $form->{media},
            options => [{
                text => $locale->text('Screen'),
                value => 'screen'}
                ]};
        if (   %{LedgerSMB::Sysconfig::printer}
            && ${LedgerSMB::Sysconfig::latex} )
        {
            for ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
                push @{$options{media}{options}}, {text => $_, value => $_};
            }
        }
    }

    $options{format} = {
        name => 'format',
        default_values => $form->{selectformat},
        options => [{text => 'HTML', value => 'html'},
                    {text => 'CSV', value => 'csv'} ],
        };
    if ( ${LedgerSMB::Sysconfig::latex} ) {
        push @{$options{format}{options}}, {
            text => $locale->text('Postscript'),
            value => 'postscript',
            };
        push @{$options{format}{options}}, {
            text => 'PDF',
            value => 'pdf',
            };
    }
    if ($form->{type} eq 'invoice'){
       push @{$options{format}{options}}, {
            text => '894.EDI',
            value => '894.edi',
            };
    }

    if (   %{LedgerSMB::Sysconfig::printer}
        && ${LedgerSMB::Sysconfig::latex}
        && $form->{media} ne 'email' )
    {
        $options{copies} = 1;
    }

    # $locale->text('Printed')
    # $locale->text('E-mailed')
    # $locale->text('Scheduled')

    $options{status} = (
        printed   => 'Printed',
        emailed   => 'E-mailed',
        recurring => 'Scheduled'
    );

    $options{groupby} = {};
    $options{groupby}{groupprojectnumber} = "checked" if $form->{groupprojectnumber};
    $options{groupby}{grouppartsgroup} = "checked" if $form->{grouppartsgroup};

    $options{sortby} = {};
    for (qw(runningnumber partnumber description bin)) {
        $options{sortby}{$_} = "checked" if $form->{sortby} eq $_;
    }

    \%options;
}

sub print_select { # Needed to print new printoptions output from non-template
                   # screens --CT
    my ($form, $select) = @_;
    my $name = $select->{name};
    my $id = $name;
    $id =~ s/\_/-/;
    print qq|<select data-dojo-type="dijit/form/Select" id="$id" name="$name" class="$select->{class}">\n|;
    for my $opt (@{$select->{options}}){
        print qq|<option value="$opt->{value}" |;
        if ($form->{$select->{name}} eq $opt->{value}){
            print qq|SELECTED="SELECTED"|;
        }
        print qq|>$opt->{text}</option>\n|;
    }
    print "</select>";
}
sub print {

  #  $logger->trace("setting fax from LedgerSMB::Company_Config::settings \$form->{formname}=$form->{formname} \$form->{fax}=$form->{fax}");


    # if this goes to the printer pass through
    my $old_form = undef;
    if ( $form->{media} !~ /(screen|email)/ ) {
        $form->error( $locale->text('Select txt, postscript or PDF!') )
          if ( $form->{format} !~ /(txt|postscript|pdf)/ );

        $old_form = new Form;
        for ( keys %$form ) { $old_form->{$_} = $form->{$_} }

    }
    &print_form($old_form);


}

sub print_form {
    my ($old_form) = @_;
    my $csettings = $LedgerSMB::Company_Config::settings;
    $form->{company} = $csettings->{company_name};
    $form->{businessnumber} = $csettings->{businessnumber};
    $form->{address} = $csettings->{company_address};
    $form->{tel} = $csettings->{company_phone};
    #$form->{myCompanyFax} = $csettings->{company_fax};#fax should be named myCompanyFax ?
    $form->{fax} = $csettings->{company_fax};
    my $inv = "inv";
    my $due = "due";
    my $class;

    my $numberfld = "sinumber";

    my $display_form =
      ( $form->{display_form} ) ? $form->{display_form} : "display_form";

    if ( $form->{formname} eq "invoice" ) {
        $form->{label} = $locale->text('Invoice');
    }
    if ( $form->{formname} eq 'sales_order' ) {
        $inv           = "ord";
        $due           = "req";
        $form->{label} = $locale->text('Sales Order');
        $numberfld     = "sonumber";
        $order         = 1;
    }
    if ( $form->{formname} eq 'work_order' ) {
        $inv           = "ord";
        $due           = "req";
        $form->{label} = $locale->text('Work Order');
        $numberfld     = "sonumber";
        $order         = 1;
    }
    if ( $form->{formname} eq 'packing_list' ) {

        # we use the same packing list as from an invoice
        $form->{label} = $locale->text('Packing List');

        if ( $form->{type} ne 'invoice' ) {
            $inv       = "ord";
            $due       = "req";
            $numberfld = "sonumber";
            $order     = 1;

            $filled = 0;
            for ( $i = 1 ; $i < $form->{rowcount} ; $i++ ) {
                if ( $form->{"ship_$i"} ) {
                    $filled = 1;
                    last;
                }
            }
            if ( !$filled ) {
                for ( 1 .. $form->{rowcount} ) {
                    $form->{"ship_$_"} = $form->{"qty_$_"};
                }
            }
        }
    }
    if ( $form->{formname} eq 'pick_list' ) {
        $form->{label} = $locale->text('Pick List');
        if ( $form->{type} ne 'invoice' ) {
            $inv       = "ord";
            $due       = "req";
            $order     = 1;
            $numberfld = "sonumber";
        }
    }
    if ( $form->{formname} eq 'purchase_order' ) {
        $inv           = "ord";
        $due           = "req";
        $form->{label} = $locale->text('Purchase Order');
        $numberfld     = "ponumber";
        $order         = 1;
    }
    if ( $form->{formname} eq 'bin_list' ) {
        $inv           = "ord";
        $due           = "req";
        $form->{label} = $locale->text('Bin List');
        $numberfld     = "ponumber";
        $order         = 1;
    }
    if ( $form->{formname} eq 'sales_quotation' ) {
        $inv           = "quo";
        $due           = "req";
        $form->{label} = $locale->text('Quotation');
        $numberfld     = "sqnumber";
        $order         = 1;
    }
    if ( $form->{formname} eq 'request_quotation' ) {
        $inv           = "quo";
        $due           = "req";
        $form->{label} = $locale->text('Quotation');
        $numberfld     = "rfqnumber";
        $order         = 1;
    }
    if (($form->{formname} eq 'envelope')
        or ($form->{formname} eq 'shipping_label')){

       $inv = undef;
    }

    if ($form->test_should_get_images){
        my $file = LedgerSMB::File->new();
        my @files;
        my $fc;
        if ($inv eq 'inv') {
           $fc = 1;
        } else {
           $fc = 2;
        }
        my @files = $file->get_for_template(
                {ref_key => $form->{id}, file_class => $fc}
        );
        my @main_files;
        my %parts_files;
        for my $f (@files){
            if ($f->{file_class} == 3) {
              $parts_files{$f->{ref_key}} = $f;
            } else {
               push @main_files, $f;
            }
        }
        $form->{file_list} = \@main_files;
        $form->{parts_files} = \%parts_files;
        $form->{file_path} = $file->file_path;
    }
    check_form(1);
    ++$form->{rowcount};

    $form->{"${inv}date"} = $form->{transdate};

    $form->isblank( "email", $locale->text('E-mail address missing!') )
      if ( $form->{media} eq 'email' );

    # $locale->text('Invoice Date missing!')
    # $locale->text('Packing List Date missing!')
    # $locale->text('Order Date missing!')
    # $locale->text('Quotation Date missing!')
    $form->isblank( "${inv}date",
                    $locale->maketext( $form->{label} . ' Date missing!' ) );

    # We used to increment the number but we no longer allow printing before
    # posting, so the safe thing to do is just to display an error.  --Chris T
    if ( !$form->{"${inv}number"} and $inv) {
        # $locale->text('Invoice Number missing!')
        # $locale->text('Packing List Number missing!')
        # $locale->text('Order Number missing!')
        # $locale->text('Quotation Number missing!')
        $form->error($locale->text('Reference Number Missing'));
    }

    &{"$form->{vc}_details"};

    my @vars = ();

    $form->{parts_id} = [];
    foreach $i ( 1 .. $form->{rowcount} ) {
        push @vars,
          (
            "partnumber_$i",    "description_$i",
            "projectnumber_$i", "partsgroup_$i",
            "serialnumber_$i",  "bin_$i",
            "unit_$i",          "notes_$i",
            "image_$i",         "id_$i"
          );
          push @{$form->{parts_id}}, $form->{"id_$i"};
    }
    for ( split / /, $form->{taxaccounts} ) { push @vars, "${_}_description" }

    $ARAP = ( $form->{vc} eq 'customer' ) ? "AR" : "AP";
    push @vars, $ARAP;

    # format payment dates
    for my $i ( 1 .. $form->{paidaccounts} - 1 ) {
        if ( exists $form->{longformat} ) {
            $form->{"datepaid_$i"} =
              $locale->date( \%myconfig, $form->{"datepaid_$i"},
                $form->{longformat} );
        }

        push @vars, "${ARAP}_paid_$i", "source_$i", "memo_$i";
    }

    $form->format_string(@vars);

    ( $form->{employee} ) = split /--/, $form->{employee};
    ( $form->{warehouse}, $form->{warehouse_id} ) = split /--/,
      $form->{warehouse};

    # this is a label for the subtotals
    $form->{groupsubtotaldescription} = $locale->text('Subtotal')
      if not exists $form->{groupsubtotaldescription};
    delete $form->{groupsubtotaldescription} if $form->{deletegroupsubtotal};

    $duedate = $form->{"${due}date"};

    # create the form variables
    if ($order) {
        OE->order_details( \%myconfig, $form );
    } elsif ($form->{formname} eq 'product_receipt'){
        @{$form->{number}} = map { $form->{"partnumber_$_"} }
            1 .. $form->{rowcount};
        @{$form->{item_description}} = map { $form->{"description_$_"} }
            1 .. $form->{rowcount};
        @{$form->{qty}} = map { $form->{"qty_$_"} }
            1 .. $form->{rowcount};
        @{$form->{unit}} = map { $form->{"unit_$_"} }
            1 .. $form->{rowcount};
        @{$form->{sellprice}} = map { $form->{"sellprice_$_"} }
            1 .. $form->{rowcount};
        @{$form->{discount}} = map { $form->{"discount_$_"} }
            1 .. $form->{rowcount};
        @{$form->{linetotal}} = map {
            $form->{"qty_$_"} * $form->{"sellprice_$_"}
         }
            1 .. $form->{rowcount} - 1;
        $form->{invtotal} = reduce { $a + $b } @{$form->{linetotal}};
    } else {
        IS->invoice_details( \%myconfig, $form );
    }
    if ( exists $form->{longformat} ) {
        $form->{"${due}date"} = $duedate;
        for ( "${inv}date", "${due}date", "shippingdate", "transdate" ) {
            $form->{$_} =
              $locale->date( \%myconfig, $form->{$_}, $form->{longformat} );
        }
    }
    @vars =
      qw(name address1 address2 city state zipcode country contact phone fax email);

    $shipto = 1;
    # if there is no shipto fill it in from billto
    $form->get_shipto($form->{locationid}) if $form->{locationid};
    foreach $item (@vars) {
        if ( $form->{"shipto$item"} ) {
            $shipto = 0;
            last;
        }
    }

    # $logger->trace("\$form->{formname}=$form->{formname} \$form->{fax}=$form->{fax} \$shipto=$shipto \$form->{shiptofax}=$form->{shiptofax}");
    if ($shipto) {
        if (   $form->{formname} eq 'purchase_order'
            || $form->{formname} eq 'request_quotation' )
        {
            $form->{shiptoname}     = $form->{company};
            $form->{shiptoaddress1} = $form->{address};
        }
        else {
            if ( $form->{formname} !~ /bin_list/ ) {
                for (@vars) {if($_ ne 'fax'){$form->{"shipto$_"}=$form->{$_}}} #fax contains myCompanyFax
            }
        }
    }

    # some of the stuff could have umlauts so we translate them
    push @vars,
      qw(contact shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptoemail shippingpoint shipvia notes intnotes employee warehouse);

    push @vars, ( "${inv}number", "${inv}date", "${due}date" );

    $form->{address} =~ s/\\n/\n/g;

    for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

    for (qw(notes intnotes)) { $form->{$_} =~ s/^\s+//g }

    # before we format replace <%var%>
    for (qw(notes intnotes message)) {
        $form->{$_} =~ s/<%(.*?)%>/$form->{$1}/g;
    }


    $form->{templates} = "$myconfig{templates}";
    $form->{IN}        = "$form->{formname}.$form->{format}";

    if ( $form->{format} =~ /(postscript|pdf)/ ) {
        $form->{IN} =~ s/$&$/tex/;
    }

    $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

    my %output_options;
    if ($form->{media} eq 'zip'){
        $form->{OUT}       = $form->{zipdir};
        $form->{printmode} = '>';
    } elsif ( $form->{media} !~ /(screen|zip|email)/ ) { # printing
        $form->{OUT}       = ${LedgerSMB::Sysconfig::printer}{ $form->{media} };
        $form->{printmode} = '|-';
        $form->{OUT} =~ s/<%(fax)%>/<%$form->{vc}$1%>/;
        $form->{OUT} =~ s/<%(.*?)%>/$form->{$1}/g;

        if ( $form->{printed} !~ /$form->{formname}/ ) {

            $form->{printed} .= " $form->{formname}";
            $form->{printed} =~ s/^ //;

            $form->update_status( \%myconfig, 1);
        }

        $old_form->{printed} = $form->{printed} if %$old_form;

    } elsif ( $form->{media} eq 'email' ) {
        $form->{subject} = qq|$form->{label} $form->{"${inv}number"}|
          unless $form->{subject};

        $form->{plainpaper} = 1;

        if ( $form->{emailed} !~ /$form->{formname}/ ) {
            $form->{emailed} .= " $form->{formname}";
            $form->{emailed} =~ s/^ //;

            # save status
            $form->update_status( \%myconfig, 1);
        }

        $now = scalar localtime;
        $cc  = $locale->text( 'Cc: [_1]', $form->{cc} ) . qq|\n| if $form->{cc};
        $bcc = $locale->text( 'Bcc: [_1]', $form->{bcc} ) . qq|\n|
          if $form->{bcc};

        $output_options{subject} = $form->{subject};
        $output_options{to} = $form->{email};
        $output_options{cc} = $form->{cc};
        $output_options{bcc} = $form->{bcc};
        $output_options{from} = $myconfig{email};
        $output_options{notify} = 1 if $form->{read_receipt};
    $output_options{message} = $form->{message};
    $output_options{filename} = $form->{formname} . '_'. $form->{"${inv}number"};
    $output_options{filename} .= '.'. $form->{format}; # assuming pdf or html

        if ( %$old_form ) {
            $old_form->{intnotes} = qq|$old_form->{intnotes}\n\n|
              if $old_form->{intnotes};
            $old_form->{intnotes} .=
                qq|[email]\n|
              . $locale->text( 'Date: [_1]', $now ) . qq|\n|
              . $locale->text( 'To: [_1]',   $form->{email} )
              . qq|\n${cc}${bcc}|
              . $locale->text( 'Subject: [_1]', $form->{subject} ) . qq|\n|;

            $old_form->{intnotes} .= qq|\n| . $locale->text('Message') . qq|: |;
            $old_form->{intnotes} .=
              ( $form->{message} ) ? $form->{message} : $locale->text('sent');

            $old_form->{message} = $form->{message};
            $old_form->{emailed} = $form->{emailed};

            $old_form->{format} = "postscript" if $myconfig{printer};
            $old_form->{media} = $myconfig{printer};

            $old_form->save_intnotes( \%myconfig, ($order) ? 'oe' : lc $ARAP );
        }

    } elsif ( $form->{media} eq 'queue' ) {
        %queued = split / /, $form->{queued};

        if ( $filename = $queued{ $form->{formname} } ) {
            $form->{queued} =~ s/$form->{formname} $filename//;
            unlink "${LedgerSMB::Sysconfig::spool}/$filename";
            $filename =~ s/\..*$//g;
        }
        else {
            $filename = time;
            $filename .= $$;
        }

        $filename .= ( $form->{format} eq 'postscript' ) ? '.ps' : '.pdf';
        $form->{OUT}       = "${LedgerSMB::Sysconfig::spool}/$filename";
        $form->{printmode} = '>';

        $form->{queued} .= " $form->{formname} $filename";
        $form->{queued} =~ s/^ //;

        # save status
        $form->update_status( \%myconfig, 1);

        $old_form->{queued} = $form->{queued};
    }

    $form->format_string( "email", "cc", "bcc" );

    $form->{fileid} = $form->{"${inv}number"};
    $form->{fileid} =~ s/(\s|\W)+//g;

    my $template = LedgerSMB::Template->new(
        user => \%myconfig,
        locale => $locale,
        template => $form->{'formname'},
        language => $form->{language_code},
        format => uc $form->{format},
        method => $form->{media},
        output_options => \%output_options,
    output_file => $form->{formname} . "-" . $form->{"${inv}number"},
        );
    $template->render($form);

    # if we got back here restore the previous form
    if ( %$old_form ) {

        $old_form->{"${inv}number"} = $form->{"${inv}number"};

        # restore and display form
        for ( keys %$old_form ) { $form->{$_} = $old_form->{$_} }
        delete $form->{pre};

        $form->{rowcount}--;

        for (qw(exchangerate creditlimit creditremaining)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        for $i ( 1 .. $form->{paidaccounts} ) {
            for (qw(paid exchangerate)) {
                $form->{"${_}_$i"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }
        }

        edit();
    }

}

sub customer_details {

    IS->customer_details( \%myconfig, \%$form );

}

sub vendor_details {

    IR->vendor_details( \%myconfig, \%$form );

}



sub ship_to {

    $title = $form->{title};
    $form->{title} = $locale->text('Ship to');

    for ( 1 .. $form->{paidaccounts} ) {
        $form->{"paid_$_"} =
          $form->parse_amount( \%myconfig, $form->{"paid_$_"} );
    }


   &{"$form->{vc}_details"};

   &list_locations_contacts();

   $number =
      ( $form->{vc} eq 'customer' )
      ? $locale->text('Customer Number')
      : $locale->text('Vendor Number');

    $nextsub =
      ( $form->{display_form} ) ? $form->{display_form} : "display_form";



    $form->header;


    print qq|
               <body class="lsmb $form->{dojo_theme}">

<form name="form" method="post" data-dojo-type="lsmb/lib/Form" action=$form->{script}>

<table width=100% cellspacing="0" cellpadding="0" border="0">
    <tr>
            <td>
               <table>
                <tr >
                      <th >
                      $form->{vc} Number:<td>$form->{"$form->{vc}number"}</td>
                      </th>
                      <th>  </th>
                       <th>
                        $form->{vc} Name:<td>$form->{name}</td>
                      </th>
                    </tr>
            </table>


            <table  cellspacing="0" cellpadding="0" border="0">
                  <tr>
                  <td valign="top">
                             <table width=70% >

                             <tr class=listheading> |
                                         . qq|<th class=listheading width=1% >
                                  |
                                        .    $locale->text(' ')
                                         . qq|</th>
                                   <th class=listheading width=5%>|
                                  .     $locale->text('Add line1')
                                  . qq|</th>
                                   <th class=listheading width=5%>|
                                  .    $locale->text('Add line2')
                                  . qq|</th>
                                   <th class=listheading width=1% >
                                  |
                                  .     $locale->text('Add line3 ')
                                        . qq|</th>
                                   <th class=listheading width=5%>|
                                  .     $locale->text('city')
                                  . qq|</th>
                                   <th class=listheading width=5%>|
                                  .    $locale->text('State')
                                  . qq|</th>
                                   <th class=listheading width=5%>|
                                  .     $locale->text('Zip Code')
                                  . qq|</th>
                                   <th class=listheading width=5%>|
                                  .     $locale->text('Country')
                                  . qq|
                           </tr>
                        |;

                           my $i;

                           for($i=1;$i<=$form->{totallocations};$i++)
                           {
                                                      my $checked = '';
                                                      $checked = 'CHECKED="CHECKED"' if $form->{location_id} == $form->{"shiptolocationid_$i"}
         or $form->{location_id} == $form->{"locationid_$i"};

                                print qq|
                           <tr>

                              <td><input type=radio data-dojo-type="dijit/form/RadioButton" name=shiptoradio value="$i"  $checked ondblclick="return uncheckRadio(this);"></td>
                              <input name=shiptolocationid_$i type="hidden" value="$form->{"shiptolocationid_$i"}" readonly>
                              <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress1_$i size=12 maxlength=64 id="ad1_$i" value="$form->{"shiptoaddress1_$i"}" readonly></td>
                              <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress2_$i size=12 maxlength=64 id="ad2_$i" value="$form->{"shiptoaddress2_$i"}" readonly></td>
                              <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress3_$i size=12 maxlength=64 id="ad2_$i" value="$form->{"shiptoaddress3_$i"}" readonly></td>
                              <td><input data-dojo-type="dijit/form/TextBox" name=shiptocity_$i size=8 maxlength=32 id="ci_$i" value="$form->{"shiptocity_$i"}" readonly></td>
                              <td><input data-dojo-type="dijit/form/TextBox" name=shiptostate_$i size=10 maxlength=32 id="st_$i" value="$form->{"shiptostate_$i"}" readonly></td>
                              <td><input data-dojo-type="dijit/form/TextBox" name=shiptozipcode_$i size=8 maxlength=10 id="zi_$i" value="$form->{"shiptozipcode_$i"}" readonly></td>
                              <td><input data-dojo-type="dijit/form/TextBox" name=shiptocountry_$i size=5 maxlength=32 id="co_$i" value="$form->{"shiptocountry_$i"}" readonly></td>

                             <tr>

                                |;

                             }
                            my $deletelocations=$i;


                              print qq|<input type=hidden name=nextsub value=$nextsub>|;

                             # delete shipto
                              for (qw(action nextsub)) { delete $form->{$_} }

                                  $form->{title} = $title;


                                    print qq|

                    </table>

                </td>
                <td>&nbsp;</td>
                <td valign="top" >
                      <table width=30%>
                             <tr class=listheading>
                                 <th>&nbsp</th>
                                 <th class=listheading width="20%">|
                                    . $locale->text('Type')
                                . qq|</th>
                                   <th class=listheading width="35%">|
                                . $locale->text('Contact')
                                . qq|</th>
                                  <th class="listheading" width="35%">|
                                . $locale->text('Description')
                                . qq|</th>
                            </tr>
                           <tr></tr>
                              |;

                           for($i=1;$i<=$form->{totalcontacts};$i++)
                           {
                        print qq|
                              <tr>
                                  <td>&nbsp</td>
                                  <td><input data-dojo-type="dijit/form/TextBox" name=shiptotype_$i size=5 maxlength=100 value="$form->{"shiptotype_$i"}" readonly></td>
                                  <td><input data-dojo-type="dijit/form/TextBox" name=shiptocontact_$i size=11 maxlength=100 value="$form->{"shiptocontact_$i"}" readonly></td>
                                  <td><input data-dojo-type="dijit/form/TextBox" name=shiptodescription_$i size=12 maxlength=100 value="$form->{"shiptodescription_$i"}" readonly></td>
                             </tr>    |;

                              }
                                 my $deletecontacts=$i;

                             print qq|
                      </table>
                 </td>
               </tr>

                </table>
                |;

                 my $country=&construct_countrys_types("country");

             my $contacttype=&construct_countrys_types("type");


              for(my $k=1;$k<$deletecontacts;$k++)
            {
                for (qq| type_$k contact_$k description_$k |)
                {
                delete $form->{"shipto$_"};
                }

               }

                 delete $form->{shiptoradiocontact};
               delete $form->{shiptoradio};

               for (qq| address1_new address2_new address3_new city_new state_new zipcode_new country_new type_new contact_new description_new|)
               {
                delete $form->{"shipto$_"};
               }



              for(my $k=1;$k<$deletelocations;$k++)
              {
                    for (qq| locationid_$k address1_$k address2_$k address3_$k city_$k state_$k zipcode_$k country_$k|)
                    {
                    delete $form->{"shipto$_"};
                    }

              }

              $form->hide_form;
              print qq|

              <hr valign="type" size=1 noshade >

              <table valign="top">
                <tr>
                     Others
                  </tr>
                </tr>
                      <td><input type=radio data-dojo-type="dijit/form/RadioButton" name=shiptoradio value="new" ondblclick="return uncheckRadio(this);"></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress1_new size=12 maxlength=64 value="$form->{shiptoaddress1_new}" ></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress2_new size=12 maxlength=64 value="$form->{shiptoaddress2_new}" ></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress3_new size=12 maxlength=64 value="$form->{shiptoaddress3_new}" ></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptocity_new size=8 maxlength=32 value="$form->{shiptocity_new}" ></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptostate_new size=10 maxlength=32 value="$form->{shiptostate_new}" ></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptozipcode_new size=8 maxlength=10 value="$form->{shiptozipcode_new}" ></td>
                      <td><select data-dojo-type="dijit/form/Select" name="shiptocountry_new">$country</select></td>

                      <td>&nbsp;</td>
                      <td><input type=radio data-dojo-type="dijit/form/RadioButton" name=shiptoradiocontact value="1" ondblclick="uncheckRadiocontact(this);" ></td>
                      <td><select data-dojo-type="dijit/form/Select" name="shiptotype_new">$contacttype</select></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptocontact_new size=10 maxlength=100 value="$form->{shiptocontact_new}" ></td>
                       <td><input data-dojo-type="dijit/form/TextBox" name=shiptodescription_new size=10 maxlength=100 value="$form->{shiptodescription_new}" ></td>

                 </tr>


              </table>
          </td>
     </tr>

</table>

<br>

|;



print qq|

<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="action" value="continuenew">|
. $locale->text('Use Shipto')
. qq|
</button>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="action" value="updatenew">|
. $locale->text('Add To List')
. qq|
</button>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="action" value="update">|.
$locale->text('Cancel')
.qq|</button>

</form>

</body>

</html>
|;

}



=pod

Author...Sadashiva

The list of functions would create the new location / uses existing locations , and sets the $form->{locationid}.

list_locations_contacts() would extracts all locations and sets into form parameter...

$form->{id} used to extract all locations and contacts(eca_to_location and eca_to_contact) and location

construct_countrys_types return the drop down list of the country/contact_class ; value= country_id/contract_class_id and display text= country name/contract class

createlocations called by update action... calling eca__location_save and eca__save_contact

setlocation_id called by continue action... just setting $form->{locationid} this is the final location id which is returned by shipto service



=cut



sub list_locations_contacts
{


        IS->list_locations_contacts( \%myconfig, \%$form );


}



sub construct_countrys_types
{

    my $retvalue="";

    if($_[0] eq "country")
    {

            $retvalue=IS->construct_countrys(\%$form);

     }
    elsif($_[0] eq "type")
    {

            $retvalue=IS->construct_types(\%$form);

    }
        return($retvalue);

}





sub createlocations
{
        my ($continue) = @_;

    my $loc_id_index=$form->{"shiptoradio"};

    my $index="locationid_".$loc_id_index;

    my $loc_id=$form->{$index};


    if($form->{shiptoradio} eq "new")
    {

         # required to create the new locations

         &validatelocation;

         $form->{location_id} = IS->createlocation($form);


    }

    if($form->{shiptoradiocontact}==1)
    {
         &validatecontact;
            IS->createcontact($form);
        }

    &ship_to unless $continue;



}


sub validatelocation
{

       my @Newlocation=("shiptoaddress1_new","shiptocity_new","shiptostate_new","shiptocountry_new");
        foreach(@Newlocation)
    {
        $form->error( $locale->text("Do not keep field empty [_1]", $_)) unless($form->{"$_"});
    }


}


sub validatecontact
{

       my @Newcontact=("shiptotype_new","shiptodescription_new","shiptocontact_new");
        foreach(@Newcontact)
    {
        $form->error( " Don not keep field empty $_") unless($form->{"$_"});
    }


}



sub setlocation_id
{

       if(!$form->{"shiptoradio"})
       {
        $form->error("Please select the location");
       }
       if($form->{"shiptoradio"} eq "new")
       {
                createlocations(1);
       }



       my $loc_id_index=$form->{"shiptoradio"};

       my $index="locationid_".$loc_id_index;

       $form->{"locationid"}=$form->{$index};


}
