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

}

sub edit {

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

    &create_links;
    &display_form;

}

sub display_form {

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

    $form->create_links( $form->{ARAP}, \%myconfig, $form->{vc} );

    $duedate     = $form->{duedate};
    $taxincluded = $form->{taxincluded};

    $form->{formname} = "transaction";
    $form->{format}   = "postscript" if $myconfig{printer};
    $form->{media}    = $myconfig{printer};

    $form->{selectformname} =
      qq|<option value="transaction">| . $locale->text('Transaction');

    if ( ${LedgerSMB::Sysconfig::latex} ) {
        if ( $form->{ARAP} eq 'AR' ) {
            $form->{selectformname} .= qq|
  <option value="receipt">| . $locale->text('Receipt');
        }
        else {
            $form->{selectformname} .= qq|
  <option value="check">| . $locale->text('Check');
        }
    }

    # currencies
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

    # projects
    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option>\n";
        for ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n|;
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
    $ml        = ( $form->{ARAP} eq 'AR' ) ? 1 : -1;

    foreach $key ( keys %{ $form->{"$form->{ARAP}_links"} } ) {

        $form->{"select$key"} = "";
        foreach $ref ( @{ $form->{"$form->{ARAP}_links"}{$key} } ) {
            if ( $key eq "$form->{ARAP}_tax" ) {
                $form->{"select$form->{ARAP}_tax_$ref->{accno}"} =
                  "<option>$ref->{accno}--$ref->{description}\n";
                next;
            }
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
                        $form->{rowcount}++;
                        $netamount += $form->{"${akey}_$i"};

                        $form->{"projectnumber_$i"} =
"$form->{acc_trans}{$key}->[$i-1]->{projectnumber}--$form->{acc_trans}{$key}->[$i-1]->{project_id}"
                          if $form->{acc_trans}{$key}->[ $i - 1 ]->{project_id};
                    }
                    else {
                        $form->{invtotal} =
                          $form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * -1 *
                          $ml;
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
    if ($form->{reverse} == 0){
       $form->{title} = $locale->text("$title $form->{ARAP} Transaction");
    }
    elsif($form->{reverse} == 1) {
       if ($form->{subtype} eq 'credit_note'){
           $form->{title} = $locale->text("$title Credit Note");
       } elsif ($form->{subtype} eq 'debit_note'){
           $form->{title} = $locale->text("$title Debit Note");
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
      : qq|<input name="$form->{vc}" value="$form->{$form->{vc}}" size=35>|;

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
<body onload="document.forms[0].${focus}.focus()" />

<form method=post action=$form->{script}>
<input type=hidden name=type value="$form->{formname}">
<input type=hidden name=title value="$title">

|;

    $form->hide_form(
        qw(id printed emailed sort closedto locked oldtransdate audittrail 
           recurring checktax reverse batch_id subtype)
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
		<td colspan=3>$name</td>
		<input type=hidden name="select$form->{vc}" value="|
      . $form->escape( $form->{"select$form->{vc}"}, 1 ) . qq|">
	      </tr>
	      <tr>
		<td></td>
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
	      $exchangerate
	      $department
	      $taxincluded
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

    $project = qq|
	  <th>| . $locale->text('Project') . qq|</th>
| if $form->{selectprojectnumber};

    print qq|
	<tr>
	  <th>| . $locale->text('Amount') . qq|</th>
	  <th></th>
	  <th>| . $locale->text('Account') . qq|</th>
	  <th>| . $locale->text('Description') . qq|</th>
	  $project
	</tr>
|;

    for $i ( 1 .. $form->{rowcount} ) {

        $selectamount = $form->{"select$form->{ARAP}_amount"};
        $selectamount =~
s/option>\Q$form->{"$form->{ARAP}_amount_$i"}\E/option selected>$form->{"$form->{ARAP}_amount_$i"}/;

        $selectprojectnumber = $form->{selectprojectnumber};
        $selectprojectnumber =~
          s/(<option value="\Q$form->{"projectnumber_$i"}\E")/$1 selected/;

        # format amounts
        $form->{"amount_$i"} =
          $form->format_amount( \%myconfig, $form->{"amount_$i"}, 2 );

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

        print qq|
	<tr valign=top>
	  <td><input name="amount_$i" size=10 value="$form->{"amount_$i"}" accesskey="$i"></td>
	  <td></td>
	  <td><select name="$form->{ARAP}_amount_$i">$selectamount</select></td>
	  $description
	  $project
	</tr>
|;
    }

    foreach $item ( split / /, $form->{taxaccounts} ) {

        $form->{"calctax_$item"} =
          ( $form->{"calctax_$item"} ) ? "checked" : "";

        $form->{"tax_$item"} =
          $form->format_amount( \%myconfig, $form->{"tax_$item"}, 2 );

        print qq|
        <tr>
	  <td><input name="tax_$item" size=10 value=$form->{"tax_$item"}></td>
	  <td align=right><input name="calctax_$item" class=checkbox type=checkbox value=1 $form->{"calctax_$item"}></td>
	  <td><select name="$form->{ARAP}_tax_$item">$form->{"select$form->{ARAP}_tax_$item"}</select></td>
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
	  <th align=right>| . $locale->text('Notes') . qq|</th>
	  <td></td>
	  <td colspan=3>$notes</td>
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
qq|<td align=center><input name="datepaid_$i" size=11 value=$form->{"datepaid_$i"}></td>|;
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

    $form->hide_form(qw(callback path login sessionid));

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
    # type=submit $locale->text('Delete')

    if ( !$form->{readonly} ) {

        &print_options;

        print "<br>";

        %button = (
            'update' =>
              { ndx => 1, key => 'U', value => $locale->text('Update') },
            'print' =>
              { ndx => 2, key => 'P', value => $locale->text('Print') },
            'post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
            'print_and_post' => {
                ndx   => 4,
                key   => 'R',
                value => $locale->text('Print and Post')
            },
            'post_as_new' =>
              { ndx => 5, key => 'N', value => $locale->text('Post as new') },
            'print_and_post_as_new' => {
                ndx   => 6,
                key   => 'W',
                value => $locale->text('Print and Post as new')
            },
            'schedule' =>
              { ndx => 7, key => 'H', value => $locale->text('Schedule') },
            'delete' =>
              { ndx => 8, key => 'D', value => $locale->text('Delete') },
        );

        if ( $form->{id} ) {

            if ( $form->{locked} || ( $transdate && $transdate <= $closedto ) )
            {
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

            for ( "post_as_new", "print_and_post_as_new", "delete" ) {
                delete $button{$_};
            }
            delete $button{"print_and_post"} if !${LedgerSMB::Sysconfig::latex};

            if ( $transdate && $transdate <= $closedto ) {
                for ( "post", "print_and_post" ) { delete $button{$_} }
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

    print qq|
</form>

</body>
</html>
|;

}

sub update {
    my $display = shift;

    if ( !$display ) {

        $form->{invtotal} = 0;

        $form->{exchangerate} =
          $form->parse_amount( \%myconfig, $form->{exchangerate} );

        @flds =
          ( "amount", "$form->{ARAP}_amount", "projectnumber", "description" );
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
            $form->all_projects( \%myconfig, undef, $form->{transdate} )
              if !$newproj;

            $form->{selectemployee} = "";
            if ( @{ $form->{all_employee} } ) {
                for ( @{ $form->{all_employee} } ) {
                    $form->{selectemployee} .=
                      qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
                }
            }
        }
    }

    # recalculate taxes
    @taxaccounts = split / /, $form->{taxaccounts};

    for (@taxaccounts) {
        $form->{"tax_$_"} =
          $form->parse_amount( \%myconfig, $form->{"tax_$_"} );
    }

    @taxaccounts = Tax::init_taxes( $form, $form->{taxaccounts} );
    if ( $form->{taxincluded} ) {
        $totaltax =
          Tax::calculate_taxes( \@taxaccounts, $form, $form->{invtotal}, 1 );
    }
    else {
        $totaltax =
          Tax::calculate_taxes( \@taxaccounts, $form, $form->{invtotal}, 0 );
    }
    foreach $item (@taxaccounts) {
        $taccno = $item->account;
        if ( $form->{calctax} ) {
            $form->{"calctax_$taccno"} = 1;
            $form->{"tax_$taccno"} = $form->round_amount( $item->value, 2 );
        }
        $form->{"select$form->{ARAP}_tax_$taccno"} =
          qq|<option>$taccno--$form->{"${taccno}_description"}|;
    }

    $form->{invtotal} =
      ( $form->{taxincluded} )
      ? $form->{invtotal}
      : $form->{invtotal} + $totaltax;

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
      ( $form->{invtotal} - $totalpaid + $form->{oldtotalpaid} -
          $form->{oldinvtotal} );
    $form->{oldinvtotal}  = $form->{invtotal};
    $form->{oldtotalpaid} = $totalpaid;

    &display_form;

}

sub post {

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

    # if oldname ne name redo form
    ($name) = split /--/, $form->{ $form->{vc} };
    if ( $form->{"old$form->{vc}"} ne qq|$name--$form->{"$form->{vc}_id"}| ) {
        &update;
        exit;
    }

    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            &repost;
            exit;
        }
    }

    if ( AA->post_transaction( \%myconfig, \%$form ) ) {
        $form->update_status( \%myconfig );
        if ( $form->{printandpost} ) {
            &{"print_$form->{formname}"}( $old_form, 1 );
        }
        $form->redirect( $locale->text('Transaction posted!') );
    }
    else {
        $form->error( $locale->text('Cannot post transaction!') );
    }

}

sub delete {

    $form->{title} = $locale->text('Confirm!');

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>
|;

    $form->{action} = "yes";
    $form->hide_form;

    print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|
      . $locale->text('Are you sure you want to delete Transaction')
      . qq| $form->{invnumber}</h4>

<button name="action" class="submit" type="submit" value="yes">|
      . $locale->text('Yes')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub yes {

    if (
        AA->delete_transaction(
            \%myconfig, \%$form, ${LedgerSMB::Sysconfig::spool}
        )
      )
    {
        $form->redirect( $locale->text('Transaction deleted!') );
    }
    else {
        $form->error( $locale->text('Cannot delete transaction!') );
    }

}

sub search {

    $form->create_links( $form->{ARAP}, \%myconfig, $form->{vc} );

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

    # departments
    if ( @{ $form->{all_department} } ) {
        $form->{selectdepartment} = "<option>\n";

        for ( @{ $form->{all_department} } ) {
            $form->{selectdepartment} .=
qq|<option value="$_->{description}--$_->{id}">$_->{description}\n|;
        }

        $l_department =
          qq|<input name="l_department" class=checkbox type=checkbox value=Y> |
          . $locale->text('Department');

        $department = qq| 
        <tr> 
	  <th align=right nowrap>| . $locale->text('Department') . qq|</th>
	  <td colspan=3><select name=department>$form->{selectdepartment}</select></td>
	</tr>
|;
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

    if ( $form->{outstanding} ) {
        $form->{title} =
          ( $form->{ARAP} eq 'AR' )
          ? $locale->text('AR Outstanding')
          : $locale->text('AP Outstanding');
        $invnumber  = "";
        $openclosed = "";
        $summary    = "";
    }

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
    $l_name =
qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $name|;
    $l_till =
      qq|<input name="l_till" class=checkbox type=checkbox value=Y> |
      . $locale->text('Till');

    if ( $form->{vc} eq 'vendor' ) {
        $name   = $locale->text('Vendor');
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
    push @a,
qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Invoice Date');
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
	$employee
	$department
	$invnumber
	<tr>
	  <th align=right>| . $locale->text('Ship via') . qq|</th>
	  <td colspan=3><input name=shipvia size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>| . $locale->text('From') . qq|</th>
	  <td><input name=transdatefrom size=11 title="$myconfig{dateformat}"></td>
	  <th align=right>| . $locale->text('To') . qq|</th>
	  <td><input name=transdateto size=11 title="$myconfig{dateformat}"></td>
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

sub transactions {
    if ( $form->{ $form->{vc} } ) {
        $form->{ $form->{vc} } = $form->unescape( $form->{ $form->{vc} } );
        ( $form->{ $form->{vc} }, $form->{"$form->{vc}_id"} ) =
          split( /--/, $form->{ $form->{vc} } );
    }
    @column_index;
    AA->transactions( \%myconfig, \%$form );

    $href = "$form->{script}?action=transactions";
    for (qw(direction oldsort till outstanding path login sessionid summary)) {
        $href .= qq|&$_=$form->{$_}|;
    }
    $href .= "&title=" . $form->escape( $form->{title} );

    $form->sort_order();

    $callback = "$form->{script}?action=transactions";
    for (qw(direction oldsort till outstanding path login sessionid summary)) {
        $callback .= qq|&$_=$form->{$_}|;
    }
    $callback .= "&title=" . $form->escape( $form->{title}, 1 );

    if ( $form->{ $form->{ARAP} } ) {
        $callback .=
          "&$form->{ARAP}=" . $form->escape( $form->{ $form->{ARAP} }, 1 );
        $href .= "&$form->{ARAP}=" . $form->escape( $form->{ $form->{ARAP} } );
        $form->{ $form->{ARAP} } =~ s/--/ /;
        $option = $locale->text('Account') . " : $form->{$form->{ARAP}}";
    }

    if ( $form->{ $form->{vc} } ) {
        $callback .=
            "&$form->{vc}="
          . $form->escape( $form->{ $form->{vc} }, 1 )
          . qq|--$form->{"$form->{vc}_id"}|;
        $href .=
            "&$form->{vc}="
          . $form->escape( $form->{ $form->{vc} } )
          . qq|--$form->{"$form->{vc}_id"}|;
        $option .= "\n<br>" if ($option);
        $name =
          ( $form->{vc} eq 'customer' )
          ? $locale->text('Customer')
          : $locale->text('Vendor');
        $option .= "$name : $form->{$form->{vc}}";
    }
    if ( $form->{department} ) {
        $callback .= "&department=" . $form->escape( $form->{department}, 1 );
        $href .= "&department=" . $form->escape( $form->{department} );
        ($department) = split /--/, $form->{department};
        $option .= "\n<br>" if ($option);
        $option .= $locale->text('Department') . " : $department";
    }
    if ( $form->{employee} ) {
        $callback .= "&employee=" . $form->escape( $form->{employee}, 1 );
        $href .= "&employee=" . $form->escape( $form->{employee} );
        ($employee) = split /--/, $form->{employee};
        $option .= "\n<br>" if ($option);
        if ( $form->{ARAP} eq 'AR' ) {
            $option .= $locale->text('Salesperson');
        }
        else {
            $option .= $locale->text('Employee');
        }
        $option .= " : $employee";
    }

    if ( $form->{invnumber} ) {
        $callback .= "&invnumber=" . $form->escape( $form->{invnumber}, 1 );
        $href   .= "&invnumber=" . $form->escape( $form->{invnumber} );
        $option .= "\n<br>" if ($option);
        $option .= $locale->text('Invoice Number') . " : $form->{invnumber}";
    }
    if ( $form->{ordnumber} ) {
        $callback .= "&ordnumber=" . $form->escape( $form->{ordnumber}, 1 );
        $href   .= "&ordnumber=" . $form->escape( $form->{ordnumber} );
        $option .= "\n<br>" if ($option);
        $option .= $locale->text('Order Number') . " : $form->{ordnumber}";
    }
    if ( $form->{ponumber} ) {
        $callback .= "&ponumber=" . $form->escape( $form->{ponumber}, 1 );
        $href   .= "&ponumber=" . $form->escape( $form->{ponumber} );
        $option .= "\n<br>" if ($option);
        $option .= $locale->text('PO Number') . " : $form->{ponumber}";
    }
    if ( $form->{source} ) {
        $callback .= "&source=" . $form->escape( $form->{source}, 1 );
        $href   .= "&source=" . $form->escape( $form->{source} );
        $option .= "\n<br>" if $option;
        $option .= $locale->text('Source') . " : $form->{source}";
    }
    if ( $form->{description} ) {
        $callback .= "&description=" . $form->escape( $form->{description}, 1 );
        $href   .= "&description=" . $form->escape( $form->{description} );
        $option .= "\n<br>" if $option;
        $option .= $locale->text('Description') . " : $form->{description}";
    }
    if ( $form->{notes} ) {
        $callback .= "&notes=" . $form->escape( $form->{notes}, 1 );
        $href   .= "&notes=" . $form->escape( $form->{notes} );
        $option .= "\n<br>" if $option;
        $option .= $locale->text('Notes') . " : $form->{notes}";
    }
    if ( $form->{shipvia} ) {
        $callback .= "&shipvia=" . $form->escape( $form->{shipvia}, 1 );
        $href   .= "&shipvia=" . $form->escape( $form->{shipvia} );
        $option .= "\n<br>" if $option;
        $option .= $locale->text('Ship via') . " : $form->{shipvia}";
    }
    if ( $form->{transdatefrom} ) {
        $callback .= "&transdatefrom=$form->{transdatefrom}";
        $href     .= "&transdatefrom=$form->{transdatefrom}";
        $option   .= "\n<br>" if ($option);
        $option .=
            $locale->text('From') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{transdatefrom}, 1 );
    }
    if ( $form->{transdateto} ) {
        $callback .= "&transdateto=$form->{transdateto}";
        $href     .= "&transdateto=$form->{transdateto}";
        $option   .= "\n<br>" if ($option);
        $option .=
          $locale->text( 'To [_1]',
            $locale->date( \%myconfig, $form->{transdateto}, 1 ) );
    }
    if ( $form->{open} ) {
        $callback .= "&open=$form->{open}";
        $href     .= "&open=$form->{open}";
        $option   .= "\n<br>" if ($option);
        $option   .= $locale->text('Open');
    }
    if ( $form->{closed} ) {
        $callback .= "&closed=$form->{closed}";
        $href     .= "&closed=$form->{closed}";
        $option   .= "\n<br>" if ($option);
        $option   .= $locale->text('Closed');
    }

    @columns =
      $form->sort_columns(
        qw(transdate id invnumber ordnumber ponumber name netamount tax amount paid due curr datepaid duedate notes till employee manager shippingpoint shipvia department)
      );
    pop @columns if $form->{department};
    unshift @columns, "runningnumber";

    foreach $item (@columns) {
        if ( $form->{"l_$item"} eq "Y" ) {
            push @column_index, $item;

            if ( $form->{l_curr} && $item =~ /(amount|tax|paid|due)/ ) {
                push @column_index, "fx_$item";
            }

            # add column to href and callback
            $callback .= "&l_$item=Y";
            $href     .= "&l_$item=Y";
        }
    }
    if ( !$form->{summary} ) {
        foreach $item (qw(source debit credit accno description projectnumber))
        {
            push @column_index, $item;
        }
    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        $callback .= "&l_subtotal=Y";
        $href     .= "&l_subtotal=Y";
    }

    $employee =
      ( $form->{ARAP} eq 'AR' )
      ? $locale->text('Salesperson')
      : $locale->text('Employee');
    $name =
      ( $form->{vc} eq 'customer' )
      ? $locale->text('Customer')
      : $locale->text('Vendor');

    $column_header{runningnumber} = qq|<th class=listheading>&nbsp;</th>|;
    $column_header{id} =
        "<th><a class=listheading href=$href&sort=id>"
      . $locale->text('ID')
      . "</a></th>";
    $column_header{transdate} =
        "<th><a class=listheading href=$href&sort=transdate>"
      . $locale->text('Date')
      . "</a></th>";
    $column_header{duedate} =
        "<th><a class=listheading href=$href&sort=duedate>"
      . $locale->text('Due Date')
      . "</a></th>";
    $column_header{invnumber} =
        "<th><a class=listheading href=$href&sort=invnumber>"
      . $locale->text('Invoice')
      . "</a></th>";
    $column_header{ordnumber} =
        "<th><a class=listheading href=$href&sort=ordnumber>"
      . $locale->text('Order')
      . "</a></th>";
    $column_header{ponumber} =
        "<th><a class=listheading href=$href&sort=ponumber>"
      . $locale->text('PO Number')
      . "</a></th>";
    $column_header{name} =
      "<th><a class=listheading href=$href&sort=name>$name</a></th>";
    $column_header{netamount} =
      "<th class=listheading>" . $locale->text('Amount') . "</th>";
    $column_header{tax} =
      "<th class=listheading>" . $locale->text('Tax') . "</th>";
    $column_header{amount} =
      "<th class=listheading>" . $locale->text('Total') . "</th>";
    $column_header{paid} =
      "<th class=listheading>" . $locale->text('Paid') . "</th>";
    $column_header{datepaid} =
        "<th><a class=listheading href=$href&sort=datepaid>"
      . $locale->text('Date Paid')
      . "</a></th>";
    $column_header{due} =
      "<th class=listheading>" . $locale->text('Amount Due') . "</th>";
    $column_header{notes} =
      "<th class=listheading>" . $locale->text('Notes') . "</th>";
    $column_header{employee} =
      "<th><a class=listheading href=$href&sort=employee>$employee</th>";
    $column_header{manager} =
      "<th><a class=listheading href=$href&sort=manager>"
      . $locale->text('Manager') . "</th>";
    $column_header{till} =
      "<th class=listheading><a class=listheading href=$href&sort=till>"
      . $locale->text('Till') . "</th>";

    $column_header{shippingpoint} =
        "<th><a class=listheading href=$href&sort=shippingpoint>"
      . $locale->text('Shipping Point')
      . "</a></th>";
    $column_header{shipvia} =
        "<th><a class=listheading href=$href&sort=shipvia>"
      . $locale->text('Ship via')
      . "</a></th>";

    $column_header{curr} =
        "<th><a class=listheading href=$href&sort=curr>"
      . $locale->text('Curr')
      . "</a></th>";
    for (qw(amount tax netamount paid due)) {
        $column_header{"fx_$_"} = "<th>&nbsp;</th>";
    }

    $column_header{department} =
        "<th><a class=listheading href=$href&sort=department>"
      . $locale->text('Department')
      . "</a></th>";

    $column_header{accno} =
        "<th><a class=listheading href=$href&sort=accno>"
      . $locale->text('Account')
      . "</a></th>";
    $column_header{source} =
        "<th><a class=listheading href=$href&sort=source>"
      . $locale->text('Source')
      . "</a></th>";
    $column_header{debit} =
      "<th class=listheading>" . $locale->text('Debit') . "</th>";
    $column_header{credit} =
      "<th class=listheading>" . $locale->text('Credit') . "</th>";
    $column_header{projectnumber} =
        "<th><a class=listheading href=$href&sort=projectnumber>"
      . $locale->text('Project')
      . "</a></th>";
    $column_header{description} =
        "<th><a class=listheading href=$href&sort=linedescription>"
      . $locale->text('Description')
      . "</a></th>";

    $form->{title} =
      ( $form->{title} ) ? $form->{title} : $locale->text('AR Transactions');

    $form->header;

    print qq|
<body>

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
	<tr class=listheading>
|;

    for (@column_index) { print "\n$column_header{$_}" }

    print qq|
	</tr>
|;

    # add sort and escape callback, this one we use for the add sub
    $form->{callback} = $callback .= "&sort=$form->{sort}";

    # escape callback for href
    $callback = $form->escape($callback);

    # flip direction
    $direction = ( $form->{direction} eq 'ASC' ) ? "ASC" : "DESC";
    $href =~ s/&direction=(\w+)&/&direction=$direction&/;

    if ( @{ $form->{transactions} } ) {
        $sameitem = $form->{transactions}->[0]->{ $form->{sort} };
    }

    # sums and tax on reports by Antonio Gallardo
    #
    $i = 0;
    foreach $ref ( @{ $form->{transactions} } ) {

        $i++;

        if ( $form->{l_subtotal} eq 'Y' ) {
            if ( $sameitem ne $ref->{ $form->{sort} } ) {
                &subtotal;
                $sameitem = $ref->{ $form->{sort} };
            }
        }

        if ( $form->{l_curr} ) {
            for (qw(netamount amount paid)) {
                $ref->{"fx_$_"} = $ref->{$_} / $ref->{exchangerate};
            }

            for (qw(netamount amount paid)) {
                $column_data{"fx_$_"} = "<td align=right>"
                  . $form->format_amount( \%myconfig, $ref->{"fx_$_"}, 2,
                    "&nbsp;" )
                  . "</td>";
            }

            $column_data{fx_tax} = "<td align=right>"
              . $form->format_amount( \%myconfig,
                $ref->{fx_amount} - $ref->{fx_netamount},
                2, "&nbsp;" )
              . "</td>";
            $column_data{fx_due} = "<td align=right>"
              . $form->format_amount( \%myconfig,
                $ref->{fx_amount} - $ref->{fx_paid},
                2, "&nbsp;" )
              . "</td>";

            $subtotalfxnetamount += $ref->{fx_netamount};
            $subtotalfxamount    += $ref->{fx_amount};
            $subtotalfxpaid      += $ref->{fx_paid};

            $totalfxnetamount += $ref->{fx_netamount};
            $totalfxamount    += $ref->{fx_amount};
            $totalfxpaid      += $ref->{fx_paid};

        }

        $column_data{runningnumber} = "<td align=right>$i</td>";

        for (qw(netamount amount paid debit credit)) {
            $column_data{$_} =
                "<td align=right>"
              . $form->format_amount( \%myconfig, $ref->{$_}, 2, "&nbsp;" )
              . "</td>";
        }

        $column_data{tax} = "<td align=right>"
          . $form->format_amount( \%myconfig,
            $ref->{amount} - $ref->{netamount},
            2, "&nbsp;" )
          . "</td>";
        $column_data{due} = "<td align=right>"
          . $form->format_amount( \%myconfig, $ref->{amount} - $ref->{paid},
            2, "&nbsp;" )
          . "</td>";

        $subtotalnetamount += $ref->{netamount};
        $subtotalamount    += $ref->{amount};
        $subtotalpaid      += $ref->{paid};
        $subtotaldebit     += $ref->{debit};
        $subtotalcredit    += $ref->{credit};

        $totalnetamount += $ref->{netamount};
        $totalamount    += $ref->{amount};
        $totalpaid      += $ref->{paid};
        $totaldebit     += $ref->{debit};
        $totalcredit    += $ref->{credit};

        $module =
            ( $ref->{invoice} )
          ? ( $form->{ARAP} eq 'AR' ) ? "is.pl" : "ir.pl"
          :   $form->{script};
        $module = ( $ref->{till} ) ? "ps.pl" : $module;

        $column_data{invnumber} =
"<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{invnumber}&nbsp;</a></td>";

        for (qw(notes description)) { $ref->{$_} =~ s/\r?\n/<br>/g }
        for (
            qw(transdate datepaid duedate department ordnumber ponumber notes shippingpoint shipvia employee manager till source description projectnumber)
          )
        {
            $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>";
        }
        for (qw(id curr)) { $column_data{$_} = "<td>$ref->{$_}</td>" }

        $column_data{accno} =
qq|<td><a href=ca.pl?path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&action=list_transactions&accounttype=standard&accno=$ref->{accno}&fromdate=$form->{transdatefrom}&todate=$form->{transdateto}&sort=transdate&l_subtotal=$form->{l_subtotal}&prevreport=$callback>$ref->{accno}</a></td>|;

        $column_data{name} =
qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&action=edit&id=$ref->{"$form->{vc}_id"}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;

        if ( $ref->{id} != $sameid ) {
            $j++;
            $j %= 2;
        }

        print "
        <tr class=listrow$j>
";

        for (@column_index) { print "\n$column_data{$_}" }

        print qq|
        </tr>
|;

        $sameid = $ref->{id};

    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        &subtotal;
        $sameitem = $ref->{ $form->{sort} };
    }

    # print totals
    print qq|
        <tr class=listtotal>
|;

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{netamount} =
        "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $totalnetamount, 2, "&nbsp;" )
      . "</th>";
    $column_data{tax} = "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $totalamount - $totalnetamount,
        2, "&nbsp;" )
      . "</th>";
    $column_data{amount} =
      "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $totalamount, 2, "&nbsp;" ) . "</th>";
    $column_data{paid} =
      "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $totalpaid, 2, "&nbsp;" ) . "</th>";
    $column_data{due} =
      "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $totalamount - $totalpaid, 2,
        "&nbsp;" )
      . "</th>";
    $column_data{debit} =
      "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $totaldebit, 2, "&nbsp;" ) . "</th>";
    $column_data{credit} =
      "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $totalcredit, 2, "&nbsp;" ) . "</th>";

    if ( $form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal} ) {
        $column_data{fx_netamount} =
            "<th class=listtotal align=right>"
          . $form->format_amount( \%myconfig, $totalfxnetamount, 2, "&nbsp;" )
          . "</th>";
        $column_data{fx_tax} = "<th class=listtotal align=right>"
          . $form->format_amount( \%myconfig,
            $totalfxamount - $totalfxnetamount,
            2, "&nbsp;" )
          . "</th>";
        $column_data{fx_amount} =
            "<th class=listtotal align=right>"
          . $form->format_amount( \%myconfig, $totalfxamount, 2, "&nbsp;" )
          . "</th>";
        $column_data{fx_paid} =
            "<th class=listtotal align=right>"
          . $form->format_amount( \%myconfig, $totalfxpaid, 2, "&nbsp;" )
          . "</th>";
        $column_data{fx_due} = "<th class=listtotal align=right>"
          . $form->format_amount( \%myconfig, $totalfxamount - $totalfxpaid,
            2, "&nbsp;" )
          . "</th>";
    }

    for (@column_index) { print "\n$column_data{$_}" }

    if ( $myconfig{acs} !~ /$form->{ARAP}--$form->{ARAP}/ ) {
        $i = 1;
        if ( $form->{ARAP} eq 'AR' ) {
            $button{'AR--Add Transaction'}{code} =
qq|<button class="submit" type="submit" name="action" value="ar_transaction">|
              . $locale->text('AR Transaction')
              . qq|</button> |;
            $button{'AR--Add Transaction'}{order} = $i++;
            $button{'AR--Sales Invoice'}{code} =
qq|<button class="submit" type="submit" name="action" value="sales_invoice_">|
              . $locale->text('Sales Invoice.')
              . qq|</button> |;
            $button{'AR--Sales Invoice'}{order} = $i++;
        }
        else {
            $button{'AP--Add Transaction'}{code} =
qq|<button class="submit" type="submit" name="action" value="ap_transaction">|
              . $locale->text('AP Transaction')
              . qq|</button> |;
            $button{'AP--Add Transaction'}{order} = $i++;
            $button{'AP--Vendor Invoice'}{code} =
qq|<button class="submit" type="submit" name="action" value="vendor_invoice_">|
              . $locale->text('Vendor Invoice.')
              . qq|</button> |;
            $button{'AP--Vendor Invoice'}{order} = $i++;
        }

        foreach $item ( split /;/, $myconfig{acs} ) {
            delete $button{$item};
        }
    }

    print qq|
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>
|;

    $form->hide_form(
        "callback",    "path", "login", "sessionid",
        "$form->{vc}", "$form->{vc}_id"
    );

    if ( !$form->{till} ) {
        foreach $item ( sort { $a->{order} <=> $b->{order} } %button ) {
            print $item->{code};
        }
    }

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print qq|
</form>

</body>
</html>
|;

}

sub subtotal {

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{tax} = "<th class=listsubtotal align=right>"
      . $form->format_amount( \%myconfig, $subtotalamount - $subtotalnetamount,
        2, "&nbsp;" )
      . "</th>";
    $column_data{amount} =
        "<th class=listsubtotal align=right>"
      . $form->format_amount( \%myconfig, $subtotalamount, 2, "&nbsp;" )
      . "</th>";
    $column_data{paid} =
        "<th class=listsubtotal align=right>"
      . $form->format_amount( \%myconfig, $subtotalpaid, 2, "&nbsp;" )
      . "</th>";
    $column_data{due} = "<th class=listsubtotal align=right>"
      . $form->format_amount( \%myconfig, $subtotalamount - $subtotalpaid,
        2, "&nbsp;" )
      . "</th>";
    $column_data{debit} =
        "<th class=listsubtotal align=right>"
      . $form->format_amount( \%myconfig, $subtotaldebit, 2, "&nbsp;" )
      . "</th>";
    $column_data{credit} =
        "<th class=listsubtotal align=right>"
      . $form->format_amount( \%myconfig, $subtotalcredit, 2, "&nbsp;" )
      . "</th>";

    if ( $form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal} ) {
        $column_data{fx_tax} = "<th class=listsubtotal align=right>"
          . $form->format_amount( \%myconfig,
            $subtotalfxamount - $subtotalfxnetamount,
            2, "&nbsp;" )
          . "</th>";
        $column_data{fx_amount} =
            "<th class=listsubtotal align=right>"
          . $form->format_amount( \%myconfig, $subtotalfxamount, 2, "&nbsp;" )
          . "</th>";
        $column_data{fx_paid} =
            "<th class=listsubtotal align=right>"
          . $form->format_amount( \%myconfig, $subtotalfxpaid, 2, "&nbsp;" )
          . "</th>";
        $column_data{fx_due} = "<th class=listsubtotal align=right>"
          . $form->format_amount( \%myconfig,
            $subtotalfxmount - $subtotalfxpaid,
            2, "&nbsp;" )
          . "</th>";
    }

    $subtotalnetamount = 0;
    $subtotalamount    = 0;
    $subtotalpaid      = 0;
    $subtotaldebit     = 0;
    $subtotalcredit    = 0;

    $subtotalfxnetamount = 0;
    $subtotalfxamount    = 0;
    $subtotalfxpaid      = 0;

    print "<tr class=listsubtotal>";

    for (@column_index) { print "\n$column_data{$_}" }

    print "
</tr>
";

}

