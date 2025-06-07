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
# Copyright (c) 2005
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#
#  Author: DWS Systems Inc.
#     Web: http://www.ledgersmb.org/
#
#  Contributors:
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
# AR / AP
#
#======================================================================

package lsmb_legacy;
use LedgerSMB::Form;
use LedgerSMB::IIAA;
use LedgerSMB::IR;
use LedgerSMB::IS;
use LedgerSMB::Tax;
# use LedgerSMB::DBObject::TransTemplate;

use List::Util qw(uniq);
use Workflow::Context;

# any custom scripts for this one
if ( -f "old/bin/custom/aa.pl" ) {
    eval { require "old/bin/custom/aa.pl"; };
}

my $is_update;


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

sub copy_to_new{
    delete $form->{id};
    delete $form->{invnumber};
    delete $form->{approved};
    delete $form->{workflow_id};
    $form->{paidaccounts} = 1;
    if ($form->{paid_1}){
        delete $form->{paid_1};
    }
    update();
}

sub new_screen {
    my @reqprops = qw(
        ARAP vc dbh stylesheet batch_id script type _locale _wire invdate
        );
    $oldform = $form;
    $form = {};
    bless $form, 'Form';
    for (@reqprops){
        $form->{$_} = $oldform->{$_};
    }
    &add();
}

sub add {
    $form->{title} = "Add";

    if (defined $form->{type}
        and $form->{type} eq "credit_note"){
        $form->{reverse} = 1;
        $form->{subtype} = 'credit_note';
        $form->{type} = 'transaction';
    } elsif (defined $form->{type}
             and $form->{type} eq 'debit_note'){
        $form->{reverse} = 1;
        $form->{subtype} = 'debit_note';
        $form->{type} = 'transaction';
    }
    else {
        $form->{reverse} = 0;
    }

    &create_links;

    $form->{focus} = "amount_1";
    &display_form;
    return 1;
}

sub del {
    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    $wf->execute_action( 'del' );

    $form->info($locale->text('Draft deleted'));
}

sub edit {

    &create_links;
    $form->{title} = $locale->text("Edit");
    if ($form->{reverse}){
        if ($form->{ARAP} eq 'AR'){
            $form->{subtype} = 'credit_note';
            $form->{type} = 'transaction';
        } elsif ($form->{ARAP} eq 'AP'){
            $form->{subtype} = 'debit_note';
            $form->{type} = 'transaction';
        } else {
            $form->error("Unknown AR/AP selection value: $form->{ARAP}");
        }
    }

    &display_form;
}

sub reverse {
    $form->{title}     = $locale->text('Add');
    $form->{reversing_reference} = $form->{invnumber};
    $form->{invnumber} .= '-VOID';
    my $wf = $form->{_wire}->get( 'workflows' )
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    $wf->execute_action( 'reverse' );

    &create_links;

    delete $form->{workflow_id};
    $form->{reversing} = delete $form->{id};
    delete $form->{approved};
    $form->{reverse} = $form->{reverse} ? 0 : 1;
    $form->{paidaccounts} = 0;
    if ($form->{reverse}){
        if ($form->{ARAP} eq 'AR'){
            $form->{subtype} = 'credit_note';
            $form->{type} = 'transaction';
        } elsif ($form->{ARAP} eq 'AP'){
            $form->{subtype} = 'debit_note';
            $form->{type} = 'transaction';
        } else {
            $form->error("Unknown AR/AP selection value: $form->{ARAP}");
        }
    }

    &display_form;
}

sub post_reversing {
    # we should save only the reference, sequence, transdate, description and notes;
    # get the rest from the transaction being reversed.

    $form->error(
        $locale->text('Cannot post transaction for a closed period!') )
        if ( $transdate and $form->is_closed( $transdate ) );
    if (not $form->{id}) {
        do {
            local $form->{id} = $form->{reversing};

            # save data we want to use from the posted form,
            # not from the reversed transaction.
            local $form->{reversing};
            local $form->{reverse};
            local $form->{notes};
            local $form->{description};
            local $form->{reference};
            local $form->{approved};
            local $form->{workflow_id};

            &create_links; # create_links overwrites 'reversing'
        };

        my $wf = $form->{_wire}->get('workflows')
            ->create_workflow( 'AR/AP',
                               Workflow::Context->new(
                                   'transdate' => $form->{transdate},
                                   'batch-id' => $form->{batch_id},
                                   'table_name' => 'gl',
                                   'reversing' => $form->{reversing},
                                   'is_transaction' => 1
                               ) );
        $form->{workflow_id} = $wf->id;
        $wf->execute_action( $form->{__action} );

        AA->post_transaction( \%myconfig, \%$form );
        $form->call_procedure( funcname=>'draft_approve',
                               args => [ $form->{id} ]);
        $form->{approved} = 1;

        my $query = q{UPDATE transactions SET reversing = ? WHERE id = ?};
        $form->{dbh}->do(
            $query,
            {},
            $form->{reversing},
            $form->{id})
            or $form->dberror($query);
    }
    else {
        my $query = <<~'QUERY';
        UPDATE gl
           SET reference = ?,
               description = ?,
               transdate = ?,
               notes = ?
         WHERE id = ?
        QUERY
    }

    delete $form->{__action};
    display_form();
}

sub display_form {
    my $invnumber = "sinumber";
    if ( $form->{vc} eq 'vendor' ) {
        $invnumber = "vinumber";
    }
    $form->{format} = $form->get_setting('format') unless $form->{format};
    $form->close_form;
    $form->generate_selects(\%myconfig);
    $form->open_form;
    AA->get_files($form, $locale);
    my $readonly = $form->{reversing} or $form->{approved};
    &form_header( readonly => $readonly );
    &form_footer( readonly => $readonly );

}

sub create_links {

    if ( $form->{script} eq 'ap.pl' ) {
        $form->{ARAP} = 'AP';
        $form->{vc}   = 'vendor';
    }
    elsif ( $form->{script} eq 'ar.pl' ) {
        $form->{ARAP} = 'AR';
        $form->{vc}   = 'customer';
    }

     $form->create_links( module => $form->{ARAP},
                                 myconfig => \%myconfig,
                                 vc => $form->{vc},
                                 billing => ($form->{vc}//'') eq 'customer'
                                      && ($form->{type}//'') eq 'invoice')
        unless $form->{"$form->{ARAP}_links"};


    $duedate     = $form->{duedate};
    $crdate     = $form->{crdate};

    $form->{formname} = "transaction";
    $form->{media}    //= $myconfig{printer};

    # currencies
    if (!$form->{currencies}){
        $form->error($locale->text(
           'No currencies defined.  Please set these up under System/Defaults.'
        ));
    }
    @curr = @{$form->{currencies}};

    for (@curr) {
        $form->{selectcurrency} .= "<option value=\"$_\">$_</option>\n"
    }

    my $vc = $form->{vc};
    AA->get_name( \%myconfig, \%$form )
            unless ($form->{"old$vc"} and $form->{$vc} and $form->{"old$vc"} eq $form->{$vc})
                    or ($form->{"old$vc"} and $form->{"old$vc"} =~ /^\Q$form->{$vc}\E--/);

    $form->{taxaccounts} =
        join(' ',
             uniq((split / /, $form->{taxaccounts}),
                  # add transaction tax accounts, which may no longer be applicable to
                  # the customer, but still are for the transaction
                  IIAA->trans_taxaccounts($form) ));

    $form->{currency} =~ s/ //g if $form->{currency};
    $form->{duedate}     = $duedate     if $duedate;
    $form->{crdate}      = $crdate      if $crdate;

    if ($form->{"$form->{vc}"} && $form->{"$form->{vc}"} !~ /--/){
        $form->{"old$form->{vc}"} = $form->{$form->{vc}} . '--' . $form->{"$form->{vc}_id"};
    } else {
        $form->{"old$form->{vc}"} = $form->{$form->{vc}};
    }
    $form->{oldtransdate} = $form->{transdate};

    # Business Reporting Units
    $form->all_business_units;

    # forex
    $form->{forex} = $form->{exchangerate};
    $exchangerate = ( $form->{exchangerate} ) ? $form->{exchangerate} : 1;

    $netamount = 0;
    $tax       = 0;
    $taxrate   = 0;
    $ml = LedgerSMB::PGNumber->new(
        ($form->{ARAP} eq 'AR') ? 1 : -1
    );

    foreach my $key ( keys %{ $form->{"$form->{ARAP}_links"} } ) {


        # if there is a value we have an old entry
        if ($form->{acc_trans}{$key}) {
        foreach my $i ( 1 .. scalar @{ $form->{acc_trans}{$key} } ) {


            if ( $key eq "$form->{ARAP}_paid" ) {

                $form->{"$form->{ARAP}_paid_$i"} =
"$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
                $form->{"paid_$i"} =
                    $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * -1 * $ml;
                $form->{"paid_${i}_approved"} =
                    $form->{acc_trans}{$key}->[ $i - 1 ]->{approved};
                $form->{"datepaid_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{transdate};
                $form->{"source_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{source};
                $form->{"memo_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{memo};

                $form->{"forex_$i"} = $form->{"exchangerate_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{exchangerate};

                $form->{paidaccounts}++;
            }
            else {

                $akey = $key;
                $akey =~ s/$form->{ARAP}_//;

                if ( $key eq "$form->{ARAP}_tax" ) {
                    $form->{"${key}_$form->{acc_trans}{$key}->[$i-1]->{accno}"}
                      = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
                    $form->{"${akey}_$form->{acc_trans}{$key}->[$i-1]->{accno}"}
                      = $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * $ml;

                    $tax +=
                      $form->{
                        "${akey}_$form->{acc_trans}{$key}->[$i-1]->{accno}"};
                    $taxrate +=
                      $form->{"$form->{acc_trans}{$key}->[$i-1]->{accno}_rate"};

                }
                else {


                    $form->{"${akey}_$i"} =
                      $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * $ml;

                    if ( $akey eq 'amount' ) {
                        $form->{"description_$i"} =
                          $form->{acc_trans}{$key}->[ $i - 1 ]->{memo};

             $form->{"entry_id_$i"} =
                          $form->{acc_trans}{$key}->[ $i - 1 ]->{entry_id};

            $form->{"taxformcheck_$i"}=1 if(AA->get_taxcheck($form->{"entry_id_$i"},$form->{dbh}));

                       $form->{rowcount}++;
                        $netamount += $form->{"${akey}_$i"};

                        my $ref = $form->{acc_trans}{$key}->[ $i - 1 ];
                        for my $cls (@{$form->{bu_class}}){
                           if ($ref->{"b_unit_$cls->{id}"}){
                              $form->{"b_unit_$cls->{id}_$i"}
                                                         = $ref->{"b_unit_$cls->{id}"};
                           }
                        }
                    }
                    elsif (not $form->{acc_trans}{$key}->[$i-1]
                           ->{payment_line}) {
                        $form->{invtotal} =
                          $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * -1 * $ml;
                    }
                    $form->{"${key}_$i"} =
"$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";



                }
            }
        }
        }
    }

    $form->{paidaccounts} = 1 if not $form->{paidaccounts};


    # check if calculated is equal to stored
    # taxincluded can't be calculated
    # this works only if all taxes are checked

    if ( !$form->{oldinvtotal} ) { # first round loading (or amount was 0)
        for (@taxaccounts) { $form->{ "calctax_" . $_->{account} } = 1 }
    }

    $form->{rowcount}++ if ( $form->{id} || !$form->{rowcount} );
    $form->{rowcount} = 1 unless $form->{"$form->{ARAP}_amount_1"};

    delete $form->{selectcurrency};
    #$form->generate_selects(\%myconfig);
    $form->{$form->{ARAP}} = $form->{"$form->{ARAP}_1"} unless $form->{$form->{ARAP}} and $form->{__action} eq 'update';

}

sub form_header {
    my %args = @_;
    my $min_lines = $form->get_setting('min_empty') // 0;
    my $readonly = ($args{readonly} or $form->{approved}) ? 'readonly="readonly"' : '';
    my $readonly_headers = $form->{approved} ? 'readonly="readonly"' : ''; # not read only unless approved

    $form->generate_selects(\%myconfig) unless $form->{"select$form->{ARAP}"};


    my $wf;
    if($form->{workflow_id}) {
        $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    }
    else {
        $wf = $form->{_wire}->get('workflows')
            ->create_workflow( 'AR/AP',
                               Workflow::Context->new(
                                   'batch-id' => $form->{batch_id},
                                   'table_name' => lc($form->{ARAP}),
                                   is_transaction => 1,
                                   reversing => $form->{reversing},
                               ) );
        $form->{workflow_id} = $wf->id;
    }
    $wf->context->param( transdate => $form->{transdate} );
    $title = $form->{title};
    $form->all_business_units($form->{transdate},
                              $form->{"$form->{vc}_id"},
                              $form->{ARAP});

    if($form->{batch_id})
    {
        $form->{batch_control_code}=$form->get_batch_control_code($form->{dbh},$form->{batch_id});
        $form->{batch_description}=$form->get_batch_description($form->{dbh},$form->{batch_id});
    }
    #     $locale->text('Add AR Transaction');
    #     $locale->text('Add AP Transaction');
    #   $locale->text('Edit AR Transaction');
    #   $locale->text('Edit AP Transaction');
    if ($form->{ARAP} eq 'AP'){
        $eclass = '1';
    } elsif ($form->{ARAP} eq 'AR'){
        $eclass = '2';
    }
    my $title_msgid="$title $form->{ARAP} Transaction";
    my $status_div_id = $form->{ARAP} . '-transaction'
         . ($form->{reverse} ? '-reverse' : '');
    if ($form->{reverse} == 0){
       #$form->{title} = $locale->text("[_1] [_2] Transaction", $title, $form->{ARAP});
       $form->{title} = $locale->maketext($title_msgid);
    }
    elsif($form->{reverse} == 1) {
       if ($form->{subtype} eq 'credit_note'){
           $title_msgid="$title Credit Note";
           $form->{title}=$locale->maketext($title_msgid);
           #$form->{title} = $locale->text("[_1] Credit Note", $title);
       } elsif ($form->{subtype} eq 'debit_note'){
           $title_msgid="$title Debit Note";
           $form->{title}=$locale->maketext($title_msgid);
           #$form->{title} = $locale->text("[_1] Debit Note", $title);
       } else {
           $form->error("Unknown subtype $form->{subtype} in $form->{ARAP} "
              . "transaction.");
       }
    }
    else {
       $form->error('Reverse flag not true or false on AR/AP transaction');
    }

    $form->{taxincluded} = ( $form->{taxincluded} ) ? "checked" : "";

    # $locale->text('Add Debit Note')
    # $locale->text('Edit Debit Note')
    # $locale->text('Add Credit Note')
    # $locale->text('Edit Credit Note')
    # $locale->text('Add AP Transaction')
    # $locale->text('Edit AP Transaction')

    $form->{selectprojectnumber} =
      $form->unescape( $form->{selectprojectnumber} );

    # format amounts
    my $formatted_exchangerate =
      $form->format_amount( \%myconfig, $form->{exchangerate} );

    $exchangerate = qq|<tr>|;
    $exchangerate .= qq|
                <th align=right nowrap><label for="currency">| . $locale->text('Currency') . qq|</label></th>
        <td><select data-dojo-type="dijit/form/Select" id=currency name=currency $readonly>$form->{selectcurrency}</select></td> |
      if $form->{defaultcurrency};
    if (   $form->{defaultcurrency}
        && $form->{currency} ne $form->{defaultcurrency} )
    {
            $exchangerate .= qq|
        <th align=right><label for="exchangerate">| . $locale->text('Exchange Rate') . qq|</label></th>
        <td><input data-dojo-type="dijit/form/TextBox" name=exchangerate id=exchangerate size=10 value=$formatted_exchangerate $readonly></td>
|;
    }
     else {
         $exchangerate .= q|<input name=exchangerate type=hidden value=1>|;
    }
    $exchangerate .= qq|
</tr>
|;

    if ( ( $rows = $form->numtextrows( $form->{notes}, 50 ) - 1 ) < 2 ) {
        $rows = 2;
    }
    $form->{notes} //= '';
    $notes =
qq|<textarea data-dojo-type="dijit/form/Textarea" name=notes rows=$rows cols=50 wrap=soft $readonly_headers>$form->{notes}</textarea>|;
    $form->{intnotes} //= '';
    $intnotes =
qq|<textarea data-dojo-type="dijit/form/Textarea" name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;

    $department = qq|
          <tr>
        <th align="right" nowrap>| . $locale->text('Department') . qq|</th>
        <td colspan=3><select data-dojo-type="dijit/form/Select" id=department name=department $readonly>$form->{selectdepartment}</select>
        <input type=hidden name=selectdepartment value="|
      . $form->escape( $form->{selectdepartment}, 1 ) . qq|">
        </td>
          </tr>
        | if $form->{selectdepartment};
     $department //= '';

    $n = ( ($form->{creditremaining} // 0) < 0 ) ? "0" : "1";

    $name =
      ( $form->{"select$form->{vc}"} )
      ? qq|<select data-dojo-type="lsmb/FilteringSelect" id="$form->{vc}" name="$form->{vc}" $readonly><option></option>$form->{"select$form->{vc}"}</select>|
      : qq|<input data-dojo-type="dijit/form/TextBox" id="$form->{vc}" name="$form->{vc}" value="$form->{$form->{vc}}" size=35 $readonly>
                 <a href="#contact.pl?__action=add&entity_class=$eclass"
                    id="new-contact" target="_blank">[|
                 .  $locale->text('New') . qq|]</a>|;

    $employee = qq|
                <input type=hidden name=employee value="$form->{employee}">
|;

    if ( $form->{selectemployee} ) {
        $label =
          ( $form->{ARAP} eq 'AR' )
          ? $locale->text('Salesperson')
          : $locale->text('Employee');

        $employee = qq|
          <tr>
        <th align=right nowrap><label for="employee">$label</label></th>
        <td><select data-dojo-type="dijit/form/Select" id=employee name=employee $readonly>$form->{selectemployee}</select></td>
        <input type=hidden name=selectemployee value="|
          . $form->escape( $form->{selectemployee}, 1 ) . qq|">
          </tr>
|;
    }

    $focus = ( $form->{focus} ) ? $form->{focus} : "amount_$form->{rowcount}";

    $form->header;

 print qq|
<body> | .
$form->open_status_div($status_div_id) . qq|
<form id="transaction"
      method="post"
      data-dojo-type="lsmb/Form"
      data-lsmb-focus="${focus}"
      action="$form->{script}">
<input type=hidden name=type value="$form->{formname}">
<input type=hidden name=title value="$title">

|;
    $form->hide_form(
        qw(batch_id approved id sort
           oldtransdate audittrail recurring checktax reverse subtype
           entity_control_code tax_id meta_number default_reportable
           address city zipcode state country workflow_id reversing)
    );

    if ( $form->{vc} eq 'customer' ) {
        $label = $locale->text('Customer');
    }
    else {
        $label = $locale->text('Vendor');
    }

    $form->hide_form(
        "old$form->{vc}",  "$form->{vc}_id",
        "terms",           "creditlimit",
        "creditremaining", "defaultcurrency",
        "rowcount"
    );

    print qq|

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table width=100% id="invoice-header">
        <tr valign=top>
      <td>
        <table>
          <tr>
        <th align="right" nowrap><label for="$form->{vc}">$label</label></th>
        <td colspan=3>$name
                </td>
          </tr>
          <tr>
        <td colspan=3>
          <table width=100%>
            <tr> |;
    if ($form->get_setting('show_creditlimit')){
       print qq|
              <th align=left nowrap>| . $locale->text('Credit Limit') . qq|</th>
              <td>$form->{creditlimit}</td>
              <th align=left nowrap>| . $locale->text('Remaining') . qq|</th>
              <td class="plus$n">|
      . $form->format_amount( \%myconfig, $form->{creditremaining}, 0, "0" )
      . qq|</td>|;
    } else {
       print qq|<td>&nbsp;</td>|;
    }
    print qq|
            </tr>
          </table>
        </td>
          </tr>
|;
        if($form->{batch_id})
        {
        print qq|    <tr>
        <th align="right" nowrap>| .
            $locale->text('Batch Control Code') . qq|</th>
        <td>$form->{batch_control_code}</td>
          </tr>
        <tr>
        <th align="right" nowrap>| .
            $locale->text('Batch Name') . qq|</th>
        <td>$form->{batch_description}</td>
          </tr>

|;

        }



        if ($form->{entity_control_code}) {
            $form->{$_} //= '' for (qw/entity_control_code tax_id
                                    meta_number address city/);
            print qq|
            <tr>
        <th align="right" nowrap>| .
            $locale->text('Entity Control Code') . qq|</th>
        <td colspan=3><a href="#contact.pl?__action=get_by_cc&control_code=$form->{entity_control_code}" target="_blank"><b>$form->{entity_control_code}</b></a></td>
          </tr>
            <tr>
        <th align="right" nowrap>| .
            $locale->text('Tax ID') . qq|</th>
        <td colspan=3>$form->{tax_id}</td>
          </tr>
            <tr>
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

     $form->{$_} //= '' for (qw(description invnumber ordnumber duedate ponumber));
    $form->{$_} //= 'today' for (qw(crdate transdate));
     $myconfig{dateformat} //= '';
     $employee //= '';
     $form->{sequence_select} = $form->sequence_dropdown($invnumber, $readonly_headers)
         unless $form->{id} and ($form->{vc} eq 'vendor');
     $form->{sequence_select} //= '';
     print qq|
          $exchangerate
          $department
            <tr>
               <th align="right" nowrap><label for="description">| . $locale->text('Description') . qq|</label>
               </th>
               <td><input data-dojo-type="dijit/form/TextBox" type="text" name="description" id="description" size="40"
                   value="| . ($form->{description} // '') . qq|" $readonly_headers /></td>
            </tr>
        </table>
      </td>
      <td style="vertical-align:middle">| .
         ($form->{reversing} ? qq|<a href="$form->{script}?__action=edit&amp;id=$form->{reversing}">| . ($form->{approved} ? $locale->text('This transaction reverses transaction [_1] with ID [_2]', $form->{reversing_reference}, $form->{reversing}) : $locale->text('This transaction will reverse transaction [_1] with ID [_2]', $form->{reversing_reference}, $form->{reversing})) .q|</a><br />| : '') .
         ($form->{reversed_by} ? qq|<a href="$form->{script}?__action=edit&amp;id=$form->{reversed_by}"> | . $locale->text('This transaction is reversed by transaction [_1] with ID [_2]', $form->{reversed_by_reference}, $form->{reversed_by}) . q|</a>| : '') .
    qq|</td>
      <td align=right>
        <table>
          $employee
          <tr>
        <th align=right nowrap><label for="invnum">| . $locale->text('Invoice Number') . qq|</label></th>
        <td><input data-dojo-type="dijit/form/TextBox" name=invnumber id=invnum size=20 value="$form->{invnumber}" $readonly_headers>
                      $form->{sequence_select}</td>
          </tr>
          <tr>
        <th align=right nowrap><label for="ordnum">| . $locale->text('Order Number') . qq|</label></th>
        <td><input data-dojo-type="dijit/form/TextBox" name=ordnumber id=ordnum size=20 value="$form->{ordnumber}" $readonly></td>
          </tr>
              <tr>
                <th align=right nowrap><label for="crdate">| . $locale->text('Invoice Created') . qq|</label></th>
                <td><lsmb-date name=crdate id=crdate size=11 title="($myconfig{'dateformat'})" value="$form->{crdate}" $readonly_headers></lsmb-date></td>
              </tr>
          <tr>
        <th align=right nowrap><label for="transdate">| . $locale->text('Invoice Date') . qq|</label></th>
        <td><lsmb-date name=transdate id=transdate size=11 title="($myconfig{'dateformat'})" value="$form->{transdate}" $readonly_headers></lsmb-date></td>
          </tr>
          <tr>
        <th align=right nowrap><label for="duedate">| . $locale->text('Due Date') . qq|</label></th>
        <td><input class="date" data-dojo-type="lsmb/DateTextBox" name=duedate id=duedate size=11 title="$myconfig{'dateformat'}" value=$form->{duedate} $readonly_headers></td>
          </tr>
          <tr>
        <th align=right nowrap><label for="ponum">| . $locale->text('PO Number') . qq|</label></th>
        <td><input data-dojo-type="dijit/form/TextBox" name=ponumber id=ponum size=20 value="$form->{ponumber}" $readonly></td>
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
      <table id="transaction-lines">
|;

    print qq|
    <thead>
    <tr class="listheading">
      <th>| . $locale->text('Amount') . qq|</th>
     <th>| . (($form->{currency} ne $form->{defaultcurrency}) ? $form->{defaultcurrency} : '') . qq|</th>
      <th>| . $locale->text('Account') . qq|</th>
      <th>| . $locale->text('Description') . qq|</th>
      <th>| . $locale->text('Tax Form Applied') . qq|</th>|;
    for my $cls (@{$form->{bu_class}}){
        if (scalar @{$form->{b_units}->{"$cls->{id}"}}){
            print qq|<th>| . $locale->maketext($cls->{label}) . qq|</th>|;
        }
    }
    print qq|
    </th>
    </thead>
|;


    # Display rows

    $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    foreach my $i ( 1 .. $form->{rowcount} + $min_lines) {
        next if $readonly and not $form->{"$form->{ARAP}_amount_$i"};

        # format amounts
        $form->{"amount_$i"} =
          $form->format_amount( \%myconfig,$form->{"amount_$i"}, $form->{_setting_decimal_places} );

        $project = qq|
      <td align=right><select data-dojo-type="dijit/form/Select" id="projectnumber_$i" name="projectnumber_$i" $readonly>$form->{"selectprojectnumber_$i"}</select></td>
            | if $form->{selectprojectnumber};
        $project //= '';

        $form->{"description_$i"} //= '';
        if ( ( $rows = $form->numtextrows( $form->{"description_$i"}, 40 ) ) >
            1 )
        {
            $description =
qq|<td><textarea data-dojo-type="dijit/form/Textarea" name="description_$i" rows=$rows cols=40 $readonly>$form->{"description_$i"}</textarea></td>|;
        }
        else {
            $description =
qq|<td><input data-dojo-type="dijit/form/TextBox" name="description_$i" size=40 value="$form->{"description_$i"}" $readonly></td>|;
        }

    $taxchecked="";
    if($form->{"taxformcheck_$i"} or ($form->{default_reportable} and ($i == $form->{rowcount})))
    {
        $taxchecked=qq|CHECKED="CHECKED"|;
    }

    $taxformcheck=qq|<td><input type="checkbox" data-dojo-type="dijit/form/CheckBox" name="taxformcheck_$i" value="1" $taxchecked></td>|;
        print qq|
    <tr valign=top class="transaction-line $form->{ARAP}" id="line-$i">
     <td><input data-dojo-type="dijit/form/TextBox" id="amount_$i" name="amount_$i" size=10 value="$form->{"amount_$i"}" $readonly></td>
     <td>| . (($form->{currency} ne $form->{defaultcurrency})
              ? $form->format_amount(\%myconfig, $form->parse_amount( \%myconfig, $form->{"amount_$i"} )
                                                  * $form->{exchangerate}, $form->{_setting_decimal_places})
              : '')  . qq|</td>
     <td><select data-dojo-type="lsmb/FilteringSelect" id="$form->{ARAP}_amount_$i" name="$form->{ARAP}_amount_$i" $readonly><option></option>$form->{"select$form->{ARAP}_amount_$i"}</select></td>
      $description
          $taxformcheck
      $project|;

        for my $cls (@{$form->{bu_class}}){
            if (scalar @{$form->{b_units}->{"$cls->{id}"}}){
                print qq|<td><select data-dojo-type="dijit/form/Select" id="b_unit_$cls->{id}_$i" name="b_unit_$cls->{id}_$i" $readonly>
                                    <option>&nbsp;</option>|;
                      for my $bu (@{$form->{b_units}->{"$cls->{id}"}}){
                         my $selected = '';
                         if ($form->{"b_unit_$cls->{id}_$i"} eq $bu->{id}){
                            $selected = 'selected="selected"';
                         }
                         print qq|  <option value="$bu->{id}" $selected>
                                        $bu->{control_code}
                                    </option>|;
                      }
                print qq|
                             </select>
                        </th>|;
            }
        }
        print qq|
    </tr>
|;

    $form->hide_form( "entry_id_$i"); #New block of code to pass entry_id

    }
     my $tax_base = $form->{invtotal};
     foreach my $item ( split / /, $form->{taxaccounts} ) {
        $form->{"calctax_$item"} =
          ( $form->{"calctax_$item"} ) ? "checked" : "";
        $form->{"tax_$item"} =
          $form->format_amount( \%myconfig, $form->{"tax_$item"}, $form->{_setting_decimal_places} );
        print qq|
        <tr class="transaction-row $form->{ARAP} tax" id="taxrow_$item">
      <td><input data-dojo-type="dijit/form/TextBox" name="tax_$item" id="tax_$item"
                     size=10 value=$form->{"tax_$item"} $readonly /></td>
      <td align=right><input id="calctax_$item" name="calctax_$item"
                                 class="checkbox" type="checkbox" data-dojo-type="dijit/form/CheckBox" value=1
                                 $form->{"calctax_$item"} $readonly
                            title="Calculate automatically"></td>
          <td><input type="hidden" name="$form->{ARAP}_tax_$item"
                id="$form->{ARAP}_tax_$item"
                value="$item" />$item--$form->{_accno_descriptions}->{$item}</td>
    </tr>
|;

        $form->hide_form(
            "${item}_rate",
            "${item}_taxnumber", "select$form->{ARAP}_tax_$item",
            "taxsource_$item"
            );
    }

    my $formatted_invtotal =
      $form->format_amount( \%myconfig, $form->{invtotal}, $form->{_setting_decimal_places} );

    $form->hide_form( "oldinvtotal", "oldtotalpaid", "taxaccounts" );

     $selectARAP = $form->{"select$form->{ARAP}"};
     if ($form->{$form->{ARAP}}) {
         $selectARAP =~ s/(\Qoption value="$form->{$form->{ARAP}}"\E)/$1 selected="selected"/;
     }
    print qq|
        <tr class="transaction-line $form->{ARAP} total" id="line-total">
      <th align=left>$formatted_invtotal</th>
     <td>| . (($form->{currency} ne $form->{defaultcurrency})
              ? $form->format_amount(
                  \%myconfig,
                  $form->{invtotal} * $form->{exchangerate},
                  $form->{_setting_decimal_places} ) : '') . qq|</td>
     <td><select data-dojo-type="dijit/form/Select" name="$form->{ARAP}" id="$form->{ARAP}" $readonly>
                 $selectARAP
              </select></td>
        </tr>
        <tr><td>&nbsp;</td></td>
        <tr class="transaction-total-paid"><td>| . $form->format_amount(\%myconfig, $form->{oldtotalpaid}, $form->{_setting_decimal_places} ) . qq|</td><td></td><td>| . $locale->text('Total paid') . qq|</td></tr>
        <tr class="transaction-remaining-balance"><td>| . $form->format_amount(\%myconfig, $form->{invtotal} - $form->{oldtotalpaid}, $form->{_setting_decimal_places} ) . qq|</td><td></td><td>| . $locale->text('Remaining balance') . qq|</td></tr>
        <tr><td>&nbsp;</td></td>
        <tr>
           <td>&nbsp;</td>
           <td>&nbsp;</td>
           <th align=left>| . $locale->text('Notes') . qq|</th>
           <th align=left>| . $locale->text('Internal Notes') . qq|</th>
        </tr>
    <tr>
           <td>&nbsp;</td>
           <td>&nbsp;</td>
      <td>$notes</td>
          <td>$intnotes</td>
    </tr>
      </table>
    </td>
  </tr>

  <tr class=listheading id="transaction-payments-label">
    <th class=listheading>| . $locale->text('Payments') . qq|</th>
  </tr>

  <tr>
    <td>
      <table width=100% id="invoice-payments-table">
|;

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        @column_index = qw(status datepaid source memo paid ARAP_paid);
    }
    else {
        @column_index = qw(status datepaid source memo paid exchangerate paidfx ARAP_paid);
    }

    $column_data{status}       = "<th></th>";
    $column_data{datepaid}     = "<th>" . $locale->text('Date') . "</th>";
    $column_data{paid}         = "<th>" . $locale->text('Amount') . "</th>";
    $column_data{exchangerate} = "<th>" . $locale->text('Exch') . "</th>";
    $column_data{paidfx}       = "<th>" . $form->{defaultcurrency} . "</th>";
    $column_data{ARAP_paid}    = "<th>" . $locale->text('Account') . "</th>";
    $column_data{source}       = "<th>" . $locale->text('Source') . "</th>";
    $column_data{memo}         = "<th>" . $locale->text('Memo') . "</th>";

    print qq|
        <tr>
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print "
        </tr>
";

     # add 0 to numify the value in paid_$paidaccounts...
    $form->{paidaccounts}++ if ( defined $form->{"paid_$form->{paidaccounts}"}
                                 and $form->{"paid_$form->{paidaccounts}"}+0 );
    if (defined $form->{cash_accno}) {
        $form->{"select$form->{ARAP}_paid"} =~ /value="(\Q$form->{cash_accno}\E--[^<]*)"/;
        $form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} = $1;
    }
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        next if $readonly and not $form->{"datepaid_$i"};

        $form->hide_form("cleared_$i");

        my ($title, $approval_status, $icon) =
            ($form->{approved} and $form->{"paid_${i}_approved"}) ? ('', 'approved', '')
            : $form->{"datepaid_$i"} ? ($locale->text('Pending approval'), 'unapproved', '&#x23F2;')
            : ('', '', '');
        $title = qq|title="$title"| if $title;
        print qq|
        <tr class="invoice-payment $approval_status" $title>
|;

        $form->{"select$form->{ARAP}_paid_$i"} =
            $form->{"select$form->{ARAP}_paid"};
        if ($form->{"$form->{ARAP}_paid_$i"}) {
            $form->{"select$form->{ARAP}_paid_$i"} =~
                s/(value="\Q$form->{"$form->{ARAP}_paid_$i"}\E")/$1 $readonly selected="selected"/;
        }

        # format amounts
        $form->{"paidfx_$i"} = $form->format_amount(
            \%myconfig,
            ($form->{"paid_$i"} // 0) * ($form->{"exchangerate_$i"} // 1) , $form->{_setting_decimal_places} );
        $form->{"paid_$i"} =
          $form->format_amount( \%myconfig, $form->{"paid_$i"}, $form->{_setting_decimal_places} );
        $form->{"exchangerate_$i"} =
          $form->format_amount( \%myconfig, $form->{"exchangerate_$i"} );

        $exchangerate = qq|&nbsp;|;
        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            if ( $form->{"forex_$i"} ) {
                $form->hide_form("exchangerate_$i");
                $exchangerate = qq|$form->{"exchangerate_$i"}|;
            }
            else {
                $exchangerate =
qq|<input data-dojo-type="dijit/form/TextBox" name="exchangerate_$i" size=10 value=$form->{"exchangerate_$i"} $readonly>|;
            }
        }

        $form->hide_form("forex_$i");

        $form->{"datepaid_$i"} //= '';
        $form->{"source_$i"} //= '';
        $form->{"memo_$i"} //= '';

        $column_data{status} = qq|<td style="text-align:center;vertical-align:middle">$icon</td>|;
        $column_data{paid} =
qq|<td align=center><input data-dojo-type="dijit/form/TextBox" name="paid_$i" id="paid_$i" size=11 value=$form->{"paid_$i"} $readonly></td>|;
        $column_data{ARAP_paid} =
qq|<td align=center><select data-dojo-type="lsmb/FilteringSelect" name="$form->{ARAP}_paid_$i" id="$form->{ARAP}_paid_$i" $readonly>$form->{"select$form->{ARAP}_paid_$i"}</select></td>|;
        $column_data{exchangerate} = qq|<td align=center>$exchangerate</td>|;
        $column_data{paidfx} = qq|<td align=center>$form->{"paidfx_$i"}</td>|;
        $column_data{datepaid} =
qq|<td align=center><input class="date" data-dojo-type="lsmb/DateTextBox" name="datepaid_$i" id="datepaid_$i" size=11 value=$form->{"datepaid_$i"} $readonly></td>|;
        $column_data{source} =
qq|<td align=center><input data-dojo-type="dijit/form/TextBox" name="source_$i" id="source_$i" size=11 value="$form->{"source_$i"}" $readonly></td>|;
        $column_data{memo} =
qq|<td align=center><input data-dojo-type="dijit/form/TextBox" name="memo_$i" id="memo_$i" size=11 value="$form->{"memo_$i"}" $readonly></td>|;

        for (@column_index) { print qq|$column_data{$_}\n| }

        print "
        </tr>
";
    }

    $form->hide_form( "paidaccounts", 'cash_accno' );

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub form_footer {
    $form->hide_form(qw(callback path login sessionid form_id));

    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $wf->context->param( transdate => $transdate );

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Print')
    # type=submit $locale->text('Post')
    # type=submit $locale->text('Schedule')
    # type=submit $locale->text('Ship to')
    # type=submit $locale->text('Post as new')
    # type=submit $locale->text('Delete')

    my $printops = &print_options;
    my $formname = { name => 'formname',
                     options => [
                         {text=> $locale->text('Transaction'), value => 'transaction'},
                         ]
    };
    $wf->context->param( transdate => $transdate );
    %button_types = (
        print => 'lsmb/PrintButton'
        );
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
    ###TODO: Move "reversing" state to the workflow!
    if ($form->{reversing}) {
        delete $button{$_} for (qw(schedule update save_temp edit_and_save));
    }


    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} }
          keys %button ) {
        $form->print_button( \%button, $_ );
    }

    if ($wf and grep { $_ eq 'print' } $wf->get_current_actions( 'output' ) ) {
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

        # Don't show the print selectors, if there's no "Print" button
        print "<br><br>";
        print_select($form, $formname);
        print_select($form, $printops->{lang});
        print_select($form, $printops->{format});
        print_select($form, $printops->{media});

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} }
              keys %button ) {
            $form->print_button( \%button, $_ );
        }
    }
    if ($form->{id}){
        print qq|
<a href="pnl.pl?__action=generate_income_statement&pnl_type=invoice&id=$form->{id}">[| . $locale->text('Profit/Loss') . qq|]</a><br />
<table width="100%">
<tr><td>|;
        IIAA->print_wf_history_table( $form, 'AR/AP' );
print q|</td></tr><tr class="listtop"><th colspan="4">| . $locale->text('Attached and Linked Files') . qq|</th>
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
<td>|. $file->{uploaded_at} .qq|</td>
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
<td> | . $file->{attached_at}->to_output . qq| </td>
<td> $file->{attached_by} </td>
</tr>|;
       }
       print qq|
</table>|;
       $callback = $form->escape(
               lc($form->{ARAP}) . ".pl?__action=edit&id=".$form->{id}
       );
       print qq|
<a href="file.pl?__action=show_attachment_screen&ref_key=$form->{id}&file_class=1&callback=$callback"
   >[| . $locale->text('Attach') . qq|]</a>|;
    }

    print qq|
</form>
| . $form->close_status_div . qq|
</body>
</html>
|;
}


sub hold {
    on_hold();
}

sub release {
    on_hold();
}

sub on_hold {
    use LedgerSMB::IS;
    use LedgerSMB::IR; # TODO: refactor this over time

    if ($form->{id}) {
        if ($form->{ARAP} eq 'AR'){
            my $toggled = IS->toggle_on_hold($form);
        } else {
            my $toggled = IR->toggle_on_hold($form);
        }
        if ($form->{workflow_id}) {
            my $wf = $form->{_wire}->get('workflows')
                ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
            $wf->execute_action( $form->{__action} );
        }
        &edit();
    }
}


# sub save_temp {
#     my $lsmb = { %$form };
#     $lsmb->{is_invoice} = 1;
#     $lsmb->{due} = $form->{invtotal};
#     $lsmb->{credit_id} = $form->{customer_id} // $form->{vendor_id};
#     $lsmb->{curr} = $form->{currency};
#     my ($department_name, $department_id) = split/--/, $form->{department};
#      if (!$lsmb->{language_code}){
#         delete $lsmb->{language_code};
#     }
#     $lsmb->{credit_id} = $form->{"$form->{vc}_id"};
#     $lsmb->{department_id} = $department_id;
#     if ($form->{ARAP} eq 'AR'){
#         $lsmb->{entity_class} = 2;
#     } else {
#         $lsmb->{entity_class} = 1;
#     }
#     $lsmb->{post_date} = $form->{transdate};
#     for my $iter (0 .. $form->{rowcount}){
#         if ($form->{"$form->{ARAP}_amount_$iter"} and
#                   ($form->{"amount_$iter"} != 0)){
#              my ($acc_id, $acc_name) = split /--/, $form->{"$form->{ARAP}_amount_$iter"};
#              my $amount = $form->{"amount_$iter"};
#              push @{$lsmb->{journal_lines}},
#                   {accno => $acc_id,
#                    amount_fx => $amount,
#                    amount => $amount*$form->{exchangerate},
#                    curr => $form->{currency},
#                    cleared => 'false',
#                   };
#         }
#     }
#     $template = LedgerSMB::DBObject::TransTemplate->new(%$lsmb);
#     $template->save;
#     $form->redirect( $locale->text('Template Saved!') );
# }

sub edit_and_save {
    AA->post_transaction( \%myconfig, \%$form );

    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
        $wf->execute_action( $form->{__action} );
    }
    $form->{rowcount} = 0;
    $form->{paidaccounts} = 0;
    edit();
}

sub approve {
    $form->call_procedure(funcname=>'draft_approve', args => [ $form->{id} ]);

    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $form->{workflow_id} );
    $wf->execute_action( $form->{__action} );
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

    if ($form->{callback}){
        print "Location: $form->{callback}\n";
        print "Status: 302 Found\n\n";
        print qq|<html><body class="lsmb">|;
        my $url = $form->{callback};
        print qq|If you are not redirected automatically, click <a href="$url">|
                . qq|here</a>.</body></html>|;

    } else {
        update();
    }
}

sub update {
    my $display = shift;
    my $form_id = delete $form->{id};
    $form->open_form() unless $form->check_form();
    $is_update = 1;
        $form->{invtotal} = 0;

        $form->{exchangerate} =
          $form->parse_amount( \%myconfig, $form->{exchangerate} );

        @flds =
          ( "amount", "$form->{ARAP}_amount", "projectnumber", "description","taxformcheck" );
        $count = 0;
        @a     = ();
    foreach my $i ( 1 .. $form->{rowcount} ) {
            $form->{"amount_$i"} =
              $form->parse_amount( \%myconfig, $form->{"amount_$i"} );
            if ( $form->{"amount_$i"} ) {
                push @a, {};
                $j = $#a;

                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                $count++;
            }
        }

        $form->redo_rows( \@flds, \@a, $count, $form->{rowcount} );
        $form->{rowcount} = $count + 1;

        for ( 1 .. $form->{rowcount} ) {
        if ( defined $form->{"amount_$_"} ) {
            $form->{invtotal} += $form->{"amount_$_"};
        }
    }

        if ( $newname = &check_name( $form->{vc} ) ) {
            $form->{notes} = $form->{intnotes} unless $form->{id};
            $form->rebuild_vc($form->{vc}, $form->{transdate});
        }
        if ( $form->{transdate} ne $form->{oldtransdate} ) {
            $form->{duedate} =
              $form->current_date( \%myconfig, $form->{transdate},
                $form->{terms} * 1 );
            $form->{oldtransdate} = $form->{transdate};
            $newproj = $form->rebuild_vc($form->{vc}, $form->{transdate})
              if !$newname;
        }

    @taxaccounts = split / /, $form->{taxaccounts};

    for (@taxaccounts) {
        $form->{"tax_$_"} =
          $form->parse_amount( \%myconfig, $form->{"tax_$_"} );
        $form->{"calctax_$_"} = 1 if !$form->{invtotal};
    }

    my @taxaccounts = Tax::init_taxes($form, $form->{taxaccounts});
    my $tax = Tax::calculate_taxes( \@taxaccounts, $form, $form->{invtotal}, 0 );
    for (@taxaccounts) {
        if ($form->{'calctax_' . $_->account} && $is_update) {
            $form->{'tax_' . $_->account} = $_->value;
        }
        $form->{invtotal} += $_->value;
    }



    my $j = 1;
    my $totalpaid = LedgerSMB::PGNumber->bzero();
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} and $form->{"paid_$i"} != 0 ) {
            for (qw(datepaid source memo cleared)) {
                $form->{"${_}_$j"} = $form->{"${_}_$i"};
            }
            for (qw(paid exchangerate)) {
                $form->{"${_}_$j"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }

            $totalpaid += $form->{"paid_$j"};

            if ( $j++ != $i ) {
                for (qw(datepaid source memo paid exchangerate forex cleared)) {
                    delete $form->{"${_}_$i"};
                }
            }
        }
        else {
            for (qw(datepaid source memo paid exchangerate forex cleared)) {
                delete $form->{"${_}_$i"};
            }
        }
    }
    $form->{paidaccounts} = $j;

    $form->{creditremaining} -=
      ( $form->parse_amount(\%myconfig, $form->{invtotal})
        - $form->parse_amount(\%myconfig, $totalpaid)
        + $form->parse_amount(\%myconfig, $form->{oldtotalpaid})
        - $form->parse_amount(\%myconfig, $form->{oldinvtotal}) );
    $form->{oldinvtotal}  = $form->{invtotal};
    $form->{oldtotalpaid} = $totalpaid;

    &create_links;
    $form->generate_selects(\%myconfig);
    $form->{id} = $form_id;
    &display_form;

}

sub post_and_approve {
    post();
    $form->call_procedure(funcname=>'draft_approve', args => [ $form->{id} ]);
}

sub post {
    if (!$form->close_form){
       $form->info(
          $locale->text('Data not saved.  Please try again.')
       );
       &update;
       $form->finalize_request();
    }
    if (!$form->{duedate}){
          $form->{duedate} = $form->{transdate};
    }
    $label =
      ( $form->{vc} eq 'customer' )
      ? $locale->text('Customer missing!')
      : $locale->text('Vendor missing!');

    # check if there is an invoice number, invoice and due date
    $form->isblank( "transdate", $locale->text('Invoice Date missing!') );
    $form->isblank( "duedate",   $locale->text('Due Date missing!') );
    #$form->isblank( "crdate",    $locale->text('Invoice Created Date missing!') );
    # pongraczi: we silently fill crdate with transdate if the user left empty to do not break existing workflow
    if (!$form->{crdate}){
          $form->{crdate} = $form->{transdate};
    }

    $form->isblank( $form->{vc}, $label );

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    $form->error(
        $locale->text('Cannot post transaction for a closed period!') )
        if ( $form->is_closed( $transdate ) );

    $form->isblank( "exchangerate", $locale->text('Exchange rate missing!') )
      if ( $form->{currency} ne $form->{defaultcurrency} );

    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} and $form->{"paid_$i"} != 0) {
            $datepaid = $form->datetonum( \%myconfig, $form->{"datepaid_$i"} );

            $form->isblank( "datepaid_$i",
                $locale->text('Payment date missing!') );

            $form->error(
                $locale->text('Cannot post payment for a closed period!') )
                if ( $form->is_closed( $datepaid ) );

            if ( $form->{currency} ne $form->{defaultcurrency} ) {
                $form->{"exchangerate_$i"} = $form->{exchangerate}
                  if ( $transdate == $datepaid );
                $form->isblank( "exchangerate_$i",
                    $locale->text('Exchange rate for payment missing!') );
            }
        }
    }

    # if oldname ne name redo form
    ($name) = split /--/, $form->{ $form->{vc} };
    if ( $form->{"old$form->{vc}"} ne qq|$name--$form->{"$form->{vc}_id"}|
         and $form->{"old$form->{vc}"} ne $name) {
        $form->info('Data changed on Post; form recalculated. Please re-post.');
        &update;
        $form->finalize_request();
    }

    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            my $id = $form->{old_workflow_id} // $form->{workflow_id};
            my $wf = $form->{_wire}->get('workflows')->fetch_workflow( 'AR/AP', $id );
            $wf->execute_action( $form->{__action} );

            &repost;
            $form->finalize_request();
        }
    }



    if ( AA->post_transaction( \%myconfig, \%$form ) ) {

        my $id = $form->{old_workflow_id} // $form->{workflow_id};
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow( 'AR/AP', $id );
        $wf->execute_action( $form->{__action} );

       if ( $form->{printandpost} ) {
           &{"print_$form->{formname}"}( $old_form, 1 );
        }

        if(defined($form->{batch_id}) and $form->{batch_id}
           and ($form->{callback} !~ /vouchers/)) {
            $form->{callback}.= qq|&batch_id=$form->{batch_id}|;
    }
        $form->{rowcount} = 0;
        $form->{paidaccounts} = 0;
            edit();
        }
    else {
        $form->error( $locale->text('Cannot post transaction!') );
    }

}#post end

# New Function Body starts Here



sub save_info {

        my $taxformfound=0;

        $taxformfound=AA->taxform_exist($form,$form->{"$form->{vc}_id"});
            $form->{arap} = lc($form->{ARAP});
        AA->save_intnotes($form);
        AA->save_employee($form);

        foreach my $i(1..($form->{rowcount}))
        {

        if($form->{"taxformcheck_$i"} and $taxformfound)
        {

          AA->update_ac_tax_form($form,$form->{dbh},$form->{"entry_id_$i"},"true") if($form->{"entry_id_$i"});

        }
        else
        {

            AA->update_ac_tax_form($form,$form->{dbh},$form->{"entry_id_$i"},"false") if($form->{"entry_id_$i"});

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
        $form->info($locale->text('Draft Posted'));
        }

}

1;
