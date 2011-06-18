#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# project/job administration
# partsgroup administration
# translation maintainance
#
#======================================================================

use LedgerSMB::PE;
use LedgerSMB::AA;
use LedgerSMB::OE;

1;

# end of main

sub add {

    # construct callback
    $form->{callback} =
"$form->{script}?action=add&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &{"prepare_$form->{type}"};

    $form->{orphaned} = 1;
    &display_form;

}

sub edit {

    &{"prepare_$form->{type}"};
    &display_form;

}

sub prepare_partsgroup {
    PE->get_partsgroup( \%myconfig, \%$form )
      if $form->{id};
}
sub prepare_pricegroup {
    PE->get_pricegroup( \%myconfig, \%$form )
      if $form->{id};
}

sub prepare_job {

    # $locale->text('Add Job')
    # $locale->text('Edit Job')

    $form->{vc} = 'customer';

    PE->get_job( \%myconfig, \%$form );

    $form->{taxaccounts} = "";
    for ( keys %{ $form->{IC_links} } ) {

        $form->{"select$_"} = "";
        foreach $ref ( @{ $form->{IC_links}{$_} } ) {
            if (/IC_tax/) {
                if (/taxpart/) {
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
                $form->{"select$_"} .=
                  "<option>$ref->{accno}--$ref->{description}\n";
            }
        }
    }
    chop $form->{taxaccounts};

    $form->{selectIC_income} = $form->{selectIC_sale};
    $form->{IC_income}       = $form->{IC_sale};

    $form->{IC_income} = qq|$form->{income_accno}--$form->{income_description}|;

    delete $form->{IC_links};

    $form->{"old$form->{vc}"} =
      qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;

    if ( @{ $form->{"all_$form->{vc}"} } ) {
        $form->{"$form->{vc}"} =
          qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;
        $form->{"select$form->{vc}"} = qq|<option>\n|;
        for ( @{ $form->{"all_$form->{vc}"} } ) {
            $form->{"select$form->{vc}"} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }
    }

    $form->get_partsgroup( \%myconfig, { all => 1 } );
    $form->{partsgroup} =
      $form->quote( $form->{partsgroup} ) . "--$form->{partsgroup_id}";
    if ( @{ $form->{all_partsgroup} } ) {
        $form->{selectpartsgroup} = qq|<option>\n|;
        for ( @{ $form->{all_partsgroup} } ) {
            $form->{selectpartsgroup} .=
                qq|<option value="|
              . $form->quote( $_->{partsgroup} )
              . qq|--$_->{id}">$_->{partsgroup}\n|;
        }
    }

    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );

    $form->{readonly} = 1 if $myconfig{acs} =~ /Job Costing--Add Job/;

}

sub job_header {

    for (qw(partnumber partdescription description notes unit)) {
        $form->{$_} = $form->quote( $form->{$_} );
    }

    for (qw(production weight)) {
        $form->{$_} = $form->format_amount( \%myconfig, $form->{$_} );
    }
    for (qw(listprice sellprice)) {
        $form->{$_} = $form->format_amount( \%myconfig, $form->{$_}, 2 );
    }

    if ( ( $rows = $form->numtextrows( $form->{partdescription}, 60 ) ) > 1 ) {
        $partdescription =
qq|<textarea name="partdescription" rows=$rows cols=60 style="width: 100%" wrap=soft>$form->{partdescription}</textarea>|;
    }
    else {
        $partdescription =
qq|<input name=partdescription size=60 value="$form->{partdescription}">|;
    }

    if ( ( $rows = $form->numtextrows( $form->{description}, 60 ) ) > 1 ) {
        $description =
qq|<textarea name="description" rows=$rows cols=60 style="width: 100%" wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input name=description size=60 value="$form->{description}">|;
    }

    if ( ( $rows = $form->numtextrows( $form->{notes}, 40 ) ) < 2 ) {
        $rows = 2;
    }

    $notes =
qq|<textarea name=notes rows=$rows cols=40 wrap=soft>$form->{notes}</textarea>|;

    $form->{selectIC_income} = $form->unescape( $form->{selectIC_income} );
    $form->{"select$form->{vc}"} =
      $form->unescape( $form->{"select$form->{vc}"} );
    $form->{"select$form->{vc}"} =~ s/ selected//;
    $form->{"select$form->{vc}"} =~
      s/(<option value="\Q$form->{"$form->{vc}"}\E")/$1 selected/;

    $label = ucfirst $form->{vc};
    if ( $form->{"select$form->{vc}"} ) {
        $name = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text($label) . qq|</th>
	  <td colspan=3><select name="$form->{vc}">$form->{"select$form->{vc}"}</select></td>
	  <input type=hidden name="select$form->{vc}" value="|
          . $form->escape( $form->{"select$form->{vc}"}, 1 ) . qq|">
	</tr>
|;
    }
    else {
        $name = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text($label) . qq|</th>
	  <td colspan=3><input name="$form->{vc}" value="$form->{"$form->{vc}"}" size=35></td>
	  <input type=hidden name="select$form->{vc}" value="|
          . $form->escape( $form->{"select$form->{vc}"}, 1 ) . qq|">
	</tr>
|;
    }

    if ( $form->{orphaned} ) {

        for (qw(income)) {
            $form->{"selectIC_$_"} =~ s/ selected//;
            $form->{"selectIC_$_"} =~
              s/option>\Q$form->{"IC_$_"}\E/option selected>$form->{"IC_$_"}/;
        }

        $production = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text('Production') . qq|</th>
	  <td><input name=production size=10 value="$form->{production}"></td>
	  <th align=right nowrap>| . $locale->text('Completed') . qq|</th>
	  <td>$form->{completed}</td>
	</tr>
|;

    }
    else {

        $form->{selectIC_income} = qq|<option selected>$form->{IC_income}|;

        $production = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text('Production') . qq|</th>
	  <td><input type=hidden name=production value="$form->{production}">$form->{production}</td>
	  <th align=right nowrap>| . $locale->text('Completed') . qq|</th>
	  <td>$form->{completed}</td>
	</tr>
|;

    }

    for ( split / /, $form->{taxaccounts} ) {
        $form->{"IC_tax_$_"} = ( $form->{"IC_tax_$_"} ) ? "checked" : "";
    }

    if ( $form->{selectpartsgroup} ) {
        $form->{selectpartsgroup} =
          $form->unescape( $form->{selectpartsgroup} );

        $partsgroup =
          qq|<input type=hidden name=selectpartsgroup value="|
          . $form->escape( $form->{selectpartsgroup}, 1 ) . qq|">|;
        $form->{partsgroup} = $form->quote( $form->{partsgroup} );
        $form->{selectpartsgroup} =~
          s/(<option value="\Q$form->{partsgroup}\E")/$1 selected/;

        $partsgroup .=
          qq|\n<select name=partsgroup>$form->{selectpartsgroup}</select>|;
        $group = $locale->text('Group');
    }

    $linkaccounts = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text('Income') . qq|</th>
	  <td><select name=IC_income>$form->{selectIC_income}</select></td>
	</tr>
|;

    for ( split / /, $form->{taxaccounts} ) {
        $tax .= qq|
        <input class=checkbox type=checkbox name="IC_tax_$_" value=1 $form->{"IC_tax_$_"}>&nbsp;<b>$form->{"IC_tax_${_}_description"}</b>
	<br><input type=hidden name=IC_tax_${_}_description value="$form->{"IC_tax_${_}_description"}">
|;
    }

    if ($tax) {
        $linkaccounts .= qq|
              <tr>
	        <th align=right>| . $locale->text('Tax') . qq|</th>
		<td>$tax</td>
	      </tr>
|;
    }

    $partnumber = qq|
	<tr>
	  <td>
	    <table>
	      <tr valign=top>
	        <th align=left>| . $locale->text('Number') . qq|</th>
		<th align=left>| . $locale->text('Description') . qq|</th>
		<th align=left>$group</th>
	      </tr>
	      <tr valign=top>
	        <td><input name=partnumber value="$form->{partnumber}" size=20></td>
		<td>$partdescription</td>
		<td>$partsgroup</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

    $form->{title} =
      ( $form->{id} ) ? $locale->text('Edit Job') : $locale->text('Add Job');

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>
|;

    for (qw(partnumber startdate enddate)) { $form->{"old$_"} = $form->{$_} }

    print qq|<input type=hidden name="selectIC_income" value="|
      . $form->escape( $form->{"selectIC_income"}, 1 )
      . qq|">\n|;

    $form->hide_form(
        "id",             "type",
        "old$form->{vc}", "$form->{vc}_id",
        "orphaned",       "taxaccounts",
        "vc",             "project"
    );

    print qq|
  
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>| . $locale->text('Number') . qq|</th>
	  <td><input name=projectnumber size=20 value="$form->{projectnumber}"></td>
	  <th align=right>| . $locale->text('Description') . qq|</th>
	  <td>$description</td>
	</tr>
	$name
	<tr>
	  <th align=right>| . $locale->text('Startdate') . qq|</th>
	  <td><input class="date" name=startdate size=11 title="($myconfig{dateformat})" value=$form->{startdate}></td>
	  <th align=right>| . $locale->text('Enddate') . qq|</th>
	  <td><input class="date" name=enddate size=11 title="($myconfig{dateformat})" value=$form->{enddate}></td>
	</tr>
	$production
      </table>
    </td>
  </tr>
  <tr class="listheading">
    <th class="listheading" align="center">|
      . $locale->text('Assembly')
      . qq|</th>
  </tr>
  <tr>
    <td>
      <table width=100%>
	$partnumber
	<tr>
	  <td colspan=3>
	    <table width=100%>
	      <tr>
	        <td width=70%>
		  <table width=100%>
		    <tr class="listheading">
		      <th class="listheading" align="center" colspan=2>|
      . $locale->text('Link Accounts')
      . qq|</th>
		    </tr>
		    $linkaccounts
		    <tr>
		      <th align="left">| . $locale->text('Notes') . qq|</th>
		    </tr>
		    <tr>
		      <td colspan=2>
			$notes
		      </td>
		    </tr>
		  </table>
		</td>
		<td align=right>
		  <table>
		    <tr>
		      <th align="right" nowrap="true">| . $locale->text('Updated') . qq|</th>
		      <td><input name=priceupdate size=11 title="$myconfig{dateformat}" value=$form->{priceupdate}></td>
		    </tr>
		    <tr>
		      <th align="right" nowrap="true">|
      . $locale->text('List Price')
      . qq|</th>
		      <td><input name=listprice size=11 value=$form->{listprice}></td>
		    </tr>
		    <tr>
		      <th align="right" nowrap="true">|
      . $locale->text('Sell Price')
      . qq|</th>
		      <td><input name=sellprice size=11 value=$form->{sellprice}></td>
		    </tr>
		    <tr>
		      <th align="right" nowrap="true">| . $locale->text('Weight') . qq|</th>
		      <td>
			<table>
			  <tr>
			    <td>
			      <input name=weight size=10 value=$form->{weight}>
			    </td>
			    <th>
			      &nbsp;
			      $form->{weightunit}
			      <input type=hidden name=weightunit value=$form->{weightunit}>
			    </th>
			  </tr>
			</table>
		      </td>
		    <tr>
		      <th align="right" nowrap="true">| . $locale->text('Bin') . qq|</th>
		      <td><input name=bin size=10 value="$form->{bin}"></td>
		    </tr>
		    <tr>
		      <th align="right" nowrap="true">| . $locale->text('Unit') . qq|</th>
		      <td><input name=unit size=5 value="$form->{unit}"></td>
		    </tr>
		  </table>
		</td>
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
|;

}

sub job_footer {

    $form->hide_form(qw(callback path login sessionid));

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Save')
    # type=submit $locale->text('Delete')

    %button =
      ( 'update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
      );

    if ( $myconfig{acs} !~ /Job Costing--Add Job/ ) {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save') };

        if ( $form->{id} && $form->{orphaned} ) {
            $button{'delete'} =
              { ndx => 16, key => 'D', value => $locale->text('Delete') };
        }
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

sub list_stock {

    PE->list_stock( \%myconfig, \%$form );

    $form->{title}  = $locale->text('Stock Finished Goods');
    $form->{action} = "list_stock";

    $href = "$form->{script}?";
    for (qw(action direction oldsort type path login sessionid status)) {
        $href .= "$_=$form->{$_}&";
    }

    $form->sort_order();

    $callback = "$form->{script}?";
    for (qw(action direction oldsort type path login sessionid status)) {
        $callback .= "$_=$form->{$_}&";
    }

    @column_index =
      $form->sort_columns(
        qw(projectnumber description startdate partnumber production completed stock)
      );

    if ( $form->{projectnumber} ) {
        $href .= "&projectnumber=" . $form->escape( $form->{projectnumber} );
        $callback .= "&projectnumber=$form->{projectnumber}";
        ($var) = split /--/, $form->{projectnumber};
        $option .= "\n<br>" . $locale->text('Job Number') . " : $var";
    }
    if ( $form->{stockingdate} ) {
        $href   .= "&stockingdate=$form->{stockingdate}";
        $option .= "\n<br>"
          . $locale->text('As of') . " : "
          . $locale->date( \%myconfig, $form->{stockingdate}, 1 );
    }

    $column_header{projectnumber} =
        qq|<th width=30%><a class=listheading href=$href&sort=projectnumber>|
      . $locale->text('Number')
      . qq|</a></th>|;
    $column_header{description} =
        qq|<th width=50%><a class=listheading href=$href&sort=description>|
      . $locale->text('Description')
      . qq|</a></th>|;
    $column_header{startdate} =
        qq|<th width=10%><a class=listheading href=$href&sort=startdate>|
      . $locale->text('Startdate')
      . qq|</a></th>|;
    $column_header{partnumber} =
        "<th><a class=listheading href=$href&sort=partnumber>"
      . $locale->text('Assembly')
      . "</a></th>";
    $column_header{production} =
      "<th class=listheading>" . $locale->text('Production') . "</a></th>";
    $column_header{completed} =
      "<th class=listheading>" . $locale->text('Completed') . "</a></th>";
    $column_header{stock} =
      "<th class=listheading>" . $locale->text('Add') . "</a></th>";

    $form->header;

    if ( @{ $form->{all_project} } ) {
        $sameitem = $form->{all_project}->[0]->{ $form->{sort} };
    }

    print qq|
<body>

<form method=post action=$form->{script}>

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

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
        </tr>
|;

    # escape callback
    $form->{callback} = $callback .= "&sort=$form->{sort}";

    # escape callback for href
    $callback = $form->escape($callback);

    # flip direction
    $direction = ( $form->{direction} eq 'ASC' ) ? "ASC" : "DESC";
    $href =~ s/&direction=(\w+)&/&direction=$direction&/;

    $i = 0;
    foreach $ref ( @{ $form->{all_project} } ) {

        $i++;

        for (qw(projectnumber description startdate enddate partnumber)) {
            $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>|;
        }
        for (qw(production completed)) {
            $column_data{$_} =
                qq|<td align=right>|
              . $form->format_amount( \%myconfig, $ref->{$_} )
              . qq|</td>|;
        }
        $column_data{stock} = qq|<td><input name="stock_$i" size=6></td>|;

        $j++;
        $j %= 2;

        print qq|
        <tr valign=top class=listrow$j>
	<input type=hidden name="id_$i" value=$ref->{id}>
|;

        for (@column_index) { print "$column_data{$_}\n" }

        print "
        </tr>
";
    }

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

    $form->hide_form(qw(callback type path login sessionid status));

    print qq|
<input type="hidden" name="nextsub" value="stock">
<br>
<button type="submit" class="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub stock {

    if ( PE->stock_assembly( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Assembly stocked!') );
    }
    else {
        $form->error( $locale->text('Cannot stock Assembly!') );
    }

}

sub prepare_project {

    $form->{vc} = 'customer';

    PE->get_project( \%myconfig, \%$form );

    $form->{title} =
      ( $form->{id} )
      ? $locale->text('Edit Project')
      : $locale->text('Add Project');

    $form->{"old$form->{vc}"} =
      qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;

    if ( @{ $form->{"all_$form->{vc}"} } ) {
        $form->{"$form->{vc}"} =
          qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;
        $form->{"select$form->{vc}"} = qq|<option>\n|;
        for ( @{ $form->{"all_$form->{vc}"} } ) {
            $form->{"select$form->{vc}"} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }
    }

}

sub search {

    # accounting years
    $form->all_years( \%myconfig );

    if ( @{ $form->{all_years} } ) {
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

        $fromto = qq|
 	<tr>
	  <th align=right>| . $locale->text('Startdate') . qq|</th>
	  <td>|
          . $locale->text('From')
          . qq| <input class="date" name=startdatefrom size=11 title="($myconfig{'dateformat'})">|
          . $locale->text('To') . qq|
	  <input class="date" name=startdateto size=11 title="($myconfig{'dateformat'})"></td>
	</tr>
|;

        $selectperiod = qq|
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

    $orphaned = qq|
	  <input name=status class=radio type=radio value=orphaned>&nbsp;|
      . $locale->text('Orphaned');

    if ( $form->{type} eq 'project' ) {
        $report        = "project_report";
        $sort          = "projectnumber";
        $form->{title} = $locale->text('Projects');

        $number = qq|
	<tr>
	  <th align=right width=1%>| . $locale->text('Number') . qq|</th>
	  <td><input name=projectnumber size=20></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Description') . qq|</th>
	  <td><input name=description size=60></td>
	</tr>
|;
    }

    if ( $form->{type} eq 'stock' ) {
        $report = "list_stock";
        $form->{title} = $locale->text('Stock Finished Goods');
        PE->list_stock( \%myconfig, \%$form );

        $selectperiod = "";
        $orphaned     = "";
        $fromto       = qq|
        <tr>
	  <th align=right nowrap>| . $locale->text('As of') . qq|</th>
	  <td><input class="date" name=stockingdate size=11 title="$myconfig{dateformat}"></td>
	</tr>
|;

        $number = qq|
	<tr>
	  <th align=right width=1%>| . $locale->text('Job Number') . qq|</th>
	  <td><input name=projectnumber size=20></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Description') . qq|</th>
	  <td><input name=description size=60></td>
	</tr>
|;
    }

    if ( $form->{type} eq 'job' ) {
        $report        = "job_report";
        $sort          = "projectnumber";
        $form->{title} = $locale->text('Jobs');

        $number = qq|
	<tr>
	  <th align=right width=1%>| . $locale->text('Number') . qq|</th>
	  <td><input name=projectnumber size=20></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Description') . qq|</th>
	  <td><input name=description size=60></td>
	</tr>
|;
    }

    if ( $form->{type} eq 'partsgroup' ) {
        $report        = "partsgroup_report";
        $sort          = 'partsgroup';
        $form->{title} = $locale->text('Groups');

        $fromto       = "";
        $selectperiod = "";
        $number       = qq|
	<tr>
	  <th align=right width=1%>| . $locale->text('Group') . qq|</th>
	  <td><input name=partsgroup size=20></td>
	</tr>
|;
    }

    if ( $form->{type} eq 'pricegroup' ) {
        $report        = "pricegroup_report";
        $sort          = 'pricegroup';
        $form->{title} = $locale->text('Pricegroups');

        $fromto       = "";
        $selectperiod = "";
        $number       = qq|
	<tr>
	  <th align=right width=1%>| . $locale->text('Pricegroup') . qq|</th>
	  <td><input name=pricegroup size=20></td>
	</tr>
|;
    }

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=sort value=$sort>
<input type=hidden name=type value=$form->{type}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        $number
	$fromto
	$selectperiod
	<tr>
	  <td></td>
	  <td><input name=status class=radio type=radio value=all checked>&nbsp;|
      . $locale->text('All') . qq|
	  <input name=status class=radio type=radio value=active>&nbsp;|
      . $locale->text('Active') . qq|
	  <input name=status class=radio type=radio value=inactive>&nbsp;|
      . $locale->text('Inactive') . qq|
	  $orphaned</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=$report>
|;

    $form->hide_form(qw(path login sessionid title));

    print qq|
<button class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
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

sub job_report {

    for (qw(projectnumber description)) {
        $form->{$_} = $form->unescape( $form->{$_} );
    }
    PE->jobs( \%myconfig, \%$form );

    $form->{action} = "job_report";
    &list_projects;

}

sub project_report {

    for (qw(projectnumber description)) {
        $form->{$_} = $form->unescape( $form->{$_} );
    }
    PE->projects( \%myconfig, \%$form );

    $form->{action} = "project_report";
    &list_projects;

}

sub list_projects {

    $href = "$form->{script}?";
    for (
        qw(action direction oldsort type path login sessionid status startdatefrom startdateto)
      )
    {
        $href .= "$_=$form->{$_}&";
    }

    $form->sort_order();

    $callback = "$form->{script}?";
    for (
        qw(action direction oldsort type path login sessionid status startdatefrom startdateto)
      )
    {
        $callback .= "$_=$form->{$_}&";
    }

    @column_index =
      $form->sort_columns(qw(projectnumber description name startdate enddate));

    if ( $form->{status} eq 'all' ) {
        $option = $locale->text('All');
    }
    if ( $form->{status} eq 'orphaned' ) {
        $option .= $locale->text('Orphaned');
    }
    if ( $form->{status} eq 'active' ) {
        $option = $locale->text('Active');
        @column_index =
          $form->sort_columns(qw(projectnumber description name startdate));
    }
    if ( $form->{status} eq 'inactive' ) {
        $option = $locale->text('Inactive');
    }

    if ( $form->{type} eq 'project' ) {
        $label = $locale->text('Project');
        $form->{title} = $locale->text('Projects');
    }
    else {
        $label = $locale->text('Job');
        push @column_index, qw(partnumber production completed);
        $form->{title} = $locale->text('Jobs');
    }

    if ( $form->{projectnumber} ) {
        $href .= "&projectnumber=" . $form->escape( $form->{projectnumber} );
        $callback .= "&projectnumber=$form->{projectnumber}";
        $option   .= "\n<br>$label : $form->{projectnumber}";
    }
    if ( $form->{description} ) {
        $href     .= "&description=" . $form->escape( $form->{description} );
        $callback .= "&description=$form->{description}";
        $option .=
          "\n<br>" . $locale->text('Description') . " : $form->{description}";
    }
    if ( $form->{startdatefrom} ) {
        $href   .= "&startdatefrom=$form->{startdatefrom}";
        $option .= "\n<br>"
          . $locale->text('From')
          . "&nbsp;"
          . $locale->date( \%myconfig, $form->{startdatefrom}, 1 );
    }
    if ( $form->{startdateto} ) {
        $href .= "&startdateto=$form->{startdateto}";
        if ( $form->{startdatefrom} ) {
            $option .= " ";
        }
        else {
            $option .= "\n<br>" if ($option);
        }
        $option .=
            $locale->text('To') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{startdateto}, 1 );
    }

    $column_header{projectnumber} =
        qq|<th><a class=listheading href=$href&sort=projectnumber>|
      . $locale->text('Number')
      . qq|</a></th>|;
    $column_header{description} =
        qq|<th><a class=listheading href=$href&sort=description>|
      . $locale->text('Description')
      . qq|</a></th>|;
    $column_header{startdate} =
        qq|<th width=10><a class=listheading href=$href&sort=startdate>|
      . $locale->text('Startdate')
      . qq|</a></th>|;
    $column_header{enddate} =
        qq|<th width=10><a class=listheading href=$href&sort=enddate>|
      . $locale->text('Enddate')
      . qq|</a></th>|;

    $column_header{partnumber} =
        "<th><a class=listheading href=$href&sort=partnumber>"
      . $locale->text('Assembly')
      . "</a></th>";
    $column_header{production} =
      "<th width=10 class=listheading>" . $locale->text('Production') . "</th>";
    $column_header{completed} =
      "<th width=10 class=listheading>" . $locale->text('Completed') . "</th>";
    $column_header{name} =
      "<th class=listheading>" . $locale->text('Customer') . "</th>";

    $form->header;

    if ( @{ $form->{all_project} } ) {
        $sameitem = $form->{all_project}->[0]->{ $form->{sort} };
    }

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

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
        </tr>
|;

    # escape callback
    $form->{callback} = $callback .= "&sort=$form->{sort}";

    # escape callback for href
    $callback = $form->escape($callback);

    # flip direction
    $direction = ( $form->{direction} eq 'ASC' ) ? "ASC" : "DESC";
    $href =~ s/&direction=(\w+)&/&direction=$direction&/;

    foreach $ref ( @{ $form->{all_project} } ) {

        for (qw(description startdate enddate name)) {
            $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>|;
        }

        for (qw(production completed)) {
            $column_data{$_} =
              qq|<td align=right>|
              . $form->format_amount( \%myconfig, $ref->{$_} );
        }

        $column_data{projectnumber} =
qq|<td><a href=$form->{script}?action=edit&type=$form->{type}&status=$form->{status}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&project=$form->{project}&callback=$callback>$ref->{projectnumber}</td>|;
        $column_data{partnumber} =
qq|<td><a href=ic.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{partnumber}</td>|;

        $j++;
        $j %= 2;

        print qq|
        <tr valign=top class=listrow$j>
|;

        for (@column_index) { print "$column_data{$_}\n" }

        print "
        </tr>
";
    }

    $i = 1;
    if ( $form->{type} eq 'project' ) {
        if ( $myconfig{acs} !~ /Projects--Projects/ ) {
            $button{'Projects--Add Project'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_project">|
              . $locale->text('Add Project')
              . qq|</button> |;
            $button{'Projects--Add Project'}{order} = $i++;

            for ( split /;/, $myconfig{acs} ) {
                delete $button{$_};
            }
        }
    }
    else {
        if ( $myconfig{acs} !~ /Job Costing--Job Costing/ ) {
            $button{'Job Costing--Add Job'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_job">|
              . $locale->text('Add Job')
              . qq|</button> |;
            $button{'Job Costing--Add Job'}{order} = $i++;

            for ( split /;/, $myconfig{acs} ) {
                delete $button{$_};
            }
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
<form method=post action=$form->{script}>
|;

    $form->hide_form(qw(callback type path login sessionid));

    foreach $item ( sort { $a->{order} <=> $b->{order} } %button ) {
        print $item->{code};
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

sub project_header {

    $form->{description} = $form->quote( $form->{description} );

    if ( ( $rows = $form->numtextrows( $form->{description}, 60 ) ) > 1 ) {
        $description =
qq|<textarea name="description" rows=$rows cols=60 style="width: 100%" wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input name=description size=60 value="$form->{description}">|;
    }

    $form->{"select$form->{vc}"} =
      $form->unescape( $form->{"select$form->{vc}"} );
    $form->{"select$form->{vc}"} =~ s/ selected//;
    $form->{"select$form->{vc}"} =~
      s/(<option value="\Q$form->{"$form->{vc}"}\E")/$1 selected/;

    $label = ucfirst $form->{vc};
    if ( $form->{"select$form->{vc}"} ) {
        $name = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text($label) . qq|</th>
	  <td colspan=3><select name="$form->{vc}">$form->{"select$form->{vc}"}</select></td>
	  <input type=hidden name="select$form->{vc}" value="|
          . $form->escape( $form->{"select$form->{vc}"}, 1 ) . qq|">
	</tr>
|;
    }
    else {
        $name = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text($label) . qq|</th>
	  <td colspan=3><input name="$form->{vc}" value="$form->{"$form->{vc}"}" size=35></td>
	  <input type=hidden name="select$form->{vc}" value="|
          . $form->escape( $form->{"select$form->{vc}"}, 1 ) . qq|">
	</tr>
|;
    }

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>
|;

    $form->hide_form(
        "id",             "type",
        "old$form->{vc}", "$form->{vc}_id",
        "orphaned",       "vc",
        "title"
    );

    print qq|
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>| . $locale->text('Number') . qq|</th>
	  <td><input name=projectnumber size=20 value="$form->{projectnumber}"></td>
	  <th align=right>| . $locale->text('Description') . qq|</th>
	  <td>$description</td>
	</tr>
	$name
	<tr>
	  <th align=right>| . $locale->text('Startdate') . qq|</th>
	  <td><input class="date" name=startdate size=11 title="($myconfig{dateformat})" value=$form->{startdate}></td>
	  <th align=right>| . $locale->text('Enddate') . qq|</th>
	  <td><input class="date" name=enddate size=11 title="($myconfig{dateformat})" value=$form->{enddate}></td>
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

sub project_footer {

    $form->hide_form(qw(callback path login sessionid));

    %button =
      ( 'update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
      );

    if ( $myconfig{acs} !~ /Projects--Add Project/ ) {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save') };

        if ( $form->{id} && $form->{orphaned} ) {
            $button{'delete'} =
              { ndx => 16, key => 'D', value => $locale->text('Delete') };
        }
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

sub save {

    if ( $form->{translation} ) {
        PE->save_translation( \%myconfig, \%$form );
        $form->redirect( $locale->text('Translations saved!') );
        $form->finalize_request();
    }

    if ( $form->{type} eq 'project' ) {
        if ( $form->{"select$form->{vc}"} ) {
            ( $null, $form->{"$form->{vc}_id"} ) = split /--/,
              $form->{"$form->{vc}"};
        }
        else {
            if ( $form->{"old$form->{vc}"} ne
                qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}| )
            {

                if (
                    (
                        $rv = $form->get_name(
                            \%myconfig, $form->{vc}, $form->{startdate}
                        )
                    ) > 1
                  )
                {
                    &select_name;
                    $form->finalize_request();
                }

                if ( $rv == 1 ) {
                    $form->{"$form->{vc}_id"} = $form->{name_list}[0]->{id};
                    $form->{"$form->{vc}"}    = $form->{name_list}[0]->{name};
                    $form->{"old$form->{vc}"} =
                      qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;
                }
            }
        }

        PE->save_project( \%myconfig, \%$form );
        $form->redirect( $locale->text('Project saved!') );
    }

    if ( $form->{type} eq 'partsgroup' ) {
        $form->isblank( "partsgroup", $locale->text('Group missing!') );
        PE->save_partsgroup( \%myconfig, \%$form );
        $form->redirect( $locale->text('Group saved!') );
    }

    if ( $form->{type} eq 'pricegroup' ) {
        $form->isblank( "pricegroup", $locale->text('Pricegroup missing!') );
        PE->save_pricegroup( \%myconfig, \%$form );
        $form->redirect( $locale->text('Pricegroup saved!') );
    }

    if ( $form->{type} eq 'job' ) {
        if ( $form->{"select$form->{vc}"} ) {
            ( $null, $form->{"$form->{vc}_id"} ) = split /--/,
              $form->{"$form->{vc}"};
        }
        else {
            if ( $form->{"old$form->{vc}"} ne
                qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}| )
            {

                if (
                    (
                        $rv = $form->get_name(
                            \%myconfig, $form->{vc}, $form->{startdate}
                        )
                    ) > 1
                  )
                {
                    &select_name;
                    $form->finalize_request();
                }

                if ( $rv == 1 ) {
                    $form->{"$form->{vc}_id"} = $form->{name_list}[0]->{id};
                    $form->{"$form->{vc}"}    = $form->{name_list}[0]->{name};
                    $form->{"old$form->{vc}"} =
                      qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;
                }
            }
        }

        PE->save_job( \%myconfig, \%$form );
        $form->redirect( $locale->text('Job saved!') );
    }

}

sub delete {

    if ( $form->{translation} ) {
        PE->delete_translation( \%myconfig, \%$form );
        $form->redirect( $locale->text('Translation deleted!') );

    }
    else {

        if ( $form->{type} eq 'project' ) {
            PE->delete_project( \%myconfig, \%$form );
            $form->redirect( $locale->text('Project deleted!') );
        }
        if ( $form->{type} eq 'job' ) {
            PE->delete_job( \%myconfig, \%$form );
            $form->redirect( $locale->text('Job deleted!') );
        }
        if ( $form->{type} eq 'partsgroup' ) {
            PE->delete_partsgroup( \%myconfig, \%$form );
            $form->redirect( $locale->text('Group deleted!') );
        }
        if ( $form->{type} eq 'pricegroup' ) {
            PE->delete_pricegroup( \%myconfig, \%$form );
            $form->redirect( $locale->text('Pricegroup deleted!') );
        }
    }

}

sub partsgroup_report {

    $form->{partsgroup} = $form->unescape( $form->{partsgroup} );
    PE->partsgroups( \%myconfig, \%$form );

    $href =
"$form->{script}?action=partsgroup_report&direction=$form->{direction}&oldsort=$form->{oldsort}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&status=$form->{status}";

    $form->sort_order();

    $callback =
"$form->{script}?action=partsgroup_report&direction=$form->{direction}&oldsort=$form->{oldsort}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&status=$form->{status}";

    if ( $form->{status} eq 'all' ) {
        $option = $locale->text('All');
    }
    if ( $form->{status} eq 'orphaned' ) {
        $option .= $locale->text('Orphaned');
    }
    if ( $form->{partsgroup} ) {
        $callback .= "&partsgroup=$form->{partsgroup}";
        $option .= "\n<br>" . $locale->text('Group') . " : $form->{partsgroup}";
    }

    @column_index = $form->sort_columns(qw(partsgroup));

    $column_header{partsgroup} =
        qq|<th><a class=listheading href=$href&sort=partsgroup width=90%>|
      . $locale->text('Group')
      . qq|</a></th>|;

    $form->{title} = $locale->text('Groups');

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

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
        </tr>
|;

    # escape callback
    $form->{callback} = $callback;

    # escape callback for href
    $callback = $form->escape($callback);

    foreach $ref ( @{ $form->{item_list} } ) {

        $i++;
        $i %= 2;

        print qq|
        <tr valign=top class=listrow$i>
|;

        $column_data{partsgroup} =
qq|<td><a href=$form->{script}?action=edit&type=$form->{type}&status=$form->{status}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{partsgroup}</td>|;
        for (@column_index) { print "$column_data{$_}\n" }

        print "
        </tr>
";
    }

    $i = 1;
    if ( $myconfig{acs} !~ /Goods \& Services--Goods \& Services/ ) {
        $button{'Goods & Services--Add Group'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_group">|
          . $locale->text('Add Group')
          . qq|</button> |;
        $button{'Goods & Services--Add Group'}{order} = $i++;

        foreach $item ( split /;/, $myconfig{acs} ) {
            delete $button{$item};
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
<form method=post action=$form->{script}>
|;

    $form->hide_form(qw(callback type path login sessionid));

    foreach $item ( sort { $a->{order} <=> $b->{order} } %button ) {
        print $item->{code};
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

sub partsgroup_header {

    $form->{action} =~ s/_.*//;
    $form->{title} = $locale->text( ucfirst $form->{action} . " Group" );

    # $locale->text('Add Group')
    # $locale->text('Edit Group')

    $form->{partsgroup} = $form->quote( $form->{partsgroup} );

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=$form->{type}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=right>| . $locale->text('Group') . qq|</th>

          <td><input name=partsgroup size=30 value="$form->{partsgroup}"></td>
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

sub partsgroup_footer {

    $form->hide_form(qw(callback path login sessionid));

    if ( $myconfig{acs} !~ /Goods \& Services--Add Group/ ) {
        print qq|
<button type="submit" class="submit" name="action" value="save">|
          . $locale->text('Save')
          . qq|</button>
|;

        if ( $form->{id} && $form->{orphaned} ) {
            print qq|
<button type="submit" class="submit" name="action" value="delete">|
              . $locale->text('Delete')
              . qq|</button>|;
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

sub pricegroup_report {

    $form->{pricegroup} = $form->unescape( $form->{pricegroup} );
    PE->pricegroups( \%myconfig, \%$form );

    $href =
"$form->{script}?action=pricegroup_report&direction=$form->{direction}&oldsort=$form->{oldsort}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&status=$form->{status}";

    $form->sort_order();

    $callback =
"$form->{script}?action=pricegroup_report&direction=$form->{direction}&oldsort=$form->{oldsort}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&status=$form->{status}";

    if ( $form->{status} eq 'all' ) {
        $option = $locale->text('All');
    }
    if ( $form->{status} eq 'orphaned' ) {
        $option .= $locale->text('Orphaned');
    }
    if ( $form->{pricegroup} ) {
        $callback .= "&pricegroup=$form->{pricegroup}";
        $option .=
          "\n<br>" . $locale->text('Pricegroup') . " : $form->{pricegroup}";
    }

    @column_index = $form->sort_columns(qw(pricegroup));

    $column_header{pricegroup} =
        qq|<th><a class=listheading href=$href&sort=pricegroup width=90%>|
      . $locale->text('Pricegroup')
      . qq|</th>|;

    $form->{title} = $locale->text('Pricegroups');

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

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
        </tr>
|;

    # escape callback
    $form->{callback} = $callback;

    # escape callback for href
    $callback = $form->escape($callback);

    foreach $ref ( @{ $form->{item_list} } ) {

        $i++;
        $i %= 2;

        print qq|
        <tr valign=top class=listrow$i>
|;

        $column_data{pricegroup} =
qq|<td><a href=$form->{script}?action=edit&type=$form->{type}&status=$form->{status}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{pricegroup}</td>|;
        for (@column_index) { print "$column_data{$_}\n" }

        print "
        </tr>
";
    }

    $i = 1;
    if ( $myconfig{acs} !~ /Goods \& Services--Goods \& Services/ ) {
        $button{'Goods & Services--Add Pricegroup'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_pricegroup">|
          . $locale->text('Add Pricegroup')
          . qq|</button> |;
        $button{'Goods & Services--Add Pricegroup'}{order} = $i++;

        foreach $item ( split /;/, $myconfig{acs} ) {
            delete $button{$item};
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
<form method=post action=$form->{script}>
|;

    $form->hide_form(qw(callback type path login sessionid));

    foreach $item ( sort { $a->{order} <=> $b->{order} } %button ) {
        print $item->{code};
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

sub pricegroup_header {

    $form->{title} = $locale->text( ucfirst $form->{action} . " Pricegroup" );

    # $locale->text('Add Pricegroup')
    # $locale->text('Edit Pricegroup')

    $form->{pricegroup} = $form->quote( $form->{pricegroup} );

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=$form->{type}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=right>| . $locale->text('Pricegroup') . qq|</th>

          <td><input name=pricegroup size=30 value="$form->{pricegroup}"></td>
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

sub pricegroup_footer {

    $form->hide_form(qw(callback path login sessionid));

    if ( $myconfig{acs} !~ /Goods \& Services--Add Pricegroup/ ) {
        print qq|
<button type="submit" class="submit" name="action" value="save">|
          . $locale->text('Save')
          . qq|</button>
|;

        if ( $form->{id} && $form->{orphaned} ) {
            print qq|
<button type="submit" class="submit" name="action" value="delete">|
              . $locale->text('Delete')
              . qq|</button>|;
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

sub translation {

    if ( $form->{translation} eq 'description' ) {
        $form->{title}  = $locale->text('Description Translations');
        $sort           = qq|<input type=hidden name=sort value=partnumber>|;
        $form->{number} = "partnumber";
        $number         = qq|
        <tr>
          <th align=right nowrap>| . $locale->text('Number') . qq|</th>
          <td><input name=partnumber size=20></td>
        </tr>
|;
    }

    if ( $form->{translation} eq 'partsgroup' ) {
        $form->{title} = $locale->text('Group Translations');
        $sort = qq|<input type=hidden name=sort value=partsgroup>|;
    }

    if ( $form->{translation} eq 'project' ) {
        $form->{title}  = $locale->text('Project Description Translations');
        $form->{number} = "projectnumber";
        $sort           = qq|<input type=hidden name=sort value=projectnumber>|;
        $number         = qq|
        <tr>
          <th align=right nowrap>| . $locale->text('Project Number') . qq|</th>
          <td><input name=projectnumber size=20></td>
        </tr>
|;
    }

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>
|;

    $form->hide_form(qw(translation title number));

    print qq|
  
<table width="100%">
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        $number
        <tr>
          <th align=right nowrap>| . $locale->text('Description') . qq|</th>
          <td colspan=3><input name=description size=40></td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

<input type=hidden name=nextsub value=list_translations>
$sort
|;

    $form->hide_form(qw(path login sessionid));

    print qq|

<br>
<button class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub list_translations {

    $title = $form->escape( $form->{title}, 1 );

    $callback =
"$form->{script}?action=list_translations&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&translation=$form->{translation}&number=$form->{number}&title=$title";

    if ( $form->{"$form->{number}"} ) {
        $callback .= qq|&$form->{number}=$form->{"$form->{number}"}|;
        $option .=
          $locale->text('Number') . qq| : $form->{"$form->{number}"}<br>|;
    }
    if ( $form->{description} ) {
        $callback .= "&description=$form->{description}";
        $description = $form->{description};
        $description =~ s/\r?\n/<br>/g;
        $option .=
          $locale->text('Description') . qq| : $form->{description}<br>|;
    }

    if ( $form->{translation} eq 'partsgroup' ) {
        @column_index = qw(description language translation);
        $form->{sort} = "";
    }
    else {
        @column_index =
          $form->sort_columns( "$form->{number}", "description", "language",
            "translation" );
    }

    &{"PE::$form->{translation}_translations"}( "", \%myconfig, \%$form );

    $callback .= "&direction=$form->{direction}&oldsort=$form->{oldsort}";

    $href = $callback;

    $form->sort_order();

    $callback =~ s/(direction=).*\&{1}/$1$form->{direction}\&/;

    $column_header{"$form->{number}"} =
        qq|<th nowrap><a class=listheading href=$href&sort=$form->{number}>|
      . $locale->text('Number')
      . qq|</a></th>|;
    $column_header{description} =
      qq|<th nowrap width=40%><a class=listheading href=$href&sort=description>|
      . $locale->text('Description')
      . qq|</a></th>|;
    $column_header{language} =
        qq|<th nowrap class=listheading>|
      . $locale->text('Language')
      . qq|</a></th>|;
    $column_header{translation} =
        qq|<th nowrap width=40% class=listheading>|
      . $locale->text('Translation')
      . qq|</a></th>|;

    $form->header;

    print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>

  <tr><td>$option</td></tr>

  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

    for (@column_index) { print "\n$column_header{$_}" }

    print qq|
        </tr>
  |;

    # add order to callback
    $form->{callback} = $callback .= "&sort=$form->{sort}";

    # escape callback for href
    $callback = $form->escape($callback);

    if ( @{ $form->{translations} } ) {
        $sameitem = $form->{translations}->[0]->{ $form->{sort} };
    }

    foreach $ref ( @{ $form->{translations} } ) {

        $ref->{description} =~ s/\r?\n/<br>/g;

        for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

        $column_data{description} =
"<td><a href=$form->{script}?action=edit_translation&translation=$form->{translation}&number=$form->{number}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}&nbsp;</a></td>";

        $i++;
        $i %= 2;
        print "<tr class=listrow$i>";

        for (@column_index) { print "\n$column_data{$_}" }

        print qq|
    </tr>
|;

    }

    print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

|;

    print qq|

<br>

<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">
|;

    $form->hide_form(qw(path login sessionid));

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

sub edit_translation {

    &{"PE::$form->{translation}_translations"}( "", \%myconfig, \%$form );

    $form->error( $locale->text('Languages not defined!') )
      unless @{ $form->{all_language} };

    $form->{selectlanguage} = qq|<option>\n|;
    for ( @{ $form->{all_language} } ) {
        $form->{selectlanguage} .=
          qq|<option value="$_->{code}">$_->{description}\n|;
    }

    $form->{"$form->{number}"} =
      $form->{translations}->[0]->{"$form->{number}"};
    $form->{description} = $form->{translations}->[0]->{description};
    $form->{description} =~ s/\r?\n/<br>/g;

    shift @{ $form->{translations} };

    $i = 1;
    foreach $row ( @{ $form->{translations} } ) {
        $form->{"language_code_$i"} = $row->{code};
        $form->{"translation_$i"}   = $row->{translation};
        $i++;
    }
    $form->{translation_rows} = $i - 1;

    $form->{title} = $locale->text('Edit Description Translations');

    &translation_header;
    &translation_footer;

}

sub translation_header {

    $form->{translation_rows}++;

    $form->{selectlanguage} = $form->unescape( $form->{selectlanguage} );
    for $i ( 1 .. $form->{translation_rows} ) {
        $form->{"selectlanguage_$i"} = $form->{selectlanguage};
        if ( $form->{"language_code_$i"} ) {
            $form->{"selectlanguage_$i"} =~
              s/(<option value="\Q$form->{"language_code_$i"}\E")/$1 selected/;
        }
    }

    $form->{selectlanguage} = $form->escape( $form->{selectlanguage}, 1 );

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=$form->{number} value="|
      . $form->quote( $form->{"$form->{number}"} ) . qq|">
<input type=hidden name=description value="|
      . $form->quote( $form->{description} ) . qq|">
|;

    $form->hide_form(
        qw(id trans_id selectlanguage translation_rows number translation title)
    );

    print qq|
  
<table width="100%">
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table width=100%>
        <tr>
          <td align=left>$form->{"$form->{number}"}</th>
	  <td align=left>$form->{description}</th>
        </tr>
        <tr>
	<tr>
	  <th class=listheading>| . $locale->text('Language') . qq|</th>
	  <th class=listheading>| . $locale->text('Translation') . qq|</th>
	</tr>
|;

    for $i ( 1 .. $form->{translation_rows} ) {

        if ( ( $rows = $form->numtextrows( $form->{"translation_$i"}, 40 ) ) >
            1 )
        {
            $translation =
qq|<textarea name="translation_$i" rows=$rows cols=40 wrap=soft>$form->{"translation_$i"}</textarea>|;
        }
        else {
            $translation =
qq|<input name="translation_$i" size=40 value="$form->{"translation_$i"}">|;
        }

        print qq|
	<tr valign=top>
	  <td><select name="language_code_$i">$form->{"selectlanguage_$i"}</select></td>
	  <td>$translation</td>
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
|;

}

sub translation_footer {

    $form->hide_form(qw(path login sessionid callback));

    %button = (
        'update' => { ndx => 1,  key => 'U', value => $locale->text('Update') },
        'save'   => { ndx => 3,  key => 'S', value => $locale->text('Save') },
        'delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
    );

    if ( !$form->{trans_id} ) {
        delete $button{'delete'};
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

sub update {

    if ( $form->{translation} ) {
        @flds  = qw(language translation);
        $count = 0;
        @a     = ();
        for $i ( 1 .. $form->{translation_rows} ) {
            if ( $form->{"language_code_$i"} ne "" ) {
                push @a, {};
                $j = $#a;

                for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
                $count++;
            }
        }
        $form->redo_rows( \@flds, \@a, $count, $form->{translation_rows} );
        $form->{translation_rows} = $count;

        &translation_header;
        &translation_footer;

        $form->finalize_request();

    }

    if ( $form->{type} =~ /(job|project)/ ) {

        # $locale->text('Customer not on file!')
        # $locale->text('Vendor not on file!')

        for (qw(production listprice sellprice weight)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        $form->{projectnumber} =
          $form->update_defaults( \%myconfig, "projectnumber" )
          unless $form->{projectnumber};

        if ( $form->{"select$form->{vc}"} ) {
            if (   $form->{startdate} ne $form->{oldstartdate}
                || $form->{enddate} ne $form->{oldenddate} )
            {

                PE->get_customer( \%myconfig, \%$form );

                if ( @{ $form->{"all_$form->{vc}"} } ) {
                    $form->{"select$form->{vc}"} = qq|<option>\n|;
                    for ( @{ $form->{"all_$form->{vc}"} } ) {
                        $form->{"select$form->{vc}"} .=
                          qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
                    }
                }
            }

            $form->{"old$form->{vc}"} = $form->{"$form->{vc}"};
            ( $null, $form->{"$form->{vc}_id"} ) = split /--/,
              $form->{"$form->{vc}"};

        }
        else {

            if ( $form->{"old$form->{vc}"} ne
                qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}| )
            {

                if (
                    (
                        $rv = $form->get_name(
                            \%myconfig, $form->{vc}, $form->{startdate}
                        )
                    ) > 1
                  )
                {
                    &select_name;
                    $form->finalize_request();
                }

                if ( $rv == 1 ) {
                    $form->{"$form->{vc}_id"} = $form->{name_list}[0]->{id};
                    $form->{"$form->{vc}"}    = $form->{name_list}[0]->{name};
                    $form->{"old$form->{vc}"} =
                      qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;
                }
                else {
                    $msg = ucfirst $form->{vc} . " not on file!";
                    $form->error( $locale->text($msg) );
                }
            }
        }
    }

    &display_form;

}

sub select_name {

    $label = ucfirst $form->{vc};

    @column_index = qw(ndx name address);
    $column_data{ndx} = qq|<th>&nbsp;</th>|;
    $column_data{name} =
      qq|<th class=listheading>| . $locale->text($label) . qq|</th>|;
    $column_data{address} =
        qq|<th class=listheading colspan=5>|
      . $locale->text('Address')
      . qq|</th>|;

    $form->header;
    $title = $locale->text('Select from one of the names below');
    print qq|
<body>

<form method=post action=$form->{script}>

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

    @column_index = qw(ndx name address city state zipcode country);

    my $i = 0;
    foreach $ref ( @{ $form->{name_list} } ) {
        $checked = ( $i++ ) ? "" : "checked";

        $ref->{name} = $form->quote( $ref->{name} );

        $column_data{ndx} =
qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
        $column_data{name} =
qq|<td><input name="new_name_$i" type=hidden value="$ref->{name}">$ref->{name}</td>|;
        $column_data{address} = qq|<td>$ref->{address1} $ref->{address2}</td>|;
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
    for (qw(action nextsub name_list)) { delete $form->{$_} }

    $form->hide_form;

    print qq|
<input type="hidden" name="nextsub" value="name_selected">
<br>
<button class="submit" type="submit" name="action" value="continue">|
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

    $form->{ $form->{vc} } = $form->{"new_name_$i"};
    $form->{"$form->{vc}_id"} = $form->{"new_id_$i"};
    $form->{"old$form->{vc}"} =
      qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;

    # delete all the new_ variables
    for $i ( 1 .. $form->{lastndx} ) {
        for (qw(id name)) { delete $form->{"new_${_}_$i"} }
    }

    for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

    &display_form;

}

sub display_form {

    &{"$form->{type}_header"};
    &{"$form->{type}_footer"};

}

sub continue { &{ $form->{nextsub} } }

sub add_group      { &add }
sub add_project    { &add }
sub add_job        { &add }
sub add_pricegroup { &add }

sub project_sales_order {

    PE->project_sales_order( \%myconfig, \%$form );

    if ( @{ $form->{all_years} } ) {
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

    $fromto = qq|
        <tr>
	  <th align=right nowrap>| . $locale->text('Transaction Dates') . qq|</th>
	  <td>|
      . $locale->text('From')
      . qq| <input class="date" name=transdatefrom size=11 title="$myconfig{dateformat}">
	  |
      . $locale->text('To')
      . qq| <input class="date" name=transdateto size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
|;

    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option>\n";
        for ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n|;
        }
    }
    else {
        $form->error( $locale->text('No open Projects!') );
    }

    if ( @{ $form->{all_employee} } ) {
        $form->{selectemployee} = "<option>\n";
        for ( @{ $form->{all_employee} } ) {
            $form->{selectemployee} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }

        $employee = qq|
              <tr>
	        <th align=right nowrap>| . $locale->text('Employee') . qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
	      </tr>
|;
    }

    $form->{title} = $locale->text('Generate Sales Orders');
    $form->{vc}    = "customer";
    $form->{type}  = "sales_order";

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
	  <th align=right>| . $locale->text('Project') . qq|</th>
	  <td colspan=3><select name=projectnumber>$form->{selectprojectnumber}</select></td>
	</tr>
	$employee
	$fromto
	<tr>
	  <th></th>
  	  <td><input name=summary type=radio class=radio value=1 checked> |
      . $locale->text('Summary') . qq|
  	  <input name=summary type=radio class=radio value=0> |
      . $locale->text('Detail') . qq|
  	  </td>
  	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

|;

    $form->{nextsub} = "project_jcitems_list";
    $form->hide_form(qw(path login sessionid nextsub type vc));

    print qq|
<button type="submit" class="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>

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

sub project_jcitems_list {

    $form->{projectnumber} = $form->unescape( $form->{projectnumber} );
    $form->{employee}      = $form->unescape( $form->{employee} );
    $form->{callback}      = "$form->{script}?action=project_jcitems_list";
    for (
        qw(month year interval summary transdatefrom transdateto login path sessionid nextsub type vc)
      )
    {
        $form->{callback} .= "&$_=$form->{$_}";
    }
    for (qw(employe projectnumber)) {
        $form->{callback} .= "&$_=" . $form->escape( $form->{$_}, 1 );
    }

    PE->get_jcitems( \%myconfig, \%$form );

    # flatten array
    $i = 1;
    foreach $ref ( @{ $form->{jcitems} } ) {

        if ( $form->{summary} ) {

            $thisitem =
              qq|$ref->{project_id}:$ref->{"$form->{vc}_id"}:$ref->{parts_id}|;

            if ( $thisitem eq $sameitem ) {

                $i--;
                for (qw(qty amount)) { $form->{"${_}_$i"} += $ref->{$_} }
                $form->{"id_$i"} .= " $ref->{id}:$ref->{qty}";
                if ( $form->{"notes_$i"} ) {
                    $form->{"notes_$i"} .= qq|\n\n$ref->{notes}|;
                }
                else {
                    $form->{"notes_$i"} = $ref->{notes};
                }

            }
            else {

                for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }

                $form->{"checked_$i"}     = 1;
                $form->{"$form->{vc}_$i"} = $ref->{ $form->{vc} };
                $form->{"id_$i"}          = "$ref->{id}:$ref->{qty}";

            }

            $sameitem =
              qq|$ref->{project_id}:$ref->{"$form->{vc}_id"}:$ref->{parts_id}|;
        }
        else {

            for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }
            $form->{"checked_$i"} = 1;
            $form->{"id_$i"}      = "$ref->{id}:$ref->{qty}";

        }

        $i++;

    }

    $form->{rowcount} = $i - 1;

    for $i ( 1 .. $form->{rowcount} ) {
        for (qw(qty allocated)) {
            $form->{"${_}_$i"} =
              $form->format_amount( \%myconfig, $form->{"${_}_$i"} );
        }
        for (qw(amount sellprice)) {
            $form->{"${_}_$i"} =
              $form->format_amount( \%myconfig, $form->{"${_}_$i"}, 2 );
        }
    }

    &jcitems;

}

sub jcitems {

    # $locale->text('Customer')
    # $locale->text('Vendor')

    $vc = ucfirst $form->{vc};

    @column_index = qw(id projectnumber name);
    if ( !$form->{summary} ) {
        push @column_index, qw(transdate);
    }
    push @column_index, qw(partnumber description qty amount);

    $column_header{id} = qq|<th>&nbsp;</th>|;
    $column_header{transdate} =
      qq|<th class=listheading>| . $locale->text('Date') . qq|</th>|;
    $column_header{partnumber} =
        qq|<th class=listheading>|
      . $locale->text('Service Code')
      . qq|<br>|
      . $locale->text('Part Number')
      . qq|</th>|;
    $column_header{projectnumber} =
      qq|<th class=listheading>| . $locale->text('Project Number') . qq|</th>|;
    $column_header{description} =
      qq|<th class=listheading>| . $locale->text('Description') . qq|</th>|;
    $column_header{name} = qq|<th class=listheading>$vc</th>|;
    $column_header{qty} =
      qq|<th class=listheading>| . $locale->text('Qty') . qq|</th>|;
    $column_header{amount} =
      qq|<th class=listheading>| . $locale->text('Amount') . qq|</th>|;

    if ( $form->{type} eq 'sales_order' ) {
        $form->{title} = $locale->text('Generate Sales Orders');
    }

    $form->header;

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
        <tr class=listheading>|;

    for (@column_index) { print "\n$column_header{$_}" }

    print qq|
        </tr>
|;

    for $i ( 1 .. $form->{rowcount} ) {

        for (@column_index) {
            $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>|;
        }
        for (qw(qty amount)) {
            $column_data{$_} = qq|<td align=right>$form->{"${_}_$i"}</td>|;
        }

        $checked = ( $form->{"checked_$i"} ) ? "checked" : "";
        $column_data{id} =
qq|<td><input name="checked_$i" class=checkbox type=checkbox value="1" $checked></td>|;

        if ( $form->{"$form->{vc}_id_$i"} ) {
            $column_data{name} = qq|<td>$form->{"$form->{vc}_$i"}</td>|;
            $form->hide_form( "$form->{vc}_id_$i", "$form->{vc}_$i" );
        }
        else {
            $column_data{name} =
qq|<td><input name="ndx_$i" class=checkbox type=checkbox value="1"></td>|;
        }

        for (qw(projectnumber partnumber description notes)) {
            $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
        }
        $form->hide_form( map { "${_}_$i" }
              qw(id project_id parts_id projectnumber transdate partnumber description notes qty amount taxaccounts sellprice)
        );

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
|;

    $form->hide_form(
        qw(path login sessionid vc nextsub rowcount type currency defaultcurrency taxaccounts summary callback)
    );

    for ( split / /, $form->{taxaccounts} ) { $form->hide_form("${_}_rate") }

    if ( $form->{rowcount} ) {
        print qq|
<button class="submit" type="submit" name="action" value="generate_sales_orders">|
          . $locale->text('Generate Sales Orders')
          . qq|</button>|;

        print qq|
<button class="submit" type="submit" name="action" value="select_customer">|
          . $locale->text('Select Customer')
          . qq|</button>|;

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

sub select_customer {

    for ( 1 .. $form->{rowcount} ) {
        last if ( $ok = $form->{"ndx_$_"} );
    }

    $form->error( $locale->text('Nothing selected!') ) unless $ok;

    $label =
      ( $form->{vc} eq 'customer' )
      ? $locale->text('Customer')
      : $locale->text('Vendor');

    $form->header;

    print qq|
<body onLoad="document.forms[0].$form->{vc}.focus()" />

<form method=post action=$form->{script}>

<b>$label</b> <input name=$form->{vc} size=40>

|;

    $form->{nextsub} = "$form->{vc}_selected";
    $form->{action}  = "$form->{vc}_selected";

    $form->hide_form;

    print qq|
<button class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button> 
    
</form>
|;

    print qq|

</body>
</html>
|;

}

sub customer_selected {

    if (
        (
            $rv = $form->get_name( \%myconfig, $form->{vc}, $form->{startdate} )
        ) > 1
      )
    {
        &select_name( $form->{vc} );
        $form->finalize_request();
    }

    if ( $rv == 1 ) {
        $form->{"$form->{vc}"}    = $form->{name_list}[0]->{name};
        $form->{"$form->{vc}_id"} = $form->{name_list}[0]->{id};
    }
    else {
        $msg =
          ( $form->{vc} eq 'customer' )
          ? $locale->text('Customer not on file!')
          : $locale->text('Vendor not on file!');
        $form->error( $locale->text($msg) );
    }

    &display_form;

}

sub sales_order_header {

    for ( 1 .. $form->{rowcount} ) {
        if ( $form->{"ndx_$_"} ) {
            $form->{"$form->{vc}_id_$_"} = $form->{"$form->{vc}_id"};
            $form->{"$form->{vc}_$_"}    = $form->{"$form->{vc}"};
        }
    }

}

sub sales_order_footer { &jcitems }

sub generate_sales_orders {

    for $i ( 1 .. $form->{rowcount} ) {
        $form->error( $locale->text('Customer missing!') )
          if ( $form->{"checked_$i"} && !$form->{"customer_$i"} );
    }

    for $i ( 1 .. $form->{rowcount} ) {
        if ( $form->{"checked_$i"} ) {
            push @{ $form->{order}{qq|$form->{"customer_id_$i"}|} },
              {
                partnumber    => $form->{"partnumber_$i"},
                id            => $form->{"parts_id_$i"},
                description   => $form->{"description_$i"},
                qty           => $form->{"qty_$i"},
                sellprice     => $form->{"sellprice_$i"},
                projectnumber => qq|--$form->{"project_id_$i"}|,
                reqdate       => $form->{"transdate_$i"},
                taxaccounts   => $form->{"taxaccounts_$i"},
                jcitems       => $form->{"id_$i"},
                notes         => $form->{"notes_$i"},
              };
        }
    }

    $order = new Form;
    for ( keys %{ $form->{order} } ) {
        $order->{dbh} = $form->{dbh};

        for (qw(type vc defaultcurrency login)) { $order->{$_} = $form->{$_} }
        for ( split / /, $form->{taxaccounts} ) {
            $order->{"${_}_rate"} = $form->{"${_}_rate"};
        }

        $i = 0;
        $order->{"$order->{vc}_id"} = $_;

        AA->get_name( \%myconfig, \%$order );

        foreach $ref ( @{ $form->{order}{$_} } ) {
            $i++;

            for ( keys %$ref ) { $order->{"${_}_$i"} = $ref->{$_} }

            $taxaccounts = "";
            for ( split / /, $order->{taxaccounts} ) {
                $taxaccounts .= qq|$_ |
                  if ( $_ =~ /$order->{"taxaccounts_$i"}/ );
            }
            $order->{"taxaccounts_$i"} = $taxaccounts;

        }
        $order->{rowcount} = $i;

        for (qw(currency)) { $order->{$_} = $form->{$_} }

        $order->{ordnumber} = $order->update_defaults( \%myconfig, 'sonumber' );
        $order->{transdate} = $order->current_date( \%myconfig );
        $order->{reqdate}   = $order->{transdate};

        for (qw(intnotes employee employee_id)) { delete $order->{$_} }

        PE->timecard_get_currency( \%$order );

        if ( OE->save( \%myconfig, \%$order ) ) {
            if ( !PE->allocate_projectitems( \%myconfig, \%$order ) ) {
                OE->delete( \%myconfig, \%$order,
                    ${LedgerSMB::Sysconfig::spool} );
            }
        }
        else {
            $order->error( $locale->text('Failed to save order!') );
        }

        for ( keys %$order ) { delete $order->{$_} }

    }

    $form->redirect( $locale->text('Orders generated!') );

}

