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

package lsmb_legacy;

use List::Util qw(max min uniq);
use Workflow::Context;

use LedgerSMB::Form;
use LedgerSMB::IIAA;
use LedgerSMB::IS;
use LedgerSMB::PE;
use LedgerSMB::Tax;


require "old/bin/arap.pl";
require "old/bin/io.pl";

# end of main
sub on_update{}

sub copy_to_new{
    delete $form->{id};
    delete $form->{invnumber};
    delete $form->{workflow_id};
    $form->{crdate} = $form->current_date( \%myconfig );
    $form->{paidaccounts} = 1;
    if ($form->{paid_1}){
        delete $form->{paid_1};
    }
    update();
}

sub edit_and_save {
    $form->{ARAP} = 'AR';
    IS->post_invoice( \%myconfig, \%$form );

    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
        $wf->execute_action( $form->{__action} );
    }
    edit();
}

sub new_screen {
    my @reqprops = qw(ARAP vc dbh stylesheet batch_id script type _locale _wire);
    $oldform = $form;
    $form = {};
    bless $form, 'Form';
    for (@reqprops){
        $form->{$_} = $oldform->{$_};
    }
    &add();
}



sub add {
    $form->{ARAP} = 'AR';
    if ($form->{type} eq 'credit_invoice'){
        $form->{title} = $locale->text('Add Credit Invoice');
        $form->{subtype} = 'credit_invoice';
        $form->{reverse} = 1;
    } elsif ($form->{type} eq 'customer_return') {
        $form->{title} = $locale->text('Add Customer Return');
        $form->{subtype} = 'credit_invoice';
        $form->{reverse} = 1;
        $form->{is_return} = 1;
    } else {
        $form->{title} = $locale->text('Add Sales Invoice');
        $form->{reverse} = 0;
    }
    $form->{callback} = "$form->{script}?__action=add&type=$form->{type}"
      unless $form->{callback};

    &invoice_links;
    &prepare_invoice;
    &display_form;

}

sub del {
    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    $wf->execute_action( 'del' );

    $form->info($locale->text('Draft deleted'));
}

sub edit {
    $form->{ARAP} = 'AR';
    if (not $form->{id} and $form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
        $form->{id} = $wf->context->param( 'id' );
    }

    &invoice_links;
    &prepare_invoice;

    if ($form->{is_return}){
        $form->{title} = $locale->text('Edit Customer Return');
        $form->{subtype} = 'credit_invoice';
    } elsif ($form->{reverse}) {
        $form->{title} = $locale->text('Edit Credit Invoice');
        $form->{subtype} = 'credit_invoice';
    } else {
        $form->{title} = $locale->text('Edit Sales Invoice');
    }

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
    if (!$form->{currencies}){
        $form->error($locale->text(
           'No currencies defined.  Please set these up under System/Defaults.'
        ));
    }
    @curr = @{$form->{currencies}};
    $form->{defaultcurrency} = $curr[0];

    for (@curr) { $form->{selectcurrency} .= "<option value=\"$_\">$_</option>\n" }

    ###TODO 20151108: came with merge from 1.4-mc; incorrectly?
    if ( @{ $form->{all_customer} } ) {
        unless ( $form->{customer_id} ) {
            $form->{customer_id} = $form->{all_customer}->[0]->{id};
        }
    }
    ###TODO 20151108; end of merge region

    delete $form->{notes};
    IS->retrieve_invoice( \%myconfig, \%$form );
    AA->get_name( \%myconfig, \%$form );
    $form->{taxaccounts} =
        join(' ',
             uniq((split / /, $form->{taxaccounts}),
                  # add transaction tax accounts, which may no longer be applicable to
                  # the customer, but still are for the transaction
                  IIAA->trans_taxaccounts($form) ));

    $form->{oldlanguage_code} = $form->{language_code};

    $form->get_partsgroup({ all => 1});

    $form->{oldcustomer}  = "$form->{customer}--$form->{customer_id}";
    $form->{oldtransdate} = $form->{transdate};

    $form->{employee} = "$form->{employee}--$form->{employee_id}";

    # forex
    $form->{forex} = $form->{exchangerate};
    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

    foreach my $key ( keys %{ $form->{AR_links} } ) {

        $form->{"select$key"} = '';
        foreach my $ref ( @{ $form->{AR_links}{$key} } ) {
            $value = "$ref->{accno}--$ref->{description}";
            $selected = ($value eq ($form->{$key}//'')) ? ' selected="selected"' : "";
            $form->{"select$key"} .= qq|<option value="$value"$selected>$value</option>\n|;
        }

        if ( $key eq "AR_paid" ) {

            if ( $form->{acc_trans} and $form->{acc_trans}{$key} ) {
                foreach my $i ( 1 .. scalar @{ $form->{acc_trans}{$key} } ) {
                    $form->{"AR_paid_$i"} =
                        "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";

                    # reverse paid
                    $form->{"paid_$i"} =
                        $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * -1;
                    $form->{"paid_${i}_approved"} =
                        $form->{acc_trans}{$key}->[ $i - 1 ]->{approved};
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
        }
        else {
            $form->{$key} =
"$form->{acc_trans}{$key}->[0]->{accno}--$form->{acc_trans}{$key}->[0]->{description}"
              if $form->{acc_trans}{$key}->[0]->{accno};
        }

    }

    $form->{AR} //= $form->{AR_1} unless $form->{id};
    $form->{AR} //= $form->{AR_links}->{AR}->[0]->{accno} unless $form->{id};
    for (qw(AR_links acc_trans)) { delete $form->{$_} }

    $form->{paidaccounts} = 1 if not $form->{paidaccounts};
}

sub prepare_invoice {
    my %args = @_;

    $form->{formname} = "invoice";
    $form->{sortby} ||= "runningnumber";
    $form->{media} = $myconfig{printer};

    $form->{selectformname} =
      qq|<option value="invoice">|
      . $locale->text('Invoice') . qq|
<option value="pick_list">| . $locale->text('Pick List') . qq|
<option value="packing_list">| . $locale->text('Packing List');

    $i = 0;
    $form->{currency} =~ s/ //g;
    $form->{oldcurrency} = $form->{currency};

    IIAA->prepare_invoice( $form, \%myconfig, module => 'IS', %args );
}

sub form_header {
    my $readonly =
        ($form->{reversing} or $form->{approved}) ? 'readonly="readonly"' : '';
    my $readonly_headers = $form->{approved} ? 'readonly="readonly"' : '';
    $form->{nextsub} = 'update';
    $form->{ARAP} = 'AR';
    $form->generate_selects(\%myconfig) unless $form->{selectAR};

    my $wf;
    if($form->{workflow_id}) {
        $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    }
    else {
        $wf = $form->{_wire}->get('workflows')
            ->create_workflow( 'AR/AP',
                               Workflow::Context->new(
                                   'batch-id' => $form->{batch_id}
                               ) );
        $form->{workflow_id} = $wf->id;
    }
    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $wf->context->param( transdate => $transdate );

    $status_div_id = 'AR-invoice';
    $status_div_id .= '-reverse' if $form->{reverse};
    $form->{exchangerate} =
      $form->format_amount( \%myconfig, $form->{exchangerate} );

    $form->{selectAR} =~ s/(\Qoption value="$form->{AR}"\E)/$1 selected="selected"/;

    $exchangerate = qq|<tr>|;
    $exchangerate .= qq|
        <th align=right nowrap>| . $locale->text('Currency') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" id="currency" name="currency" $readonly>$form->{selectcurrency}</select>
| if $form->{defaultcurrency};

    if (   $form->{defaultcurrency}
        && $form->{currency} ne $form->{defaultcurrency} )
    {
        $exchangerate .=
                qq|</td><th align=right>|
              . $locale->text('Exchange Rate')
              . qq|</th><td><input data-dojo-type="dijit/form/TextBox" name="exchangerate" size="10" value="$form->{exchangerate}" $readonly>|;
    }
    $exchangerate .= qq|
<input type=hidden name="forex" value="$form->{forex}"></td>
</tr>
|;

    if ( $form->{selectcustomer} ) {
        $customer = qq|<select data-dojo-type="lsmb/FilteringSelect" id="customer" name="customer" $readonly><option></option>$form->{selectcustomer}</select>|;
    }
    else {
        $customer = qq|<input data-dojo-type="dijit/form/TextBox" id="customer" name="customer" value="$form->{customer}" size="35" $readonly>
     <a id="new-contact" target="_blank"
        href="#contact.pl?__action=add&entity_class=2">[| .
        $locale->text('New') . qq|]</a> |;
    }

    $department = qq|
              <tr>
            <th align="right" nowrap>| . $locale->text('Department') . qq|</th>
        <td colspan="3"><select data-dojo-type="dijit/form/Select" id="department" name="department" $readonly>$form->{selectdepartment}</select>
        </td>
          </tr>
| if $form->{selectdepartment};

    $n = ( defined $form->{creditremaining} and $form->{creditremaining} < 0 ) ? "0" : "1";

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
                <input type=hidden name="employee" value="$form->{employee}">
|;

    $employee = qq|
          <tr>
            <th align=right nowrap>| . $locale->text('Salesperson') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" id="employee" name="employee">$form->{selectemployee}</select></td>
          </tr>
| if $form->{selectemployee};

    $i     = ($form->{rowcount} // 0) + 1;
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

    $form->hide_form(
        qw(form_id id type printed emailed title vc terms discount
           creditlimit creditremaining tradediscount business
           shipped oldtransdate recurring reverse batch_id subtype tax_id
           meta_number separate_duties lock_description nextsub
           default_reportable address city zipcode state country
           is_return cash_accno shiptolocationid)
    );

    if ($form->{notice}){
         print qq|<th>$form->{notice}</th>|;
    }
    my $manual_tax;
    if ($form->{approved}){
        $manual_tax =
            qq|<input type="hidden" name="manual_tax" value="|
               . $form->{manual_tax} . qq|" />|;
    } else {
        $manual_tax = $locale->text("Calculate Taxes") .
                    qq|<label for="manual-tax-0">|.
                       $locale->text("Automatic"). qq|</label>
                       <input type="radio" data-dojo-type="dijit/form/RadioButton" name="manual_tax" value="0"
                              id="manual-tax-0" $readonly >
                        <label for="manual-tax-1">|.
                        $locale->text("Manual"). qq|</label>
                      <input type="radio" data-dojo-type="dijit/form/RadioButton" name="manual_tax" value="1"
                              id="manual-tax-1" $readonly >|;
    }
    print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table id="invoice-header" width=100%>
    <tr valign=top>
      <td>
        <table>
          <tr>
        <th align=right nowrap><label for="customer">| . $locale->text('Customer') . qq|</label></th>
        <td colspan=3>$customer
        <input type=hidden name="customer_id" value="$form->{customer_id}">
        <input type=hidden name="oldcustomer" value="$form->{oldcustomer}">
</td>
          </tr>
          <tr>
        <td></td>
        <td colspan=3>
          <table>
            <tr> |;
      if ($form->get_setting('show_creditlimit')){
          print qq|
              <th align=right nowrap>| . $locale->text('Credit Limit') . qq|</th>
              <td>|
      . $form->format_amount( \%myconfig, $form->{creditlimit}, 0, "0" )
      . qq|</td>
              <td width=10></td>
              <th align=right nowrap>| . $locale->text('Remaining') . qq|</th>
              <td class="plus$n" nowrap>|
      . $form->format_amount( \%myconfig, $form->{creditremaining}, 0, "0" )
      . qq|</td> |;
     } else { print "<td>&nbsp;</td>"; }
        print qq|
            </tr>|;
       if ($form->{entity_control_code}){
           $form->hide_form(qw(entity_control_code meta_number));
           $form->{$_} //= '' for (qw(entity_control_code meta_number tax_id address city));
            print qq|
            <tr>
        <th align="right" nowrap>| .
            $locale->text('Entity Code') . qq|</th>
        <td colspan="2" nowrap><a href="#contact.pl?__action=get_by_cc&control_code=$form->{entity_control_code}" target="_blank"><b>$form->{entity_control_code}</b></a></td>
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

    $form->{$_} //= '' for (qw(description shippingpoint shipvia invnumber ordnumber
                            quonumber ponumber crdate transdate duedate));
    $myconfig{dateformat} //= '';
    $business //= '';
    $department //= '';
    $exchangerate //= '';
    $form->get_shipto( $form->{shiptolocationid} );
    print qq|
            $business
          </table>
        </td>
          </tr>

          <tr>
        <th align="right" nowrap><label for="AR">| . $locale->text('Record in') . qq|</label></th>
        <td colspan="3"><select data-dojo-type="dijit/form/Select" name="AR" id="AR" $readonly>$form->{selectAR}</select></td>
          </tr>
          $department
          $exchangerate
            <tr>
               <th align="right" nowrap><label for="description">| . $locale->text('Description') . qq|</label>
               </th>
               <td><input data-dojo-type="dijit/form/TextBox" type="text" id="description" name="description" size="40"
                   value="| . $form->{description} . qq|" $readonly_headers /></td>
            </tr>
          <tr>
        <th align=right nowrap><label for="shippingpoint">| . $locale->text('Shipping Point') . qq|</label></th>
        <td colspan=3><input data-dojo-type="dijit/form/TextBox" id="shippingpoint" name="shippingpoint" size="35" value="$form->{shippingpoint}" $readonly></td>
          </tr>
          <tr>
            <th align=right nowrap>| . $locale->text('Shipping Attn') . qq|</th>
            <td><input name=shiptoattn id=shiptoattn data-dojo-type="dijit/form/TextBox" value="$form->{shiptoattn}"></td>
          </tr>
          <tr>
            <th align=right valign=top nowrap>| . $locale->text('Shipping Address') . qq|</th>
            <td>$form->{shiptoaddress1} <br/>
                $form->{shiptoaddress2} <br/>
                $form->{shiptocity}, $form->{shiptostate} <br/>
                $form->{shiptozipcode} <br/>
                $form->{shiptocountry}
                </td>
          </tr>
          <tr>
        <th align=right nowrap><label for="shipvia">| . $locale->text('Ship via') . qq|</label></th>
        <td colspan=3>
                   <textarea data-dojo-type="dijit/form/Textarea" id="shipvia" name="shipvia" cols="35" rows="3" $readonly
                       >$form->{shipvia}</textarea></td>
          </tr>
        </table>
      </td>
      <td style="vertical-align:middle">| .
        ($form->{reversing} ? qq|<a href="$form->{script}?__action=edit&amp;id=$form->{reversing}">|. ($form->{approved} ? $locale->text('This transaction reverses transaction [_1] with ID [_2]', $form->{reversing_reference}, $form->{reversing}) : $locale->text('This transaction will reverse transaction [_1] with ID [_2]', $form->{reversing_reference}, $form->{reversing})) . q|</a><br />| : '') .
        ($form->{reversed_by} ? qq|<a href="$form->{script}?__action=edit&amp;id=$form->{reversed_by}"> | . $locale->text('This transaction is reversed by transaction [_1] with ID [_2]', $form->{reversed_by_reference}, $form->{reversed_by}) . q|</a>| : '') .
      qq|</td>
      <td align=right>
        <table>
          $employee
          <tr>
        <th align=right nowrap><label for="invnumber">| . $locale->text('Invoice Number') . qq|</label></th>
        <td><input data-dojo-type="dijit/form/TextBox" name="invnumber" id="invnumber" size="20" value="$form->{invnumber}" $readonly_headers>| .  $form->sequence_dropdown('sinumber', $readonly_headers) . qq|</td>
          </tr>
          <tr>
        <th align=right nowrap><label for="ordnumber">| . $locale->text('Order Number') . qq|</label></th>
        <td><input data-dojo-type="dijit/form/TextBox" name="ordnumber" id="ordnumber" size="20" value="$form->{ordnumber}" $readonly>
<input type=hidden name="quonumber" value="$form->{quonumber}"></td>
          </tr>
          <tr class="crdate-row">
        <th align=right><label for="crdate">| . $locale->text('Invoice Created') . qq|</label></th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name="crdate" size="11" title="$myconfig{dateformat}" value="$form->{crdate}" id="crdate" data-dojo-props="defaultIsToday:true" $readonly_headers ></td>
          </tr>
          <tr class="transdate-row">
        <th align=right><label for="transdate">| . $locale->text('Invoice Date') . qq|</label></th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name="transdate" id="transdate" size="11" title="$myconfig{dateformat}" value="$form->{transdate}" data-dojo-props="defaultIsToday:true" $readonly_headers ></td>
          </tr>
          <tr>
        <th align=right><label for="duedate">| . $locale->text('Due Date') . qq|</label></th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name="duedate" id="duedate" size="11" title="$myconfig{dateformat}" value="$form->{duedate}" $readonly_headers ></td>
          </tr>
          <tr>
        <th align=right nowrap><label for="ponumber">| . $locale->text('PO Number') . qq|</label></th>
        <td><input data-dojo-type="dijit/form/TextBox" name="ponumber" id="ponumber" size="20" value="$form->{ponumber}" $readonly ></td>
          </tr>
          <tr>
          <th align=right nowrap>| . $locale->text('State') . qq|</th>
          <td>| . ( $wf ? $locale->maketext($wf->state) : '' ) . qq|</td>
          </tr>
        </table>
      </td>
    </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

    $form->hide_form(
        qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts)
    );

    foreach my $item ( split / /, $form->{taxaccounts} ) {
        $form->hide_form( "${item}_rate", "${item}_taxnumber" );
    }

    print q|
    </td>
  </tr>
|;


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

sub void {
    $form->{reversing_reference} = $form->{invnumber};
    my $invnumber = $form->{invnumber} . '-VOID';
    $form->{reverse} = not $form->{reverse};
    $form->{paidaccounts} = 1;
    if ($form->{paid_1}){
       warn $locale->text(
             'Payments associated with voided invoice may need to be reversed.'
        );
        delete $form->{paid_1};
    }
    $form->{reversing} = delete $form->{id};

    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    $wf->execute_action( $form->{__action} );

    delete $form->{workflow_id};
    &post_as_new( invnumber => $invnumber );
}

sub form_footer {
    my $readonly =
        ($form->{reversing} or $form->{approved}) ? 'readonly="readonly"' : '';
    my $readonly_headers = $form->{approved} ? 'readonly="readonly"' : '';
    my $manual_tax;
    if ($form->{approved}){
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
                              id="manual-tax-0" $checked0 $readonly />
                        <label for="manual-tax-1">|.
                        $locale->text("Manual"). qq|</label>
                      <input type="radio" data-dojo-type="dijit/form/RadioButton" name="manual_tax" value="1"
                              id="manual-tax-1" $checked1 $readonly >|;
    }
    _calc_taxes();
    $form->{invtotal} = $form->{invsubtotal};

    if ( ( $rows = $form->numtextrows( $form->{notes}, 35, 8 ) ) < 2 ) {
        $rows = 5;
    }
    if ( ( $introws = $form->numtextrows( $form->{intnotes}, 35, 8 ) ) < 2 ) {
        $introws = 5;
    }
    $rows = ( $rows > $introws ) ? $rows : $introws;
    $form->{notes} //= '';
    $notes =
        qq|<textarea data-dojo-type="dijit/form/Textarea" id="notes" name="notes" rows="$rows" cols="40" wrap="soft" $readonly_headers>$form->{notes}</textarea>|;
    $form->{intnotes} //= '';
    $intnotes =
qq|<textarea data-dojo-type="dijit/form/Textarea" id="intnotes" name="intnotes" rows="$rows" cols="40" wrap="soft">$form->{intnotes}</textarea>|;

    $form->{taxincluded} = ( $form->{taxincluded} ) ? "checked" : "";

    $taxincluded = "";
    if ($form->{taxaccounts} ) {
        $taxincluded = qq|
              <tr height="5"></tr>
              <tr>
            <td align=right>
            <input id="taxincluded" name="taxincluded" class="checkbox" type="checkbox" data-dojo-type="dijit/form/CheckBox" value="1" $form->{taxincluded} $readonly></td><th align=left>|
          . $locale->text('Tax Included')
          . qq|</th>
         </tr>
|;
    }

    $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    if ( !$form->{taxincluded} ) {
        if ($form->{manual_tax}){
             $tax .= qq|<tr class="listtop">
                      <td>&nbsp</td>
                      <th align="center">|.$locale->text('Amount').qq| ($form->{currency})</th>
                      <th align="center">|.$locale->text('Rate').qq|</th>
                      <th align="center">|.$locale->text('Basis').qq| ($form->{currency})</th>
                      <th align="center">|.$locale->text('Tax Code').qq|</th>
                      <th align="center">|.$locale->text('Memo').qq|</th>
                    </tr>|;
        }
        foreach my $item (keys %{$form->{taxes}}) {
            my $taccno = $item;
            if ($form->{manual_tax}){
               # Setting defaults from tax calculations
               # These are set in io.pl sub _calc_taxes --CT
               if ($form->{"mt_rate_$item"} eq '' or
                   !defined $form->{"mt_rate_$item"}){
                   $form->{"mt_rate_$item"} = $form->{tax_obj}{$item}->rate;
               }
               if ($form->{"mt_basis_$item"} eq '' or
                   !defined $form->{"mt_basis_$item"}){
                   $form->{"mt_basis_$item"} = $form->{taxbasis}{$item};
               }
               if ($form->{"mt_amount_$item"} eq '' or
                   !defined $form->{"mt_amount_$item"}){
                   $form->{"mt_amount_$item"} =
                           $form->{"mt_rate_$item"}
                           * ($form->{"mt_basis_$item"} // 0);
               }
               $form->{invtotal} += $form->round_amount(
                                         $form->parse_amount( \%myconfig,  $form->{"mt_amount_$item"}), 2);
               # Setting this up as a table
               # Note that the screens may be not wide enough to display
               # this in the normal way so we have to change the layout of the
               # notes fields. --CT
               $tax .= qq|<tr class="invoice-manual-tax">
                <th align=right>$form->{_accno_descriptions}->{$taccno}</th>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_amount_$item"
                        id="mt-amount-$item" value="|
                        .$form->format_amount(\%myconfig, $form->{"mt_amount_$item"}, $form->{_setting_decimal_places} )
                        .qq|" size="10" $readonly /></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_rate_$item"
                         id="mt-rate-$item" value="|
                        .$form->format_amount(\%myconfig, $form->{"mt_rate_$item"})
                        .qq|" size="4" $readonly /></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_basis_$item"
                         id="mt-basis-$item" value="|
                        .$form->format_amount(\%myconfig, $form->{"mt_basis_$item"}, $form->{_setting_decimal_places} )
                        .qq|" size="10" $readonly /></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_ref_$item"
                         id="mt-ref-$item" value="|
                        . $form->{"mt_ref_$item"} .qq|" size="10" $readonly /></td>
                <td><input data-dojo-type="dijit/form/TextBox" type="text" name="mt_memo_$item"
                         id="mt-memo-$item" value="|
                        .$form->{"mt_memo_$item"} .qq|" size="10" $readonly /></td>
               </tr>|;
            }  else {
           $form->{invtotal} += $form->round_amount($form->{taxes}{$item}, 2);
                $form->{"${taccno}_total"} =
                      $form->format_amount( \%myconfig,
                           $form->round_amount( $form->{taxes}{$item}, 2 ), $form->{_setting_decimal_places} );
                next if !$form->{"${taccno}_total"};
                $tax .= qq|
                <tr class="invoice-auto-tax" title="Source: $form->{acc_trans}{ $form->{id} }{ $taccno }{source}">
                  <th align=right>$form->{_accno_descriptions}->{$taccno}</th>
                  <td align=right>$form->{"${taccno}_total"}</td>
                  <td>$form->{currency}</td>
                </tr>|;
            }
            $tax .= q|<tr><td>&nbsp;</td></tr>|;
        }
        $form->{invsubtotal} =
          $form->format_amount( \%myconfig, $form->{invsubtotal}, $form->{_setting_decimal_places}, 0 );

        $subtotal = qq|
          <tr class="invoice-subtotal">
        <th align=right>| . $locale->text('Subtotal') . qq|</th>
      <td align=right>$form->{invsubtotal}</td><td>$form->{currency}</td></tr>| .
      (($form->{currency} ne $form->{defaultcurrency})
       ? ("<tr><th align=right>&nbsp;</th><td align=right>".$form->format_amount( \%myconfig,
                                         $form->{invsubtotal}
                                        * $form->{exchangerate}, 2)."</td><td>$form->{defaultcurrency}</td></tr>")
         : '')
      . qq|</tr>
|;

    }

    $form->{oldinvtotal} = $form->{invtotal};
    $form->{invtotal} =
    $form->format_amount( \%myconfig, $form->{invtotal}, $form->{_setting_decimal_places}, 0 );
    my $invtotal_bc;
    $invtotal_bc =
        $form->format_amount( \%myconfig,
                              $form->{invtotal} * $form->{exchangerate}, $form->{_setting_decimal_places})
        if $form->{currency} ne $form->{defaultcurrency};


    my $hold = '';
    my $hold_button_text;
    if ($form->{on_hold}) {

        $hold = qq| <font size="17"><b> This invoice is On Hold </b></font> |;
        $hold_button_text = $locale->text('Off Hold');
    } else {
        $hold_button_text = $locale->text('On Hold');
    }

    $totalpaid = 0;
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        next if $readonly and not $form->{"datepaid_$i"};
        $totalpaid += $form->{"paid_$i"};
    }
    $remaining_balance = $form->{invtotal} - $totalpaid;
    $totalpaid = $form->format_amount( \%myconfig, $totalpaid, $form->{_setting_decimal_places}, 0 );
    $remaining_balance = $form->format_amount( \%myconfig, $remaining_balance, $form->{_setting_decimal_places}, 0 );

    my $display_barcode = $form->get_setting('have_barcodes') ? "initial" : "none";
    print qq|
  <tr style="display:$display_barcode">
   <td colspan="5"><b><label for="barcode">Barcode</label></b>: <input data-dojo-type="dijit/form/TextBox" id=barcode name=barcode></td>
  </tr>
  <tr>
    <td>
      <table width=100%>
    <tr valign=bottom>
        | . $hold . qq|
      <td>
        <table>
          <tr>
        <th align=left>| . $locale->text('Notes') . qq|</th>|;
     # Redesigning layout as per notes above.  When this is redesigned
     # we really should use floats and CSS instead. --CT
     if (!$form->{manual_tax}){
           print qq|
        <th align=left>| . $locale->text('Internal Notes') . qq|</th>|;
     }
     print qq|
          </tr>
          <tr valign=top>|;
     if ($form->{manual_tax}){
         print qq|<td>$notes</td>
              </tr><tr>
               <th align=left>| . $locale->text('Internal Notes') . qq|</th>
              </tr><tr>
              <td>$intnotes</td>|;
     } else {
         print qq|
        <td>$notes</td>
        <td>$intnotes</td>|;
    }
    print qq|
          </tr>
        </table>
      </td>
      <td align=right>
        <table>
          $subtotal
              <tr><td>&nbsp;</td></tr>
              <tr><th align="center"
                      colspan="2">|.$locale->text('Calculate Taxes').qq|</th>
                   <td colspan="3">$manual_tax</td>
              </tr>
              <tr>
                <td>&nbsp;</td>
              </tr>
          $tax
          <tr class="invoice-total">
        <th align=right>| . $locale->text('Total') . qq|</th>
      <td align=right>$form->{invtotal}</td><td>$form->{currency}</td></tr>| .
      (($form->{currency} ne $form->{defaultcurrency})
       ? "<tr><td><!-- total --></td><td align=right>$invtotal_bc</td><td>$form->{defaultcurrency}</td></tr>" : '')
      . qq|
              <tr>
                <td>&nbsp;</td>
              </tr>
      <tr class="invoice-total-paid">
        <th>| . $locale->text('Total paid') . qq|</th><td align=right>$totalpaid</td><td>$form->{currency}</td>
      </tr>
              <tr>
                <td>&nbsp;</td>
              </tr>
      <tr class="invoice-remaining-balance">
        <th>| . $locale->text('Remaining balance') . qq|</th><td align=right>$remaining_balance</td><td>$form->{currency}</td>
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
|;

    IIAA->print_wf_history_table($form, 'AR/AP');

    print qq|
    </td>
  </tr>
  <tr>
    <td>
      <table width=100% id="invoice-payments-table">
        <thead>
          <tr class=listheading>
            <th colspan=7 class=listheading>| . $locale->text('Payments') . qq|</th>
          </tr>
        </thead>
|;

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        @column_index = qw(status datepaid source memo paid AP_paid);
    }
    else {
        @column_index = qw(status datepaid source memo paid exchangerate paidfx AP_paid);
    }

    $column_data{status}       = "<th></th>";
    $column_data{datepaid}     = "<th>" . $locale->text('Date') . "</th>";
    $column_data{paid}         = "<th>" . $locale->text('Amount') . "</th>";
    $column_data{exchangerate} = "<th>" . $locale->text('Exch') . "</th>";
    $column_data{paidfx}       = "<th>" . $form->{defaultcurrency} . "</th>";
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
    $form->{paidaccounts}++ if ( $form->{"paid_$form->{paidaccounts}"}+0 );
    $form->{"selectAR_paid"} =~ /value="(\Q$form->{cash_accno}\E--[^<]*)"/;
    $form->{"AR_paid_$form->{paidaccounts}"} = $1;
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        next if $readonly and not $form->{"datepaid_$i"};

        $form->hide_form("cleared_$i");

        my ($title, $approval_status, $icon) =
            $form->{"paid_${i}_approved"} ? ('', 'approved', '')
            : $form->{"datepaid_$i"} ? ($locale->text('Pending approval'), 'unapproved', '&#x23F2;')
            : ('', '', '');
        $title = qq|title="$title"| if $title;
        print qq|
        <tr class="invoice-payment $approval_status" $title>
|;

        $form->{"selectAR_paid_$i"} = $form->{selectAR_paid};
        $form->{"selectAR_paid_$i"} =~
s/option value="\Q$form->{"AR_paid_$i"}\E"/option value="$form->{"AR_paid_$i"}" selected="selected"/;

        # format amounts
        $totalpaid += $form->{"paid_$i"};
        $form->{"paidfx_$i"} =
            $form->format_amount(
                \%myconfig,
                $form->{"paid_$i"} * ($form->{"exchangerate_$i"} // 1), $form->{_setting_decimal_places} );
        $form->{"paid_$i"} =
          $form->format_amount( \%myconfig, $form->{"paid_$i"}, $form->{_setting_decimal_places} );
        $form->{"exchangerate_$i"} =
          $form->format_amount( \%myconfig, $form->{"exchangerate_$i"} );

        $exchangerate = qq|&nbsp;|;
        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            if ( $form->{"forex_$i"} ) {
                $exchangerate =
qq|<input type="hidden" name="exchangerate_$i" value="$form->{"exchangerate_$i"}">$form->{"exchangerate_$i"}|;
            }
            else {
                $exchangerate =
qq|<input data-dojo-type="dijit/form/TextBox" name="exchangerate_$i" id="exchangerate_$i" size="10" value="$form->{"exchangerate_$i"}" $readonly>|;
            }
        }

        $exchangerate .= qq|
<input type="hidden" name="forex_$i" value="$form->{"forex_$i"}">
|;

        $column_data{status} = qq|<td style="text-align:center">$icon</td>|;
        $column_data{paid} =
qq|<td align="center"><input data-dojo-type="dijit/form/TextBox" name="paid_$i" id="paid_$i" size="11" value="$form->{"paid_$i"}" $readonly></td>|;
        $column_data{exchangerate} = qq|<td align="center">$exchangerate</td>|;
        $column_data{paidfx} = qq|<td align="center">$form->{"paidfx_$i"}</td>|;
        $column_data{AR_paid} =
qq|<td align="center"><select data-dojo-type="dijit/form/Select" name="AR_paid_$i" id="AR_paid_$i" $readonly>$form->{"selectAR_paid_$i"}</select></td>|;
        $column_data{datepaid} =
qq|<td align="center"><input class="date" data-dojo-type="lsmb/DateTextBox" name="datepaid_$i" id="datepaid_$i" size="11" title="$myconfig{dateformat}" value="$form->{"datepaid_$i"}" $readonly></td>|;
        $column_data{source} =
qq|<td align="center"><input data-dojo-type="dijit/form/TextBox" name="source_$i" id="source_$i" size="11" value="$form->{"source_$i"}" $readonly></td>|;
        $column_data{memo} =
qq|<td align="center"><input data-dojo-type="dijit/form/TextBox" name="memo_$i" id="memo_$i" size="11" value="$form->{"memo_$i"}" $readonly></td><td style="display:none">|;

        for (@column_index) { print qq|$column_data{$_}\n| }
        print "</td></tr>\n";
    }
    print "</table>";

    $form->{oldtotalpaid} = $totalpaid;
    $form->hide_form(qw(paidaccounts oldinvtotal oldtotalpaid));

    print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
<br>
|;

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Print')
    # type=submit $locale->text('Post')
    # type=submit $locale->text('Schedule')
    # type=submit $locale->text('Ship to')
    # type=submit $locale->text('Post as new')
    # type=submit $locale->text('E-mail')
    # type=submit $locale->text('Delete')
    # type=submit $locale->text('Sales Order')

    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        $form->print_button( \%button, $_ );
    }

    my $wf = $form->{_wire}->get( 'workflows' )->fetch_workflow( 'AR/AP', $form->{workflow_id} );
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
        IS->get_files($form, $locale);
        print qq|
<a href="pnl.pl?__action=generate_income_statement&pnl_type=invoice&id=$form->{id}">[| . $locale->text('Profit/Loss') . qq|]</a><br />
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
<td><a href="file.pl?__action=get&file_class=1&ref_key=$form->{id}&id=$file->{id}"
       target="_download">$file->{file_name}</a></td>
<td>$file->{mime_type}</td>
<td>| . $file->{uploaded_at} . qq|</td>
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
       $callback = $form->escape("is.pl?__action=edit&id=".$form->{id});
       print qq|
<a href="file.pl?__action=show_attachment_screen&ref_key=$form->{id}&file_class=1&callback=$callback"
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
    my $form_id = delete $form->{id}; # github issue #975
    $form->{ARAP} = 'AR';
    delete $form->{"partnumber_$form->{delete_line}"} if $form->{delete_line};
    $form->{exchangerate} =
      $form->parse_amount( \%myconfig, $form->{exchangerate} );

    $form->{$_} = $form->parse_date( \%myconfig, $form->{$_} )->to_output()
       for qw(transdate duedate crdate);


    $form->{taxes} = {};

    ( undef, $form->{employee_id} ) = split /--/, $form->{employee}
        if $form->{employee} && ! $form->{employee_id};
    if ( $newname = &check_name('customer') ) {
        $form->rebuild_vc('customer', $form->{transdate}, 1);
    }
    if ( ($form->{transdate} // '') ne ($form->{oldtransdate} // '') ) {
        $form->{duedate} =
          ( $form->{terms} )
          ? $form->current_date( \%myconfig, $form->{transdate},
            $form->{terms} * 1 )
          : $form->{duedate};
        $form->{oldtransdate} = $form->{transdate};

        $form->rebuild_vc('customer', $form->{transdate}, 1) if !$newname;

        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            delete $form->{exchangerate};
        }

    }
    else {
        $form->get_regular_metadata;
    }

    if ( $form->{currency} ne $form->{oldcurrency} ) {
        delete $form->{exchangerate};
    }

    $j = 1;
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} and $form->{"paid_$i"} != 0 ) {
            for (qw(datepaid source memo cleared)) {
                $form->{"${_}_$j"} = $form->{"${_}_$i"};
            }
            for (qw(paid exchangerate)) {
                $form->{"${_}_$j"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }

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

    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

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
            max($form->get_setting('min_empty')//1,1)
            - $current_empties);


    $form->{rowcount} += $new_empties;
    for my $i ( 1 .. $form->{rowcount}){
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
            IS->retrieve_item( \%myconfig, \%$form );

            $rows = scalar @{ $form->{item_list} };
        #TODO if language_code in select id="formname", see $printops &print_options $printops->{lang}, will do unnecessary lookup on new item
            if ( $form->{language_code} && $rows == 0 ) {
                $language_code = $form->{language_code};
                $form->{language_code} = "";
                IS->retrieve_item( \%myconfig, \%$form );
                $form->{language_code} = $language_code;
                $rows = scalar @{ $form->{item_list} };
            }

            if ($rows) {

                $form->{"sellprice_$i"} = $form->{item_list}->[0]->{sellprice};
                $form->{"qty_$i"} =
                  ( $form->{"qty_$i"} * 1 ) ? $form->{"qty_$i"} : 1;

                $sellprice =
                  $form->parse_amount( \%myconfig, $form->{"sellprice_$i"} );

                for (qw(partnumber description unit)) {
                    $form->{item_list}[$i]{$_} =
                      $form->quote( $form->{item_list}[$i]{$_} );
                }

                ###EH 20160218
                ### Why do we move {item_list}[0] into the $form hash,
                ### while above we quoted {item_list}[$i] ????
                for ( keys %{ $form->{item_list}[0] } ) {
                    # copy, but don't overwrite e.g. description
                    $form->{"${_}_$i"} = $form->{item_list}[0]{$_}
                         unless $form->{"${_}_$i"};
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
        }
    }
#    $form->create_links( module => "AR",
#             myconfig => \%myconfig,
#             vc => "customer",
#             billing => 1,
#             job => 1 );
#    $form->generate_selects(\%myconfig);
    $form->{id} = $form_id;
    check_form();
    $form->{rowcount}--;
    display_form();
}

sub post_and_approve {
    post();
    $form->call_procedure(funcname=>'draft_approve', args => [ $form->{id} ]);
}

sub post {
    $form->{ARAP} = 'AR';
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
    $form->isblank( "customer",  $locale->text('Customer missing!') );

    # if oldcustomer ne customer redo form
    if ( &check_name('customer') ) {
        &update;
        $form->finalize_request();
    }
    check_form(1);

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    $form->error( $locale->text('Cannot post invoice for a closed period!') )
        if ( $form->is_closed( $transdate ) );

    $form->isblank( "exchangerate", $locale->text('Exchange rate missing!') )
      if ( $form->{currency} ne $form->{defaultcurrency} );

    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        delete $form->{"paid_$i"} if $form->{"paid_$i"} == 0;
        if ( $form->{"paid_$i"}) {
            $datepaid = $form->datetonum( \%myconfig, $form->{"datepaid_$i"} );

            $form->isblank( "datepaid_$i",
                $locale->text('Payment date missing!') );

            $form->error(
                $locale->text('Cannot post payment for a closed period!')
                )
                if ( $form->is_closed( $datepaid ) );

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

    IS->post_invoice( \%myconfig, \%$form );

    my $id = $form->{old_workflow_id} // $form->{workflow_id};
    my $wf = $form->{_wire}->get('workflows')->fetch_workflow( 'AR/AP', $id );

    # m/save_as/ matches both 'print_and_save_as'_new as well as 'save_as_new'
    # note that "post" is modelled through the 'approve' entrypoint
    # and that the 'post' entrypoint actually models the 'save' action
    if ($form->{__action} =~ m/post_as/) {
        $wf->execute_action( 'save_as_new' );
    }
    else {
        my $ctx = $wf->context;
        $ctx->param( spawned_type => 'Order/Quote' );
        $ctx->param( spawned_id   => $form->{workflow_id} );


        $wf->execute_action( $form->{__action} );
    }

    delete $form->{old_workflow_id};

    edit();
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

    $old_form = Form->new;
    $form->{display_form} = "post";
    for ( keys %$form ) { $old_form->{$_} = $form->{$_} }
    $old_form->{rowcount}++;

    my $wf =
        $form->{_wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    $wf->execute_action( 'print' );
    &print_form($old_form);

}

sub hold {
    on_hold();
}

sub release {
    on_hold();
}

sub on_hold {

    if ($form->{id}) {

        my $toggled = IS->toggle_on_hold($form);

        #&invoice_links(); # is that it?
        if ($form->{workflow_id}) {
            my $wf = $form->{_wire}->get('workflows')
                ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
            $wf->execute_action( $form->{__action} );
        }
        &edit(); # it was already IN edit for this to be reached.
    }
}



sub save_info {

        my $taxformfound=0;

        $taxformfound=IS->taxform_exist($form,$form->{"customer_id"});

        $form->{arap} = 'ar';
        AA->save_intnotes($form);
        AA->save_employee($form);

        foreach my $i(1..($form->{rowcount}))
        {

        if($form->{"taxformcheck_$i"} and $taxformfound)
        {

          IS->update_invoice_tax_form($form,$form->{dbh},$form->{"invoice_id_$i"},"true") if($form->{"invoice_id_$i"});

        }
        else
        {

            IS->update_invoice_tax_form($form,$form->{dbh},$form->{"invoice_id_$i"},"false") if($form->{"invoice_id_$i"});

        }

        }

        if ($form->{workflow_id}) {
            my $wf = $form->{_wire}->get('workflows')
                ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
            $wf->execute_action( $form->{__action} );
        }
        if ($form->{callback}){
        print "Location: $form->{callback}\n";
        print "Status: 302 Found\n\n";
        print qq|<html><body class="lsmb">|;
        my $url = $form->{callback};
        print qq|If you are not redirected automatically, click <a href="$url">|
            . qq|here</a>.</body></html>|;

        } else {
            edit();
        }

}

1;
