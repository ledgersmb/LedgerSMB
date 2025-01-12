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

use LedgerSMB::IIAA;
use LedgerSMB::OE;
use LedgerSMB::Tax;
use LedgerSMB::Template;
use LedgerSMB::Legacy_Util;
use LedgerSMB::File;
use List::Util qw(max reduce);


require "old/bin/printer.pl";
# any custom scripts for this one
if ( -f "old/bin/custom/io.pl" ) {
    eval { require "old/bin/custom/io.pl"; };
}

# end of main

# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May')
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
    my $moneyplaces = $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    foreach my $i (1 .. $form->{rowcount}){
        local $decimalplaces = $form->{"precision_$i"};

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
            $tax //= LedgerSMB::PGNumber->from_db(0);
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
            $form->{taxbasis}{$_->account} += $linetotal;
        }
    }
}

sub approve {
    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    die 'No workflow found to approve' unless $wf;

    $wf->execute_action( 'approve' );
    my $query =
        ($form->{vc} eq 'customer')
        ? 'select invnumber from ar where id = ?'
        : 'select invnumber from ap where id = ?';
    my $sth = $form->{dbh}->prepare($query)
        or $form->dberror($query);
    $sth->execute( $form->{id} )
        or $form->dberror($query);
    ($form->{invnumber}) = $sth->fetchrow_array;
    $form->dberror($query) if $sth->err;
    edit();
}

sub display_row {
    my $readonly = ($form->{reversing} or $form->{approved}) ? 'readonly="readonly"' : '';
    my $numrows = shift;
    my $min_lines = $form->get_setting('min_empty') // 0;
    my $lsmb_module;
    my $desc_disabled = "";
    $desc_disabled = 'DISABLED="DISABLED"' if $form->{lock_description};
    if ($form->{vc} eq 'customer'){
        $lsmb_module = 'AR';
        $parts_list = 'sales';
    } elsif ($form->{vc} eq 'vendor'){
        $lsmb_module = 'AP';
        $parts_list = 'purchase';
    }

    # replace '' transdate with NULL
    $form->all_business_units( ($form->{transdate} or undef) ,
                              $form->{"$form->{vc}_id"},
                              $lsmb_module);
    @column_index = qw(deleteline runningnumber partnumber description qty);

    if ( $form->{type} eq "sales_order" ) {
        push @column_index, "ship";
        $column_data{ship} =
            qq|<th class="listheading ship" align=center width="auto">|
          . $locale->text('Ship')
            . qq|</th>|;
        $readonly = '';
    }
    if ( $form->{type} eq "purchase_order" ) {
        push @column_index, "ship";
        $column_data{ship} =
            qq|<th class="listheading ship" align=center width="auto">|
          . $locale->text('Recd')
          . qq|</th>|;
        $readonly = '';
    }

    for (qw(projectnumber partsgroup)) {
        $form->{"select$_"} = $form->unescape( $form->{"select$_"} )
          if $form->{"select$_"};
    }

    if ( ($form->{language_code} // '') ne ($form->{oldlanguage_code} // '') ) {

        # rebuild partsgroup
        $l{language_code} = $form->{language_code};
        $l{searchitems} = 'nolabor' if $form->{vc} eq 'customer';

        $form->get_partsgroup(\%l);
        if ( @{ $form->{all_partsgroup} } ) {
            $form->{selectpartsgroup} = "<option>\n";
            foreach my $ref ( @{ $form->{all_partsgroup} } ) {
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

    push @column_index, qw(unit onhand sellprice discount linetotal);
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

    $column_data{deleteline} = qq|<th class="listheading"></td>|;
    $column_data{runningnumber} =
      qq|<th class="listheading runningnumber" nowrap>| . $locale->text('Item') . qq|</th>|;
    $column_data{partnumber} =
      qq|<th class="listheading partnumber" nowrap>| . $locale->text('Number') . qq|</th>|;
    $column_data{description} =
        qq|<th class="listheading description" nowrap>|
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
      <table width=100% id="invoice-lines"
                        data-dojo-type="lsmb/InvoiceLines"
                        data-dojo-attach-point="lines">
<thead>
    <tr class=listheading>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
</thead>
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
    my $moneyplaces =
        $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    foreach my $i ( 1 .. max($numrows, $min_lines)) {
        next if $readonly and not $form->{"partnumber_$i"};

        $desc_disabled = '' if $i == $numrows;
        $dec = '';
        if ($form->{"sellprice_$i"}) {
            if ( $spc eq '.' ) {
                ( $null, $dec ) = split /\./, $form->{"sellprice_$i"};
            }
            else {
                ( $null, $dec ) = split /,/, $form->{"sellprice_$i"};
            }
        }
        $dec = length $dec;
        $decimalplaces = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;
        $form->{"precision_$i"} = $decimalplaces;

        # undo formatting
        for (qw(qty oldqty ship discount sellprice)) {
            $form->{"${_}_$i"} =
              $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
        }

        if ( $form->{"qty_$i"} != $form->{"oldqty_$i"} ) {

            # check pricematrix
            @a = split / /, $form->{"pricematrix_$i"};
            if ( scalar @a > 2 ) {
                foreach my $item (@a) {
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
            $column_data{description} = qq|<td class="description">$form->{"description_$i"} |
             . qq|<input type="hidden" name="description_$i"
                        value="$form->{"description_$i"}" /></td>|
        } elsif ($form->{"partnumber_$i"}) {
            $form->{"description_$i"} //= '';
            $column_data{description} =
                qq|<td class="description"><div data-dojo-type="dijit/form/Textarea"
                            id="description_$i" name="description_$i"
                            size=48 style="width: 100%;font:inherit !important"
                            $readonly >$form->{"description_$i"}</div></td>|;
        } else {
            $form->{"description_$i"} //= '';
            $column_data{description} =
                qq|<td class="description"><div data-dojo-type="lsmb/parts/PartDescription"
                            id="description_$i" name="description_$i"
                            $desc_disabled size=48
                            data-dojo-props="channel:'/invoice/part-select/$i',fetchProperties:{type:'$parts_list'}"
                            style="width: 100%"
                            $readonly >$form->{"description_$i"}</div></td>|;
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

        $form->{"${delvar}_$i"} //= '';
        $delivery = qq|
          <td colspan=2 nowrap>
             <b><label for="deliverydate_$i">${$delvar}</label></b>
             <input class="date" data-dojo-type="lsmb/DateTextBox" id="deliverydate_$i" name="deliverydate_$i" size=11 title="$myconfig{dateformat}" value="$form->{"${delvar}_$i"}" $readonly >
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
                   qq|<td><select data-dojo-type="dijit/form/Select" id="b_unit_$cls->{id}_$i" name="b_unit_$cls->{id}_$i" $readonly >
                           <option>&nbsp;</option>|;
                for my $bu (@{$form->{b_units}->{"$cls->{id}"}}){
                   my $selected = "";
                   if ($bu->{id} eq $form->{"b_unit_$cls->{id}_$i"}){
                       $selected = "selected='selected'";
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
          qq|<td class="runningnumber"><input data-dojo-attach-point="runningnumber" data-dojo-type="dijit/form/TextBox" id="runningnumber_$i" name="runningnumber_$i" size="3" value="$i" $readonly ></td>|;
        if ($form->{"partnumber_$i"}){
            $column_data{deleteline} = qq|
<td rowspan="2" valign="middle">|;
            if (not $form->{approved} and not $readonly) {
                $column_data{deleteline} .= qq|
<button data-dojo-type="dijit/form/Button"><span>X</span>
<script type="dojo/on" data-dojo-event="click">
require('dijit/registry').byId('invoice-lines').removeLine('line-$i');
</script>
</button>|;
            }
            $column_data{deleteline} .= q|</td>|;
            $column_data{partnumber} =
           qq|<td> $form->{"partnumber_$i"}
                 <input type="hidden" id="partnumber_$i" name="partnumber_$i"
                       value="$form->{"partnumber_$i"}" /></td>|;
        } else {
            $skunumber //= '';
            $form->{"partnumber_$i"} //= '';
            $column_data{deleteline} = '<td rowspan="2"></td>';
            $column_data{partnumber} =
qq|<td class="partnumber"><input data-dojo-type="lsmb/parts/PartSelector" data-dojo-props="required:false,channel: '/invoice/part-select/$i',fetchProperties:{type:'$parts_list'}" name="partnumber_$i" id="partnumber_$i" size=15 value="$form->{"partnumber_$i"}" style="width:100%"  $readonly>$skunumber</td>|;
        }
        $form->{"onhand_$i"} //= '';
        $column_data{qty} =
qq|<td align=right class="qty"><input data-dojo-type="dijit/form/TextBox" id="qty_$i" name="qty_$i" title="$form->{"onhand_$i"}" size="5" value="|
          . $form->format_amount( \%myconfig, $form->{"qty_$i"} )
          . qq|" $readonly ></td>|;
        $column_data{ship} =
            qq|<td align=right class="ship"><input data-dojo-type="dijit/form/TextBox" id="ship_$i" name="ship_$i" size="5" value="|
          . $form->format_amount( \%myconfig, $form->{"ship_$i"} )
          . qq|" $readonly ></td>|;
        $form->{"unit_$i"} //= '';
        $column_data{unit} =
          qq|<td class="unit"><input data-dojo-type="dijit/form/TextBox" id="unit_$i" name="unit_$i" size=5 value="$form->{"unit_$i"}" $readonly ></td>|;
        $column_data{sellprice} =
          qq|<td align=right class="sellprice"><input data-dojo-type="dijit/form/TextBox" id="sellprice_$i" name="sellprice_$i" size="9" value="|
          . $form->format_amount( \%myconfig, $form->{"sellprice_$i"},
            $form->{"precision_$i"} )
          . qq|" $readonly ></td>|;
        $column_data{discount} =
            qq|<td align=right class="discount"><input data-dojo-type="dijit/form/TextBox" id="discount_$i" name="discount_$i" size="3" value="|
          . $form->format_amount( \%myconfig, $form->{"discount_$i"} )
          . qq|" $readonly ></td>|;
        $column_data{linetotal} =
            qq|<td align=right class="linetotal">|
          . $form->format_amount( \%myconfig, $linetotal, $form->{_setting_decimal_places} )
          . qq|</td>|;
        $form->{"bin_$i"} //= '';
        $column_data{bin}    = qq|<td class="bin">$form->{"bin_$i"}</td>|;
        $column_data{onhand} = qq|<td class="onhand">|. $form->format_amount( \%myconfig, $form->{"onhand_$i"}) . qq|</td>|;
        $column_data{taxformcheck} = qq|<td class="taxform"><input type="checkbox" data-dojo-type="dijit/form/CheckBox" id="taxformcheck_$i" name="taxformcheck_$i" value="1" $taxchecked $readonly></td>|;
        print qq|
<tbody data-dojo-type="lsmb/InvoiceLine"
 id="line-$i">
        <tr valign=top>|;

        for (@column_index) {
            print "\n$column_data{$_}";
        }

        print qq|
<td style="display:none">
<input type=hidden name="oldqty_$i" value="$form->{"qty_$i"}">
|;

        for (
            qw(image orderitems_id id bin weight listprice lastcost taxaccounts pricematrix sku onhand assembly inventory_accno_id income_accno_id expense_accno_id invoice_id precision)
          )
        {
            $form->hide_form("${_}_$i");
        }

        print qq|
        </td></tr>
|;
        if ($form->{selectprojectnumber}) {
            $form->{selectprojectnumber} =~ s/ selected="selected"//;
            $form->{selectprojectnumber} =~
                s/(<option value="\Q$form->{"projectnumber_$i"}\E")/$1 selected="selected"/;
        }

        $project = '';
        $project = qq|
                <b>$projectnumber</b>
        <select data-dojo-type="dijit/form/Select" id="projectnumber-$i" name="projectnumber_$i" $readonly>$form->{selectprojectnumber}</select>
| if $form->{selectprojectnumber};

        if ( ( $rows = $form->numtextrows( $form->{"notes_$i"}, 36, 6 ) ) > 1 )
        {
            $form->{"notes_$i"} = $form->quote( $form->{"notes_$i"} ) // '';
            $notes =
qq|<td><textarea data-dojo-type="dijit/form/Textarea" id="notes_$i" name="notes_$i" rows=$rows cols=36 wrap=soft $readonly>$form->{"notes_$i"}</textarea></td>|;
        }
        else {
            $form->{"notes_$i"} = $form->quote( $form->{"notes_$i"} ) // '';
            $notes =
qq|<td><input data-dojo-type="dijit/form/TextBox" id="notes_$i" name="notes_$i" size=38 value="$form->{"notes_$i"}" $readonly></td>|;
        }

        $form->{"serialnumber_$i"} //= '';
        $serial = qq|
                <td colspan=6 nowrap><b>$serialnumber</b> <input data-dojo-type="dijit/form/TextBox" id="serialnumber_$i" name="serialnumber_$i" value="$form->{"serialnumber_$i"}" $readonly></td>|
          if $form->{type} !~ /_quotation/;

        if ( $i >= $numrows ) {
            $partsgroup = "";
            if ( $form->{selectpartsgroup} ) {
                $partsgroup = qq|
            <b>$group</b>
        <select data-dojo-type="dijit/form/Select" id="partsgroup-$i" name="partsgroup_$i" $readonly>$form->{selectpartsgroup}</select>
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
</tbody>
|;

        $skunumber = "";

        if ($form->{"taxaccounts_$i"}) {
            for ( split / /, $form->{"taxaccounts_$i"} ) {
                $form->{"${_}_base"} += $linetotal;
            }
        }

        $form->{invsubtotal} += $linetotal;
    }

    print qq|
      </table>|;

    print qq|

<input type=hidden name=oldcurrency value=$form->{currency}>

<input type=hidden name=selectpartsgroup value="|
      . ($form->escape( $form->{selectpartsgroup}, 1 )//'') . qq|">
<input type=hidden name=selectprojectnumber value="|
      . ($form->escape( $form->{selectprojectnumber}, 1 )//'') . qq|">


    </td>
  </tr>
|;

    $form->hide_form(qw(audittrail));
}

sub new_item {

    # change callback
    $form->{old_callback} = $form->escape( $form->{callback}, 1 );
    $form->{callback} =
      $form->escape( "$form->{script}?__action=display_form", 1 );

    # save all other form variables in a previousform variable
    if ( !$form->{previousform} ) {
        foreach my $key ( keys %$form ) {

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
<body class="lsmb">

<h4 class=error>| . $locale->text('Item not on file!') . qq|</h4>|;

    print qq|
<h4>| . $locale->text('What type of item is this?') . qq|</h4>

<form method="post" data-dojo-type="lsmb/Form" action="ic.pl">

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
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continue">|
          . $locale->text('Continue')
          . qq|</button>
</form>
|;

    print qq|
</body>
</html>
|;

    $form->finalize_request();

}

sub display_form {
    my ($want_return) = @_;
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

    if (defined $form->{item} && $form->{item} eq 'part' ) {

        # create makemodel rows
        &makemodel_row( ++$form->{makemodel_rows} );

        &vendor_row( ++$form->{vendor_rows} );

        $numrows    = ++$form->{customer_rows};
        $subroutine = "customer_row";
    }
    if (defined $form->{item} &&  $form->{item} eq 'assembly' ) {

        # create makemodel rows
        &makemodel_row( ++$form->{makemodel_rows} );

        $numrows    = ++$form->{customer_rows};
        $subroutine = "customer_row";
    }
    if (defined $form->{item} &&  $form->{item} eq 'service' ) {
        &vendor_row( ++$form->{vendor_rows} );

        $numrows    = ++$form->{customer_rows};
        $subroutine = "customer_row";
    }
    if (defined $form->{item} &&  $form->{item} eq 'labor' ) {
        $numrows = 0;
    }

    # create rows

    &{$subroutine}($numrows) if $numrows;

    $form->hide_form(qw|shiptolocationid|);

    &form_footer;
    $form->finalize_request unless $want_return;

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
        foreach my $i ( 1 .. $form->{makemodel_rows} ) {
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

        foreach my $i ( 1 .. ( $form->{assembly_rows} - 1 ) ) {
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

        foreach my $i ( 1 .. ( $form->{makemodel_rows} ) ) {
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
            foreach my $i ( 1 .. $form->{rowcount} ) {
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
    return if $form->{__action} =~ /(save|post)/ or $nodisplay;
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

    foreach my $i ( 1 .. $form->{rowcount} ) {
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
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
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

    foreach my $i ( 1 .. $form->{rowcount} - 1 ) {
        $form->isblank( "partnumber_$i",
            $locale->text( 'Number missing in Row [_1]', $i ) );
    }

}

sub purchase_order {

    my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
        ($form->{type} eq 'invoice') ? 'AR/AP' : 'Order/Quote',
        $form->{workflow_id}
        );

    $form->{title} = $locale->text('Add Purchase Order');
    $form->{vc}    = 'vendor';
    $form->{type}  = 'purchase_order';
    $buysell       = 'sell';

    &create_form;

    $wf->context->param( 'spawned_id'   => $form->{workflow_id} );
    $wf->context->param( 'spawned_type' => 'Order/Quote' );
    $wf->execute_action( 'purchase_order' );
}

sub sales_order {

    my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
        ($form->{type} eq 'invoice') ? 'AR/AP' : 'Order/Quote',
        $form->{workflow_id}
        );

    $form->{title} = $locale->text('Add Sales Order');
    $form->{vc}    = 'customer';
    $form->{type}  = 'sales_order';
    $buysell       = 'buy';

    &create_form;

    $wf->context->param( 'spawned_id'   => $form->{workflow_id} );
    $wf->context->param( 'spawned_type' => 'Order/Quote' );
    $wf->execute_action( 'sales_order' );
}

sub rfq {

    my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
        ($form->{type} eq 'invoice') ? 'AR/AP' : 'Order/Quote',
        $form->{workflow_id}
        );

    $form->{title} = $locale->text('Add Request for Quotation');
    $form->{vc}    = 'vendor';
    $form->{type}  = 'request_quotation';
    $buysell       = 'sell';

    &create_form;

    $wf->context->param( 'spawned_id'   => $form->{workflow_id} );
    $wf->context->param( 'spawned_type' => 'Order/Quote' );
    $wf->execute_action( 'rfq' );
}

sub quotation {

    my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
        ($form->{type} eq 'invoice') ? 'AR/AP' : 'Order/Quote',
        $form->{workflow_id}
        );

    $form->{title} = $locale->text('Add Quotation');
    $form->{vc}    = 'customer';
    $form->{type}  = 'sales_quotation';
    $buysell       = 'buy';

    &create_form;

    $wf->context->param( 'spawned_id'   => $form->{workflow_id} );
    $wf->context->param( 'spawned_type' => 'Order/Quote' );
    $wf->execute_action( 'quotation' );
}

sub create_form {

    for (qw(id workflow_id)) { delete $form->{$_} }

    $form->{script} = 'oe.pl';

    $form->{shipto} = 1;

    $form->{rowcount}-- if $form->{rowcount};
    $form->{rowcount} = 0 if !$form->{"$form->{vc}_id"};

    {
        local ($!, $@);
        my $do_ = "old/bin/$form->{script}";
        unless ( do $do_ ) {
            if ($! or $@) {
                print "Status: 500 Internal server error (io.pl)\n\n";
                warn "Failed to execute $do_ ($!): $@\n";
            }
        }
    };

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

    &prepare_order;
    OE->save( \%myconfig, $form );

    &display_form(1);

}

sub e_mail {
    my $old_form = $form;
    $form = Form->new;
    $form->{$_} = $old_form->{$_} for (
        qw/ __action type formname script format language_code vc dbh id /,
        grep { /^_/ } keys %$old_form
        );

    if ($form->{type} eq 'invoice') {
        &invoice_links;
        &prepare_invoice;
    }
    else {
        &order_links;
        &prepare_order;
    }

    $form->{$_} = $old_form->{$_} for (
        qw/ __action type formname script format language_code vc dbh id /,
        grep { /^_/ } keys %$old_form
        );
    $form->{media} = 'email';
    $form->{rowcount}++;
    &print_form;
}

sub print {
    my $saved_form = { %$form };
    $lang = $form->{language_code};

    if ($form->{type} eq 'invoice') {
        &invoice_links;
        &prepare_invoice( unquoted => 1 );
    }
    else {
        &order_links;
        &prepare_order( unquoted => 1 );
    }
    $form->{$_} = $saved_form->{$_} for (qw(language_code media formname));

    # if this goes to the printer pass through
    my $old_form = undef;
    if ( $form->{media} !~ /(screen|email)/ ) {
        $form->error( $locale->text('Select txt, postscript or PDF!') )
          if ( $form->{format} !~ /(txt|postscript|pdf)/ );
    }

    $old_form = Form->new;
        for ( keys %$form ) { $old_form->{$_} = $form->{$_} }

    $form->{rowcount}++;
    &print_form;
}

my %copy_settings = (
    company => 'company_name',
    businessnumber => 'businessnumber',
    address => 'company_address',
    tel => 'company_phone',
    fax => 'company_fax',
    );
sub print_form {
    my ($old_form) = @_;
    while (my ($key, $setting) = each %copy_settings ) {
        $form->{$key} = $form->get_setting($setting);
    }
    my $inv = "inv";
    my $due = "due";
    my $numberfld = "sinumber";

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

    $form->{parts_id} = [];
    foreach my $i ( 1 .. $form->{rowcount} ) {
          push @{$form->{parts_id}}, $form->{"id_$i"};
    }

    $ARAP = ( $form->{vc} eq 'customer' ) ? "AR" : "AP";

    # format payment dates
    foreach my $i ( 1 .. $form->{paidaccounts} - 1 ) {
        if ( exists $form->{longformat} ) {
            $form->{"datepaid_$i"} =
              $locale->date( \%myconfig, $form->{"datepaid_$i"},
                $form->{longformat} );
        }
    }

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
        $form->{discount} = []; # bug: discount is a number here??
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
    my @vars =
      qw(name attn address1 address2 city state zipcode country contact phone fax email);

    $shipto = 0;
    # if there is no shipto fill it in from billto
    $form->get_shipto($form->{shiptolocationid}) if $form->{shiptolocationid};
    foreach my $item (@vars) {
        if ($form->{"shipto$item"} ) {
            $shipto = 1;
            last;
        }
    }

    $form->{shipto} = $shipto;
    if (! $shipto) {
        if (   $form->{formname} eq 'purchase_order'
            || $form->{formname} eq 'request_quotation' ) {
            $form->{shiptoname}     = $form->{company};
            $form->{shiptoaddress1} = $form->{address};
        }
        else {
            if ( $form->{formname} !~ /bin_list/ ) {
                for (@vars) {
                    if($_ ne 'fax') {  #fax contains myCompanyFax
                        $form->{"shipto$_"} = $form->{$_}
                    }
                }
            }
        }
    }

    $form->{address} =~ s/\\n/\n/g;

    for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

    for (qw(notes intnotes)) { $form->{$_} =~ s/^\s+//g }

    # before we format replace <%var%>
    for (qw(notes intnotes message)) {
        $form->{$_} =~ s/<%(.*?)%>/$form->{$1}/g
            if $form->{$_};
    }


    $form->{IN}        = "$form->{formname}.$form->{format}";

    if ( $form->{format} =~ /(postscript|pdf)/ ) {
        $form->{IN} =~ s/$1$/tex/;
    }

    my %output_options;
    if ($form->{media} eq 'zip'){
        $form->{OUT} = $form->{zipdir};
        $form->{printmode} = '>';
    } elsif ( $form->{media} !~ /(screen|zip|email)/ ) { # printing
        $form->{OUT} = $form->{_wire}->get( 'printers' )->get( $form->{media} );
        $form->{OUT} =~ s/<%(fax)%>/<%$form->{vc}$1%>/;
        $form->{OUT} =~ s/<%(.*?)%>/$form->{$1}/g;
        $form->{printmode} = '|-';
    } elsif ( $form->{media} eq 'email' ) {
        $form->{plainpaper} = 1;
        $output_options{filename} = $form->{formname} . '-'. $form->{"${inv}number"};
        my $template =
            LedgerSMB::Template->new( # printed document
                user => \%myconfig,
                locale => $locale,
                template => $form->{'formname'},
                dbh => $form->{dbh},
                path => 'DB',
                language => $form->{language_code},
                output_options => \%output_options,
                filename => $form->{formname} . "-" . $form->{"${inv}number"},
                formatter_options => $form->formatter_options,
                format_plugin   =>
                   $form->{_wire}->get( 'output_formatter' )->get( uc($form->{format} ) ),
            );
        $template->render($form);

        my $wf_id;
        my $wf;
        my %expansions =
            $form->%{
                grep { defined $form->{$_} }
                     ( "${inv}total", "${due}date", qw(
    formname id

    businessnumber company tel fax address

    invnumber ordnumber quonumber exchangerate terms duedate taxincluded
    curr employee reverse ponumber crdate duedate transdate terms

    customernumber name address1 address2 city state zipcode country sic iban

    totalqty totalship totalweight totalparts totalservices totalweightship

    paid subtotal total

    shipto shiptoname shiptoattn shiptoaddress1 shiptoaddress2 shiptocity shiptostate
    shiptozipcode shiptocountry shiptocontact shiptophone shiptoemail
                       ))};
        my $body = $template->{output};
        utf8::encode($body) if utf8::is_utf8($body);  ## no critic
        my $email_data = {
            _transport    => $form->{_wire}->get( 'mail' )->{transport},
            immediateSend => $form->{immediate},
            expansions    => \%expansions,
            body          => $form->{message},
            from          => $form->get_setting( 'default_email_from' ),
            subject       => ($form->{subject}
                              // qq|$form->{label} $form->{"${inv}number"}|),
            _attachments   => [
                { content => $body,
                  mime_type => $template->{mimetype},
                  file_name => ($form->{formname} . '-'
                                . $form->{"${inv}number"} . '.'
                                . lc($form->{format})),
                } ],
        };
        my %map = (
            email   => 'to',
            cc      => 'cc',
            bcc     => 'bcc',
            );
        for my $type (qw/ email cc bcc /) {
            my @addresses;
            if ( my $default
                 = $form->get_setting( "default_email_$map{$type}" ) ) {
                 push @addresses, $default;
            }
            if ( $form->{$type} ) {
                push @addresses, $form->{$type};
            }
            $email_data->{$map{$type}} = join(', ', @addresses);
        }

        my $trans_wf;
        if ($order) {
            ($wf_id) =
                $form->{dbh}->selectrow_array(
                    q{select workflow_id from oe where id = ?},
                    {}, $form->{id});

            $trans_wf = $form->{_wire}->get('workflows')
                ->fetch_workflow( 'Order/Quote', $wf_id );
        }
        else {
            ($wf_id) =
                $form->{dbh}->selectrow_array(
                    q{select workflow_id from transactions where id = ?},
                    {}, $form->{id});

            $trans_wf = $form->{_wire}->get('workflows')
                ->fetch_workflow( 'AR/AP', $wf_id );
        }

        $trans_wf->context->param( '_email_data' => $email_data );
        $trans_wf->execute_action( 'e_mail' );
        my $id = $trans_wf->context->param( 'spawned_workflow' );
        if (not $form->{header}) {
            print "Location: email.pl?id=$id&__action=render&callback=$form->{script}%3F"
                . "id%3D$form->{id}%26__action%3Dedit\n";
            print "Status: 302 Found\n\n";
            $form->{header} = 1;
        }

        return;
    } elsif ( $form->{media} eq 'screen' ) {
        $output_options{filename} =
            $form->{formname} . '-'. $form->{"${inv}number"} .
            '.'. $form->{format}; # assuming pdf or htm
    }

    $form->{fileid} = $form->{"${inv}number"};
    $form->{fileid} =~ s/(\s|\W)+//g;

    my $template = LedgerSMB::Template->new( # printed document
        user => \%myconfig,
        locale => $locale,
        template => $form->{'formname'},
        dbh => $form->{dbh},
        path => 'DB',
        language => $form->{language_code},
        #@@@TODO the formatter options need to be based
        # on the recipient's preferences, not on the current user!
        formatter_options => $form->formatter_options(),
        output_options => \%output_options,
        filename => $form->{formname} . "-" . $form->{"${inv}number"},
        format_plugin   =>
            $form->{_wire}->get( 'output_formatter' )->get( uc($form->{format} ) ),
        );
    $template->render($form);
    LedgerSMB::Legacy_Util::output_template($template, $form,
                                            method => $form->{media});

    # if we got back here restore the previous form
    if ( %$old_form ) {

        $old_form->{"${inv}number"} = $form->{"${inv}number"};

        # restore and display form
        for ( keys %$old_form ) { $form->{$_} = $old_form->{$_} }

        $form->{rowcount}--;

        for (qw(exchangerate creditlimit creditremaining)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        for my $i ( 1 .. $form->{paidaccounts} ) {
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

    list_locations_contacts( \%myconfig, \%$form );

   $number =
      ( $form->{vc} eq 'customer' )
      ? $locale->text('Customer Number')
      : $locale->text('Vendor Number');

    $nextsub =
      ( $form->{display_form} ) ? $form->{display_form} : "display_form";



    $form->header;


    for (qw| address1_ address2_ address3_ city_ state_ zipcode_ country_ type_ contact_ description_|) {
        delete $form->{"shipto${_}new"};
    }
    my $country=&construct_countrys_types("country");
    my $contacttype=&construct_countrys_types("type");

    print qq|
               <body class="lsmb">

<form name="form" method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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
                             <table style="margin-top:1em">
                             <caption><b>| . $locale->text('Shipping Address') . qq|</b></caption>

                             <tr class=listheading>
                                <th class=listheading width=1% rowspan=2>&nbsp;</th>
                                <th class=listheading colspan=3 nowrap>|
                                . $locale->text('Address')
                                . qq|</th>
                                   <th class=listheading rowspan=2 width=5% nowrap>|
                                  .     $locale->text('City')
                                  . qq|</th>
                                   <th class=listheading rowspan=2 width=5% nowrap>|
                                  .    $locale->text('State')
                                  . qq|</th>
                                   <th class=listheading rowspan=2 width=5% nowrap>|
                                  .     $locale->text('Zipcode')
                                  . qq|</th>
                                   <th class=listheading rowspan=2 width=5% nowrap>|
                                  .     $locale->text('Country')
                                  . qq|
                             </tr>
                             <tr class=listheading>
                                   <th class=listheading width=5% nowrap>|
                                  .     $locale->text('Line 1')
                                  . qq|</th>
                                   <th class=listheading width=5% nowrap>|
                                  .    $locale->text('Line 2')
                                  . qq|</th>
                                   <th class=listheading width=1% nowrap>
                                  |
                                  .     $locale->text('Line 3')
                                        . qq|</th>
                           </tr>
                        |;


                           for ($i=1;$i<=$form->{totallocations};$i++)
                           {
                               my $checked = '';
                               $checked = 'CHECKED="CHECKED"'
                                   if ($form->{shiptolocationid}
                                       and ($form->{shiptolocationid} == $form->{"shiptolocationid_$i"}
                                            or $form->{shiptolocationid} == $form->{"locationid_$i"}));

                                print qq|
                           <tr>

                              <td><input type=radio data-dojo-type="dijit/form/RadioButton" name="shiptoradio" id="shiptoradio_$i" value="$i"  $checked >
                              <input name="shiptolocationid_$i" id="shiptolocationid_$i" type="hidden" value="$form->{"shiptolocationid_$i"}" readonly></td>
                              <td nowrap>$form->{"shiptoaddress1_$i"}</td>
                              <td nowrap>$form->{"shiptoaddress2_$i"}</td>
                              <td nowrap>$form->{"shiptoaddress3_$i"}</td>
                              <td nowrap>$form->{"shiptocity_$i"}</td>
                              <td nowrap>$form->{"shiptostate_$i"}</td>
                              <td nowrap>$form->{"shiptozipcode_$i"}</td>
                              <td nowrap>$form->{"shiptocountry_$i"}</td>
                             <tr>
                                |;

                             }
                            my $deletelocations=$i;


                              print qq|<input type=hidden name=nextsub value=$nextsub>|;

                             # delete shipto
                              for (qw(__action nextsub)) { delete $form->{$_} }

                                  $form->{title} = $title;


                                    print qq|
                </tr>
                <tr>
                      <td><input type=radio data-dojo-type="dijit/form/RadioButton" name=shiptoradio id="shiptoradio-new" value="new"></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress1_new size=12 maxlength=64 value="$form->{shiptoaddress1_new}"></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress2_new size=12 maxlength=64 value="$form->{shiptoaddress2_new}"></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptoaddress3_new size=12 maxlength=64 value="$form->{shiptoaddress3_new}"></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptocity_new size=8 maxlength=32 value="$form->{shiptocity_new}"></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptostate_new size=10 maxlength=32 value="$form->{shiptostate_new}"></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptozipcode_new size=8 maxlength=10 value="$form->{shiptozipcode_new}"></td>
                      <td><select data-dojo-type="dijit/form/Select" id="shiptocountry-new" name="shiptocountry_new">$country</select></td>

                 </tr>

                    </table>

                </td>
                </tr>
                <tr>
                <td valign="top" >
                      <table style="margin-top:1em">
                        <caption><b>| . $locale->text('Shipping Attn') . qq|</b></caption>
                             <tr class=listheading>
                                 <th>&nbsp</th>
                                 <th class=listheading width="20%">|
                                    . $locale->text('Type')
                                . qq|</th>
                                  <th class="listheading" width="35%">|
                                . $locale->text('Description')
                                . qq|</th>
                                   <th class=listheading width="35%">|
                                . $locale->text('Contact')
                                . qq|</th>
                            </tr>
                              <tr>
                                  <td><input type="radio" data-dojo-type="dijit/form/RadioButton" name="shiptoradiocontact" id="shiptoradiocontact_current" value="" CHECKED="CHECKED"></td>
                                  <td colspan=2 nowrap>| . $locale->text('Current Attn') . qq|</td>
                                  <td nowrap>$form->{shiptoattn}</td>
                             </tr>    |;

                           for($i=1;$i<=$form->{totalcontacts};$i++)
                           {
                               my $checked = '';
                        print qq|
                              <tr>
                                  <td><input type="radio" data-dojo-type="dijit/form/RadioButton" name="shiptoradiocontact" id="shiptoradiocontact_$i" value="$form->{"shiptocontact_$i"}"></td>
                                  <td nowrap>$form->{"shiptotype_$i"}</td>
                                  <td nowrap>$form->{"shiptodescription_$i"}</td>
                                  <td nowrap>$form->{"shiptocontact_$i"}</td>
                             </tr>    |;

                              }
                                 my $deletecontacts=$i;

                             print qq|
                   <tr>
                      <td><input type=radio data-dojo-type="dijit/form/RadioButton" name=shiptoradiocontact id="shiptoradiocontact-new" value="new"></td>
                      <td><select data-dojo-type="dijit/form/Select" id="shiptotype-new" name="shiptotype_new">$contacttype</select></td>
                      <td><input data-dojo-type="dijit/form/TextBox" name=shiptocontact_new size=10 maxlength=100 value="$form->{shiptocontact_new}" ></td>
                       <td><input data-dojo-type="dijit/form/TextBox" name=shiptodescription_new size=10 maxlength=100 value="$form->{shiptodescription_new}" ></td>
                       </tr>
                      </table>
                 </td>
               </tr>

                </table>
                |;

              for(my $k=1;$k<$deletecontacts;$k++)
            {
                for (qw| type_ contact_ description_ |)
                {
                delete $form->{"shipto$_$k"};
                }

               }

                 delete $form->{shiptoradiocontact};
               delete $form->{shiptoradio};


              for(my $k=1;$k<$deletelocations;$k++)
              {
                    for (qw| locationid_ address1_ address2_ address3_ city_ state_ zipcode_ country_|)
                    {
                    delete $form->{"shipto$_$k"};
                    }

              }

              $form->hide_form;
              print qq|

              </table>
          </td>
     </tr>

</table>

<br>

|;



print qq|

<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continuenew">|
. $locale->text('Use Shipto')
. qq|
</button>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="updatenew">|
. $locale->text('Add To List')
. qq|
</button>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="update">|.
$locale->text('Cancel')
.qq|</button>

</form>

</body>

</html>
|;

}



=pod

Author...Sadashiva

The list of functions would create the new location / uses existing locations , and sets the $form->{shiptolocationid}.

list_locations_contacts() would extracts all locations and sets into form parameter...

$form->{id} used to extract all locations and contacts(eca_to_location and eca_to_contact) and location

construct_countrys_types return the drop down list of the country/contact_class ; value= country_id/contract_class_id and display text= country name/contract class

createlocations called by update action... calling eca__location_save and eca__save_contact

setlocation_id called by continue action... just setting $form->{shiptolocationid} this is the final location id which is returned by shipto service



=cut


sub construct_countrys_types
{

    my $retvalue="";

    if($_[0] eq "country")
    {

            $retvalue=construct_countrys(\%$form);

     }
    elsif($_[0] eq "type")
    {

            $retvalue=construct_types(\%$form);

    }
        return($retvalue);

}





sub createlocations
{
        my ($continue) = @_;

    my $loc_id_index=$form->{"shiptoradio"};

    my $index="shiptolocationid_".$loc_id_index;

    my $loc_id=$form->{$index};


    if($form->{shiptoradio} eq "new")
    {

         # required to create the new locations

         &validatelocation;

         $form->{shiptolocationid} = IIAA->createlocation($form);


    }

    if($form->{shiptoradiocontact} eq 'new')
    {
         &validatecontact;
         IIAA->createcontact($form);
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

       my $index="shiptolocationid_".$loc_id_index;

       $form->{"shiptolocationid"}=$form->{$index};


       $form->{"shiptoattn"} = $form->{shiptoradiocontact} if $form->{shiptoradiocontact};

}


sub list_locations_contacts
{

    my ( $myconfig, $form ) = @_;



    my $dbh = $form->{dbh};

    # get rest for the customer
    my $query = qq|
WITH eca AS (
  select * from entity_credit_account
   where id = ?
)
select id as shiptolocationid,
       line_one as shiptoaddress1,
       line_two as shiptoaddress2,
       line_three as shiptoaddress3,
       city as shiptocity,
       state as shiptostate,
       mail_code as shiptozipcode,
       country as shiptocountry
  from (
    select (eca__list_locations(id)).*
      FROM eca
     UNION
    SELECT (entity__list_locations(entity_id)).*
      FROM eca
  ) l
 WHERE location_class = 3;
          |;



    my $sth = $dbh->prepare($query);

    $sth->execute( $form->{customer_id} // $form->{vendor_id} ) || $form->dberror($query);

    my $i=0;

    while($ref = $sth->fetchrow_hashref(NAME_lc))
    {
           $i++;
           for ( keys %$ref )
       {
         $form->{"$_\_$i"} = $ref->{$_};
       }

    }

    $form->{totallocations}=$i;

    $sth->finish();






    $query = qq|
select c.class as shiptotype,
       ec.contact as shiptocontact,
       ec.description as shiptodescription
  from eca_to_contact ec
  join contact_class c
       on (c.id=ec.contact_class_id)
 where ec.credit_id = ?;
          |;



    $sth = $dbh->prepare($query);

    $sth->execute( $form->{customer_id} ) || $form->dberror($query);

    $i=0;

    while($ref = $sth->fetchrow_hashref(NAME_lc))
    {
           $i++;
           for ( keys %$ref )
       {
         $form->{"$_\_$i"} = $ref->{$_};
       }

    }

    $form->{totalcontacts}=$i;

    $sth->finish();

    # for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
}


sub construct_countrys
{


    my ( $form ) = @_;

    my $dbh = $form->{dbh};


    my $query = qq|
            select id,name  from location_list_country();
          |;



    my $sth = $dbh->prepare($query);

    $sth->execute() || $form->dberror($query);

    my $returnvalue=qq|<option value=""></option>|;

    while(my $ref = $sth->fetchrow_hashref(NAME_lc))
    {

      $returnvalue.=qq|<option value="$ref->{id} ">$ref->{name}</option>|;

    }


   $sth->finish();

   return($returnvalue);

}


sub construct_types
{


    my ( $form ) = @_;

    my $dbh = $form->{dbh};


    my $query = qq|
            select id,class from contact_class;
          |;



    my $sth = $dbh->prepare($query);

    $sth->execute() || $form->dberror($query);

    my $returnvalue=qq|<option value=""></option>|;

    while(my $ref = $sth->fetchrow_hashref(NAME_lc))
    {

      $returnvalue.=qq|<option value="$ref->{id} ">|.$ref->{class}.qq|</option>|;  ## no critic (ProhibitMagicNumbers) sniff

    }


   $sth->finish();

   return($returnvalue);

}


1;
