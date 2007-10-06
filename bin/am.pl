#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
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
#  Contributors:
#
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# administration
#
#======================================================================

use LedgerSMB::AM;
use LedgerSMB::CA;
use LedgerSMB::Form;
use LedgerSMB::User;
use LedgerSMB::RP;
use LedgerSMB::GL;
use LedgerSMB::Template;

1;

# end of main

sub add    { &{"add_$form->{type}"} }
sub edit   { &{"edit_$form->{type}"} }
sub save   { &{"save_$form->{type}"} }
sub delete { &{"delete_$form->{type}"} }

sub save_as_new {

    delete $form->{id};

    &save;

}

sub add_account {

    $form->{title}     = "Add";
    $form->{charttype} = "A";

    $form->{callback} =
"$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &account_header;
    &form_footer;

}

sub edit_account {

    $form->{title} = "Edit";

    $form->{accno} =~ s/\\'/'/g;
    $form->{accno} =~ s/\\\\/\\/g;

    AM->get_account( \%myconfig, \%$form );

    foreach my $item ( split( /:/, $form->{link} ) ) {
        $form->{$item} = "checked";
    }

    &account_header;
    &form_footer;

}

sub account_header {

    $form->{title} = $locale->text("$form->{title} Account");

    $checked{ $form->{charttype} } = "checked";
    $checked{contra} = "checked" if $form->{contra};
    $checked{"$form->{category}_"} = "checked";

    for (qw(accno description)) { $form->{$_} = $form->quote( $form->{$_} ) }

    # this is for our parser only!
    # type=submit $locale->text('Add Account')
    # type=submit $locale->text('Edit Account')

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=account>

<input type=hidden name=inventory_accno_id value=$form->{inventory_accno_id}>
<input type=hidden name=income_accno_id value=$form->{income_accno_id}>
<input type=hidden name=expense_accno_id value=$form->{expense_accno_id}>
<input type=hidden name=fxgain_accno_id values=$form->{fxgain_accno_id}>
<input type=hidden name=fxloss_accno_id values=$form->{fxloss_accno_id}>

<table border=0 width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align="right">| . $locale->text('Account Number') . qq|</th>
	  <td><input name=accno size=20 value="$form->{accno}"></td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Description') . qq|</th>
	  <td><input name=description size=40 value="$form->{description}"></td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Account Type') . qq|</th>
	  <td>
	    <table>
	      <tr valign=top>
		<td><input name=category type=radio class=radio value=A $checked{A_}>&nbsp;|
      . $locale->text('Asset')
      . qq|\n<br>
		<input name=category type=radio class=radio value=L $checked{L_}>&nbsp;|
      . $locale->text('Liability')
      . qq|\n<br>
		<input name=category type=radio class=radio value=Q $checked{Q_}>&nbsp;|
      . $locale->text('Equity')
      . qq|\n<br>
		<input name=category type=radio class=radio value=I $checked{I_}>&nbsp;|
      . $locale->text('Income')
      . qq|\n<br>
		<input name=category type=radio class=radio value=E $checked{E_}>&nbsp;|
      . $locale->text('Expense')
      . qq|</td>
		<td>
		<input name=contra class=checkbox type=checkbox value=1 $checked{contra}>&nbsp;|
      . $locale->text('Contra') . qq|
		</td>
		<td>
		<input name=charttype type=radio class=radio value="H" $checked{H}>&nbsp;|
      . $locale->text('Heading') . qq|<br>
		<input name=charttype type=radio class=radio value="A" $checked{A}>&nbsp;|
      . $locale->text('Account')
      . qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

    if ( $form->{charttype} eq "A" ) {
        print qq|
	<tr>
	  <td colspan=2>
	    <table>
	      <tr>
		<th align=left>|
          . $locale->text('Is this a summary account to record')
          . qq|</th>
		<td>
		<input name=AR class=checkbox type=checkbox value=AR $form->{AR}>&nbsp;|
          . $locale->text('AR')
          . qq|&nbsp;<input name=AP class=checkbox type=checkbox value=AP $form->{AP}>&nbsp;|
          . $locale->text('AP')
          . qq|&nbsp;<input name=IC class=checkbox type=checkbox value=IC $form->{IC}>&nbsp;|
          . $locale->text('Inventory')
          . qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr>
	  <th colspan=2>| . $locale->text('Include in drop-down menus') . qq|</th>
	</tr>
	<tr valign=top>
	  <td colspan=2>
	    <table width=100%>
	      <tr>
		<th align=left>| . $locale->text('Receivables') . qq|</th>
		<th align=left>| . $locale->text('Payables') . qq|</th>
		<th align=left>| . $locale->text('Tracking Items') . qq|</th>
		<th align=left>| . $locale->text('Non-tracking Items') . qq|</th>
	      </tr>
	      <tr>
		<td>
		<input name=AR_amount class=checkbox type=checkbox value=AR_amount $form->{AR_amount}>&nbsp;|
          . $locale->text('Income')
          . qq|\n<br>
		<input name=AR_paid class=checkbox type=checkbox value=AR_paid $form->{AR_paid}>&nbsp;|
          . $locale->text('Payment')
          . qq|\n<br>
		<input name=AR_tax class=checkbox type=checkbox value=AR_tax $form->{AR_tax}>&nbsp;|
          . $locale->text('Tax') . qq|
		</td>
		<td>
		<input name=AP_amount class=checkbox type=checkbox value=AP_amount $form->{AP_amount}>&nbsp;|
          . $locale->text('Expense/Asset')
          . qq|\n<br>
		<input name=AP_paid class=checkbox type=checkbox value=AP_paid $form->{AP_paid}>&nbsp;|
          . $locale->text('Payment')
          . qq|\n<br>
		<input name=AP_tax class=checkbox type=checkbox value=AP_tax $form->{AP_tax}>&nbsp;|
          . $locale->text('Tax') . qq|
		</td>
		<td>
		<input name=IC_sale class=checkbox type=checkbox value=IC_sale $form->{IC_sale}>&nbsp;|
          . $locale->text('Income')
          . qq|\n<br>
		<input name=IC_cogs class=checkbox type=checkbox value=IC_cogs $form->{IC_cogs}>&nbsp;|
          . $locale->text('COGS')
          . qq|\n<br>
		<input name=IC_taxpart class=checkbox type=checkbox value=IC_taxpart $form->{IC_taxpart}>&nbsp;|
          . $locale->text('Tax') . qq|
		</td>
		<td>
		<input name=IC_income class=checkbox type=checkbox value=IC_income $form->{IC_income}>&nbsp;|
          . $locale->text('Income')
          . qq|\n<br>
		<input name=IC_expense class=checkbox type=checkbox value=IC_expense $form->{IC_expense}>&nbsp;|
          . $locale->text('Expense')
          . qq|\n<br>
		<input name=IC_taxservice class=checkbox type=checkbox value=IC_taxservice $form->{IC_taxservice}>&nbsp;|
          . $locale->text('Tax') . qq|
		</td>
	      </tr>
	    </table>
	  </td>  
	</tr>  
	<tr>
	</tr>
|;
    }

    print qq|
        <tr>
	  <th align="right">| . $locale->text('GIFI') . qq|</th>
	  <td><input name=gifi_accno size=9 value="$form->{gifi_accno}"></td>
	</tr>
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

    # type=submit $locale->text('Save')
    # type=submit $locale->text('Save as new')
    # type=submit $locale->text('Delete')

    %button = ();

    if ( $form->{id} ) {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save') };
        $button{'save_as_new'} =
          { ndx => 7, key => 'N', value => $locale->text('Save as new') };

        if ( $form->{orphaned} ) {
            $button{'delete'} =
              { ndx => 16, key => 'D', value => $locale->text('Delete') };
        }
    }
    else {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save') };
    }

    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        $form->print_button( \%button, $_ );
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

sub save_account {

    $form->isblank( "accno",    $locale->text('Account Number missing!') );
    $form->isblank( "category", $locale->text('Account Type missing!') );

    # check for conflicting accounts
    if ( $form->{AR} || $form->{AP} || $form->{IC} ) {
        $a = "";
        for (qw(AR AP IC)) { $a .= $form->{$_} }
        $form->error(
            $locale->text(
                'Cannot set account for more than one of AR, AP or IC')
        ) if length $a > 2;

        for (
            qw(AR_amount AR_tax AR_paid AP_amount AP_tax AP_paid IC_taxpart IC_taxservice IC_sale IC_cogs IC_income IC_expense)
          )
        {
            $form->error(
                "$form->{AR}$form->{AP}$form->{IC} "
                  . $locale->text(
                    'account cannot be set to any other type of account')
            ) if $form->{$_};
        }
    }

    foreach $item ( "AR", "AP" ) {
        $i = 0;
        for ( "${item}_amount", "${item}_paid", "${item}_tax" ) {
            $i++ if $form->{$_};
        }
        $form->error(
            $locale->text( 'Cannot set multiple options for [_1]', $item ) )
          if $i > 1;
    }

    if ( AM->save_account( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Account saved!') );
    }
    else {
        $form->error( $locale->text('Cannot save account!') );
    }

}

sub list_account {

    CA->all_accounts( \%myconfig, \%$form );

    $form->{title} = $locale->text('Chart of Accounts');

    # construct callback
    $callback =
"$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->{callback} = $callback;
    @column_index = qw(accno gifi_accno description debit credit link);

    $column_header{accno} = $locale->text('Account');
    $column_header{gifi_accno} = $locale->text('GIFI');
    $column_header{description} = $locale->text('Description');
    $column_header{debit} = $locale->text('Debit');
    $column_header{credit} = $locale->text('Credit');
    $column_header{link} = $locale->text('Link');

    # escape callback
    $callback = $form->escape($callback);

    my @rows;
    foreach my $ca ( @{ $form->{CA} } ) {

        my %column_data;
        $ca->{debit}  = " ";
        $ca->{credit} = " ";

        if ( $ca->{amount} > 0 ) {
            $ca->{credit} =
              $form->format_amount( \%myconfig, $ca->{amount}, 2, " " );
        }
        if ( $ca->{amount} < 0 ) {
            $ca->{debit} =
              $form->format_amount( \%myconfig, -$ca->{amount}, 2, " " );
        }

        #$ca->{link} =~ s/:/<br>/og;

        $gifi_accno = $form->escape( $ca->{gifi_accno} );

        if ( $ca->{charttype} eq "H" ) {
            $column_data{class} = 'heading';
            $column_data{accno} = {
              text => $ca->{accno},
              href => "$form->{script}?action=edit_account&id=$ca->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback"};
            $column_data{gifi_accno} = {
              text => $ca->{gifi_accno},
              href => "$form->{script}?action=edit_gifi&accno=$gifi_accno&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback"};
            $column_data{description} = $ca->{description};
            $column_data{debit}  = " ";
            $column_data{credit} = " ";
            $column_data{link}   = " ";

        }
        else {
            $i++;
            $i %= 2;
            $column_data{i} = $i;
            $column_data{accno} = {
              text => $ca->{accno},
              href => "$form->{script}?action=edit_account&id=$ca->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback"};
            $column_data{gifi_accno} = {
              text => $ca->{gifi_accno},
              href => "$form->{script}?action=edit_gifi&accno=$gifi_accno&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback"};
            $column_data{description} = $ca->{description};
            $column_data{debit}       = $ca->{debit};
            $column_data{credit} = $ca->{credit};
	    $column_data{link}   = {text => $ca->{link}, delimiter => ':'};

        }
        push @rows, \%column_data;
    }

    my @buttons;
    for my $type (qw(CSV XLS ODS)) {
        push @buttons, {
            name => 'action',
            value => lc "${type}_list_account",
            text => $locale->text("$type Report"),
            type => 'submit',
            class => 'submit',
        };
    }
    my %hiddens = (
        callback => $callback,
        action => 'list_account',
        path => $form->{path},
        login => $form->{login},
        sessionid => $form->{sessionid},
        );

    my %row_alignment = ('credit' => 'right', 'debit' => 'right');
    my $format = uc substr($form->{action}, 0, 3);
    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale,
        path => 'UI',
        template => 'form-dynatable',
        format => ($format ne 'LIS')? $format: 'HTML');
    $template->render({
        form => $form,
        buttons => \@buttons,
	hiddens => \%hiddens,
        columns => \@column_index,
        heading => \%column_header,
        rows => \@rows,
	row_alignment => \%row_alignment,
    });
}

sub csv_list_account { &list_account }
sub xls_list_account { &list_account }
sub ods_list_account { &list_account }

sub delete_account {

    $form->{title} = $locale->text('Delete Account');

    foreach $id (
        qw(inventory_accno_id income_accno_id expense_accno_id fxgain_accno_id fxloss_accno_id)
      )
    {
        if ( $form->{id} == $form->{$id} ) {
            $form->error( $locale->text('Cannot delete default account!') );
        }
    }

    if ( AM->delete_account( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Account deleted!') );
    }
    else {
        $form->error( $locale->text('Cannot delete account!') );
    }

}

sub list_gifi {

    @{ $form->{fields} } = qw(accno description);
    $form->{table} = "gifi";

    AM->gifi_accounts( \%myconfig, \%$form );

    $form->{title} = $locale->text('GIFI');
    my %hiddens;

    # construct callback
    my $callback =
"$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
    $form->{callback} = $callback;
    $hiddens{callback} = $callback;
    $hiddens{action} = 'list_gifi';
    $hiddens{path} = $form->{path};
    $hiddens{login} = $form->{login};
    $hiddens{sessionid} = $form->{sessionid};

    my @column_index = qw(accno description);
    my %column_header;
    my @rows;

    $column_header{accno} = $locale->text('GIFI');
    $column_header{description} = $locale->text('Description');

    my $i = 0;
    foreach $ca ( @{ $form->{ALL} } ) {

        my %column_data;
        $i++;
        $i %= 2;
        $column_data{i} = $i;

        $accno = $form->escape( $ca->{accno} );
        $column_data{accno} = {text => $ca->{accno}, href =>
          qq|$form->{script}?action=edit_gifi&coa=1&accno=$accno&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback|};
        $column_data{description} = $ca->{description};

        push @rows, \%column_data;
    }

    my @buttons;
    push @buttons, {
        name => 'action',
        value => 'csv_list_gifi',
        text => $locale->text('CSV Report'),
        type => 'submit',
        class => 'submit',
    };

    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale,
        path => 'UI',
	template => 'form-dynatable',
        format => ($form->{action} =~ /^csv/)? 'CSV': 'HTML');
    $template->render({
        form => \%$form,
        hiddens => \%hiddens,
        buttons => \@buttons,
        columns => \@column_index,
        heading => \%column_header,
        rows => \@rows,
    });
}

sub csv_list_gifi { &list_gifi }

sub add_gifi {
    $form->{title} = "Add";

    # construct callback
    $form->{callback} =
"$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->{coa} = 1;

    &gifi_header;
    &gifi_footer;

}

sub edit_gifi {

    $form->{title} = "Edit";

    AM->get_gifi( \%myconfig, \%$form );

    $form->error( $locale->text('Account does not exist!') )
      unless $form->{accno};

    &gifi_header;
    &gifi_footer;

}

sub gifi_header {

    $form->{title} = $locale->text("$form->{title} GIFI");

    # $locale->text('Add GIFI')
    # $locale->text('Edit GIFI')

    for (qw(accno description)) { $form->{$_} = $form->quote( $form->{$_} ) }

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value="$form->{accno}">
<input type=hidden name=type value=gifi>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">| . $locale->text('GIFI') . qq|</th>
	  <td><input name=accno size=20 value="$form->{accno}"></td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Description') . qq|</th>
	  <td><input name=description size=60 value="$form->{description}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub gifi_footer {

    $form->hide_form(qw(callback path login sessionid));

    # type=submit $locale->text('Save')
    # type=submit $locale->text('Copy to COA')
    # type=submit $locale->text('Delete')

    %button = ();

    $button{'save'} = { ndx => 3, key => 'S', value => $locale->text('Save') };

    if ( $form->{accno} ) {
        if ( $form->{orphaned} ) {
            $button{'delete'} =
              { ndx => 16, key => 'D', value => $locale->text('Delete') };
        }
    }

    if ( $form->{coa} ) {
        $button{'copy_to_coa'} =
          { ndx => 7, key => 'C', value => $locale->text('Copy to COA') };
    }

    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        $form->print_button( \%button, $_ );
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

sub save_gifi {

    $form->isblank( "accno", $locale->text('GIFI missing!') );
    AM->save_gifi( \%myconfig, \%$form );
    $form->redirect( $locale->text('GIFI saved!') );

}

sub copy_to_coa {

    $form->isblank( "accno", $locale->text('GIFI missing!') );

    AM->save_gifi( \%myconfig, \%$form );

    delete $form->{id};
    $form->{gifi_accno} = $form->{accno};

    $form->{title}     = "Add";
    $form->{charttype} = "A";

    &account_header;
    &form_footer;

}

sub delete_gifi {

    AM->delete_gifi( \%myconfig, \%$form );
    $form->redirect( $locale->text('GIFI deleted!') );

}

sub add_department {

    $form->{title} = "Add";
    $form->{role}  = "P";

    $form->{callback} =
"$form->{script}?action=add_department&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &department_header;
    &form_footer;

}

sub edit_department {

    $form->{title} = "Edit";

    AM->get_department( \%myconfig, \%$form );

    &department_header;
    &form_footer;

}

sub list_department {

    AM->departments( \%myconfig, \%$form );

    my $href =
"$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $form->{callback} =
"$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    my $callback = $form->escape( $form->{callback} );

    $form->{title} = $locale->text('Departments');

    my @column_index = qw(description cost profit);
    my %column_header;

    $column_header{description} = { text => $locale->text('Description'),
        href => $href};
    $column_header{cost} = $locale->text('Cost Center');
    $column_header{profit} = $locale->text('Profit Center');


    my @rows;
    my $i = 0;
    foreach my $ref ( @{ $form->{ALL} } ) {

        my %column_data;
        $i++;
        $i %= 2;
        $column_data{i} = $i;

        $column_data{cost}   = ( $ref->{role} eq "C" ) ? "*" : " ";
        $column_data{profit} = ( $ref->{role} eq "P" ) ? "*" : " ";

        $column_data{description} = { text => $ref->{description}, 
            href => qq|$form->{script}?action=edit_department&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback|,};

        push @rows, \%column_data;
    }

    $form->{type} = "department";

    my @hiddens = qw(type callback path login sessionid);

    ## SC: removing this for now
    #if ( $form->{lynx} ) {
    #    require "bin/menu.pl";
    #    &menubar;
    #}

    my @buttons;
    push @buttons, {
        name => 'action',
        value => 'add_department',
        text => $locale->text('Add Department'),
        type => 'submit',
        class => 'submit',
    };

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'am-list-departments');
    $template->render({
        form => $form,
        buttons => \@buttons,
        columns => \@column_index,
        heading => \%column_header,
        rows => \@rows,
        hiddens => \@hiddens,
    });
}

sub department_header {

    $form->{title} = $locale->text("$form->{title} Department");

    # $locale->text('Add Department')
    # $locale->text('Edit Department')

    $form->{description} = $form->quote( $form->{description} );

    if ( ( $rows = $form->numtextrows( $form->{description}, 60 ) ) > 1 ) {
        $description =
qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input name=description size=60 value="$form->{description}">|;
    }

    $costcenter   = "checked" if $form->{role} eq "C";
    $profitcenter = "checked" if $form->{role} eq "P";

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=department>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">| . $locale->text('Description') . qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <td></td>
    <td><input type=radio style=radio name=role value="C" $costcenter> |
      . $locale->text('Cost Center') . qq|
        <input type=radio style=radio name=role value="P" $profitcenter> |
      . $locale->text('Profit Center') . qq|
    </td>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub save_department {

    $form->isblank( "description", $locale->text('Description missing!') );
    AM->save_department( \%myconfig, \%$form );
    $form->redirect( $locale->text('Department saved!') );

}

sub delete_department {

    AM->delete_department( \%myconfig, \%$form );
    $form->redirect( $locale->text('Department deleted!') );

}

sub add_business {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add_business&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &business_header;
    &form_footer;

}

sub edit_business {

    $form->{title} = "Edit";

    AM->get_business( \%myconfig, \%$form );

    &business_header;

    $form->{orphaned} = 1;
    &form_footer;

}

sub list_business {

    AM->business( \%myconfig, \%$form );

    my $href =
"$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $form->{callback} =
"$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    my $callback = $form->escape( $form->{callback} );

    $form->{title} = $locale->text('Type of Business');

    my @column_index = qw(description discount);

    my %column_header;
    $column_header{description} = { text => $locale->text('Description'),
        href => $href };
    $column_header{discount} = $locale->text('Discount %');

    my @rows;
    $i = 0;
    foreach my $ref ( @{ $form->{ALL} } ) {
    
        my %column_data;
        $i++;
        $i %= 2;
        $column_data{i} = $i;

        $column_data{discount} =
          $form->format_amount( \%myconfig, $ref->{discount} * 100, 2, " " );
        $column_data{description} = { text => $ref->{description}, href =>
            qq|$form->{script}?action=edit_business&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback|};

	push @rows, \%column_data;
    }

    $form->{type} = "business";

    my @hiddens = qw(type callback path login sessionid);

## SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my @buttons;
    push @buttons, {
        name => 'action',
        value => 'add_business',
        text => $locale->text('Add Business'),
        type => 'submit',
        class => 'submit',
    };

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'am-list-departments');
    $template->render({
        form => $form,
        buttons => \@buttons,
        columns => \@column_index,
        heading => \%column_header,
        rows => \@rows,
        hiddens => \@hiddens,
    });
}

sub business_header {

    $form->{title} = $locale->text("$form->{title} Business");

    # $locale->text('Add Business')
    # $locale->text('Edit Business')

    $form->{description} = $form->quote( $form->{description} );
    $form->{discount} =
      $form->format_amount( \%myconfig, $form->{discount} * 100 );

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=business>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">| . $locale->text('Type of Business') . qq|</th>
	  <td><input name=description size=30 value="$form->{description}"></td>
	<tr>
	<tr>
	  <th align="right">| . $locale->text('Discount') . qq| %</th>
	  <td><input name=discount size=5 value=$form->{discount}></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub save_business {

    $form->isblank( "description", $locale->text('Description missing!') );
    AM->save_business( \%myconfig, \%$form );
    $form->redirect( $locale->text('Business saved!') );

}

sub delete_business {

    AM->delete_business( \%myconfig, \%$form );
    $form->redirect( $locale->text('Business deleted!') );

}

sub add_sic {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add_sic&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &sic_header;
    &form_footer;

}

sub edit_sic {

    $form->{title} = "Edit";

    $form->{code} =~ s/\\'/'/g;
    $form->{code} =~ s/\\\\/\\/g;

    AM->get_sic( \%myconfig, \%$form );
    $form->{id} = $form->{code};

    &sic_header;

    $form->{orphaned} = 1;
    &form_footer;

}

sub list_sic {

    AM->sic( \%myconfig, \%$form );

    $href =
"$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $form->{callback} =
"$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $callback = $form->escape( $form->{callback} );

    $form->{title} = $locale->text('Standard Industrial Codes');

    @column_index = $form->sort_columns(qw(code description));

    $column_header{code} =
        qq|<th><a class="listheading" href=$href&sort=code>|
      . $locale->text('Code')
      . qq|</a></th>|;
    $column_header{description} =
        qq|<th><a class="listheading" href=$href&sort=description>|
      . $locale->text('Description')
      . qq|</a></th>|;

    $form->header;

    print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
        </tr>
|;

    foreach $ref ( @{ $form->{ALL} } ) {

        $i++;
        $i %= 2;

        if ( $ref->{sictype} eq 'H' ) {
            print qq|
        <tr valign=top class="listheading">
|;
            $column_data{code} =
qq|<th><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</th>|;
            $column_data{description} = qq|<th>$ref->{description}</th>|;

        }
        else {
            print qq|
        <tr valign=top class=listrow$i>
|;

            $column_data{code} =
qq|<td><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</td>|;
            $column_data{description} = qq|<td>$ref->{description}</td>|;

        }

        for (@column_index) { print "$column_data{$_}\n" }

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
<form method=post action=$form->{script}>
|;

    $form->{type} = "sic";

    $form->hide_form(qw(type callback path login sessionid));

    print qq|
<button class="submit" type="submit" name="action" value="add_sic">|
      . $locale->text('Add SIC')
      . qq|</button>|;

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

sub sic_header {

    $form->{title} = $locale->text("$form->{title} SIC");

    # $locale->text('Add SIC')
    # $locale->text('Edit SIC')

    for (qw(code description)) { $form->{$_} = $form->quote( $form->{$_} ) }

    $checked = ( $form->{sictype} eq 'H' ) ? "checked" : "";

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=sic>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">| . $locale->text('Code') . qq|</th>
    <td><input name=code size=10 value="$form->{code}"></td>
  <tr>
  <tr>
    <td></td>
    <th align=left><input name=sictype class=checkbox type=checkbox value="H" $checked> |
      . $locale->text('Heading')
      . qq|</th>
  <tr>
  <tr>
    <th align="right">| . $locale->text('Description') . qq|</th>
    <td><input name=description size=60 value="$form->{description}"></td>
  </tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub save_sic {

    $form->isblank( "code",        $locale->text('Code missing!') );
    $form->isblank( "description", $locale->text('Description missing!') );
    AM->save_sic( \%myconfig, \%$form );
    $form->redirect( $locale->text('SIC saved!') );

}

sub delete_sic {

    AM->delete_sic( \%myconfig, \%$form );
    $form->redirect( $locale->text('SIC deleted!') );

}

sub add_language {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add_language&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &language_header;
    &form_footer;

}

sub edit_language {

    $form->{title} = "Edit";

    $form->{code} =~ s/\\'/'/g;
    $form->{code} =~ s/\\\\/\\/g;

    AM->get_language( \%myconfig, \%$form );
    $form->{id} = $form->{code};

    &language_header;

    $form->{orphaned} = 1;
    &form_footer;

}

sub list_language {

    AM->language( \%myconfig, \%$form );

    $href =
"$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $form->{callback} =
"$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    my $callback = $form->escape( $form->{callback} );

    $form->{title} = $locale->text('Languages');

    my @column_index = $form->sort_columns(qw(code description));
    my %column_header;

    $column_header{code} = { text => $locale->text('Code'),
        href => "$href&sort=code" };
    $column_header{description} = { text => $locale->text('Description'),
        href => "$href&sort=description" };

    my @rows;
    my $i = 0;
    foreach my $ref ( @{ $form->{ALL} } ) {

        my %column_data;
        $i++;
        $i %= 2;
        $column_data{i} = $i;

        $column_data{code} = {text => $ref->{code}, href =>
            qq|$form->{script}?action=edit_language&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback|};
        $column_data{description} = $ref->{description};

        push @rows, \%column_data;
    
    }

    $form->{type} = "language";

    my @hiddens = qw(type callback path login sessionid);

## SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my @buttons;
    push @buttons, {
        name => 'action',
        value => 'add_language',
        text => $locale->text('Add Lanugage'),
        type => 'submit',
        class => 'submit',
    };

    # SC: I'm not concerned about the wider description as code is 6 chars max
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'am-list-departments');
    $template->render({
        form => $form,
        buttons => \@buttons,
        columns => \@column_index,
        heading => \%column_header,
        rows => \@rows,
        hiddens => \@hiddens,
    });
}

sub language_header {

    $form->{title} = $locale->text("$form->{title} Language");

    # $locale->text('Add Language')
    # $locale->text('Edit Language')

    for (qw(code description)) { $form->{$_} = $form->quote( $form->{$_} ) }

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=language>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">| . $locale->text('Code') . qq|</th>
    <td><input name=code size=10 value="$form->{code}"></td>
  <tr>
  <tr>
    <th align="right">| . $locale->text('Description') . qq|</th>
    <td><input name=description size=60 value="$form->{description}"></td>
  </tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub save_language {

    $form->isblank( "code",        $locale->text('Code missing!') );
    $form->isblank( "description", $locale->text('Description missing!') );

    $form->{code} =~ s/(\.\.|\*)//g;

    AM->save_language( \%myconfig, \%$form );

    if ( !-d "$myconfig{templates}/$form->{code}" ) {

        umask(002);

        if ( mkdir "$myconfig{templates}/$form->{code}", oct("771") ) {

            umask(007);

            opendir TEMPLATEDIR, "$myconfig{templates}"
              or $form->error("$myconfig{templates} : $!");
            @templates = grep !/^(\.|\.\.)/, readdir TEMPLATEDIR;
            closedir TEMPLATEDIR;

            foreach $file (@templates) {
                if ( -f "$myconfig{templates}/$file" ) {
                    open( TEMP, '<', "$myconfig{templates}/$file" )
                      or $form->error("$myconfig{templates}/$file : $!");

                    open( NEW, '>', "$myconfig{templates}/$form->{code}/$file" )
                      or $form->error(
                        "$myconfig{templates}/$form->{code}/$file : $!");

                    while ( $line = <TEMP> ) {
                        print NEW $line;
                    }
                    close(TEMP);
                    close(NEW);
                }
            }
        }
        else {
            $form->error("${templates}/$form->{code} : $!");
        }
    }

    $form->redirect( $locale->text('Language saved!') );

}

sub delete_language {

    $form->{title} = $locale->text('Confirm!');

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>
|;

    for (qw(action nextsub)) { delete $form->{$_} }

    $form->hide_form;

    print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|
      . $locale->text(
'Deleting a language will also delete the templates for the language [_1]',
        $form->{invnumber}
      )
      . qq|</h4>

<input type=hidden name=action value=continue>
<input type=hidden name=nextsub value=yes_delete_language>
<button name="action" class="submit" type="submit" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub yes_delete_language {

    AM->delete_language( \%myconfig, \%$form );

    # delete templates
    $dir = "$myconfig{templates}/$form->{code}";
    if ( -d $dir ) {
        unlink <$dir/*>;
        rmdir "$myconfig{templates}/$form->{code}";
    }
    $form->redirect( $locale->text('Language deleted!') );

}

sub display_stylesheet {

    $form->{file} = "css/$myconfig{stylesheet}";
    &display_form;

}

sub list_templates {

    AM->language( \%myconfig, \%$form );

    if ( !@{ $form->{ALL} } ) {
        &display_form;
        exit;
    }

    unshift @{ $form->{ALL} },
      { code => '.', description => $locale->text('Default Template') };

    my $href =
"$form->{script}?action=list_templates&direction=$form->{direction}&oldsort=$form->{oldsort}&file=$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $form->{callback} =
"$form->{script}?action=list_templates&direction=$form->{direction}&oldsort=$form->{oldsort}&file=$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    my $callback = $form->escape( $form->{callback} );

    chomp $myconfig{templates};
    $form->{file} =~ s/$myconfig{templates}//;
    $form->{file} =~ s/\///;
    $form->{title} = "$form->{format}: $form->{template}";

    my @column_index = $form->sort_columns(qw(code description));

    $column_header{code} = { text => $locale->text('Code'),
        href => "$href&sort=code" };
    $column_header{description} = { text => $locale->text('Description'),
        href => "$href&sort=description" };

    my @rows;
    my $i = 0;
    foreach my $ref ( @{ $form->{ALL} } ) {

        my %column_data;
        $i++;
        $i %= 2;
        $column_data{i} = $i;

        $column_data{code} = { text => $ref->{code}, href =>
            qq|$form->{script}?action=display_form&file=$myconfig{templates}/$ref->{code}/$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&code=$ref->{code}&callback=$callback|};
        $column_data{description} = $ref->{description};

	push @rows, \%column_data;
    
    }

    $form->{type} = 'language';
    my @hiddens = qw(sessionid login path calllback type);

## SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    # SC: I'm not concerned about the wider description as code is 6 chars max
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'am-list-departments');
    $template->render({
        form => $form,
        columns => \@column_index,
        heading => \%column_header,
        rows => \@rows,
        hiddens => \@hiddens,
    });
}

sub display_form {

    AM->load_template( \%myconfig, \%$form );

    $form->{title} = $form->{file};

    $form->{body} =~
s/<%include (.*?)%>/<a href=$form->{script}\?action=display_form&file=$myconfig{templates}\/$form->{code}\/$1&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}>$1<\/a>/g;

    # if it is anything but html
    if ( $form->{file} !~ /\.html$/ ) {
        $form->{body} = "<pre>\n$form->{body}\n</pre>";
    }

    $form->header;

    print qq|
<body>

$form->{body}

<form method=post action=$form->{script}>
|;

    $form->{type} = "template";

    $form->hide_form(qw(file type path login sessionid));

    print qq|
<button name="action" type="submit" class="submit" value="edit">|
      . $locale->text('Edit')
      . qq|</button>|;

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

sub edit_template {

    AM->load_template( \%myconfig, \%$form );

    $form->{title} = $locale->text('Edit Template');

    # convert &nbsp to &amp;nbsp;
    $form->{body} =~ s/&nbsp;/&amp;nbsp;/gi;

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input name=file type=hidden value=$form->{file}>
<input name=type type=hidden value=template>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input name=callback type=hidden value="$form->{script}?action=display_form&file=$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}">

<textarea name=body rows=25 cols=70>
$form->{body}
</textarea>

<br>
<button type="submit" class="submit" name="action" value="save">|
      . $locale->text('Save')
      . qq|</button>|;

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print q|
  </form>


</body>
</html>
|;

}

sub save_template {

    AM->save_template( \%myconfig, \%$form );
    $form->redirect( $locale->text('Template saved!') );

}

sub defaults {

    # get defaults for account numbers and last numbers
    AM->get_all_defaults( \%$form );

    my %selects = (
        'FX_loss' => {name => 'FX_loss', options => []},
        'FX_gain' => {name => 'FX_gain', options => []},
        'IC_expense' => {name => 'IC_expense', options => []},
        'IC_income' => {name => 'IC_income', options => []},
        'IC_inventory' => {name => 'IC_inventory', options => []},
        'IC' => {name => 'IC', options => []},
        );
    foreach $key ( keys %{ $form->{accno} } ) {
        foreach $accno ( sort keys %{ $form->{accno}{$key} } ) {
            push @{$selects{$key}{options}}, {
                text => "$accno--$form->{accno}{$key}{$accno}{description}",
                value => "$accno--$form->{accno}{$key}{$accno}{description}",
                };
            $selects{$key}{default_values} = "$accno--$form->{accno}{$key}{$accno}{description}" if
                ($form->{defaults}{$key} == $form->{accno}{$key}{$accno}{id});
        }
    }

    for (qw(accno defaults)) { delete $form->{$_} }

##SC: temporary commenting out
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my %hiddens = (
        path => $form->{path},
        login => $form->{login},
        sessionid => $form->{sessionid},
        type => 'defaults',
        );
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'am-defaults');
    $template->render({
        form => $form,
	hiddens => \%hiddens,
	selects => \%selects,
    });
}

sub taxes {

    # get tax account numbers
    AM->taxes( \%myconfig, \%$form );

    $i = 0;
    foreach $ref ( @{ $form->{taxrates} } ) {
        $i++;
        $form->{"taxrate_$i"} =
          $form->format_amount( \%myconfig, $ref->{rate} );
        $form->{"taxdescription_$i"} = $ref->{description};

        for (qw(taxnumber validto pass taxmodulename)) {
            $form->{"${_}_$i"} = $ref->{$_};
        }
        $form->{taxaccounts} .= "$ref->{id}_$i ";
    }
    chop $form->{taxaccounts};

    &display_taxes;

}

sub display_taxes {

    $form->{title} = $locale->text('Taxes');
    my %hiddens = (
        path => $form->{path},
        login => $form->{login},
        sessionid => $form->{sessionid},
        type => 'taxes',
        );

    my @rows;
    for ( split( / /, $form->{taxaccounts} ) ) {

        ( $null, $i ) = split /_/, $_;

        $form->{"taxrate_$i"} =
          $form->format_amount( \%myconfig, $form->{"taxrate_$i"} );

        $hiddens{"taxdescription_$i"} = $form->{"taxdescription_$i"};

        my %select = (name => "taxmodule_id_$i", options => []);
        foreach my $taxmodule ( sort keys %$form ) {
            next if ( $taxmodule !~ /^taxmodule_/ );
            next if ( $taxmodule =~ /^taxmodule_id_/ );
            my $modulenum = $taxmodule;
            $modulenum =~ s/^taxmodule_//;
            push @{$select{options}},
                {text => $form->{$taxmodule}, value => $modulenum};
            $select{default_values} = $modulenum
              if $form->{$taxmodule} eq $form->{"taxmodulename_$i"};
        }
        if ( $form->{"taxdescription_$i"} eq $sametax ) {
            push @rows, ["", \%select];
        } else {
            push @rows, [$form->{"taxdescription_$i"}, \%select];
        }

	$sametax = $form->{"taxdescription_$i"};

    }

    $hiddens{taxaccounts} = $form->{taxaccounts};
    foreach my $taxmodule ( sort keys %$form ) {
        next if ( $taxmodule !~ /^taxmodule_/ );
        next if ( $taxmodule =~ /^taxmodule_id_/ );
        $hiddens{$taxmodule};
    }

##SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'am-taxes');
    $template->render({
        form => $form,
	hiddens => \%hiddens,
	selects => \%selects,
	rows => \@rows,
    });
}

sub update {

    @a = split / /, $form->{taxaccounts};
    $ndx = $#a + 1;

    foreach $item (@a) {
        ( $accno, $i ) = split /_/, $item;
        push @t, $accno;
        $form->{"taxmodulename_$i"} =
          $form->{ "taxmodule_" . $form->{"taxmodule_id_$i"} };

        if ( $form->{"validto_$i"} ) {
            $j = $i + 1;
            if ( $form->{"taxdescription_$i"} ne $form->{"taxdescription_$j"} )
            {

                #insert line
                for ( $j = $ndx + 1 ; $j > $i ; $j-- ) {
                    $k = $j - 1;
                    for (qw(taxrate taxdescription taxnumber validto)) {
                        $form->{"${_}_$j"} = $form->{"${_}_$k"};
                    }
                }
                $ndx++;
                $k = $i + 1;
                for (qw(taxdescription taxnumber)) {
                    $form->{"${_}_$k"} = $form->{"${_}_$i"};
                }
                for (qw(taxrate validto)) { $form->{"${_}_$k"} = "" }
                push @t, $accno;
            }
        }
        else {

            # remove line
            $j = $i + 1;
            if ( $form->{"taxdescription_$i"} eq $form->{"taxdescription_$j"} )
            {
                for ( $j = $i + 1 ; $j <= $ndx ; $j++ ) {
                    $k = $j + 1;
                    for (qw(taxrate taxdescription taxnumber validto)) {
                        $form->{"${_}_$j"} = $form->{"${_}_$k"};
                    }
                }
                $ndx--;
                splice @t, $i - 1, 1;
            }
        }

    }

    $i = 1;
    $form->{taxaccounts} = "";
    for (@t) {
        $form->{taxaccounts} .= "${_}_$i ";
        $i++;
    }
    chop $form->{taxaccounts};

    &display_taxes;

}

sub config {

    my %selects;
    $selects{dateformat} = {
        name => 'dateformat',
        default_values => $myconfig{dateformat},
        options => [],
        };
    foreach $item (qw(mm-dd-yy mm/dd/yy dd-mm-yy dd/mm/yy dd.mm.yy yyyy-mm-dd))
    {
        push @{$selects{dateformat}{options}}, {text => $item, value => $item};
    }

    $selects{numberformat} = {
        name => 'numberformat',
        default_values => $myconfig{numberformat},
        options => [],
        };
    my @formats = qw(1,000.00 1000.00 1.000,00 1000,00 1'000.00);
    push @formats, '1 000.00';
    foreach $item (@formats) {
        push @{$selects{numberformat}{options}}, {text => $item, value => $item};
    }

##    for (qw(name company address signature)) {
##        $myconfig{$_} = $form->quote( $myconfig{$_} );
##    }
    for (qw(address signature)) { $myconfig{$_} =~ s/\\n/\n/g }

    $selects{countrycode} = {
        name => 'countrycode',
        default_values => ($myconfig{countrycode})? $myconfig{countrycode}: 'en',
        options => [],
        };
    %countrycodes = LedgerSMB::User->country_codes;
    foreach $key ( sort { $countrycodes{$a} cmp $countrycodes{$b} }
        keys %countrycodes )
    {
        push @{$selects{countrycode}{options}}, {
            text => $countrycodes{$key},
            value => $key
            };
    }

    opendir CSS, "css/.";
    @all = grep /.*\.css$/, readdir CSS;
    closedir CSS;

    $selects{stylesheet} = {
        name => 'usestylesheet',
	default_values => $myconfig{stylesheet},
        options => [],
        };
    foreach $item (@all) {
        push @{$selects{stylesheet}{options}}, {text => $item, value => $item};
    }
    push @{$selects{stylesheet}{options}}, {text => 'none', value => '0'};

    if ( %{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex} ) {
        $selects{printer} = {
            name => 'printer',
            default_values => $myconfig{printer},
            options => [],
            };
        foreach $item ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
            push @{$selects{printer}{options}}, {text => $item, value => $item};
        }
    }

    $form->{title} =
      $locale->text( 'Edit Preferences for [_1]', $form->{login} );

##SC: Temporary commenting out
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my %hiddens = (
        path => $form->{path},
        login => $form->{login},
        sessionid => $form->{sessionid},
        type => 'preferences',
        role => $myconfig{role},
        old_password => $myconfig{password},
        );
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'am-userconfig');
    $template->render({
        form => $form,
        user => \%myconfig,
	hiddens => \%hiddens,
	selects => \%selects,
    });
}

sub save_defaults {

    if ( AM->save_defaults( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Defaults saved!') );
    }
    else {
        $form->error( $locale->text('Cannot save defaults!') );
    }

}

sub save_taxes {

    if ( AM->save_taxes( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Taxes saved!') );
    }
    else {
        $form->error( $locale->text('Cannot save taxes!') );
    }

}

sub save_preferences {

    $form->{stylesheet} = $form->{usestylesheet};

    if ( $form->{new_password} ne $form->{old_password} ) {
        $form->error( $locale->text('Password does not match!') )
          if $form->{new_password} ne $form->{confirm_password};
    }

    if ( AM->save_preferences( \%myconfig, \%$form ) ) {
        $form->info( $locale->text('Preferences saved!') );
    }
    else {
        $form->error( $locale->text('Cannot save preferences!') );
    }

}

sub backup {

    if ( $form->{media} eq 'email' ) {
        $form->error(
            $locale->text( 'No email address for [_1]', $myconfig{name} ) )
          unless ( $myconfig{email} );
    }

    $SIG{INT} = 'IGNORE';
    AM->backup(
        \%myconfig, \%$form,
        ${LedgerSMB::Sysconfig::userspath},
        ${LedgerSMB::Sysconfig::gzip}
    );

    if ( $form->{media} eq 'email' ) {
        $form->redirect(
            $locale->text( 'Backup sent to [_1]', $myconfig{email} ) );
    }

}

sub audit_control {

    $form->{title} = $locale->text('Audit Control');

    AM->closedto( \%myconfig, \%$form );

    if ( $form->{revtrans} ) {
        $checked{revtransY} = "checked";
    }
    else {
        $checked{revtransN} = "checked";
    }

    if ( $form->{audittrail} ) {
        $checked{audittrailY} = "checked";
    }
    else {
        $checked{audittrailN} = "checked";
    }

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">|
      . $locale->text('Enforce transaction reversal for all dates')
      . qq|</th>
	  <td><input name=revtrans class=radio type=radio value="1" $checked{revtransY}> |
      . $locale->text('Yes')
      . qq| <input name=revtrans class=radio type=radio value="0" $checked{revtransN}> |
      . $locale->text('No')
      . qq|</td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Close Books up to') . qq|</th>
	  <td><input class="date" name=closedto size=11 title="$myconfig{dateformat}" value=$form->{closedto}></td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Activate Audit trail') . qq|</th>
	  <td><input name=audittrail class=radio type=radio value="1" $checked{audittrailY}> |
      . $locale->text('Yes')
      . qq| <input name=audittrail class=radio type=radio value="0" $checked{audittrailN}> |
      . $locale->text('No')
      . qq|</td>
	</tr><!-- SC: Disabling audit trail deletion
	<tr>
	  <th align="right">| . $locale->text('Remove Audit trail up to') . qq|</th>
	  <td><input class="date" name=removeaudittrail size=11 title="$myconfig{dateformat}"></td>
	</tr> -->
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input type=hidden name=nextsub value=doclose>
<input type=hidden name=action value=continue>
<button type="submit" class="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>

</form>

</body>
</html>
|;

}

sub doclose {

    AM->closebooks( \%myconfig, \%$form );

    if ( $form->{revtrans} ) {
        $msg = $locale->text('Transaction reversal enforced for all dates');
    }
    else {

        if ( $form->{closedto} ) {
            $msg =
                $locale->text('Transaction reversal enforced up to') . " "
              . $locale->date( \%myconfig, $form->{closedto}, 1 );
        }
        else {
            $msg = $locale->text('Books are open');
        }
    }

    $msg .= "<p>";
    if ( $form->{audittrail} ) {
        $msg .= $locale->text('Audit trail enabled');
    }
    else {
        $msg .= $locale->text('Audit trail disabled');
    }

##SC: Disabling audit trail deletion
##    $msg .= "<p>";
##    if ( $form->{removeaudittrail} ) {
##        $msg .=
##            $locale->text('Audit trail removed up to') . " "
##          . $locale->date( \%myconfig, $form->{removeaudittrail}, 1 );
##    }

    $form->redirect($msg);

}

sub add_warehouse {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add_warehouse&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &warehouse_header;
    &form_footer;

}

sub edit_warehouse {

    $form->{title} = "Edit";

    AM->get_warehouse( \%myconfig, \%$form );

    &warehouse_header;
    &form_footer;

}

sub list_warehouse {

    AM->warehouses( \%myconfig, \%$form );

    $href =
"$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $form->{callback} =
"$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $callback = $form->escape( $form->{callback} );

    $form->{title} = $locale->text('Warehouses');

    @column_index = qw(description);

    $column_header{description} =
        qq|<th width=100%><a class="listheading" href=$href>|
      . $locale->text('Description')
      . qq|</a></th>|;

    $form->header;

    print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
        </tr>
|;

    foreach $ref ( @{ $form->{ALL} } ) {

        $i++;
        $i %= 2;

        print qq|
        <tr valign=top class=listrow$i>
|;

        $column_data{description} =
qq|<td><a href=$form->{script}?action=edit_warehouse&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}</td>|;

        for (@column_index) { print "$column_data{$_}\n" }

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
<form method=post action=$form->{script}>
|;

    $form->{type} = "warehouse";

    $form->hide_form(qw(type callback path login sessionid));

    print qq|
<button class="submit" type="submit" name="action" value="add_warehouse">|
      . $locale->text('Add Warehouse')
      . qq|</button>|;

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

sub warehouse_header {

    $form->{title} = $locale->text("$form->{title} Warehouse");

    # $locale->text('Add Warehouse')
    # $locale->text('Edit Warehouse')

    $form->{description} = $form->quote( $form->{description} );

    if ( ( $rows = $form->numtextrows( $form->{description}, 60 ) ) > 1 ) {
        $description =
qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input name=description size=60 value="$form->{description}">|;
    }

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=warehouse>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">| . $locale->text('Description') . qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub save_warehouse {

    $form->isblank( "description", $locale->text('Description missing!') );
    AM->save_warehouse( \%myconfig, \%$form );
    $form->redirect( $locale->text('Warehouse saved!') );

}

sub delete_warehouse {

    AM->delete_warehouse( \%myconfig, \%$form );
    $form->redirect( $locale->text('Warehouse deleted!') );

}

sub yearend {

    AM->earningsaccounts( \%myconfig, \%$form );
    $chart = "";
    for ( @{ $form->{chart} } ) {
        $chart .= "<option>$_->{accno}--$_->{description}";
    }

    $form->{title} = $locale->text('Yearend');
    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=decimalplaces value=2>
<input type=hidden name=l_accno value=Y>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">| . $locale->text('Yearend') . qq|</th>
	  <td><input class="date" name=todate size=11 title="$myconfig{dateformat}" value=$todate></td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Reference') . qq|</th>
	  <td><input name=reference size=20 value="|
      . $locale->text('Yearend')
      . qq|"></td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Description') . qq|</th>
	  <td><textarea name=description rows=3 cols=50 wrap=soft></textarea></td>
	</tr>
	<tr>
	  <th align="right">| . $locale->text('Retained Earnings') . qq|</th>
	  <td><select name=accno>$chart</select></td>
	</tr>
	<tr>
          <th align="right">| . $locale->text('Method') . qq|</th>
          <td><input name=method class=radio type=radio value=accrual checked>&nbsp;|
      . $locale->text('Accrual')
      . qq|&nbsp;<input name=method class=radio type=radio value=cash>&nbsp;|
      . $locale->text('Cash')
      . qq|</td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<input type=hidden name=nextsub value=generate_yearend>
|;

    $form->hide_form(qw(path login sessionid));

    print qq|
<button class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>|;

}

sub generate_yearend {

    $form->isblank( "todate", $locale->text('Yearend date missing!') );

    RP->yearend_statement( \%myconfig, \%$form );

    $form->{transdate} = $form->{todate};

    $earnings = 0;

    $form->{rowcount} = 1;
    foreach $key ( keys %{ $form->{I} } ) {
        if ( $form->{I}{$key}{charttype} eq "A" ) {
            $form->{"debit_$form->{rowcount}"} = $form->{I}{$key}{this};
            $earnings += $form->{I}{$key}{this};
            $form->{"accno_$form->{rowcount}"} = $key;
            $form->{rowcount}++;
            $ok = 1;
        }
    }

    foreach $key ( keys %{ $form->{E} } ) {
        if ( $form->{E}{$key}{charttype} eq "A" ) {
            $form->{"credit_$form->{rowcount}"} = $form->{E}{$key}{this} * -1;
            $earnings += $form->{E}{$key}{this};
            $form->{"accno_$form->{rowcount}"} = $key;
            $form->{rowcount}++;
            $ok = 1;
        }
    }
    if ( $earnings > 0 ) {
        $form->{"credit_$form->{rowcount}"} = $earnings;
        $form->{"accno_$form->{rowcount}"}  = $form->{accno};
    }
    else {
        $form->{"debit_$form->{rowcount}"} = $earnings * -1;
        $form->{"accno_$form->{rowcount}"} = $form->{accno};
    }

    if ($ok) {
        if ( AM->post_yearend( \%myconfig, \%$form ) ) {
            $form->redirect( $locale->text('Yearend posted!') );
        }
        else {
            $form->error( $locale->text('Yearend posting failed!') );
        }
    }
    else {
        $form->error('Nothing to do!');
    }

}

sub company_logo {

    $myconfig{address} =~ s/\\n/<br>/g;
    $myconfig{dbhost} = $locale->text('localhost') unless $myconfig{dbhost};

    $form->{stylesheet} = $myconfig{stylesheet};

    $form->{title} = $locale->text('About');

    # create the logo screen
    $form->header;

    print qq|
<body>

<pre>

</pre>
<center>
<a href="http://www.ledgersmb.org/" target="_blank"><img src="images/ledgersmb.png" width="200" height="100" border="0" alt="LedgerSMB Logo" /></a>
<h1 class="login">| . $locale->text('Version') . qq| $form->{version}</h1>

<p>
|.$locale->text('Company').qq| :
<p>
<b>
$myconfig{company}
<br>$myconfig{address}
</b>

<p>
<table border=0>
  <tr>
    <th align="right">| . $locale->text('User') . qq|</th>
    <td>$myconfig{name}</td>
  </tr>
  <tr>
    <th align="right">| . $locale->text('Dataset') . qq|</th>
    <td>$myconfig{dbname}</td>
  </tr>
  <tr>
    <th align="right">| . $locale->text('Database Host') . qq|</th>
    <td>$myconfig{dbhost}</td>
  </tr>
</table>

</center>

</body>
</html>
|;

}

sub recurring_transactions {

    # $locale->text('Day')
    # $locale->text('Days')
    # $locale->text('Month')
    # $locale->text('Months')
    # $locale->text('Week')
    # $locale->text('Weeks')
    # $locale->text('Year')
    # $locale->text('Years')

    $form->{stylesheet} = $myconfig{stylesheet};

    $form->{title} = $locale->text('Recurring Transactions');

    $column_header{id} = "";

    AM->recurring_transactions( \%myconfig, \%$form );

    $href = "$form->{script}?action=recurring_transactions";
    for (qw(direction oldsort path login sessionid)) {
        $href .= qq|&$_=$form->{$_}|;
    }

    $form->sort_order();

    # create the logo screen
    $form->header;

    @column_index = qw(ndx reference description);

    push @column_index,
      qw(nextdate enddate id amount curr repeat howmany recurringemail recurringprint);

    $column_header{reference} =
        qq|<th><a class="listheading" href="$href&sort=reference">|
      . $locale->text('Reference')
      . q|</a></th>|;
    $column_header{ndx} = q|<th class="listheading">&nbsp;</th>|;
    $column_header{id} =
      q|<th class="listheading">| . $locale->text('ID') . q|</th>|;
    $column_header{description} =
      q|<th class="listheading">| . $locale->text('Description') . q|</th>|;
    $column_header{nextdate} =
        qq|<th><a class="listheading" href="$href&sort=nextdate">|
      . $locale->text('Next')
      . q|</a></th>|;
    $column_header{enddate} =
        qq|<th><a class="listheading" href="$href&sort=enddate">|
      . $locale->text('Ends')
      . q|</a></th>|;
    $column_header{amount} =
      q|<th class="listheading">| . $locale->text('Amount') . q|</th>|;
    $column_header{curr} = q|<th class="listheading">&nbsp;</th>|;
    $column_header{repeat} =
      q|<th class="listheading">| . $locale->text('Every') . q|</th>|;
    $column_header{howmany} =
      q|<th class="listheading">| . $locale->text('Times') . q|</th>|;
    $column_header{recurringemail} =
      q|<th class="listheading">| . $locale->text('E-mail') . q|</th>|;
    $column_header{recurringprint} =
      q|<th class="listheading">| . $locale->text('Print') . q|</th>|;

    print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

    for (@column_index) { print "\n$column_header{$_}" }

    print qq|
        </tr>
|;

    $i       = 1;
    $colspan = $#column_index + 1;

    %tr = (
        ar => $locale->text('AR'),
        ap => $locale->text('AP'),
        gl => $locale->text('GL'),
        so => $locale->text('Sales Orders'),
        po => $locale->text('Purchase Orders'),
    );

    %f = &formnames;

    foreach $transaction ( sort keys %{ $form->{transactions} } ) {
    	my $transaction_count = scalar( @{ $form->{transactions}{$transaction} } );
        print qq|
        <tr>
	  <th class="listheading" colspan=$colspan>$tr{$transaction} ($transaction_count)</th>
	</tr>
|;

        foreach $ref ( @{ $form->{transactions}{$transaction} } ) {

            for (@column_index) {
                $column_data{$_} = "<td nowrap>$ref->{$_}</td>";
            }

            if ( $ref->{repeat} > 1 ) {
                $unit   = $locale->text( ucfirst $ref->{unit} );
                $repeat = "$ref->{repeat} $unit";
            }
            else {
                chop $ref->{unit};
                $unit   = $locale->text( ucfirst $ref->{unit} );
                $repeat = $unit;
            }

            $column_data{ndx} = qq|<td></td>|;

            if ( !$ref->{expired} ) {
                if ( $ref->{overdue} <= 0 ) {
                    $k++;
                    $column_data{ndx} =
qq|<td nowrap><input name="ndx_$k" class=checkbox type=checkbox value=$ref->{id} checked></td>|;
                }
            }

            $reference =
              ( $ref->{reference} )
              ? $ref->{reference}
              : $locale->text('Next Number');
            $column_data{reference} =
qq|<td nowrap><a href=$form->{script}?action=edit_recurring&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&module=$ref->{module}&invoice=$ref->{invoice}&transaction=$ref->{transaction}&recurringnextdate=$ref->{nextdate}>$reference</a></td>|;

            $module = "$ref->{module}.pl";
            $type   = "";
            if ( $ref->{module} eq 'ar' ) {
                $module = "is.pl" if $ref->{invoice};
                $ref->{amount} /= $ref->{exchangerate};
            }
            if ( $ref->{module} eq 'ap' ) {
                $module = "ir.pl" if $ref->{invoice};
                $ref->{amount} /= $ref->{exchangerate};
            }
            if ( $ref->{module} eq 'oe' ) {
                $type =
                  ( $ref->{vc} eq 'customer' )
                  ? "sales_order"
                  : "purchase_order";
            }

            $column_data{id} =
qq|<td><a href="$module?action=edit&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$type&readonly=1">$ref->{id}</a></td>|;

            $column_data{repeat} = qq|<td align="right" nowrap>$repeat</td>|;
            $column_data{howmany} =
              qq|<td align="right" nowrap>|
              . $form->format_amount( \%myconfig, $ref->{howmany} ) . "</td>";
            $column_data{amount} =
              qq|<td align="right" nowrap>|
              . $form->format_amount( \%myconfig, $ref->{amount}, 2 ) . "</td>";

            $column_data{recurringemail} = "<td nowrap>";
            @f = split /:/, $ref->{recurringemail};
            for ( 0 .. $#f ) {
                $column_data{recurringemail} .= "$f{$f[$_]}<br>";
            }
            $column_data{recurringemail} .= "</td>";

            $column_data{recurringprint} = "<td nowrap>";
            @f = split /:/, $ref->{recurringprint};
            for ( 0 .. $#f ) {
                $column_data{recurringprint} .= "$f{$f[$_]}<br>";
            }
            $column_data{recurringprint} .= "</td>";

            $j++;
            $j %= 2;
            print qq|
      <tr class=listrow$j>
|;

            for (@column_index) { print "\n$column_data{$_}" }

            print qq|
      </tr>
|;
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

<input name=lastndx type=hidden value=$k>
|;

    $form->hide_form(qw(path login sessionid));

    print qq|
<button class="submit" type="submit" name="action" value="process_transactions">|
      . $locale->text('Process Transactions')
      . qq|</button>|
      if $k;

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

sub edit_recurring {

    %links = (
        ar => 'create_links',
        ap => 'create_links',
        gl => 'create_links',
        is => 'invoice_links',
        ir => 'invoice_links',
        oe => 'order_links',
    );
    %prepare = (
        is => 'prepare_invoice',
        ir => 'prepare_invoice',
        oe => 'prepare_order',
    );

    $form->{callback} =
"$form->{script}?action=recurring_transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->{type} = "transaction";

    if ( $form->{module} eq 'ar' ) {
        if ( $form->{invoice} ) {
            $form->{type}   = "invoice";
            $form->{module} = "is";
        }
    }
    if ( $form->{module} eq 'ap' ) {
        if ( $form->{invoice} ) {
            $form->{type}   = "invoice";
            $form->{module} = "ir";
        }
    }

    if ( $form->{module} eq 'oe' ) {
        %tr = (
            so => sales_order,
            po => purchase_order,
        );

        $form->{type} = $tr{ $form->{transaction} };
    }

    $form->{script} = "$form->{module}.pl";
    do "bin/$form->{script}";

    &{ $links{ $form->{module} } };

    # return if transaction doesn't exist
    $form->redirect unless $form->{recurring};

    if ( $prepare{ $form->{module} } ) {
        &{ $prepare{ $form->{module} } };
    }

    $form->{selectformat} = qq|<option value="html">html\n|;
    if ( ${LedgerSMB::Sysconfig::latex} ) {
        $form->{selectformat} .= qq|
            <option value="postscript">| . $locale->text('Postscript') . qq|
	    <option value="pdf">| . $locale->text('PDF');
    }

    &schedule;

}

sub process_transactions {

    # save variables
    my $pt = new Form;
    for ( keys %$form ) { $pt->{$_} = $form->{$_} }

    my $defaultprinter;
    while ( my ( $key, $value ) = each %{LedgerSMB::Sysconfig::printer} ) {
        if ( $value =~ /lpr/ ) {
            $defaultprinter = $key;
            last;
        }
    }

    $myconfig{vclimit} = 0;
    %f = &formnames;

    for ( my $i = 1 ; $i <= $pt->{lastndx} ; $i++ ) {
        if ( $pt->{"ndx_$i"} ) {
            $id = $pt->{"ndx_$i"};

            # process transaction
            AM->recurring_details( \%myconfig, \%$pt, $id );

            $header = $form->{header};

            # reset $form
            for ( keys %$form ) { delete $form->{$_}; }
            for (qw(login path sessionid stylesheet timeout)) {
                $form->{$_} = $pt->{$_};
            }
            $form->{id}     = $id;
            $form->{header} = $header;
            $form->db_init(\%myconfig);

            # post, print, email
            if ( $pt->{arid} || $pt->{apid} || $pt->{oeid} ) {
                if ( $pt->{arid} || $pt->{apid} ) {
                    if ( $pt->{arid} ) {
                        $form->{script} =
                          ( $pt->{invoice} ) ? "is.pl" : "ar.pl";
                        $form->{ARAP}   = "AR";
                        $form->{module} = "ar";
                        $invfld         = "sinumber";
                    }
                    else {
                        $form->{script} =
                          ( $pt->{invoice} ) ? "ir.pl" : "ap.pl";
                        $form->{ARAP}   = "AP";
                        $form->{module} = "ap";
                        $invfld         = "vinumber";
                    }
                    do "bin/$form->{script}";

                    if ( $pt->{invoice} ) {
                        &invoice_links;
                        &prepare_invoice;

                        for ( keys %$form ) {
                            $form->{$_} = $form->unquote( $form->{$_} );
                        }

                    }
                    else {
                        &create_links;

                        $form->{type} = "transaction";
                        for ( 1 .. $form->{rowcount} - 1 ) {
                            $form->{"amount_$_"} =
                              $form->format_amount( \%myconfig,
                                $form->{"amount_$_"}, 2 );
                        }
                        for ( 1 .. $form->{paidaccounts} ) {
                            $form->{"paid_$_"} =
                              $form->format_amount( \%myconfig,
                                $form->{"paid_$_"}, 2 );
                        }

                    }

                    delete $form->{"$form->{ARAP}_links"};
                    for (qw(acc_trans invoice_details)) { delete $form->{$_} }
                    for (
                        qw(department employee language month partsgroup project years)
                      )
                    {
                        delete $form->{"all_$_"};
                    }

                    $form->{invnumber} = $pt->{reference};
                    $form->{transdate} = $pt->{nextdate};

                    # tax accounts
                    $form->all_taxaccounts( \%myconfig, undef,
                        $form->{transdate} );

                    # calculate duedate
                    $form->{duedate} =
                      $form->add_date( \%myconfig, $form->{transdate},
                        $pt->{overdue}, "days" );

                    if ( $pt->{payment} ) {

                        # calculate date paid
                        for ( $j = 1 ; $j <= $form->{paidaccounts} ; $j++ ) {
                            $form->{"datepaid_$j"} =
                              $form->add_date( \%myconfig, $form->{transdate},
                                $pt->{paid}, "days" );

                            ( $form->{"$form->{ARAP}_paid_$j"} ) = split /--/,
                              $form->{"$form->{ARAP}_paid_$j"};
                            delete $form->{"cleared_$j"};
                        }

                        $form->{paidaccounts}++;
                    }
                    else {
                        $form->{paidaccounts} = -1;
                    }

                    for (qw(id recurring intnotes printed emailed queued)) {
                        delete $form->{$_};
                    }

                    ( $form->{ $form->{ARAP} } ) = split /--/,
                      $form->{ $form->{ARAP} };

                    $form->{invnumber} =
                      $form->update_defaults( \%myconfig, "$invfld" )
                      unless $form->{invnumber};
                    $form->{reference} = $form->{invnumber};
                    for (qw(invnumber reference)) {
                        $form->{$_} = $form->unquote( $form->{$_} );
                    }

                    if ( $pt->{invoice} ) {
                        if ( $pt->{arid} ) {
                            $form->info(
                                "\n"
                                  . $locale->text(
                                    'Posting Sales Invoice [_1]',
                                    $form->{invnumber}
                                  )
                            );
                            $ok = IS->post_invoice( \%myconfig, \%$form );
                        }
                        else {
                            $form->info(
                                "\n"
                                  . $locale->text(
                                    'Posting Vendor Invoice [_1]',
                                    $form->{invnumber}
                                  )
                            );
                            $ok = IR->post_invoice( \%myconfig, \%$form );
                        }
                    }
                    else {
                        if ( $pt->{arid} ) {
                            $form->info(
                                "\n"
                                  . $locale->text(
                                    'Posting Transaction [_1]',
                                    $form->{invnumber}
                                  )
                            );
                        }
                        else {
                            $form->info(
                                "\n"
                                  . $locale->text(
                                    'Posting Transaction [_1]',
                                    $form->{invnumber}
                                  )
                            );
                        }

                        $ok = AA->post_transaction( \%myconfig, \%$form );

                    }
                    $form->info( " ..... " . $locale->text('done') );

                    # print form
                    if ( ${LedgerSMB::Sysconfig::latex} && $ok ) {
                        $ok = &print_recurring( \%$pt, $defaultprinter );
                    }

                    &email_recurring( \%$pt ) if $ok;

                }
                else {

                    # order
                    $form->{script} = "oe.pl";
                    $form->{module} = "oe";

                    $ordnumber = "ordnumber";
                    if ( $pt->{customer_id} ) {
                        $form->{vc}   = "customer";
                        $form->{type} = "sales_order";
                        $ordfld       = "sonumber";
                        $flabel       = $locale->text('Sales Order');
                    }
                    else {
                        $form->{vc}   = "vendor";
                        $form->{type} = "purchase_order";
                        $ordfld       = "ponumber";
                        $flabel       = $locale->text('Purchase Order');
                    }
                    require "bin/$form->{script}";

                    &order_links;
                    &prepare_order;

                    for ( keys %$form ) {
                        $form->{$_} = $form->unquote( $form->{$_} );
                    }

                    $form->{$ordnumber} = $pt->{reference};
                    $form->{transdate} = $pt->{nextdate};

                    # calculate reqdate
                    $form->{reqdate} =
                      $form->add_date( \%myconfig, $form->{transdate},
                        $pt->{req}, "days" )
                      if $form->{reqdate};

                    for (qw(id recurring intnotes printed emailed queued)) {
                        delete $form->{$_};
                    }
                    for ( 1 .. $form->{rowcount} ) {
                        delete $form->{"orderitems_id_$_"};
                    }

                    $form->{$ordnumber} =
                      $form->update_defaults( \%myconfig, "$ordfld" )
                      unless $form->{$ordnumber};
                    $form->{reference} = $form->{$ordnumber};
                    for ( "$ordnumber", "reference" ) {
                        $form->{$_} = $form->unquote( $form->{$_} );
                    }
                    $form->{closed} = 0;

                    $form->info(
                        "\n"
                          . $locale->text(
                            'Saving [_1] [_2]',
                            $flabel, $form->{$ordnumber}
                          )
                    );
                    if ( $ok = OE->save( \%myconfig, \%$form ) ) {
                        $form->info( " ..... " . $locale->text('done') );
                    }
                    else {
                        $form->info( " ..... " . $locale->text('failed') );
                    }

                    # print form
                    if ( ${LedgerSMB::Sysconfig::latex} && $ok ) {
                        &print_recurring( \%$pt, $defaultprinter );
                    }

                    &email_recurring( \%$pt );

                }

            }
            else {

                # GL transaction
                GL->transaction( \%myconfig, \%$form );

                $form->{reference} = $pt->{reference};
                $form->{transdate} = $pt->{nextdate};

                $j = 1;
                foreach $ref ( @{ $form->{GL} } ) {
                    $form->{"accno_$j"} = "$ref->{accno}--$ref->{description}";

                    $form->{"projectnumber_$j"} =
                      "$ref->{projectnumber}--$ref->{project_id}"
                      if $ref->{project_id};
                    $form->{"fx_transaction_$j"} = $ref->{fx_transaction};

                    if ( $ref->{amount} < 0 ) {
                        $form->{"debit_$j"} = $ref->{amount} * -1;
                    }
                    else {
                        $form->{"credit_$j"} = $ref->{amount};
                    }

                    $j++;
                }

                $form->{rowcount} = $j;

                for (qw(id recurring)) { delete $form->{$_} }
                $form->info(
                    "\n"
                      . $locale->text(
                        'Posting GL Transaction [_1]',
                        $form->{reference}
                      )
                );
                $ok = GL->post_transaction( \%myconfig, \%$form );
                $form->info( " ..... " . $locale->text('done') );

            }

            AM->update_recurring( \%myconfig, \%$pt, $id ) if $ok;

        }
    }

    $form->{callback} =
"am.pl?action=recurring_transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&header=$form->{header}";
    $form->redirect;

}

sub print_recurring {
    my ( $pt, $defaultprinter ) = @_;
    use List::Util qw(first);

    my %f  = &formnames;
    my $ok = 1;

    if ( $pt->{recurringprint} ) {
        @f = split /:/, $pt->{recurringprint};
        for ( $j = 0 ; $j <= $#f ; $j += 3 ) {
            $media = $f[ $j + 2 ];
            $media ||= $myconfig->{printer}
              if ${LedgerSMB::Sysconfig::printer}{ $myconfig->{printer} };
            $media ||= $defaultprinter;

            $form->info( "\n"
                  . $locale->text('Printing') . " "
                  . $locale->text( $f{ $f[$j] } )
                  . " $form->{reference}" );

            @a = (
                "perl", "$form->{script}",
"action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=$media&vc=$form->{vc}&ARAP=$form->{ARAP}"
            );

            $form->error( $locale->text('Invalid redirect') )
              unless first { $_ eq $form->{script} }
            @{LedgerSMB::Sysconfig::scripts};
            $ok = !( system(@a) );

            if ($ok) {
                $form->info( " ..... " . $locale->text('done') );
            }
            else {
                $form->info( " ..... " . $locale->text('failed') );
                last;
            }
        }
    }

    $ok;

}

sub email_recurring {
    my ($pt) = @_;
    use List::Util qw(first);

    my %f  = &formnames;
    my $ok = 1;

    if ( $pt->{recurringemail} ) {

        @f = split /:/, $pt->{recurringemail};
        for ( $j = 0 ; $j <= $#f ; $j += 2 ) {

            $form->info( "\n"
                  . $locale->text('Sending') . " "
                  . $locale->text( $f{ $f[$j] } )
                  . " $form->{reference}" );

            # no email, bail out
            if ( !$form->{email} ) {
                $form->info(
                    " ..... " . $locale->text('E-mail address missing!') );
                last;
            }

            $message = $form->escape( $pt->{message}, 1 );

            @a = (
                "perl", "$form->{script}",
"action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=email&vc=$form->{vc}&ARAP=$form->{ARAP}&message=$message"
            );

            $form->error( $locale->text('Invalid redirect') )
              unless first { $_ eq $form->{script} }
            @{LedgerSMB::Sysconfig::scripts};
            $ok = !( system(@a) );

            if ($ok) {
                $form->info( " ..... " . $locale->text('done') );
            }
            else {
                $form->info( " ..... " . $locale->text('failed') );
                last;
            }
        }
    }

    $ok;

}

sub formnames {

    # $locale->text('Transaction')
    # $locale->text('Invoice')
    # $locale->text('Credit Invoice')
    # $locale->text('Debit Invoice')
    # $locale->text('Packing List')
    # $locale->text('Pick List')
    # $locale->text('Sales Order')
    # $locale->text('Work Order')
    # $locale->text('Purchase Order')
    # $locale->text('Bin List')

    my %f = (
        transaction    => 'Transaction',
        invoice        => 'Invoice',
        credit_invoice => 'Credit Invoice',
        debit_invoice  => 'Debit Invoice',
        packing_list   => 'Packing List',
        pick_list      => 'Pick List',
        sales_order    => 'Sales Order',
        work_order     => 'Work Order',
        purchase_order => 'Purchase Order',
        bin_list       => 'Bin List',
    );

    %f;

}

sub continue { &{ $form->{nextsub} } }

