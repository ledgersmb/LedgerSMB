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

use LedgerSMB::Tax;

# any custom scripts for this one
if ( -f "bin/custom/aa.pl" ) {
    eval { require "bin/custom/aa.pl"; };
}
if ( -f "bin/custom/$form->{login}_aa.pl" ) {
    eval { require "bin/custom/$form->{login}_aa.pl"; };
}

my $is_update;

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

sub copy_to_new{
    delete $form->{id};
    delete $form->{invnumber};
    update();
}

sub new_screen {
    use LedgerSMB::Form;
    my @reqprops = qw(ARAP vc dbh stylesheet batch_id);
    $oldform = $form;
    $form = {};
    bless $form, Form;
    for (@reqprops){
        $form->{$_} = $oldform->{$_};
    }
    &add();
}

sub add {

    $form->{title} = "Add";
	
    $form->{callback} =
"$form->{script}?action=add&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};
    if ($form->{type} eq "credit_note"){
        $form->{reverse} = 1;
        $form->{subtype} = 'credit_note';
        $form->{type} = 'transaction';
    } elsif ($form->{type} eq 'debit_note'){
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

sub edit {

    &create_links;
    $form->{title} = "Edit";
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

sub display_form {
    $form->close_form;
    $form->open_form;
    $form->{dbh}->commit;
    AA->get_files($form, $locale);
    &form_header;
    &form_footer;

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
			 billing => $form->{vc} eq 'customer'
			            && $form->{type} eq 'invoice');

    $duedate     = $form->{duedate};
    $taxincluded = $form->{taxincluded};

    $form->{formname} = "transaction";
    $form->{format}   = "postscript" if $myconfig{printer};
    $form->{media}    = $myconfig{printer};

    $form->{selectformname} =
      qq|<option value="transaction">| . $locale->text('Transaction');

    # currencies
    if (!$form->{currencies}){
        $form->error($locale->text(
           'No currencies defined.  Please set these up under System/Defaults.'
        ));
    }
    @curr = split /:/, $form->{currencies};
    $form->{defaultcurrency} = $curr[0];
    chomp $form->{defaultcurrency};

    for (@curr) { $form->{selectcurrency} .= "<option>$_\n" }

    AA->get_name( \%myconfig, \%$form );

    $form->{currency} =~ s/ //g;
    $form->{duedate}     = $duedate     if $duedate;
    $form->{taxincluded} = $taxincluded if $form->{id};

    $form->{notes} = $form->{intnotes} if !$form->{id};

    $form->{"old$form->{vc}"} =
      qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
    $form->{oldtransdate} = $form->{transdate};

    # customers/vendors
    $form->{"select$form->{vc}"} = "";
    if ( @{ $form->{"all_$form->{vc}"} } ) {
        $form->{ $form->{vc} } =
          qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
        for ( @{ $form->{"all_$form->{vc}"} } ) {
            $form->{"select$form->{vc}"} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }
    }
    # Business Reporting Units
    $form->all_business_units;

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

    $netamount = 0;
    $tax       = 0;
    $taxrate   = 0;
    #$ml        = ( $form->{ARAP} eq 'AR' ) ? 1 : -1;
    $ml        = new Math::BigFloat( ( $form->{ARAP} eq 'AR' ) ? 1 : -1);

    foreach $key ( keys %{ $form->{"$form->{ARAP}_links"} } ) {


        $form->{"select$key"} = "";
        foreach $ref ( @{ $form->{"$form->{ARAP}_links"}{$key} } ) {
            $form->{"select$key"} .=
              "<option>$ref->{accno}--$ref->{description}\n";
        }

        # if there is a value we have an old entry
        for $i ( 1 .. scalar @{ $form->{acc_trans}{$key} } ) {


            if ( $key eq "$form->{ARAP}_paid" ) {

                $form->{"$form->{ARAP}_paid_$i"} =
"$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
                $form->{"paid_$i"} =
                  $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * -1 * $ml;
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
                    else {
                        $form->{invtotal} =
                          $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * -1 * $ml;
                    }
                    $form->{"${key}_$i"} =
"$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";



                }
            }
        }
    }

    $form->{paidaccounts} = 1 if not defined $form->{paidaccounts};

    if ( $form->{taxincluded} ) {
        $diff = 0;

        # add tax to individual amounts
        # XXX needs alteration for conditional taxes
        for $i ( 1 .. $form->{rowcount} ) {
            if ($netamount) {
                $amount = $form->{"amount_$i"} * ( 1 + $tax / $netamount );
                $form->{"amount_$i"} = $form->round_amount( $amount, 2 );
            }
        }
    }

    $form->{invtotal} = $netamount + $tax;

    # check if calculated is equal to stored
    # taxincluded is terrible to calculate
    # this works only if all taxes are checked

    @taxaccounts = Tax::init_taxes( $form, $form->{taxaccounts} );

    if ( $form->{id} ) {
        if ( $form->{taxincluded} ) {

            $amount =
              Tax::calculate_taxes( \@taxaccounts, $form, $form->{invtotal},
                1 );
            $tax = $form->round_amount( $amount, 2 );

        }
        else {
            $tax =
              $form->round_amount(
                Tax::calculate_taxes( \@taxaccounts, $form, $netamount, 0 ) );
        }
        foreach $item (@taxaccounts) {
            $tax{ $item->account } = $form->round_amount( $item->value, 2 );
            $form->{ "calctax_" . $item->account } = 1
              if $item->value
              and
              ( $tax{ $item->account } == $form->{ "tax_" . $item->account } );
        }
    }
    else {
        for (@taxaccounts) { $form->{ "calctax_" . $_->account } = 1 }
    }

    $form->{rowcount}++ if ( $form->{id} || !$form->{rowcount} );

    $form->{ $form->{ARAP} } = $form->{"$form->{ARAP}_1"};
    $form->{rowcount} = 1 unless $form->{"$form->{ARAP}_amount_1"};

    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );

    # readonly
    if ( !$form->{readonly} ) {
        $form->{readonly} = 1
          if $myconfig{acs} =~ /$form->{ARAP}--Add Transaction/;
    }

}

sub form_header {

    $title = $form->{title};
    $form->all_business_units($form->{transdate}, 
                              $form->{"$form->{vc}_id"}, 
                              $form->{ARAP});

    if($form->{batch_id})
    {
		$form->{batch_control_code}=$form->get_batch_control_code($form->{dbh},$form->{batch_id});
		$form->{batch_description}=$form->get_batch_description($form->{dbh},$form->{batch_id});
    }
    # 	$locale->text('Add AR Transaction');
    # 	$locale->text('Add AP Transaction');
    #   $locale->text('Edit AR Transaction');
    #   $locale->text('Edit AP Transaction');
    if ($form->{ARAP} eq 'AP'){
        $eclass = '1';
    } elsif ($form->{ARAP} eq 'AR'){
        $eclass = '2';
    }
    my $title_msgid="$title $form->{ARAP} Transaction";
    if ($form->{reverse} == 0){
       #$form->{title} = $locale->text("[_1] [_2] Transaction", $title, $form->{ARAP});
       $form->{title} = $locale->text($title_msgid);
    }
    elsif($form->{reverse} == 1) {
       if ($form->{subtype} eq 'credit_note'){
           $title_msgid="$title Credit Note";$form->{title}=$locale->text($title_msgid);
           #$form->{title} = $locale->text("[_1] Credit Note", $title);
       } elsif ($form->{subtype} eq 'debit_note'){
           $title_msgid="$title Debit Note";$form->{title}=$locale->text($title_msgid);
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

    # set option selected
    for ( "$form->{ARAP}", "currency" ) {
        $form->{"select$_"} =~ s/ selected//;
        $form->{"select$_"} =~
          s/<option>\Q$form->{$_}\E/<option selected>$form->{$_}/;
    }

    for ( "$form->{vc}", "department", "employee", "formname" ) {
        $form->{"select$_"} = $form->unescape( $form->{"select$_"} );
        $form->{"select$_"} =~ s/ selected//;
        $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
    }

    $form->{selectprojectnumber} =
      $form->unescape( $form->{selectprojectnumber} );

    # format amounts
    $form->{exchangerate} =
      $form->format_amount( \%myconfig, $form->{exchangerate} );

    $exchangerate = qq|<tr>|;
    $exchangerate .= qq|
                <th align=right nowrap>| . $locale->text('Currency') . qq|</th>
		<td><select name=currency>$form->{selectcurrency}</select></td> |
      if $form->{defaultcurrency};
    $exchangerate .= qq|
                <input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
|;

    if (   $form->{defaultcurrency}
        && $form->{currency} ne $form->{defaultcurrency} )
    {
        if ( $form->{forex} ) {
            $exchangerate .= qq|
	<th align=right>| . $locale->text('Exchange Rate') . qq|</th>
	<td><input type=hidden name=exchangerate value=$form->{exchangerate}>$form->{exchangerate}</td>
|;
        }
        else {
            $exchangerate .= qq|
        <th align=right>| . $locale->text('Exchange Rate') . qq|</th>
        <td><input name=exchangerate size=10 value=$form->{exchangerate}></td>
|;
        }
    }
    $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
</tr>
|;

    $taxincluded = "";
    if ( $form->{taxaccounts} ) {
        $taxincluded = qq|
	      <tr>
		<td align=right><input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
		<th align=left nowrap>| . $locale->text('Tax Included') . qq|</th>
	      </tr>
|;
    }

    if ( ( $rows = $form->numtextrows( $form->{notes}, 50 ) - 1 ) < 2 ) {
        $rows = 2;
    }
    $notes =
qq|<textarea name=notes rows=$rows cols=50 wrap=soft>$form->{notes}</textarea>|;
    $intnotes =
qq|<textarea name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;

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

    $name =
      ( $form->{"select$form->{vc}"} )
      ? qq|<select name="$form->{vc}">$form->{"select$form->{vc}"}</select>|
      : qq|<input name="$form->{vc}" value="$form->{$form->{vc}}" size=35> 
                 <a href="contact.pl?action=add&entity_class=$eclass" 
                    target="new" id="new-contact">[|
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
		<th align=right nowrap>$label</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|
          . $form->escape( $form->{selectemployee}, 1 ) . qq|">
	      </tr>
|;
    }

    $focus = ( $form->{focus} ) ? $form->{focus} : "amount_$form->{rowcount}";

    $form->header;

 print qq|
<body onload="document.forms[0].${focus}.focus()" /> | .
$form->open_status_div . qq|
<form method=post action=$form->{script}>
<input type=hidden name=type value="$form->{formname}">
<input type=hidden name=title value="$title">

|;
    if (!defined $form->{approved}){
        $form->{approved} = 1;
    }
    $form->hide_form(
        qw(batch_id approved id printed emailed sort closedto locked 
           oldtransdate audittrail recurring checktax reverse batch_id subtype
           entity_control_code meta_number default_reportable)
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
        "creditremaining", "selectcurrency",
        "defaultcurrency", "select$form->{ARAP}_amount",
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
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align="right" nowrap>$label</th>
		<td colspan=3>$name 
                </td>
		<input type=hidden name="select$form->{vc}" value="|
      . $form->escape( $form->{"select$form->{vc}"}, 1 ) . qq|">
	      </tr>
	      <tr>
		<td colspan=3>
		  <table width=100%>
		    <tr>
		      <th align=left nowrap>| . $locale->text('Credit Limit') . qq|</th>
		      <td>$form->{creditlimit}</td>
		      <th align=left nowrap>| . $locale->text('Remaining') . qq|</th>
		      <td class="plus$n">|
      . $form->format_amount( \%myconfig, $form->{creditremaining}, 0, "0" )
      . qq|</td>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
		if($form->{batch_id})
		{
		print qq|	<tr>
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



		if ($form->{entity_control_code}){
			print qq|
	        <tr>
		<th align="right" nowrap>| . 
			$locale->text('Entity Control Code') . qq|</th>
		<td colspan=3>$form->{entity_control_code}</td>
	      </tr>
	        <tr>
		<th align="right" nowrap>| . 
			$locale->text('Account') . qq|</th>
		<td colspan=3>$form->{meta_number}</td>
	      </tr>
		|;
	       }
	print qq|
	      $exchangerate
	      $department
	      $taxincluded
            <tr>
               <th align="right" nowrap>| . $locale->text('Description') . qq|
               </th>
               <td><input type="text" name="description" size="40" 
                   value="| . $form->{description} . qq|" /></td>
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
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Invoice Date') . qq|</th>
		<td><input name=transdate size=11 title="($myconfig{'dateformat'})" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Due Date') . qq|</th>
		<td><input name=duedate size=11 title="$myconfig{'dateformat'}" value=$form->{duedate}></td>
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
  <input type=hidden name=selectprojectnumber value="|
      . $form->escape( $form->{selectprojectnumber}, 1 ) . qq|">
  <tr>
    <td>
      <table>
|;

    print qq|
	<tr>
	  <th>| . $locale->text('Amount') . qq|</th>
	  <th></th>
	  <th>| . $locale->text('Account') . qq|</th>
	  <th>| . $locale->text('Description') . qq|</th>
	  <th>| . $locale->text('Tax Form Applied') . qq|</th>|;
    for my $cls (@{$form->{bu_class}}){
        if (scalar @{$form->{b_units}->{"$cls->{id}"}}){
            print qq|<th>| . $locale->text($cls->{label}) . qq|</th>|;
        }
    }
    print qq|
	</tr>
|;
    # Building buisness unit dropdowns


    # Display rows

    for $i ( 1 .. $form->{rowcount} ) {

        $selectamount = $form->{"select$form->{ARAP}_amount"};
        $selectamount =~
s/option>\Q$form->{"$form->{ARAP}_amount_$i"}\E/option selected>$form->{"$form->{ARAP}_amount_$i"}/;

        $selectprojectnumber = $form->{selectprojectnumber};
        $selectprojectnumber =~
          s/(<option value="\Q$form->{"projectnumber_$i"}\E")/$1 selected/;

        # format amounts
        $form->{"amount_$i"} =
          $form->format_amount( \%myconfig,$form->{"amount_$i"}, 2 );

        $project = qq|
	  <td align=right><select name="projectnumber_$i">$selectprojectnumber</select></td>
| if $form->{selectprojectnumber};

        if ( ( $rows = $form->numtextrows( $form->{"description_$i"}, 40 ) ) >
            1 )
        {
            $description =
qq|<td><textarea name="description_$i" rows=$rows cols=40>$form->{"description_$i"}</textarea></td>|;
        }
        else {
            $description =
qq|<td><input name="description_$i" size=40 value="$form->{"description_$i"}"></td>|;
        }

	$taxchecked="";
	if($form->{"taxformcheck_$i"} or ($form->{default_reportable} and ($i == $form->{rowcount})))
	{
		$taxchecked=qq|CHECKED="CHECKED"|;

	}

	$taxformcheck=qq|<td><input type="checkbox" name="taxformcheck_$i" value="1" $taxchecked></td>|;
        print qq|
	<tr valign=top>
	  <td><input name="amount_$i" size=10 value="$form->{"amount_$i"}" accesskey="$i"></td>
	  <td></td>
	  <td><select name="$form->{ARAP}_amount_$i">$selectamount</select></td>
	  $description
          $taxformcheck
	  $project|;

        for my $cls (@{$form->{bu_class}}){
            if (scalar @{$form->{b_units}->{"$cls->{id}"}}){
                print qq|<td><select name="b_unit_$cls->{id}_$i">
                                    <option></option>|;
                      for my $bu (@{$form->{b_units}->{"$cls->{id}"}}){
                         my $selected = '';
                         if ($form->{"b_unit_$cls->{id}_$i"} eq $bu->{id}){
                            $selected = "SELECTED='SELECTED'";
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
    foreach $item ( split / /, $form->{taxaccounts} ) {

	if($form->{"calctax_$item"} && $is_update){
             $form->{invtotal} += $form->{"tax_$item"};
	}
        $form->{"calctax_$item"} =
          ( $form->{"calctax_$item"} ) ? "checked" : "";
         
        $form->{"tax_$item"} =
          $form->format_amount( \%myconfig, $form->{"tax_$item"}, 2 );
	# CT:  This should probably be moved to a hidden field and a text label.
        print qq|
        <tr>
	  <td><input name="tax_$item" size=10 value=$form->{"tax_$item"}></td>
	  <td align=right><input name="calctax_$item" class=checkbox type=checkbox value=1 $form->{"calctax_$item"}></td>
 	  <td><select name="$form->{ARAP}_tax_$item">
 	<option value="$form->{ARAP}_tax_$item">$item--$form->{"${item}_description"}</option></select></td>
	</tr>
|;

        $form->hide_form(
            "${item}_rate",      "${item}_description",
            "${item}_taxnumber", "select$form->{ARAP}_tax_$item"
        );
    }

    $form->{invtotal} =
      $form->format_amount( \%myconfig, $form->{invtotal}, 2 );

    $form->hide_form( "oldinvtotal", "oldtotalpaid", "taxaccounts",
        "select$form->{ARAP}" );

    print qq|
        <tr>
	  <th align=left>$form->{invtotal}</th>
	  <td></td>
	  <td><select name=$form->{ARAP}>$form->{"select$form->{ARAP}"}</select></td>
        </tr>
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

  <tr class=listheading>
    <th class=listheading>| . $locale->text('Payments') . qq|</th>
  </tr>

  <tr>
    <td>
      <table width=100%>
|;

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        @column_index = qw(datepaid source memo paid ARAP_paid);
    }
    else {
        @column_index = qw(datepaid source memo paid exchangerate ARAP_paid);
    }

    $column_data{datepaid}     = "<th>" . $locale->text('Date') . "</th>";
    $column_data{paid}         = "<th>" . $locale->text('Amount') . "</th>";
    $column_data{exchangerate} = "<th>" . $locale->text('Exch') . "</th>";
    $column_data{ARAP_paid}    = "<th>" . $locale->text('Account') . "</th>";
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
        <tr>
";

        $form->{"select$form->{ARAP}_paid_$i"} =
          $form->{"select$form->{ARAP}_paid"};
        $form->{"select$form->{ARAP}_paid_$i"} =~
s/option>\Q$form->{"$form->{ARAP}_paid_$i"}\E/option selected>$form->{"$form->{ARAP}_paid_$i"}/;

        # format amounts
        $form->{"paid_$i"} =
          $form->format_amount( \%myconfig, $form->{"paid_$i"}, 2 );
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
qq|<input name="exchangerate_$i" size=10 value=$form->{"exchangerate_$i"}>|;
            }
        }

        $form->hide_form("forex_$i");

        $column_data{paid} =
qq|<td align=center><input name="paid_$i" size=11 value=$form->{"paid_$i"}></td>|;
        $column_data{ARAP_paid} =
qq|<td align=center><select name="$form->{ARAP}_paid_$i">$form->{"select$form->{ARAP}_paid_$i"}</select></td>|;
        $column_data{exchangerate} = qq|<td align=center>$exchangerate</td>|;
        $column_data{datepaid} =
qq|<td align=center><input class="date" name="datepaid_$i" size=11 value=$form->{"datepaid_$i"}></td>|;
        $column_data{source} =
qq|<td align=center><input name="source_$i" size=11 value="$form->{"source_$i"}"></td>|;
        $column_data{memo} =
qq|<td align=center><input name="memo_$i" size=11 value="$form->{"memo_$i"}"></td>|;

        for (@column_index) { print qq|$column_data{$_}\n| }

        print "
        </tr>
";
    }

    $form->hide_form( "paidaccounts", "select$form->{ARAP}_paid" );

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

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Print')
    # type=submit $locale->text('Post')
    # type=submit $locale->text('Schedule')
    # type=submit $locale->text('Ship to')
    # type=submit $locale->text('Post as new')
    # type=submit $locale->text('Delete')

    if ( !$form->{readonly} ) {

        &print_options;

        print "<br>";

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
            'schedule' =>
              { ndx => 7, key => 'H', value => $locale->text('Schedule') },
            'delete' =>
              { ndx => 8, key => 'D', value => $locale->text('Delete') },

            'save_info' => 
              { ndx => 9, key => 'I', value => $locale->text('Save Info') },
            'new_screen' => # Create a blank ar/ap invoice.
             { ndx => 10, key=> 'N', value => $locale->text('New') }
        );
        my $is_draft = 0;
        if (!$form->{approved} && !$form->{batch_id}){
           $is_draft = 1;
           $button{approve} = { 
                   ndx   => 3, 
                   key   => 'O', 
                   value => $locale->text('Post as Saved') };
           if (grep /^lsmb_$form->{company}__draft_edit$/, @{$form->{_roles}}){
               $button{edit_and_approve} = { 
                   ndx   => 4, 
                   key   => 'E', 
                   value => $locale->text('Post as Shown') };
          }
           delete $button{post_as_new};
           delete $button{post};
        }

        if ($form->{separate_duties} || $form->{batch_id}){
            $button{post}->{value} = $locale->text('Save');
            $button{post_as_new}->{value} = $locale->text('Save as New');
            $form->hide_form('separate_duties');
        }
        if ( $form->{id}) { 
            for ( "post","delete" ) {
                delete $button{$_};
            }
        }
        elsif (!$form->{id}) {

            for ( "post_as_new","delete","save_info",
                  "print", 'copy_to_new', 'new_screen') {
                delete $button{$_};
            }

            if ( $transdate && ($transdate <= $closedto) ) {
                for ( "post","save_info") { 
                    delete $button{$_};
                }
            }
        }
        if ($form->{id}){
            for ( "post_as_new"){
               delete $button{$_};
            }
            delete $button{'update'} unless $is_draft;
        }

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            $form->print_button( \%button, $_ );
        }

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
<td><a href="file.pl?action=get&file_class=1&ref_key=$form->{id}&id=$file->{id}"
            >$file->{file_name}</a></td> 
<td>$file->{mime_type}</td> 
<td>$file->{uploaded_at}</td> 
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
               lc($form->{ARAP}) . ".pl?action=edit&id=".$form->{id}
       );
       print qq|
<a href="file.pl?action=show_attachment_screen&ref_key=$form->{id}&file_class=1&callback=$callback"
   >[| . $locale->text('Attach') . qq|]</a>|;
    }
    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print qq|
</form>
| . $form->close_status_div . qq|
</body>
</html>
|;
}

sub edit_and_approve {
    use LedgerSMB::DBObject::Draft;
    use LedgerSMB;
    my $lsmb = LedgerSMB->new();
    $lsmb->merge($form);
    my $draft = LedgerSMB::DBObject::Draft->new({base => $lsmb});
    $draft->delete();
    delete $form->{id};
    AA->post_transaction( \%myconfig, \%$form );
    approve();
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
        print "<html><body>";
        my $url = $form->{callback};
        print qq|If you are not redirected automatically, click <a href="$url">|
                . qq|here</a>.</body></html>|;

    } else {
        $form->info($locale->text('Draft Posted'));
    }
}

sub update {
    my $display = shift;
    $is_update = 1;
    if ( !$display ) {

        $form->{invtotal} = 0;

        $form->{exchangerate} =
          $form->parse_amount( \%myconfig, $form->{exchangerate} );

        @flds =
          ( "amount", "$form->{ARAP}_amount", "projectnumber", "description","taxformcheck" );
        $count = 0;
        @a     = ();
        for $i ( 1 .. $form->{rowcount} ) {
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
            $form->{invtotal} += $form->{"amount_$_"};
        }

        $form->{exchangerate} = $exchangerate
          if (
            $form->{forex} = (
                $exchangerate = $form->check_exchangerate(
                    \%myconfig, $form->{currency}, $form->{transdate},
                    ( $form->{ARAP} eq 'AR' ) ? 'buy' : 'sell'
                )
            )
          );

        if ( $newname = &check_name( $form->{vc} ) ) {
            $form->{notes} = $form->{intnotes} unless $form->{id};
            &rebuild_vc( $form->{vc}, $form->{ARAP}, $form->{transdate} );
        }
        if ( $form->{transdate} ne $form->{oldtransdate} ) {
            $form->{duedate} =
              $form->current_date( \%myconfig, $form->{transdate},
                $form->{terms} * 1 );
            $form->{oldtransdate} = $form->{transdate};
            $newproj =
              &rebuild_vc( $form->{vc}, $form->{ARAP}, $form->{transdate} )
              if !$newname;

            $form->{selectemployee} = "";
            if ( @{ $form->{all_employee} } ) {
                for ( @{ $form->{all_employee} } ) {
                    $form->{selectemployee} .=
                      qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
                }
            }
        }
    }#!$display
    @taxaccounts = split / /, $form->{taxaccounts};

    for (@taxaccounts) {
        $form->{"tax_$_"} =
          $form->parse_amount( \%myconfig, $form->{"tax_$_"} );
    }

    @taxaccounts = Tax::init_taxes( $form, $form->{taxaccounts} );

    $j = 1;
    for $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} and $form->{"paid_$i"} != 0 ) {
            for (qw(datepaid source memo cleared)) {
                $form->{"${_}_$j"} = $form->{"${_}_$i"};
            }
            for (qw(paid exchangerate)) {
                $form->{"${_}_$j"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }

            $totalpaid += $form->{"paid_$j"};

            $form->{"exchangerate_$j"} = $exchangerate
              if (
                $form->{"forex_$j"} = (
                    $exchangerate = $form->check_exchangerate(
                        \%myconfig, $form->{currency},
                        $form->{"datepaid_$j"},
                        ( $form->{ARAP} eq 'AR' ) ? 'buy' : 'sell'
                    )
                )
              );

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

    &display_form;

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
    $form->isblank( $form->{vc}, $label );

    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );
    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    $form->error(
        $locale->text('Cannot post transaction for a closed period!') )
      if ( $transdate <= $closedto );

    $form->isblank( "exchangerate", $locale->text('Exchange rate missing!') )
      if ( $form->{currency} ne $form->{defaultcurrency} );

    for $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} and $form->{"paid_$i"} != 0) {
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

    # if oldname ne name redo form
    ($name) = split /--/, $form->{ $form->{vc} };
    if ( $form->{"old$form->{vc}"} ne qq|$name--$form->{"$form->{vc}_id"}| ) {
        &update;
        $form->finalize_request();
    }

    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            &repost;
            $form->finalize_request();
        }
    }

    
    
    if ( AA->post_transaction( \%myconfig, \%$form ) ) {
	  
       $form->update_status( \%myconfig );
       if ( $form->{printandpost} ) {
           &{"print_$form->{formname}"}( $old_form, 1 );
        }

        if(defined($form->{batch_id}) and $form->{batch_id} 
           and ($form->{callback} !~ /vouchers/))
	{
        	$form->{callback}.= qq|&batch_id=$form->{batch_id}|;
	}
        if($form->{separate_duties}){edit();}
        else {$form->redirect( $locale->text('Transaction posted!') );}
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


#New function starts Here


sub search {

    $form->create_links( module => $form->{ARAP},
			 myconfig => \%myconfig,
			 vc => $form->{vc},
			 billing => 0);

    $form->{"select$form->{ARAP}"} = "<option>\n";
    for ( @{ $form->{"$form->{ARAP}_links"}{ $form->{ARAP} } } ) {
        $form->{"select$form->{ARAP}"} .=
          "<option>$_->{accno}--$_->{description}\n";
    }

    if ( @{ $form->{"all_$form->{vc}"} } ) {
        $selectname = "";
        for ( @{ $form->{"all_$form->{vc}"} } ) {
            $selectname .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }
        $selectname =
          qq|<select name="$form->{vc}"><option>\n$selectname</select>|;
    }
    else {
        $selectname = qq|<input name=$form->{vc} size=35>|;
    }


    if ( @{ $form->{all_employee} } ) {
        $form->{selectemployee} = "<option>\n";
        for ( @{ $form->{all_employee} } ) {
            $form->{selectemployee} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }

        $employeelabel =
          ( $form->{ARAP} eq 'AR' )
          ? $locale->text('Salesperson')
          : $locale->text('Employee');

        $employee = qq|
        <tr>
	  <th align=right nowrap>$employeelabel</th>
	  <td colspan=3><select name=employee>$form->{selectemployee}</select></td>
	</tr>
|;

        $l_employee =
qq|<input name="l_employee" class=checkbox type=checkbox value=Y> $employeelabel|;

        $l_manager =
          qq|<input name="l_manager" class=checkbox type=checkbox value=Y> |
          . $locale->text('Manager');
    }

    $form->{title} =
      ( $form->{ARAP} eq 'AR' )
      ? $locale->text('AR Transactions')
      : $locale->text('AP Transactions');

    $invnumber = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text('Invoice Number') . qq|</th>
	  <td colspan=3><input name=invnumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>| . $locale->text('Order Number') . qq|</th>
	  <td colspan=3><input name=ordnumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>| . $locale->text('PO Number') . qq|</th>
	  <td colspan=3><input name=ponumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>| . $locale->text('Source') . qq|</th>
	  <td colspan=3><input name=source size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>| . $locale->text('Description') . qq|</th>
	  <td colspan=3><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>| . $locale->text('Notes') . qq|</th>
	  <td colspan=3><input name=notes size=40></td>
	</tr>
|;

    $openclosed = qq|
	      <tr>
		<td nowrap><input name=open class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Open')
      . qq|</td>
		<td nowrap><input name=closed class=checkbox type=checkbox value=Y> |
      . $locale->text('Closed')
      . qq|</td>
	      </tr>
|;

    if ( $form->{outstanding} ) {
        $form->{title} =
          ( $form->{ARAP} eq 'AR' )
          ? $locale->text('AR Outstanding')
          : $locale->text('AP Outstanding');
        $invnumber  = "";
        $openclosed = "";
        $summary    = "";
    }
    $summary = qq|
              <tr>
		<td><input name=summary type=radio class=radio value=1 checked> |
      . $locale->text('Summary')
      . qq|</td>
		<td><input name=summary type=radio class=radio value=0> |
      . $locale->text('Detail') . qq|
		</td>
	      </tr>
|;


    if ( @{ $form->{all_years} } ) {

        # accounting years
        $form->{selectaccountingyear} = "<option>\n";
        for ( @{ $form->{all_years} } ) {
            $form->{selectaccountingyear} .= qq|<option>$_\n|;
        }
        $form->{selectaccountingmonth} = "<option>\n";
        for ( sort keys %{ $form->{all_month} } ) {
            $form->{selectaccountingmonth} .=
              qq|<option value=$_>|
              . $locale->text( $form->{all_month}{$_} ) . qq|\n|;
        }

        $selectfrom = qq|
        <tr>
	<th align=right>| . $locale->text('Period') . qq|</th>
	<td colspan=3>
	<select name=month>$form->{selectaccountingmonth}</select>
	<select name=year>$form->{selectaccountingyear}</select>
	<input name=interval class=radio type=radio value=0 checked>&nbsp;|
          . $locale->text('Current') . qq|
	<input name=interval class=radio type=radio value=1>&nbsp;|
          . $locale->text('Month') . qq|
	<input name=interval class=radio type=radio value=3>&nbsp;|
          . $locale->text('Quarter') . qq|
	<input name=interval class=radio type=radio value=12>&nbsp;|
          . $locale->text('Year') . qq|
	</td>
      </tr>
|;
    }

    $name = $locale->text('Customer');
    my $msgid_vc_number="Customer Number";
    $l_name =
qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $name|;
    $l_till =
      qq|<input name="l_till" class=checkbox type=checkbox value=Y> |
      . $locale->text('Till');

    if ( $form->{vc} eq 'vendor' ) {
        $name   = $locale->text('Vendor');
        $msgid_vc_number="Vendor Number";
        $l_till = "";
        $l_name =
qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $name|;
    }

    @a = ();
    push @a,
      qq|<input name="l_runningnumber" class=checkbox type=checkbox value=Y> |
      . $locale->text('No.');
    push @a, qq|<input name="l_id" class=checkbox type=checkbox value=Y> |
      . $locale->text('ID');
    push @a,
qq|<input name="l_invnumber" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Invoice Number');
    push @a,
      qq|<input name="l_ordnumber" class=checkbox type=checkbox value=Y> |
      . $locale->text('Order Number');
    push @a, qq|<input name="l_ponumber" class=checkbox type=checkbox value=Y> |
      . $locale->text('PO Number');
    push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Invoice Date');
    if (!$form->{outstanding}){
        push @a,
qq|<input name="l_projectnumber" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Project Numbers');
    }
    push @a, $l_name;
    push @a, $l_employee if $l_employee;
    push @a, $l_manager if $l_employee;
    push @a, $l_department if $l_department;
    push @a,
      qq|<input name="l_netamount" class=checkbox type=checkbox value=Y> |
      . $locale->text('Amount');
    push @a, qq|<input name="l_tax" class=checkbox type=checkbox value=Y> |
      . $locale->text('Tax');
    push @a,
      qq|<input name="l_amount" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Total');
    push @a, qq|<input name="l_curr" class=checkbox type=checkbox value=Y> |
      . $locale->text('Currency');
    push @a, qq|<input name="l_datepaid" class=checkbox type=checkbox value=Y> |
      . $locale->text('Date Paid');
    push @a,
      qq|<input name="l_paid" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Paid');
    push @a, qq|<input name="l_duedate" class=checkbox type=checkbox value=Y> |
      . $locale->text('Due Date');
    push @a, qq|<input name="l_due" class=checkbox type=checkbox value=Y> |
      . $locale->text('Amount Due');
    push @a, qq|<input name="l_notes" class=checkbox type=checkbox value=Y> |
      . $locale->text('Notes');
    push @a, $l_till if $l_till;
    push @a,
      qq|<input name="l_shippingpoint" class=checkbox type=checkbox value=Y> |
      . $locale->text('Shipping Point');
    push @a, qq|<input name="l_shipvia" class=checkbox type=checkbox value=Y> |
      . $locale->text('Ship via');

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>| . $locale->text('Account') . qq|</th>
	  <td colspan=3><select name=$form->{ARAP}>$form->{"select$form->{ARAP}"}</select></td>
	</tr>
	<tr>
	  <th align=right>$name</th>
	  <td colspan=3>$selectname</td>
	</tr>
	<tr><th align="right">|.$locale->text("$msgid_vc_number").qq|</th>
	    <td colspan="3"><input name="meta_number" size="36">
        </tr>
	$employee
	$department
	$invnumber
	<tr>
	  <th align=right>| . $locale->text('Ship via') . qq|</th>
	  <td colspan=3><input name=shipvia size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>| . $locale->text('From') . qq|</th>
	  <td><input class="date" name=transdatefrom size=11 title="$myconfig{dateformat}"></td>
	  <th align=right>| . $locale->text('Date to') . qq|</th>
	  <td><input class="date" name=transdateto size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
      </table>
    </td>
  </tr>
  
  <tr>
    <td>        
        |.$locale->text('All Invoices').qq|: <input type="radio" name="invoice_type" checked value="1"> 
        |.$locale->text('Active').qq|: <input type="radio" name="invoice_type" value="2">  
        |.$locale->text('On Hold').qq|: <input type="radio" name="invoice_type" value="3"> 
        <br/>    
    </td>
  </tr>
  
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>| . $locale->text('Include in Report') . qq|</th>
	  <td>
	    <table width=100%>
	      $openclosed
	      $summary
|;

    $form->{sort} = "transdate";
    $form->hide_form(qw(title outstanding sort));

    while (@a) {
        for ( 1 .. 5 ) {
            print qq|<td nowrap>| . shift @a;
            print qq|</td>\n|;
        }
        print qq|</tr>\n|;
    }

    print qq|
	      <tr>
		<td nowrap><input name="l_subtotal" class=checkbox type=checkbox value=Y> |
      . $locale->text('Subtotal')
      . qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type="hidden" name="action" value="continue">
<button class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>|;

    $form->hide_form(qw(nextsub path login sessionid));

    print qq|
</form>
|;

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print qq|
 
</body>
</html>
|;

}

