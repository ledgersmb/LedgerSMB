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
# Inventory received module
#
#======================================================================

package lsmb_legacy;
use List::Util qw(min max);
use LedgerSMB::IR;
use LedgerSMB::IS;
use LedgerSMB::PE;
use LedgerSMB::Tax;
use LedgerSMB::Setting;

require 'bin/bridge.pl'; # needed for voucher dispatches
require "bin/io.pl";
require "bin/arap.pl";

1;

# end of main
sub copy_to_new{
    delete $form->{id};
    delete $form->{invnumber};
    $form->{paidaccounts} = 1;
    if ($form->{paid_1}){
        delete $form->{paid_1};
    }
    update();
}

sub edit_and_save {
    use LedgerSMB::DBObject::Draft;
    use LedgerSMB;
    my $lsmb = LedgerSMB->new();
    $lsmb->merge($form);
    my $draft = LedgerSMB::DBObject::Draft->new({base => $lsmb});
    $draft->delete();
    delete $form->{id};
    IR->post_invoice( \%myconfig, \%$form );
    edit();
}

sub approve {
    use LedgerSMB::DBObject::Draft;
    use LedgerSMB;
    my $lsmb = LedgerSMB->new();
    $lsmb->merge($form);

    my $draft = LedgerSMB::DBObject::Draft->new({base => $lsmb});

    $draft->approve();

    if ($form->{callback}){
        print "Location: $form->{callback}\n";
        print "Status: 302 Found\n\n";
        print qq|<html><body class="lsmb $form->{dojo_theme}">|;
        my $url = $form->{callback};
        print qq|If you are not redirected automatically, click <a href="$url">|
                . qq|here</a>.</body></html>|;

    } else {
        $form->info($locale->text('Draft Posted'));
    }
}

sub new_screen {
    use LedgerSMB::Form;
    my @reqprops = qw(ARAP vc dbh stylesheet type);
    $oldform = $form;
    $form = {};
    bless $form, Form;
    for (@reqprops){
        $form->{$_} = $oldform->{$_};
    }
    &add();
}


sub add {
    if ($form->{type} eq 'debit_invoice'){
        $form->{title} = $locale->text('Add Debit Invoice');
        $form->{subtype} = 'debit_invoice';
        $form->{reverse} = 1;
    } elsif ($form->{type} eq 'vendor_return') {
        $form->{title} = $locale->text('Add Vendor Return');
        $form->{subtype} = 'debit_invoice';
        $form->{reverse} = 1;
        $form->{is_return} = 1;
    } else {
        $form->{title} = $locale->text('Add Vendor Invoice');
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
    if ($form->{is_return}){
        $form->{title} = $locale->text('Edit Vendor Return');
        $form->{subtype} = 'debit_invoice';
    } elsif ($form->{reverse}) {
        $form->{title} = $locale->text('Add Debit Invoice');
        $form->{subtype} = 'debit_invoice';
    } else {
        $form->{title} = $locale->text('Edit Vendor Invoice');
    }


    &invoice_links;
    &prepare_invoice;
    &display_form;

}

sub invoice_links {

    $form->{vc}   = "vendor";
    $form->{type} = "invoice";

    # create links
    $form->create_links( module => "AP",
             myconfig => \%myconfig,
             vc => "vendor",
             billing => 0,
             job => 1 );

    if (!$form->{currencies}){
        $form->error($locale->text(
              'No currencies defined.  Please set these up under System/Defaults.'
                            ));
    }


    if ( @{ $form->{all_vendor} } ) {
        unless ( $form->{vendor_id} ) {
            $form->{vendor_id} = $form->{all_vendor}->[0]->{id};
        }
    }

    AA->get_name( \%myconfig, \%$form );
    delete $form->{notes};
    IR->retrieve_invoice( \%myconfig, \%$form );

    $form->{oldlanguage_code} = $form->{language_code};

    $form->get_partsgroup( \%myconfig,
        { language_code => $form->{language_code} } );

    if ( $form->{all_department} && @{ $form->{all_department} } ) {
        $form->{department} = "$form->{department}--$form->{department_id}"
          if $form->{department_id};
     }

    $form->{oldvendor}    = "$form->{vendor}--$form->{vendor_id}";
    $form->{oldtransdate} = $form->{transdate};

    # forex
    $form->{forex} = $form->{exchangerate};
    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

    foreach $key ( keys %{ $form->{AP_links} } ) {

        $form->{"select$key"} = "";
        foreach $ref ( @{ $form->{AP_links}{$key} } ) {
            $form->{"select$key"} .=
              "<option value=\"$ref->{accno}--$ref->{description}\">$ref->{accno}--$ref->{description}</option>\n";
        }

        if ( $key eq "AP_paid" ) {
            for $i ( 1 .. scalar @{ $form->{acc_trans}{$key} } ) {
                $form->{"AP_paid_$i"} =
"$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";

                # reverse paid
                $form->{"paid_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{amount};
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

    $form->{paidaccounts} = 1 unless ( exists $form->{paidaccounts} );

    $form->{AP} = $form->{AP_1} unless $form->{id};

    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );

    if ( !$form->{readonly} ) {
        $form->{readonly} = 1 if $myconfig{acs} =~ /AP--Vendor Invoice/;
    }

     $form->generate_selects(\%myconfig);

}

sub prepare_invoice {

    $form->{type} = "invoice";
    $form->{currency} =~ s/ //g;
    $form->{oldcurrency} = $form->{currency};

    if ( $form->{id} ) {

        for (qw(invnumber ordnumber ponumber quonumber)) {
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

            my $moneyplaces = LedgerSMB::Setting->get('decimal_places');
            my ($dec) = ($form->{"sellprice_$i"} =~/\.(\d*)/);
            $dec = length $dec;
            $form->{"precision_$i"} ||= $dec;
            $decimalplaces = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;

            $form->{"sellprice_$i"} =
              $form->format_amount( \%myconfig, $form->{"sellprice_$i"},
                $decimalplaces );
            $form->{"qty_$i"} =
              $form->format_amount( \%myconfig, $form->{"qty_$i"} );
            $form->{"oldqty_$i"} = $form->{"qty_$i"};

        $form->{"taxformcheck_$i"}=1 if(IR->get_taxcheck($form,$form->{"invoice_id_$i"},$form->{dbh}));


            for (qw(partnumber sku description unit)) {
                $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
            }

            $form->{rowcount} = $i;
        }
    }

}

sub form_header {

    $form->{nextsub} = 'update';

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    # set option selected
    for (qw(AP currency)) {
        $form->{"select$_"} =~ s/ selected="selected"//;
        $form->{"select$_"} =~
          s/(option value="\Q$form->{$_}\E")/$1 selected="selected"/;
    }

    for (qw(vendor department)) {
        $form->{"select$_"} = $form->unescape( $form->{"select$_"} );
        $form->{"select$_"} =~ s/ selected="selected"//;
        $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
    }

    if ( $form->{selectlanguage} ) {
        $lang = qq|
          <tr>
        <th align=right nowrap>| . $locale->text('Language') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" name=language_code>$form->{selectlanguage}</select></td>
          </tr>
|;

    }

    $form->{exchangerate} =
      $form->format_amount( \%myconfig, $form->{exchangerate} );

    $exchangerate = qq|<tr>|;
    $exchangerate .= qq|
                <th align=right nowrap>| . $locale->text('Currency') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" name=currency>$form->{selectcurrency}</select></td> |
      if $form->{defaultcurrency};

    if (   $form->{defaultcurrency}
        && $form->{currency} ne $form->{defaultcurrency} )
    {
        $exchangerate .= qq|
                <th align=right nowrap>|
              . $locale->text('Exchange Rate')
              . qq|</th>
                <td><input data-dojo-type="dijit/form/TextBox" name=exchangerate size=10 value=$form->{exchangerate}></td>
|;
    }
    $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
</tr>
|;

    if ( $form->{selectvendor} ) {
        $vendor = qq|<select data-dojo-type="dijit/form/Select" name=vendor>$form->{selectvendor}</select>
                 <input type=hidden name="selectvendor" value="|
          . $form->escape( $form->{selectvendor}, 1 ) . qq|">|;
    }
    else {
        $vendor = qq|<input data-dojo-type="dijit/form/TextBox" name=vendor value="$form->{vendor}" size=35>
                 <a href="contact.pl?action=add&entity_class=1"
                  target="new" id="new-contact">[|
                 .  $locale->text('New') . qq|]</a>|;
    }

    $department = qq|
              <tr>
          <th align="right" nowrap>| . $locale->text('Department') . qq|</th>
          <td colspan=3><select data-dojo-type="dijit/form/Select" name=department>$form->{selectdepartment}</select>
          <input type=hidden name=selectdepartment value="|
      . $form->escape( $form->{selectdepartment}, 1 ) . qq|">
          </td>
        </tr>
| if $form->{selectdepartment};

    $n = ( $form->{creditremaining} < 0 ) ? "0" : "1";

    $i     = $form->{rowcount} + 1;
    $focus = "partnumber_$i";

    $form->header;

    print qq|
<body class="lsmb $form->{dojo_theme}" onLoad="document.forms[0].${focus}.focus()" />
| . $form->open_status_div . qq|
<script>
function on_return_submit(event){
  var kc;
  if (window.event){
    kc = window.event.keyCode;
  } else {
    kc = event.which;
  }
  if (kc == '13' && document.activeElement.tagName != 'TEXTAREA'){
        document.forms[0].submit();
  }
}
</script>
<form method="post" data-dojo-type="lsmb/lib/Form" action="$form->{script}" onkeypress="on_return_submit(event)">
|;
    if ($form->{notice}){
         print qq|$form->{notice}<br/>|;
    }
    $form->{vc} = "vendor";
    $form->{nextsub} = 'update';
    $form->hide_form(
        qw(id title vc type terms creditlimit creditremaining closedto locked
           shipped oldtransdate recurring reverse batch_id subtype form_id
           separate_duties nextsub default_reportable address city is_return
           cash_accno)
    );

    print qq|
<table width=100%>
  <tr class=listtop>
    <th>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
      <td>
        <table>
          <tr>
        <th align=right nowrap>| . $locale->text('Vendor') . qq|</th>
        <td colspan=3>$vendor</td>

        <input type=hidden name=vendor_id value=$form->{vendor_id}>
        <input type=hidden name=oldvendor value="$form->{oldvendor}">

          </tr>
          <tr>
            <td></td>
        <td colspan=3>
          <table>
            <tr> |;
      if (LedgerSMB::Setting->get('show_creditlimit')){
          print qq|
              <th nowrap>| . $locale->text('Credit Limit') . qq|</th>
              <td>|
      . $form->format_amount( \%myconfig, $form->{creditlimit}, 0, "0" )
      . qq|</td>
              <td width=20%></td>
              <th nowrap>| . $locale->text('Remaining') . qq|</th>
              <td class="plus$n" nowrap>|
      . $form->format_amount( \%myconfig, $form->{creditremaining}, 0, "0" )
      . qq|</td>|;
      } else { print "<td>&nbsp;</td>" }
          print qq|
            </tr>|;
        if ($form->{entity_control_code}){
                    $form->hide_form(qw(entity_control_code meta_number));
            print qq|
            <tr>
        <th align="right" nowrap>| .
            $locale->text('Entity Code') . qq|</th>
        <td colspan="2" nowrap>$form->{entity_control_code}</td>
        <th align="right" nowrap>| .
            $locale->text('Account') . qq|</th>
        <td colspan=3>$form->{meta_number}</td>
          </tr>
              <tr>
                <th align="right" nowrap>| .
                        $locale->text('Tax ID'). qq|</th>
                <td colspan=3>$form->{tax_id}</td>
              </tr>
              <tr class="address_row">
                <th align="right" nowrap>| .
                        $locale->text('Address'). qq|</th>
                <td colspan=3>$form->{address}, $form->{city}</td>
              </tr>
        |;
           }
    print qq|
          </table>
        </td>
          <tr>
        <th align=right>| . $locale->text('Record in') . qq|</th>
        <td colspan=3><select data-dojo-type="dijit/form/Select" name=AP>$form->{selectAP}</select></td>
          </tr>
              $department
          $exchangerate
            <tr>
               <th align="right" nowrap>| . $locale->text('Description') . qq|
               </th>
               <td><input data-dojo-type="dijit/form/TextBox" type="text" name="description" size="40"
                   value="| . $form->{description} . qq|" /></td>
            </tr>
        </table>
      </td>
      <td align=right>
        <table>
          <tr>
        <th align=right nowrap>| . $locale->text('Invoice Number') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=invnumber size=20 value="$form->{invnumber}">
                   | .  $form->sequence_dropdown('vinumber') . qq|</td>
          </tr>
          <tr>
        <th align=right nowrap>| . $locale->text('Order Number') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=ordnumber size=20 value="$form->{ordnumber}"></td>
<input type=hidden name=quonumber value="$form->{quonumber}">
          </tr>
              <tr>
                <th align=right nowrap>| . $locale->text('Invoice Created') . qq|</th>
                <td><input class="date" data-dojo-type="lsmb/lib/DateTextBox" name=crdate size=11 title="$myconfig{dateformat}" value=$form->{crdate}></td>
              </tr>
          <tr>
        <th align=right nowrap>| . $locale->text('Invoice Date') . qq|</th>
        <td><input class="date" data-dojo-type="lsmb/lib/DateTextBox" name=transdate size=11 title="$myconfig{dateformat}" value="$form->{transdate}" id="transdate"></td>
          </tr>
          <tr>
        <th align=right nowrap>| . $locale->text('Due Date') . qq|</th>
        <td><input class="date" data-dojo-type="lsmb/lib/DateTextBox" name=duedate size=11 title="$myconfig{dateformat}" value="$form->{duedate}" id="duedate"></td>
          </tr>
          <tr>
        <th align=right nowrap>| . $locale->text('PO Number') . qq|</th>
        <td><input data-dojo-type="dijit/form/TextBox" name=ponumber size=20 value="$form->{ponumber}"></td>
          </tr>
          $lang
        </table>
      </td>
    </tr>
      </table>
    </td>
  </tr>
|;

    if ( !$form->{readonly} ) {

        if ($form->{on_hold}) {
            $hold_button_text = $locale->text('Off Hold');
        } else {
            $hold_button_text = $locale->text('On Hold');
        }

        print qq|<tr><td>|;
        %button = (
            'update' =>
              { ndx => 1, key => 'U', value => $locale->text('Update') },
            'copy_to_new' => # Shares an index with copy because one or the other
                             # must be deleted.  One can only either copy or
                             # update, not both. --CT
              { ndx => 1, key => 'C', value => $locale->text('Copy to New') },
            'print' =>
              { ndx => 2, key => 'P', value => $locale->text('Print') },
            'post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
            'post_as_new' =>
              { ndx => 5, key => 'N', value => $locale->text('Post as new') },
            'purchase_order' => {
                ndx   => 6,
                key   => 'L',
                value => $locale->text('Purchase Order')
            },
            'schedule' =>
              { ndx => 7, key => 'H', value => $locale->text('Schedule') },
            'on_hold' =>
              { ndx => 9, key=> 'O', value => $hold_button_text },
        'save_info'  =>
                { ndx => 10, key => 'I', value => $locale->text('Save Info') },
            'new_screen' => # Create a blank ar/ap invoice.
             { ndx => 11, key=> 'N', value => $locale->text('New') }
        );

        if ($form->{separate_duties} or $form->{batch_id}){
           $button{'post'}->{value} = $locale->text('Save');
        }

        if ( $form->{id} ) {

            for ( "post", "delete") { delete $button{$_} }
            for ( 'post_as_new', 'print_and_post_as_new') {
                delete $button{$_};
            }
            my $is_draft = 0;
            if (!$form->{approved}){
               $is_draft = 1;
               $button{approve} = {
                       ndx   => 3,
                       key   => 'O',
                       value => $locale->text('Post') };
               if (grep /^lsmb_$form->{company}__draft_modify$/, @{$form->{_roles}}){
                   $button{edit_and_save} = {
                       ndx   => 4,
                       key   => 'E',
                       value => $locale->text('Save Draft') };
              }
               # Delete these for batches too
               delete $button{$_}
                 for qw(post_as_new post e_mail sales_order void print on_hold);
            }

        }
        else {

            if ( $transdate > $closedto ) {
                for ( 'update', 'post', 'schedule' ) { $allowed{$_} = 1 }
                for ( keys %button ) { delete $button{$_} if !$allowed{$_} }
            }
            elsif ($closedto) {
                %buttons = ();
            }
        }

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            $form->print_button( \%button, $_ );
        }

    }

#    $form->hide_form(qw(selectcurrency defaultcurrency taxaccounts));

    for ( split / /, $form->{taxaccounts} ) {
        $form->hide_form( "${_}_rate", "${_}_description" );
    }

}

sub form_footer {
    my $manual_tax;
    if ($form->{id}){
        $manual_tax =
            qq|<input type="hidden" name="manual_tax" value="|
               . $form->{manual_tax} . qq|" />|;
    } else {
        my $checked0;
        my $checked1;
        if ($form->{manual_tax}){
           $checked1=qq|checked="CHECKED"|;
           $checked0="";
        } else {
           $checked0=qq|checked="CHECKED"|;
           $checked1="";
        }
        $manual_tax =
                    qq|<label for="manual-tax-0">|.
                       $locale->text("Automatic"). qq|</label>
                       <input type="radio" data-dojo-type="dijit/form/RadioButton" name="manual_tax" value="0"
                              id="manual-tax-0" $checked0 />
                        <label for="manual-tax-1">|.
                        $locale->text("Manual"). qq|</label>
                      <input type="radio" data-dojo-type="dijit/form/RadioButton" name="manual_tax" value="1"
                              id="manual-tax-1" $checked1 />|;
    }
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
qq|<textarea data-dojo-type="dijit/form/Textarea" name=notes rows=$rows cols=35 wrap=soft>$form->{notes}</textarea>|;
    $intnotes =
qq|<textarea data-dojo-type="dijit/form/Textarea" name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;
    $tax = "";
    $form->{taxincluded} = ( $form->{taxincluded} ) ? "checked" : "";

    $taxincluded = "";
    if ($form->{taxaccounts} ) {
        $taxincluded = qq|
        <input name=taxincluded class=checkbox type=checkbox data-dojo-type="dijit/form/CheckBox" value=1 $form->{taxincluded}> <b>|
          . $locale->text('Tax Included') . qq|</b>
|;
    }

    if ( !$form->{taxincluded} ) {
        if ($form->{manual_tax}){
             $tax .= qq|
                 <tr class="listtop">
                      <td>&nbsp</td>
                      <th align="center">|.$locale->text('Amount').qq|</th>
                      <th align="center">|.$locale->text('Rate').qq|</th>
                      <th align="center">|.$locale->text('Basis').qq|</th>
                      <th align="center">|.$locale->text('Tax Code').qq|</th>
                      <th align="center">|.$locale->text('Memo').qq|</th>
                      <td>&nbsp</td>
                    </tr>|;
        }
        foreach $item (keys %{$form->{taxes}}) {
            my $taccno = $item;
            if ($form->{manual_tax}){
               # Setting defaults from tax calculations
               # These are set in io.pl sub _calc_taxes --CT
               if ($form->{"mt_rate_$item"} eq '' or
                   !defined $form->{"mt_rate_$item"}){
                   $form->{"mt_rate_$item"} = $form->{tax_obj}{$item}->rate;
               }
               else
               {
                $form->{"mt_rate_$item"}=$form->parse_amount(\%myconfig,$form->{"mt_rate_$item"});
               }
               if ($form->{"mt_basis_$item"} eq '' or
                   !defined $form->{"mt_basis_$item"}){
                   $form->{"mt_basis_$item"} = $form->{taxbasis}{$item};
               }
               else
               {
                $form->{"mt_basis_$item"}=$form->parse_amount(\%myconfig,$form->{"mt_basis_$item"});
               }
               if ($form->{"mt_amount_$item"} eq '' or
                   !defined $form->{"mt_amount_$item"}){
                   $form->{"mt_amount_$item"} =
                           $form->{"mt_rate_$item"}
                           * $form->{"mt_basis_$item"};
               }
               else
               {
                $form->{"mt_amount_$item"}=$form->parse_amount(\%myconfig,$form->{"mt_amount_$item"});
               }
               $form->{invtotal} += $form->round_amount(
                                         $form->{"mt_amount_$item"}, 2);
               # Setting this up as a table
               # Note that the screens may be not wide enough to display
               # this in the normal way so we have to change the layout of the
               # notes fields. --CT
               $tax .= qq|<tr>
                <th align=right>$form->{"${taccno}_description"}</th>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_amount_$item"
                        id="mt-amount-$item" value="|
                        .$form->format_amount(\%myconfig,$form->{"mt_amount_$item"}).qq|" size="10"/></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_rate_$item"
                         id="mt-rate-$item" value="|
                        .$form->format_amount(\%myconfig,$form->{"mt_rate_$item"}).qq|" size="6"/></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_basis_$item"
                         id="mt-basis-$item" value="|
                        .$form->format_amount(\%myconfig,$form->{"mt_basis_$item"}).qq|" size="10" /></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_ref_$item"
                         id="mt-ref-$item" value="|
                        .$form->{"mt_ref_$item"} .qq|" size="10"/></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_memo_$item"
                         id="mt-memo-$item" value="|
                        .$form->{"mt_memo_$item"} .qq|" size="10"/></td>
               </tr>|;
            }  else {
                $form->{invtotal} += $form->round_amount($form->{taxes}{$item}, 2);
                $form->{"${taccno}_total"} =
                    $form->round_amount($form->{taxes}{$item}, 2);
                my $item_total_formatted=$form->format_amount(\%myconfig,$form->{"${item}_total"},2,0);
                    $tax .= qq|
                <tr>
              <th align=right>$form->{"${item}_description"}</th>
              <td align=right>$item_total_formatted</td>
                </tr>
|;
            }
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
        <th align=left>| . $locale->text('Notes') . qq|</th>|;
    if (!$form->{manual_tax}){
        print qq|
        <th align=left>| . $locale->text('Internal Notes') . qq|</th>
                <th align=left>| . $locale->text('Import Text') . qq|</th>
          </tr>
          <tr valign=top>|;
     }
     # Redesigning layout as per notes above.  When this is redesigned
     # we really should use floats and CSS instead. --CT
     if ($form->{manual_tax}){
         print qq|</tr><tr><td>$notes</td></tr>
                 <tr><th align=left>| . $locale->text('Internal Notes').qq|</th>
                 </tr>
                 <tr><td>$intnotes</td></tr>
                 <tr><th align=left>| . $locale->text('Import Text') . qq|</th>
                 </tr>
                 <tr>
                <td><textarea data-dojo-type="dijit/form/Textarea" name=import_text rows=$rows cols=25></textarea>|;
     } else {
         print qq|
        <td>$notes</td>
        <td>$intnotes</td>
                <td><textarea data-dojo-type="dijit/form/Textarea" name=import_text rows=$rows cols=25></textarea>|;
    }
    print qq|
          </tr>
        </table>
      </td>
      <td align=right valign="top">
        $taxincluded <br/>
        <table>
              <tr><th align="center" colspan="2">|.
                   $locale->text('Calculate Taxes').qq|</th>
              </tr>
              <tr>
                   <td colspan=2>$manual_tax</td>
               </tr>
          $subtotal
          $tax
          <tr>
        <th align=right>| . $locale->text('Total') . qq|</th>
        <td align=right>$form->{invtotal}</td>
          </tr>
        </table>
      </td>
    </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100% id="invoice-payments-table">
        <tr>
      <th colspan=6 class=listheading>| . $locale->text('Payments') . qq|</th>
    </tr>
|;

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        @column_index = qw(datepaid source memo paid AP_paid);
    }
    else {
        @column_index = qw(datepaid source memo paid exchangerate AP_paid);
    }

    $column_data{datepaid}     = "<th>" . $locale->text('Date') . "</th>";
    $column_data{paid}         = "<th>" . $locale->text('Amount') . "</th>";
    $column_data{exchangerate} = "<th>" . $locale->text('Exch') . "</th>";
    $column_data{AP_paid}      = "<th>" . $locale->text('Account') . "</th>";
    $column_data{source}       = "<th>" . $locale->text('Source') . "</th>";
    $column_data{memo}         = "<th>" . $locale->text('Memo') . "</th>";

    print qq|
    <tr>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    print qq|
    </tr>
|;

    $form->{paidaccounts}++ if ( $form->{"paid_$form->{paidaccounts}"} );
    $form->{"selectAP_paid"} =~ /($form->{cash_accno}--[^<]*)/;
    $form->{"AP_paid_$form->{paidaccounts}"} = $1;
    for $i ( 1 .. $form->{paidaccounts} ) {

        $form->hide_form("cleared_$i");

        print qq|
    <tr>
|;

        $form->{"selectAP_paid_$i"} = $form->{selectAP_paid};
        $form->{"selectAP_paid_$i"} =~
s/option>\Q$form->{"AP_paid_$i"}\E/option selected>$form->{"AP_paid_$i"}/;

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
qq|<input data-dojo-type="dijit/form/TextBox" name="exchangerate_$i" id="exchangerate_$i" size=10 value=$form->{"exchangerate_$i"}>|;
            }
        }
        $exchangerate .= qq|
<input type=hidden name="forex_$i" value=$form->{"forex_$i"}>
|;

        $column_data{"paid_$i"} =
qq|<td align=center><input data-dojo-type="dijit/form/TextBox" name="paid_$i" id="paid_$i" size=11 value=$form->{"paid_$i"}></td>|;
        $column_data{"exchangerate_$i"} =
          qq|<td align=center>$exchangerate</td>|;
        $column_data{"AP_paid_$i"} =
qq|<td align=center><select data-dojo-type="dijit/form/Select" name="AP_paid_$i" id="AP_paid_$i">$form->{"selectAP_paid_$i"}</select></td>|;
        $column_data{"datepaid_$i"} =
qq|<td align=center><input class="date" data-dojo-type="lsmb/lib/DateTextBox" name="datepaid_$i" id="datepaid_$i" size=11 title="$myconfig{dateformat}" value=$form->{"datepaid_$i"}></td>|;
        $column_data{"source_$i"} =
qq|<td align=center><input data-dojo-type="dijit/form/TextBox" name="source_$i" id="source_$i" size=11 value="$form->{"source_$i"}"></td>|;
        $column_data{"memo_$i"} =
qq|<td align=center><input data-dojo-type="dijit/form/TextBox" name="memo_$i" id="memo_$i" size=11 value="$form->{"memo_$i"}"></td>|;

        for (@column_index) { print qq|$column_data{"${_}_$i"}\n| }

        print qq|
    </tr>
|;
    }

    $form->{oldtotalpaid} = $totalpaid;
    $form->hide_form(qw(paidaccounts oldinvtotal oldtotalpaid));

    print qq|
      </table>
    </td>
  </tr>
  <tr><td>|;
    my $printops = &print_options;
    my $formname = { name => 'formname',
                     options => [
                                  {text=> $locale->text('Product Receipt'), value => 'product_receipt'},
                                ]
                   };
    print_select($form, $formname);
    print_select($form, $printops->{lang});
    print_select($form, $printops->{format});
    print_select($form, $printops->{media});
  print qq|
  </td></tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
<br>
|;

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Post')
    # type=submit $locale->text('Post as new')
    # type=submit $locale->text('Schedule')
    # type=submit $locale->text('Purchase Order')
    # type=submit $locale->text('Delete')

    if ( !$form->{readonly} ) {
        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            $form->print_button( \%button, $_ );
        }

    }
    if ($form->{id}){
        IR->get_files($form, $locale);
        print qq|
<a href="pnl.pl?action=generate_income_statement&pnl_type=invoice&id=$form->{id}">[| . $locale->text('Profit/Loss') . qq|]</a><br />
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
<td><a href="file.pl?action=get&file_class=1&ref_key=$form->{id}&id=$file->{id}"
            >$file->{file_name}</a></td>
<td>$file->{mime_type}</td>
<td>| . $file->{uploaded_at}->to_output . qq|</td>
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
       $callback = $form->escape("ir.pl?action=edit&id=".$form->{id});
       print qq|
<a href="file.pl?action=show_attachment_screen&ref_key=$form->{id}&file_class=1&callback=$callback"
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

sub import_text {
    my @o_list;
    my @i_lines = split( /(\n|\r|\r\n)/, $form->{import_text} );
    foreach $i (@i_lines) {
        chomp($i);
        if ( $i ne "" ) {    # Strip out blank lines
            push @o_list, $i;
        }
    }
    my $c          = 1;
    my $linenumber = 0;
    foreach $l (@o_list) {
        if ( $c % 2 ) {
            $linenumber += 1;
            $form->{"partnumber_$linenumber"} = $l;
        }
        else {
            $form->{"qty_$linenumber"} = $l;
        }
        $c += 1;
        $form->{rowcount} = $linenumber;
        IR->retrieve_item( \%myconfig, \%$form );
        $rows = scalar @{ $form->{item_list} };
        $rows = 0 unless $rows;
        $i    = $form->{rowcount};
        if ( $rows = 0 ) {
            $form->{"id_$i"}   = 0;
            $form->{"unit_$i"} = $locale->text('ea');

            &new_item;
        }
        elsif ( $rows > 1 ) {
            &select_item;
            $form->finalize_request();
        }
        else {
            map {
                $form->{item_list}[$i]{$_} =
                  $form->quote( $form->{item_list}[$i]{$_} )
            } qw(partnumber description unit);

            map { $form->{"${_}_$i"} = $form->{item_list}[0]{$_} }
              keys %{ $form->{item_list}[0] };

            $s = ($sellprice) ? $sellprice : $form->{"sellprice_$i"};

            ($dec) = ( $s =~ /\.(\d+)/ );
            $dec = length $dec;
            $decimalplaces = ( $dec > 2 ) ? $dec : 2;

            $amount =
              $form->{"sellprice_$i"} * $form->{"qty_$i"} *
              ( 1 - $form->{"discount_$i"} / 100 );
            map { $form->{"${_}_base"} = 0 }
              ( split / /, $form->{taxaccounts} );
            map { $form->{"${_}_base"} += $amount }
              ( split / /, $form->{"taxaccounts_$i"} );
            if ( !$form->{taxincluded} ) {
                my @taxes = Tax::init_taxes( $form, $form->{taxaccounts} );
                $amount +=
                  ( Tax::calculate_taxes( \@taxes, $form, $amount, 0 ) );
            }

            $form->{creditremaining} -= $amount;

            $form->{"sellprice_$i"} =
              $form->format_amount( \%myconfig, $form->{"sellprice_$i"},
                $decimalplaces );
            $form->{"qty_$i"} =
              $form->format_amount( \%myconfig, $form->{"qty_$i"} );

        }
        $form->{item_list} = [];
    }
    ++$form->{rowcount};
}

sub update {
     $form->{ARAP} = 'AP';
    if ( $form->{import_text} ) {
        &import_text;
    }
    delete $form->{"partnumber_$form->{delete_line}"} if $form->{delete_line};
    $form->{exchangerate} =
      $form->parse_amount( \%myconfig, $form->{exchangerate} );

    $form->{$_} = LedgerSMB::PGDate->from_input($form->{$_})->to_output()
       for qw(transdate duedate crdate);

    if ( $newname = &check_name(vendor) ) {
        &rebuild_vc( vendor, AP, $form->{transdate}, 1 );
    }
    if ( $form->{transdate} ne $form->{oldtransdate} ) {
        $form->{duedate} =
          ( $form->{terms} )
          ? $form->current_date( \%myconfig, $form->{transdate},
            $form->{terms} * 1 )
          : $form->{duedate};
        $form->{oldtransdate} = $form->{transdate};
        &rebuild_vc( vendor, AP, $form->{transdate}, 1 ) if !$newname;

        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            delete $form->{exchangerate};
            $form->{exchangerate} = $exchangerate
              if (
                $form->{forex} = (
                    $exchangerate = $form->check_exchangerate(
                        \%myconfig,         $form->{currency},
                        $form->{transdate}, 'sell'
                    )
                )
              );
            $form->{oldcurrency} = $form->{currency};
        }
    }

    if ( $form->{currency} ne $form->{oldcurrency} ) {
        delete $form->{exchangerate};
        $form->{exchangerate} = $exchangerate
          if (
            $form->{forex} = (
                $exchangerate = $form->check_exchangerate(
                    \%myconfig,         $form->{currency},
                    $form->{transdate}, 'sell'
                )
            )
          );
    }

    $j = 1;
    for $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} and $form->{"paid_$i"} != 0) {
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
                        $form->{"datepaid_$j"}, 'sell'
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
        $form->{paidaccounts} = $j;
    }

    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;
    my $non_empty_rows = 0;
    for my $i (1 .. $form->{rowcount}) {
        $non_empty_rows++
            if $form->{"id_$i"}
               || ! ( ( $form->{"partnumber_$i"} eq "" )
                      && ( $form->{"description_$i"} eq "" )
                      && ( $form->{"partsgroup_$i"}  eq "" ) );
    }

    my $current_empties = $form->{rowcount} - $non_empty_rows;
    my $new_empties =
        max(0,
            max($LedgerSMB::Company_Config::settings->{min_empty}, 1)
            - $current_empties);


    $form->{rowcount} += $new_empties;
    for my $i (1 .. $form->{rowcount}){
        $form->{rowcount} = $i;
        next if $form->{"id_$i"};

        for (qw(partsgroup projectnumber)) {
            $form->{"select$_"} = $form->unescape( $form->{"select$_"} )
              if $form->{"select$_"};
        }

        if (   ( $form->{"partnumber_$i"} eq "" )
            && ( $form->{"description_$i"} eq "" )
            && ( $form->{"partsgroup_$i"}  eq "" ) )
        {

            $form->{creditremaining} +=
              ( $form->{oldinvtotal} - $form->{oldtotalpaid} );

        }
        else {
            ($form->{"partnumber_$i"}) = split (/--/, $form->{"partnumber_$i"});
            IR->retrieve_item( \%myconfig, \%$form );

            my $rows = scalar @{ $form->{item_list} };

            if ( $form->{language_code} && $rows == 0 ) {
                $language_code = $form->{language_code};
                $form->{language_code} = "";
                IR->retrieve_item( \%myconfig, \%$form );
                $form->{language_code} = $language_code;
                $rows = scalar @{ $form->{item_list} };
            }

            if ($rows) {

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
                    $decimalplaces = ( $dec > 2 ) ? $dec : 2;
                }
                else {
                    ($dec) = ( $form->{"sellprice_$i"} =~ /\.(\d+)/ );
                    $dec = length $dec;
                    $decimalplaces = ( $dec > 2 ) ? $dec : 2;

                    $form->{"sellprice_$i"} /= $exchangerate;
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
                if ( !$form->{taxincluded} ) {
                    my @taxes = Tax::init_taxes(
                        $form,
                        $form->{"taxaccounts_$i"},
                        $form->{"taxaccounts"}
                    );
                    $amount +=
                      ( Tax::calculate_taxes( \@taxes, $form, $amount, 0 ) );
                }

                $form->{creditremaining} -= $amount;

                $form->{"sellprice_$i"} =
                  $form->format_amount( \%myconfig, $form->{"sellprice_$i"},
                    $decimalplaces );

                $form->{"oldqty_$i"} = $form->{"qty_$i"};
                for (qw(qty discount)) {
                    $form->{"{_}_$i"} =
                      $form->format_amount( \%myconfig, $form->{"${_}_$i"} );
                }

            } else {

                # ok, so this is a new part
                # ask if it is a part or service item

                if (   $form->{"partsgroup_$i"}
                    && ( $form->{"partsnumber_$i"} eq "" )
                    && ( $form->{"description_$i"} eq "" ) )
                {
                    $form->{"discount_$i"} = "";
                }
                else {

                    $form->{"id_$i"}   = 0;
                    $form->{"unit_$i"} = $locale->text('ea');

                    &new_item;

                }
            }
        }
    }
     $form->generate_selects();
     $form->{rowcount}--;
    display_form();
}

sub post {

    if (!$form->close_form()){
       $form->{notice} = $locale->text(
             'Could not save the data.  Please try again'
       );
       &update;
       $form->finalize_request();
    }
    if (!$form->{duedate}){
          $form->{duedate} = $form->{transdate};
    }

    $form->isblank( "transdate", $locale->text('Invoice Date missing!') );
    $form->isblank( "vendor",    $locale->text('Vendor missing!') );

    # if the vendor changed get new values
    if ( &check_name(vendor) ) {
        &update;
        $form->finalize_request();
    }
    check_form(1);

    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );
    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    $form->error( $locale->text('Cannot post invoice for a closed period!') )
      if ( $transdate <= $closedto );

    $form->isblank( "exchangerate", $locale->text('Exchange rate missing!') )
      if ( $form->{currency} ne $form->{defaultcurrency} );

    for $i ( 1 .. $form->{paidaccounts} ) {
        #if ( $form->{"paid_$i"} ) {
        if ( $form->{"paid_$i"} !=0.0 ) {
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

    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            &repost;
            $form->finalize_request();
        }
    }

    ( $form->{AP} )      = split /--/, $form->{AP};
    ( $form->{AP_paid} ) = split /--/, $form->{AP_paid};

    IR->post_invoice( \%myconfig, \%$form );
    edit();

}

sub on_hold {

    if ($form->{id}) {

        my $toggled = IR->toggle_on_hold($form);#tshvr4

        #&invoice_links(); # is that it?
        &edit(); # it was already IN edit for this to be reached.
    }
}



sub save_info {

        my $taxformfound=0;

        $taxformfound=IR->taxform_exist($form,$form->{"vendor_id"});
            $form->{arap} = 'ap';
            AA->save_intnotes($form);

        foreach my $i(1..($form->{rowcount}))
        {

                if($taxformfound)
                {
                if($form->{"taxformcheck_$i"})
        {
          IR->update_invoice_tax_form($form,$form->{dbh},$form->{"invoice_id_$i"},"true") if($form->{"invoice_id_$i"});
        }
        else
        {
            IR->update_invoice_tax_form($form,$form->{dbh},$form->{"invoice_id_$i"},"false") if($form->{"invoice_id_$i"});
        }
                }#taxformfound
        }

        if ($form->{callback}){
        print "Location: $form->{callback}\n";
        print "Status: 302 Found\n\n";
        print qq|<html><body class="lsmb $form->{dojo_theme}">|;
        my $url = $form->{callback};
        print qq|If you are not redirected automatically, click <a href="$url">|
            . qq|here</a>.</body></html>|;

        } else {
        edit();
        }

}





