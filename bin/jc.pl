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
# Job Costing module
#
#======================================================================

use Error qw(:try);

use LedgerSMB::Template;
use LedgerSMB::JC;

1;

# end of main

sub add {

    if ( $form->{type} eq 'timecard' ) {
        $form->{title} = $locale->text('Add Time Card');
    }
    if ( $form->{type} eq 'storescard' ) {
        $form->{title} = $locale->text('Add Stores Card');
    }

    $form->{callback} =
"$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&project=$form->{project}"
      unless $form->{callback};

    &{"prepare_$form->{type}"};

    $form->{orphaned} = 1;
    &display_form;

}

sub edit {

    if ( $form->{type} eq 'timecard' ) {
        $form->{title} = $locale->text('Edit Time Card');
    }
    if ( $form->{type} eq 'storescard' ) {
        $form->{title} = $locale->text('Add Stores Card');
    }

    &{"prepare_$form->{type}"};

    &display_form;

}

sub jcitems_links {

    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option>\n";
        foreach $ref ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$ref->{projectnumber}--$ref->{id}">$ref->{projectnumber} ($ref->{description})</option>\n|;
            if ( $form->{projectnumber} eq "$ref->{projectnumber}--$ref->{id}" )
            {
                $form->{projectdescription} = $ref->{description};
            }
        }
    }
    else {
        if ( $form->{project} eq 'job' ) {
            $form->error( $locale->text('No open Jobs!') );
        }
        else {
            $form->error( $locale->text('No open Projects!') );
        }
    }

    if ( @{ $form->{all_parts} } ) {
        $form->{selectpartnumber} = "<option>\n";
        foreach $ref ( @{ $form->{all_parts} } ) {
            $form->{selectpartnumber} .=
qq|<option value="$ref->{partnumber}--$ref->{id}">$ref->{partnumber}\n|;
            if ( $form->{partnumber} eq "$ref->{partnumber}--$ref->{id}" ) {
                if ( $form->{partnumber} ne $form->{oldpartnumber} ) {
                    for (qw(description unit sellprice pricematrix)) {
                        $form->{$_} = $ref->{$_};
                    }
                }
            }
        }
    }
    else {
        if ( $form->{type} eq 'timecard' ) {
            if ( $form->{project} eq 'job' ) {
                $form->error( $locale->text('No Labor codes on file!') );
            }
            else {
                $form->error( $locale->text('No Services on file!') );
            }
        }
        else {
            $form->error( $locale->text('No Parts on file!') );
        }
    }

    # employees
    if ( @{ $form->{all_employee} } ) {
        $form->{selectemployee} = "<option>\n";
        for ( @{ $form->{all_employee} } ) {
            $form->{selectemployee} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
        }
    }
    else {
        $form->error( $locale->text('No Employees on file!') );
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
	  <th align=right nowrap>| . $locale->text('Startdate') . qq|</th>
	  <td>|
      . $locale->text('From')
      . qq| <input class="date" name=startdatefrom size=11 title="$myconfig{dateformat}">
	  |
      . $locale->text('To')
      . qq| <input class="date" name=startdateto size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
|;

    if ( $form->{type} eq 'timecard' ) {
        $form->{title} = $locale->text('Time Cards');
        JC->jcitems_links( \%myconfig, \%$form );
    }
    if ( $form->{type} eq 'storescard' ) {
        $form->{title} = $locale->text('Stores Cards');
        JC->jcitems_links( \%myconfig, \%$form );
    }

    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option>\n";
        for ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n|;
        }
    }

    if ( @{ $form->{all_parts} } ) {
        $form->{selectpartnumber} = "<option>\n";
        foreach $ref ( @{ $form->{all_parts} } ) {
            $form->{selectpartnumber} .=
qq|<option value="$ref->{partnumber}--$ref->{id}">$ref->{partnumber}\n|;
        }
    }

    if ( $form->{project} eq 'job' ) {
        $joblabel   = $locale->text('Job Number');
        $laborlabel = $locale->text('Labor Code');
    }
    elsif ( $form->{project} eq 'project' ) {
        $joblabel   = $locale->text('Project Number');
        $laborlabel = $locale->text('Service Code');
    }
    else {
        $joblabel   = $locale->text('Project/Job Number');
        $laborlabel = $locale->text('Service/Labor Code');
    }

    if ( $form->{selectprojectnumber} ) {
        $jobnumber = qq|
      <tr>
	<th align=right nowrap>$joblabel</th>
	<td colspan=3><select name=projectnumber>$form->{selectprojectnumber}</select></td>
      </tr>
|;
    }

    if ( $form->{type} eq 'timecard' ) {

        # employees
        if ( @{ $form->{all_employee} } ) {
            $form->{selectemployee} = "<option>\n";
            for ( @{ $form->{all_employee} } ) {
                $form->{selectemployee} .=
                  qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
            }
        }
        else {
            $form->error( $locale->text('No Employees on file!') );
        }

        if ( $form->{selectpartnumber} ) {
            $partnumber = qq|
	<tr>
	  <th align=right nowrap>$laborlabel</th>
	  <td colspan=3><select name=partnumber>$form->{selectpartnumber}</select></td>
        </tr>
|;
        }

        $employee = qq|
	<tr>
	  <th align=right nowrap>| . $locale->text('Employee') . qq|</th>
	  <td colspan=3><select name=employee>$form->{selectemployee}</select></td>
        </tr>
|;

        $l_time =
qq|<td nowrap><input name=l_time class=checkbox type=checkbox value=Y>&nbsp;|
          . $locale->text('Time')
          . qq|</td>|;

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
  <tr valign=top>
    <td>
      <table>
        $jobnumber
	$partnumber
	$employee
	$fromto

	<tr>
	  <th align=right nowrap>| . $locale->text('Include in Report') . qq|</th>
	  <td>
	    <table>
	      <tr>
       		<td nowrap><input name=open class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Open')
      . qq|</td>
		<td nowrap><input name=closed class=checkbox type=checkbox value=Y> |
      . $locale->text('Closed')
      . qq|</td>
	      </tr>
	      <tr>
		$l_time
       		<td nowrap><input name=l_allocated class=checkbox type=checkbox value=Y> |
      . $locale->text('Allocated')
      . qq|</td>
	      </tr>
	      <tr>
	        <td><input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|
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

<input type=hidden name=nextsub value="list_$form->{type}">
<input type=hidden name=sort value="transdate">
|;

    $form->hide_form(qw(db path login sessionid project type));

    print qq|
<br>
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

sub display_form {

    &{"$form->{type}_header"};
    &{"$form->{type}_footer"};

}

sub form_header {

    &{"$form->{type}_header"};

}

sub form_footer {

    &{"form->{type}_footer"};

}

sub prepare_timecard {

    $form->{formname} = "timecard";
    $form->{format}   = "postscript" if $myconfig{printer};
    $form->{media}    = $myconfig{printer};

    JC->get_jcitems( \%myconfig, \%$form );

    $form->{selectformname} =
      qq|<option value="timecard">| . $locale->text('Time Card');

    foreach $item (qw(in out)) {
        ( $form->{"${item}hour"}, $form->{"${item}min"}, $form->{"${item}sec"} )
          = split /:/, $form->{"checked$item"};
        for (qw(hour min sec)) {
            if ( ( $form->{"$item$_"} *= 1 ) > 0 ) {
                $form->{"$item$_"} = substr( qq|0$form->{"$item$_"}|, -2 );
            }
            else {
                $form->{"$item$_"} ||= "";
            }
        }
    }

    $form->{checkedin} =
      $form->{inhour} * 3600 + $form->{inmin} * 60 + $form->{insec};
    $form->{checkedout} =
      $form->{outhour} * 3600 + $form->{outmin} * 60 + $form->{outsec};

    if ( $form->{checkedin} > $form->{checkedout} ) {
        $form->{checkedout} =
          86400 - ( $form->{checkedin} - $form->{checkedout} );
        $form->{checkedin} = 0;
    }

    $form->{clocked} = ( $form->{checkedout} - $form->{checkedin} ) / 3600;
    if ( $form->{clocked} ) {
        $form->{oldnoncharge} = $form->{clocked} - $form->{qty};
    }
    $form->{oldqty} = $form->{qty};

    $form->{noncharge} =
      $form->format_amount( \%myconfig, $form->{clocked} - $form->{qty}, 4 )
      if $form->{checkedin} != $form->{checkedout};
    $form->{clocked} = $form->format_amount( \%myconfig, $form->{clocked}, 4 );

    $form->{amount} = $form->{sellprice} * $form->{qty};
    for (qw(sellprice amount)) {
        $form->{$_} = $form->format_amount( \%myconfig, $form->{$_}, 2 );
    }
    $form->{qty} = $form->format_amount( \%myconfig, $form->{qty}, 4 );
    $form->{allocated} = $form->format_amount( \%myconfig, $form->{allocated} );

    $form->{employee}      .= "--$form->{employee_id}";
    $form->{projectnumber} .= "--$form->{project_id}";
    $form->{partnumber}    .= "--$form->{parts_id}";
    $form->{oldpartnumber} = $form->{partnumber};

    if ( @{ $form->{all_language} } ) {
        $form->{selectlanguage} = "<option>\n";
        for ( @{ $form->{all_language} } ) {
            $form->{selectlanguage} .=
              qq|<option value="$_->{code}">$_->{description}\n|;
        }
    }

    &jcitems_links;

    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );

    $form->{readonly} = 1 if $myconfig{acs} =~ /Production--Add Time Card/;

    if ( $form->{income_accno_id} ) {
        $form->{locked} = 1 if $form->{production} == $form->{completed};
    }

}

sub timecard_header {

    # set option selected
    for (qw(employee projectnumber partnumber)) {
        $form->{"select$_"} =~ s/ selected//;
        $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
    }

    $rows = $form->numtextrows( $form->{description}, 50, 8 );

    for (qw(transdate checkedin checkedout partnumber)) {
        $form->{"old$_"} = $form->{$_};
    }
    for (qw(partnumber description)) {
        $form->{$_} = $form->quote( $form->{$_} );
    }

    if ( $rows > 1 ) {
        $description =
qq|<textarea name=description rows=$rows cols=46 wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input name=description size=48 value="$form->{description}">|;
    }

    if ( $form->{project} eq 'job' ) {

        $projectlabel = $locale->text('Job Number');
        $laborlabel   = $locale->text('Labor Code');
        $rate = qq|<input type=hidden name=sellprice value=$form->{sellprice}>|;

    }
    else {

        if ( $form->{project} eq 'project' ) {
            $projectlabel = $locale->text('Project Number');
            $laborlabel   = $locale->text('Service Code');
        }
        else {
            $projectlabel = $locale->text('Project/Job Number');
            $laborlabel   = $locale->text('Service/Labor Code');
        }

        if ( $myconfig{role} ne 'user' ) {
            $rate = qq|
		<tr>
		  <th align=right nowrap>| . $locale->text('Chargeout Rate') . qq|</th>
		  <td><input name=sellprice value=$form->{sellprice}></td>
		  <th align=right nowrap>| . $locale->text('Total') . qq|</th>
		  <td>$form->{amount}</td>
		</tr>
		<tr>
		  <th align=right nowrap>| . $locale->text('Allocated') . qq|</th>
		  <td><input name=allocated value=$form->{allocated}></td>
		</tr>
|;
        }
        else {
            $rate = qq|
		<tr>
		  <th align=right nowrap>| . $locale->text('Chargeout Rate') . qq|</th>
		  <td>$form->{sellprice}</td>
		  <th align=right nowrap>| . $locale->text('Total') . qq|</th>
		  <td>$form->{amount}</td>
		</tr>
		<tr>
		  <th align=right nowrap>| . $locale->text('Allocated') . qq|</th>
		  <td>$form->{allocated}</td>
		</tr>
		<input type=hidden name=sellprice value=$form->{sellprice}>
		<input type=hidden name=allocated value=$form->{allocated}>
|;
        }
    }

    if ( $myconfig{role} eq 'user' ) {
        $charge =
          qq|<input type=hidden name=qty value=$form->{qty}>$form->{qty}|;
    }
    else {
        $charge = qq|<input name=qty value=$form->{qty}>|;
    }

    if ( ( $rows = $form->numtextrows( $form->{notes}, 40, 6 ) ) < 2 ) {
        $rows = 2;
    }

    $notes = qq|<tr>
		<th align=right>| . $locale->text('Notes') . qq|</th>
                  <td colspan=3><textarea name="notes" rows=$rows cols=46 wrap=soft>$form->{notes}</textarea>
		</td>
	      </tr>
|;

##################
    ( $null, $form->{oldproject_id} ) = split /--/, $form->{projectnumber};

    $form->header;

    print qq|
<body>

<form method=post action="$form->{script}">
|;

    $form->hide_form(
        qw(id type media format printed queued title closedto locked oldtransdate oldcheckedin oldcheckedout oldpartnumber project oldqty oldnoncharge pricematrix oldproject_id)
    );

    print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>| . $locale->text('Employee') . qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
	      </tr>
	      <tr>
		<th align=right nowrap>$projectlabel</th>
		<td><select name=projectnumber>$form->{selectprojectnumber}</select>
		</td>
		<td></td>
		<td>$form->{projectdescription}</td>
		<input type=hidden name=projectdescription value="|
      . $form->quote( $form->{projectdescription} ) . qq|">
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Date worked') . qq|</th>
		<td><input class="date" name=transdate size=11 title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>$laborlabel</th>
		<td><select name=partnumber>$form->{selectpartnumber}</select></td>
	      </tr>
	      <tr valign=top>
		<th align=right nowrap>| . $locale->text('Description') . qq|</th>
		<td colspan=3>$description</td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Time In') . qq|</th>
		<td>
		  <table>
		    <tr>
		      <td><input name=inhour title="hh" size=3 maxlength=2 value=$form->{inhour}></td>
		      <td><input name=inmin title="mm" size=3 maxlength=2 value=$form->{inmin}></td>
		      <td><input name=insec title="ss" size=3 maxlength=2 value=$form->{insec}></td>
		    </tr>
		  </table>
		</td>
		<th align=right nowrap>| . $locale->text('Time Out') . qq|</th>
		<td>
		  <table>
		    <tr>
		      <td><input name=outhour title="hh" size=3 maxlength=2 value=$form->{outhour}></td>
		      <td><input name=outmin title="mm" size=3 maxlength=2 value=$form->{outmin}></td>
		      <td><input name=outsec title="ss" size=3 maxlength=2 value=$form->{outsec}></td>
		    </tr>
		  </table>
		</td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Clocked') . qq|</th>
		<td>$form->{clocked}</td>
              </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Non-chargeable') . qq|</th>
		<td><input name=noncharge value=$form->{noncharge}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Chargeable') . qq|</th>
		<td>$charge</td>
	      </tr>
	      $rate
	      $notes
	    </table>
	  </td>
	</tr>

|;

}

sub timecard_footer {

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

    &print_options;

    print qq|
    </td>
  </tr>
</table>
<br>
|;

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    if ( !$form->{readonly} ) {

        # type=submit $locale->text('Update')
        # type=submit $locale->text('Print')
        # type=submit $locale->text('Save')
        # type=submit $locale->text('Print and Save')
        # type=submit $locale->text('Save as new')
        # type=submit $locale->text('Print and Save as new')
        # type=submit $locale->text('Delete')

        %button = (
            'update' =>
              { ndx => 1, key => 'U', value => $locale->text('Update') },
            'print' =>
              { ndx => 2, key => 'P', value => $locale->text('Print') },
            'save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
            'print_and_save' => {
                ndx   => 6,
                key   => 'R',
                value => $locale->text('Print and Save')
            },
            'save_as_new' =>
              { ndx => 7, key => 'N', value => $locale->text('Save as new') },
            'print_and_save_as_new' => {
                ndx   => 8,
                key   => 'W',
                value => $locale->text('Print and Save as new')
            },

            'delete' =>
              { ndx => 16, key => 'D', value => $locale->text('Delete') },
        );

        %a = ();

        if ( $form->{id} ) {

            if ( !$form->{locked} ) {
                for ( 'update', 'print', 'save', 'save_as_new' ) { $a{$_} = 1 }

                if ( ${LedgerSMB::Sysconfig::latex} ) {
                    for ( 'print_and_save', 'print_and_save_as_new' ) {
                        $a{$_} = 1;
                    }
                }

                if ( $form->{orphaned} ) {
                    $a{'delete'} = 1;
                }

            }

        }
        else {

            if ( $transdate > $closedto ) {

                for ( 'update', 'print', 'save' ) { $a{$_} = 1 }

                if ( ${LedgerSMB::Sysconfig::latex} ) {
                    $a{'print_and_save'} = 1;
                }

            }
        }
    }

    for ( keys %button ) { delete $button{$_} if !$a{$_} }
    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        $form->print_button( \%button, $_ );
    }

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    $form->hide_form(qw(callback path login sessionid));

    print qq|

</form>

</body>
</html>
|;

}

sub prepare_storescard {

    $form->{formname} = "storescard";
    $form->{format}   = "postscript" if $myconfig{printer};
    $form->{media}    = $myconfig{printer};

    JC->get_jcitems( \%myconfig, \%$form );

    $form->{selectformname} =
      qq|<option value="storescard">| . $locale->text('Stores Card');

    $form->{amount} = $form->{sellprice} * $form->{qty};
    for (qw(sellprice amount)) {
        $form->{$_} = $form->format_amount( \%myconfig, $form->{$_}, 2 );
    }
    $form->{qty} = $form->format_amount( \%myconfig, $form->{qty}, 4 );

    $form->{employee}      .= "--$form->{employee_id}";
    $form->{projectnumber} .= "--$form->{project_id}";
    $form->{partnumber}    .= "--$form->{parts_id}";
    $form->{oldpartnumber} = $form->{partnumber};

    if ( @{ $form->{all_language} } ) {
        $form->{selectlanguage} = "<option>\n";
        for ( @{ $form->{all_language} } ) {
            $form->{selectlanguage} .=
              qq|<option value="$_->{code}">$_->{description}\n|;
        }
    }

    &jcitems_links;

    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );

    $form->{readonly} = 1 if $myconfig{acs} =~ /Production--Add Time Card/;

    if ( $form->{income_accno_id} ) {
        $form->{locked} = 1 if $form->{production} == $form->{completed};
    }

}

sub storescard_header {

    # set option selected
    for (qw(employee projectnumber partnumber)) {
        $form->{"select$_"} =~ s/ selected//;
        $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
    }

    $rows = $form->numtextrows( $form->{description}, 50, 8 );

    for (qw(transdate partnumber)) { $form->{"old$_"} = $form->{$_} }
    for (qw(partnumber description)) {
        $form->{$_} = $form->quote( $form->{$_} );
    }

    if ( $rows > 1 ) {
        $description =
qq|<textarea name=description rows=$rows cols=46 wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input name=description size=48 value="$form->{description}">|;
    }

    $form->header;

    print qq|
<body>

<form method=post action="$form->{script}">
|;

    $form->hide_form(
        qw(id type media format printed queued title closedto locked oldtransdate oldpartnumber project)
    );

    print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>| . $locale->text('Job Number') . qq|</th>
		<td><select name=projectnumber>$form->{selectprojectnumber}</select>
		</td>
		<td>$form->{projectdescription}</td>
		<input type=hidden name=projectdescription value="|
      . $form->quote( $form->{projectdescription} ) . qq|">
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Date') . qq|</th>
		<td><input class="date" name=transdate size=11 title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Part Number') . qq|</th>
		<td><select name=partnumber>$form->{selectpartnumber}</td>
	      </tr>
	      <tr valign=top>
		<th align=right nowrap>| . $locale->text('Description') . qq|</th>
		<td>$description</td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Qty') . qq|</th>
		<td><input name=qty size=6 value=$form->{qty}>
		<b>| . $locale->text('Cost') . qq|</b>
		<input name=sellprice size=10 value=$form->{sellprice}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Total') . qq|</th>
		<td>$form->{amount}</td>
	      </tr>
	    </table>
	  </td>
	</tr>

|;

}

sub storescard_footer {

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

    &print_options;

    print qq|
    </td>
  </tr>
</table>
<br>
|;

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Print')
    # type=submit $locale->text('Save')
    # type=submit $locale->text('Print and Save')
    # type=submit $locale->text('Save as new')
    # type=submit $locale->text('Print and Save as new')
    # type=submit $locale->text('Delete')

    if ( !$form->{readonly} ) {

        %button = (
            'update' =>
              { ndx => 1, key => 'U', value => $locale->text('Update') },
            'print' =>
              { ndx => 2, key => 'P', value => $locale->text('Print') },
            'save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
            'print_and_save' => {
                ndx   => 6,
                key   => 'R',
                value => $locale->text('Print and Save')
            },
            'save_as_new' =>
              { ndx => 7, key => 'N', value => $locale->text('Save as new') },
            'print_and_save_as_new' => {
                ndx   => 8,
                key   => 'W',
                value => $locale->text('Print and Save as new')
            },
            'delete' =>
              { ndx => 16, key => 'D', value => $locale->text('Delete') },
        );

        %a = ();

        if ( $form->{id} ) {

            if ( !$form->{locked} ) {
                for ( 'update', 'print', 'save', 'save_as_new' ) { $a{$_} = 1 }
                if ( ${LedgerSMB::Sysconfig::latex} ) {
                    for ( 'print_and_save', 'print_and_save_as_new' ) {
                        $a{$_} = 1;
                    }
                }
                if ( $form->{orphaned} ) {
                    $a{'delete'} = 1;
                }
            }

        }
        else {

            if ( $transdate > $closedto ) {
                for ( 'update', 'print', 'save' ) { $a{$_} = 1 }

                if ( ${LedgerSMB::Sysconfig::latex} ) {
                    $a{'print_and_save'} = 1;
                }
            }
        }

        for ( keys %button ) { delete $button{$_} if !$a{$_} }
        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            $form->print_button( \%button, $_ );
        }

    }

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    $form->hide_form(qw(callback path login sessionid));

    print qq|

</form>

</body>
</html>
|;

}

sub update {

    ( $null, $form->{project_id} ) = split /--/, $form->{projectnumber};

    # check labor/part
    JC->jcitems_links( \%myconfig, \%$form );

    &jcitems_links;

    $checkmatrix = 1 if $form->{oldproject_id} != $form->{project_id};

    if ( $form->{type} eq 'timecard' ) {

        # time clocked
        %hour = ( in => 0, out => 0 );
        for $t (qw(in out)) {
            if ( $form->{"${t}sec"} > 60 ) {
                $form->{"${t}sec"} -= 60;
                $form->{"${t}min"}++;
            }
            if ( $form->{"${t}min"} > 60 ) {
                $form->{"${t}min"} -= 60;
                $form->{"${t}hour"}++;
            }
            $hour{$t} = $form->{"${t}hour"};
        }

        $form->{checkedin} =
          $hour{in} * 3600 + $form->{inmin} * 60 + $form->{insec};
        $form->{checkedout} =
          $hour{out} * 3600 + $form->{outmin} * 60 + $form->{outsec};

        if ( $form->{checkedin} > $form->{checkedout} ) {
            $form->{checkedout} =
              86400 - ( $form->{checkedin} - $form->{checkedout} );
            $form->{checkedin} = 0;
        }

        $form->{clocked} = ( $form->{checkedout} - $form->{checkedin} ) / 3600;

        for (qw(sellprice qty noncharge allocated)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        $checkmatrix = 1 if $form->{oldqty} != $form->{qty};

        if (   ( $form->{oldcheckedin} != $form->{checkedin} )
            || ( $form->{oldcheckedout} != $form->{checkedout} ) )
        {
            $checkmatrix = 1;
            $form->{oldqty} = $form->{qty} =
              $form->{clocked} - $form->{noncharge};
            $form->{oldnoncharge} = $form->{noncharge};
        }

        if ( ( $form->{qty} != $form->{oldqty} ) && $form->{clocked} ) {
            $form->{oldnoncharge} = $form->{noncharge} =
              $form->{clocked} - $form->{qty};
            $checkmatrix = 1;
        }

        if ( ( $form->{oldnoncharge} != $form->{noncharge} )
            && $form->{clocked} )
        {
            $form->{oldqty} = $form->{qty} =
              $form->{clocked} - $form->{noncharge};
            $checkmatrix = 1;
        }

        if ($checkmatrix) {
            @a = split / /, $form->{pricematrix};
            if ( scalar @a > 2 ) {
                for (@a) {
                    ( $q, $p ) = split /:/, $_;
                    if ( ( $p * 1 ) && ( $form->{qty} >= ( $q * 1 ) ) ) {
                        $form->{sellprice} = $p;
                    }
                }
            }
        }

        $form->{amount} = $form->{sellprice} * $form->{qty};

        $form->{clocked} =
          $form->format_amount( \%myconfig, $form->{clocked}, 4 );
        for (qw(sellprice amount)) {
            $form->{$_} = $form->format_amount( \%myconfig, $form->{$_}, 2 );
        }
        for (qw(qty noncharge)) {
            $form->{"old$_"} = $form->{$_};
            $form->{$_} = $form->format_amount( \%myconfig, $form->{$_}, 4 );
        }

    }
    else {

        for (qw(sellprice qty allocated)) {
            $form->{$_} = $form->parse_amount( \%myconfig, $form->{$_} );
        }

        if ( $form->{oldqty} != $form->{qty} ) {
            @a = split / /, $form->{pricematrix};
            if ( scalar @a > 2 ) {
                for (@a) {
                    ( $q, $p ) = split /:/, $_;
                    if ( ( $p * 1 ) && ( $form->{qty} >= ( $q * 1 ) ) ) {
                        $form->{sellprice} = $p;
                    }
                }
            }
        }

        $form->{amount} = $form->{sellprice} * $form->{qty};
        for (qw(sellprice amount)) {
            $form->{$_} = $form->format_amount( \%myconfig, $form->{$_}, 2 );
        }

    }

    $form->{allocated} = $form->format_amount( \%myconfig, $form->{allocated} );

    &display_form;

}

sub save {

    $form->isblank( "transdate", $locale->text('Date missing!') );

    if ( $form->{project} eq 'project' ) {
        $form->isblank( "projectnumber",
            $locale->text('Project Number missing!') );
        $form->isblank( "partnumber", $locale->text('Service Code missing!') );
    }
    else {
        $form->isblank( "projectnumber", $locale->text('Job Number missing!') );
        $form->isblank( "partnumber",    $locale->text('Labor Code missing!') );
    }

    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );
    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    $msg =
      ( $form->{type} eq 'timecard' )
      ? $locale->text('Cannot save time card for a closed period!')
      : $locale->text('Cannot save stores card for a closed period!');
    $form->error($msg) if ( $transdate <= $closedto );

    if ( !$form->{resave} ) {
        if ( $form->{id} ) {
            &resave;
            $form->finalize_request();
        }
    }

    $rc = JC->save( \%myconfig, \%$form );

    if ( $form->{type} eq 'timecard' ) {
        $form->error(
            $locale->text('Cannot change time card for a completed job!') )
          if ( $rc == -1 );
        $form->error(
            $locale->text('Cannot add time card for a completed job!') )
          if ( $rc == -2 );

        if ($rc) {
            $form->redirect( $locale->text('Time Card saved!') );
        }
        else {
            $form->error( $locale->text('Cannot save time card!') );
        }

    }
    else {
        $form->error(
            $locale->text('Cannot change stores card for a completed job!') )
          if ( $rc == -1 );
        $form->error(
            $locale->text('Cannot add stores card for a completed job!') )
          if ( $rc == -2 );

        if ($rc) {
            $form->redirect( $locale->text('Stores Card saved!') );
        }
        else {
            $form->error( $locale->text('Cannot save stores card!') );
        }
    }

}

sub save_as_new {

    delete $form->{id};
    &save;

}

sub print_and_save_as_new {

    delete $form->{id};
    &print_and_save;

}

sub resave {

    my %hiddens;
    my @buttons;
    if ( $form->{print_and_save} ) {
        $form->{nextsub} = "print_and_save";
        @buttons = ({
            name => 'action',
            value => 'print_and_save',
            text => $locale->text('Print and Save Transaction'),
            });
        $msg =
          $locale->text('You are printing and saving an existing transaction!');
    }
    else {
        $form->{nextsub} = "save";
        @buttons = ({
            name => 'action',
            value => 'save',
            text => $locale->text('Save Transaction'),
            });
        $msg = $locale->text('You are saving an existing transaction!');
    }

    delete $form->{action};
    $hiddens{$_} = $form->{$_} foreach keys %$form;
    $hiddens{resave} = 1;
    $form->{title} = $locale->text('Warning!');
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'form-confirmation');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
        query => $msg,
    });
}

sub print_and_save {

    $form->error( $locale->text('Select postscript or PDF!') )
      if $form->{format} !~ /(postscript|pdf)/;
    $form->error( $locale->text('Select a Printer!') )
      if $form->{media} eq 'screen';

    if ( !$form->{resave} ) {
        if ( $form->{id} ) {
            $form->{print_and_save} = 1;
            &resave;
            $form->finalize_request();
        }
    }

    $old_form = new Form;
    $form->{display_form} = "save";
    for ( keys %$form ) { $old_form->{$_} = $form->{$_} }

    &{"print_$form->{formname}"}($old_form);

}

sub delete_timecard {

    my $employee = $form->{employee};
    $employee =~ s/--.*//g;
    my $projectnumber = $form->{projectnumber};
    $projectnumber =~ s/--.*//g;

    delete $form->{action};
    $form->{title} = $locale->text('Confirm!');

    my %hiddens;
    $hiddens{$_} = $form->{$_} foreach keys %$form;
    my @buttons = ({
        name => 'action',
        value => 'yes_delete_timecard',
        text => $locale->text('Delete Timecard'),
        });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale,
        template => 'form-confirmation');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
        query => $locale->text(
            'Are you sure you want to delete time card for [_1] [_2] [_3]',
            $form->{transdate},
            $employee,
            $projectnumber),
    });
}

sub delete { &{"delete_$form->{type}"} }
sub yes    { &{"yes_delete_$form->{type}"} }

sub yes_delete_timecard {

    if ( JC->delete_timecard( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Time Card deleted!') );
    }
    else {
        $form->error( $locale->text('Cannot delete time card!') );
    }

}

sub list_timecard {

    $form->{type} = "timecard";

    JC->jcitems( \%myconfig, \%$form );

    $form->{title} = $locale->text('Time Cards');

    @a =
      qw(type direction oldsort path login sessionid project l_subtotal open closed l_time l_allocated);
    $href = "$form->{script}?action=list_timecard";
    for (@a) { $href .= "&$_=$form->{$_}" }

    $href .= "&title=" . $form->escape( $form->{title} );

    $form->sort_order();

    $callback = "$form->{script}?action=list_timecard";
    for (@a) { $callback .= "&$_=$form->{$_}" }

    $callback .= "&title=" . $form->escape( $form->{title}, 1 );

    @column_index =
      (qw(transdate projectnumber projectdescription id partnumber description)
      );

    push @column_index, (qw(allocated)) if $form->{l_allocated};
    push @column_index, (qw(1 2 3 4 5 6 7));

    @column_index = $form->sort_columns(@column_index);

    if ( $form->{project} eq 'job' ) {
        $joblabel   = $locale->text('Job Number');
        $laborlabel = $locale->text('Labor Code');
        $desclabel  = $locale->text('Job Name');
    }
    elsif ( $form->{project} eq 'project' ) {
        $joblabel   = $locale->text('Project Number');
        $laborlabel = $locale->text('Service Code');
        $desclabel  = $locale->text('Project Name');
    }
    else {
        $joblabel   = $locale->text('Project/Job Number');
        $laborlabel = $locale->text('Service/Labor Code');
        $desclabel  = $locale->text('Project/Job Name');
    }

    if ( $form->{projectnumber} ) {
        $callback .=
          "&projectnumber=" . $form->escape( $form->{projectnumber}, 1 );
        $href .= "&projectnumber=" . $form->escape( $form->{projectnumber} );
        ($var) = split /--/, $form->{projectnumber};
        $option .= "\n<br>" if ($option);
        $option .= "$joblabel : $var";
        @column_index = grep !/projectnumber/, @column_index;
    }
    if ( $form->{partnumber} ) {
        $callback .= "&partnumber=" . $form->escape( $form->{partnumber}, 1 );
        $href .= "&partnumber=" . $form->escape( $form->{partnumber} );
        ($var) = split /--/, $form->{partnumber};
        $option .= "\n<br>" if ($option);
        $option .= "$laborlabel : $var";
        @column_index = grep !/partnumber/, @column_index;
    }
    if ( $form->{employee} ) {
        $callback .= "&employee=" . $form->escape( $form->{employee}, 1 );
        $href .= "&employee=" . $form->escape( $form->{employee} );
    }

    if ( $form->{startdatefrom} ) {
        $callback .= "&startdatefrom=$form->{startdatefrom}";
        $href     .= "&startdatefrom=$form->{startdatefrom}";
        $option   .= "\n<br>" if ($option);
        $option .=
            $locale->text('From') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{startdatefrom}, 1 );
    }
    if ( $form->{startdateto} ) {
        $callback .= "&startdateto=$form->{startdateto}";
        $href     .= "&startdateto=$form->{startdateto}";
        $option   .= "\n<br>" if ($option);
        $option .=
            $locale->text('To') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{startdateto}, 1 );
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

    %weekday = (
        1 => $locale->text('Sunday'),
        2 => $locale->text('Monday'),
        3 => $locale->text('Tuesday'),
        4 => $locale->text('Wednesday'),
        5 => $locale->text('Thursday'),
        6 => $locale->text('Friday'),
        7 => $locale->text('Saturday'),
    );

    for ( keys %weekday ) {
        $column_header{$_} =
          "<th class=listheading width=25>"
          . substr( $weekday{$_}, 0, 3 ) . "</th>";
    }

    $column_header{id} =
        "<th><a class=listheading href=$href&sort=id>"
      . $locale->text('ID')
      . "</a></th>";
    $column_header{transdate} =
        "<th><a class=listheading href=$href&sort=transdate>"
      . $locale->text('Date')
      . "</a></th>";
    $column_header{description} =
      "<th><a class=listheading href=$href&sort=description>"
      . $locale->text('Description') . "</th>";
    $column_header{projectnumber} =
"<th><a class=listheading href=$href&sort=projectnumber>$joblabel</a></th>";
    $column_header{partnumber} =
"<th><a class=listheading href=$href&sort=partnumber>$laborlabel</a></th>";
    $column_header{projectdescription} =
"<th><a class=listheading href=$href&sort=projectdescription>$desclabel</a></th>";
    $column_header{allocated} = "<th class=listheading></th>";

    $form->header;

    if ( @{ $form->{transactions} } ) {
        $sameitem           = $form->{transactions}->[0]->{ $form->{sort} };
        $sameemployeenumber = $form->{transactions}->[0]->{employeenumber};
        $employee           = $form->{transactions}->[0]->{employee};
        $sameweek           = $form->{transactions}->[0]->{workweek};
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
	<tr>
	  <th colspan=2 align=left>
	    $employee
	  </th>
	  <th align=left>
	    $sameemployeenumber
	  </th>
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

    %total = ();

    foreach $ref ( @{ $form->{transactions} } ) {

        if ( $sameemployeenumber ne $ref->{employeenumber} ) {
            $sameemployeenumber = $ref->{employeenumber};
            $sameweek           = $ref->{workweek};

            if ( $form->{l_subtotal} ) {
                print qq|
        <tr class=listsubtotal>
|;

                for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

                $weektotal = 0;
                for ( keys %weekday ) {
                    $column_data{$_} = "<th class=listsubtotal align=right>"
                      . $form->format_amount( \%myconfig, $subtotal{$_}, "",
                        "&nbsp;" )
                      . "</th>";
                    $weektotal += $subtotal{$_};
                    $subtotal{$_} = 0;
                }

                $column_data{ $form->{sort} } =
                    "<th class=listsubtotal align=right>"
                  . $form->format_amount( \%myconfig, $weektotal, "", "&nbsp;" )
                  . "</th>";

                for (@column_index) { print "\n$column_data{$_}" }
            }

            # print total
            print qq|
        <tr class=listtotal>
|;

            for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

            $total = 0;
            for ( keys %weekday ) {
                $column_data{$_} =
                    "<th class=listtotal align=right>"
                  . $form->format_amount( \%myconfig, $total{$_}, "", "&nbsp;" )
                  . "</th>";
                $total += $total{$_};
                $total{$_} = 0;
            }

            $column_data{ $form->{sort} } =
                "<th class=listtotal align=right>"
              . $form->format_amount( \%myconfig, $total, "", "&nbsp;" )
              . "</th>";

            for (@column_index) { print "\n$column_data{$_}" }

            print qq|
	<tr height=30 valign=bottom>
	  <th colspan=2 align=left>
	    $ref->{employee}
	  </th>
	  <th align=left>
	    $ref->{employeenumber}
	  </th>
        <tr class=listheading>
|;

            for (@column_index) { print "\n$column_header{$_}" }

            print qq|
        </tr>
|;

        }

        if ( $form->{l_subtotal} ) {
            if ( $ref->{workweek} != $sameweek ) {
                for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
                $weektotal = 0;
                for ( keys %weekday ) {
                    $column_data{$_} = "<th class=listsubtotal align=right>"
                      . $form->format_amount( \%myconfig, $subtotal{$_}, "",
                        "&nbsp;" )
                      . "</th>";
                    $weektotal += $subtotal{$_};
                    $subtotal{$_} = 0;
                }
                $column_data{ $form->{sort} } =
                    "<th class=listsubtotal align=right>"
                  . $form->format_amount( \%myconfig, $weektotal, "", "&nbsp;" )
                  . "</th>";
                $sameweek = $ref->{workweek};

                print qq|
        <tr class=listsubtotal>
|;

                for (@column_index) { print "\n$column_data{$_}" }

                print qq|
        </tr>
|;
            }
        }

        for (@column_index)   { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
        for ( keys %weekday ) { $column_data{$_} = "<td>&nbsp;</td>" }

        $column_data{allocated} =
            "<td align=right>"
          . $form->format_amount( \%myconfig, $ref->{allocated}, "", "&nbsp;" )
          . "</td>";
        $column_data{ $ref->{weekday} } =
          "<td align=right>"
          . $form->format_amount( \%myconfig, $ref->{qty}, "", "&nbsp;" );

        if ( $form->{l_time} ) {
            $column_data{ $ref->{weekday} } .=
              "<br>$ref->{checkedin}<br>$ref->{checkedout}";
        }
        $column_data{ $ref->{weekday} } .= "</td>";

        $column_data{id} =
"<td><a href=$form->{script}?action=edit&id=$ref->{id}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&project=$form->{project}&callback=$callback>$ref->{id}</a></td>";

        $subtotal{ $ref->{weekday} } += $ref->{qty};
        $total{ $ref->{weekday} }    += $ref->{qty};

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

    # print last subtotal
    if ( $form->{l_subtotal} ) {
        print qq|
        <tr class=listsubtotal>
|;

        for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

        $weektotal = 0;
        for ( keys %weekday ) {
            $column_data{$_} =
                "<th class=listsubtotal align=right>"
              . $form->format_amount( \%myconfig, $subtotal{$_}, "", "&nbsp;" )
              . "</th>";
            $weektotal += $subtotal{$_};
        }

        $column_data{ $form->{sort} } =
            "<th class=listsubtotal align=right>"
          . $form->format_amount( \%myconfig, $weektotal, "", "&nbsp;" )
          . "</th>";

        for (@column_index) { print "\n$column_data{$_}" }
    }

    # print last total
    print qq|
        <tr class=listtotal>
|;

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $total = 0;
    for ( keys %weekday ) {
        $column_data{$_} =
            "<th class=listtotal align=right>"
          . $form->format_amount( \%myconfig, $total{$_}, "", "&nbsp;" )
          . "</th>";
        $total += $total{$_};
        $total{$_} = 0;
    }

    $column_data{ $form->{sort} } =
      "<th class=listtotal align=right>"
      . $form->format_amount( \%myconfig, $total, "", "&nbsp;" ) . "</th>";

    for (@column_index) { print "\n$column_data{$_}" }

    if ( $form->{project} eq 'job' ) {
        if ( $myconfig{acs} !~ /Production--Production/ ) {
            $i = 1;
            $button{'Production--Add Time Card'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_time_card">|
              . $locale->text('Add Time Card')
              . qq|</button> |;
            $button{'Production--Add Time Card'}{order} = $i++;
        }
    }
    elsif ( $form->{project} eq 'project' ) {
        if ( $myconfig{acs} !~ /Projects--Projects/ ) {
            $i = 1;
            $button{'Projects--Add Time Card'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_time_card">|
              . $locale->text('Add Time Card')
              . qq|</button> |;
            $button{'Projects--Add Time Card'}{order} = $i++;
        }
    }
    else {
        if ( $myconfig{acs} !~ /Time Cards--Time Cards/ ) {
            $i = 1;
            $button{'Time Cards--Add Time Card'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_time_card">|
              . $locale->text('Add Time Card')
              . qq|</button> |;
            $button{'Time Cards--Add Time Card'}{order} = $i++;
        }
    }

    for ( split /;/, $myconfig{acs} ) { delete $button{$_} }

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

    $form->hide_form(qw(callback path login sessionid project));

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

sub list_storescard {

    $form->{type} = "storescard";

    JC->jcitems( \%myconfig, \%$form );

    $form->{title} = $locale->text('Stores Cards');

    $href = "$form->{script}?action=list_storescard";
    for (qw(type direction oldsort path login sessionid project)) {
        $href .= "&$_=$form->{$_}";
    }

    $href .= "&title=" . $form->escape( $form->{title} );

    $form->sort_order();

    $callback = "$form->{script}?action=list_storescard";
    for (qw(type direction oldsort path login sessionid project)) {
        $callback .= "&$_=$form->{$_}";
    }

    $callback .= "&title=" . $form->escape( $form->{title}, 1 );

    @column_index =
      $form->sort_columns(
        qw(transdate projectnumber projectdescription id partnumber description qty amount)
      );

    if ( $form->{projectnumber} ) {
        $callback .=
          "&projectnumber=" . $form->escape( $form->{projectnumber}, 1 );
        $href .= "&projectnumber=" . $form->escape( $form->{projectnumber} );
        ($var) = split /--/, $form->{projectnumber};
        $option .= "\n<br>" if ($option);
        $option .= "$joblabel : $var";
        @column_index = grep !/projectnumber/, @column_index;
    }
    if ( $form->{partnumber} ) {
        $callback .= "&partnumber=" . $form->escape( $form->{partnumber}, 1 );
        $href .= "&partnumber=" . $form->escape( $form->{partnumber} );
        ($var) = split /--/, $form->{partnumber};
        $option .= "\n<br>" if ($option);
        $option .= "$laborlabel : $var";
        @column_index = grep !/partnumber/, @column_index;
    }
    if ( $form->{startdatefrom} ) {
        $callback .= "&startdatefrom=$form->{startdatefrom}";
        $href     .= "&startdatefrom=$form->{startdatefrom}";
        $option   .= "\n<br>" if ($option);
        $option .=
            $locale->text('From') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{startdatefrom}, 1 );
    }
    if ( $form->{startdateto} ) {
        $callback .= "&startdateto=$form->{startdateto}";
        $href     .= "&startdateto=$form->{startdateto}";
        $option   .= "\n<br>" if ($option);
        $option .=
            $locale->text('To') . "&nbsp;"
          . $locale->date( \%myconfig, $form->{startdateto}, 1 );
    }

    $column_header{id} =
        "<th><a class=listheading href=$href&sort=id>"
      . $locale->text('ID')
      . "</a></th>";
    $column_header{transdate} =
        "<th><a class=listheading href=$href&sort=transdate>"
      . $locale->text('Date')
      . "</a></th>";
    $column_header{projectnumber} =
        "<th><a class=listheading href=$href&sort=projectnumber>"
      . $locale->text('Job Number')
      . "</a></th>";
    $column_header{projectdescription} =
        "<th><a class=listheading href=$href&sort=projectdescription>"
      . $locale->text('Job Description')
      . "</a></th>";
    $column_header{partnumber} =
        "<th><a class=listheading href=$href&sort=partnumber>"
      . $locale->text('Part Number')
      . "</a></th>";
    $column_header{description} =
        "<th><a class=listheading href=$href&sort=description>"
      . $locale->text('Description')
      . "</a></th>";
    $column_header{qty} =
      "<th class=listheading>" . $locale->text('Qty') . "</th>";
    $column_header{amount} =
      "<th class=listheading>" . $locale->text('Amount') . "</th>";

    $form->header;

    if ( @{ $form->{transactions} } ) {
        $sameitem = $form->{transactions}->[0]->{ $form->{sort} };
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

    $total = 0;
    foreach $ref ( @{ $form->{transactions} } ) {

        for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
        $column_data{qty} =
            qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{qty}, "", "&nbsp;" )
          . "</td>";
        $column_data{amount} =
          qq|<td align=right>|
          . $form->format_amount( \%myconfig, $ref->{qty} * $ref->{sellprice},
            2 )
          . "</td>";

        $column_data{id} =
"<td><a href=$form->{script}?action=edit&id=$ref->{id}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&project=$form->{project}&callback=$callback>$ref->{id}</a></td>";

        $total += ( $ref->{qty} * $ref->{sellprice} );

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

    # print total
    print qq|
        <tr class=listtotal>
|;

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
    $column_data{amount} =
      qq|<th align=right>|
      . $form->format_amount( \%myconfig, $total, 2 ) . "</th";

    for (@column_index) { print "\n$column_data{$_}" }

    if ( $form->{project} eq 'job' ) {
        if ( $myconfig{acs} !~ /Production--Production/ ) {
            $i = 1;
            $button{'Production--Add Stores Card'}{code} =
qq|<button class="submit" type="submit" name="action" value="add_stores_card">|
              . $locale->text('Add Stores Card')
              . qq|</button> |;
            $button{'Production--Add Stores Card'}{order} = $i++;
        }
    }

    for ( split /;/, $myconfig{acs} ) { delete $button{$_} }

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

    $form->hide_form(qw(callback path login sessionid project));

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

sub continue { &{ $form->{nextsub} } }

sub add_time_card {

    $form->{type} = "timecard";
    &add;

}

sub add_stores_card {

    $form->{type} = "storescard";
    &add;

}

sub print_options {

    if ( $form->{selectlanguage} ) {
        $form->{"selectlanguage"} =
          $form->unescape( $form->{"selectlanguage"} );
        $form->{"selectlanguage"} =~ s/ selected//;
        $form->{"selectlanguage"} =~
          s/(<option value="\Q$form->{language_code}\E")/$1 selected/;
        $lang = qq|<select name=language_code>$form->{selectlanguage}</select>
    <input type=hidden name=selectlanguage value="|
          . $form->escape( $form->{selectlanguage}, 1 ) . qq|">|;
    }

    $form->{selectformname} = $form->unescape( $form->{selectformname} );
    $form->{selectformname} =~ s/ selected//;
    $form->{selectformname} =~
      s/(<option value="\Q$form->{formname}\E")/$1 selected/;

    $type = qq|<select name=formname>$form->{selectformname}</select>
  <input type=hidden name=selectformname value="|
      . $form->escape( $form->{selectformname}, 1 ) . qq|">|;

    $media = qq|<select name=media>
          <option value="screen">| . $locale->text('Screen');

    $form->{selectformat} = qq|<option value="html">html\n|;

    if ( %{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex} ) {
        for ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
            $media .= qq| 
          <option value="$_">$_|;
        }
    }

    if ( ${LedgerSMB::Sysconfig::latex} ) {
        $media .= qq|
          <option value="queue">| . $locale->text('Queue');

        $form->{selectformat} .= qq|
            <option value="postscript">| . $locale->text('Postscript') . qq|
	    <option value="pdf">| . $locale->text('PDF');
    }

    $format = qq|<select name=format>$form->{selectformat}</select>|;
    $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;
    $format .= qq|
  <input type=hidden name=selectformat value="|
      . $form->escape( $form->{selectformat}, 1 ) . qq|">|;
    $media .= qq|</select>|;
    $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

    print qq|
  <table width=100%>
    <tr>
      <td>$type</td>
      <td>$lang</td>
      <td>$format</td>
      <td>$media</td>
      <td align=right width=90%>
  |;

    if ( $form->{printed} =~ /$form->{formname}/ ) {
        print $locale->text('Printed') . qq|<br>|;
    }

    if ( $form->{queued} =~ /$form->{formname}/ ) {
        print $locale->text('Queued');
    }

    print qq|
      </td>
    </tr>
  </table>
|;

}

sub print {

    if ( $form->{media} !~ /screen/ ) {
        $form->error( $locale->text('Select postscript or PDF!') )
          if $form->{format} !~ /(postscript|pdf)/;
        $old_form = new Form;
        for ( keys %$form ) { $old_form->{$_} = $form->{$_} }
    }

    &{"print_$form->{formname}"}($old_form);

}

sub print_timecard {
    my ($old_form) = @_;

    $display_form =
      ( $form->{display_form} ) ? $form->{display_form} : "update";

    $form->{description} =~ s/^\s+//g;

    for (qw(partnumber projectnumber)) { $form->{$_} =~ s/--.*// }

    @a = qw(hour min sec);
    foreach $item (qw(in out)) {
        for (@a) { $form->{"$item$_"} = substr( qq|00$form->{"$item$_"}|, -2 ) }
        $form->{"checked$item"} =
qq|$form->{"${item}hour"}:$form->{"${item}min"}:$form->{"${item}sec"}|;
    }

    @a = ();
    for (qw(company address tel fax businessnumber)) {
        $form->{$_} = $myconfig{$_};
    }
    $form->{address} =~ s/\\n/\n/g;

    push @a, qw(partnumber description projectnumber projectdescription);
    push @a, qw(company address tel fax businessnumber username useremail);

    $form->format_string(@a);

    $form->{total} = $form->format_amount(
        \%myconfig,
        $form->parse_amount( \%myconfig,   $form->{qty} ) *
          $form->parse_amount( \%myconfig, $form->{sellprice} ),
        2
    );

    ( $form->{employee}, $form->{employee_id} ) = split /--/, $form->{employee};

    $form->{templates} = "$myconfig{templates}";
    $form->{IN}        = "$form->{formname}.html";

    if ( $form->{format} =~ /(postscript|pdf)/ ) {
        $form->{IN} =~ s/html$/tex/;
    }

    if ( $form->{media} !~ /(screen|queue)/ ) {
        $form->{OUT}       = ${LedgerSMB::Sysconfig::printer}{ $form->{media} };
        $form->{printmode} = '|-';

        if ( $form->{printed} !~ /$form->{formname}/ ) {
            $form->{printed} .= " $form->{formname}";
            $form->{printed} =~ s/^ //;

            $form->update_status( \%myconfig );
        }

        %audittrail = (
            tablename => jcitems,
            reference => $form->{id},
            formname  => $form->{formname},
            action    => 'printed',
            id        => $form->{id}
        );

        %status = ();
        for (qw(printed queued audittrail)) { $status{$_} = $form->{$_} }

        $status{audittrail} .=
          $form->audittrail( "", \%myconfig, \%audittrail );

    }

    if ( $form->{media} eq 'queue' ) {
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

        $form->{queued} = "$form->{formname} $filename";
        $form->update_status( \%myconfig );

        %audittrail = (
            tablename => jcitems,
            reference => $form->{id},
            formname  => $form->{formname},
            action    => 'queued',
            id        => $form->{id}
        );

        %status = ();
        for (qw(printed queued audittrail)) { $status{$_} = $form->{$_} }

        $status{audittrail} .=
          $form->audittrail( "", \%myconfig, \%audittrail );
    }

    my $template = LedgerSMB::Template->new( user => \%myconfig, 
      template => $form->{'formname'}, format => uc $form->{format} );
    try {
        $template->render($form);
        $template->output(%{$form});
    }
    catch Error::Simple with {
        my $E = shift;
        $form->error( $E->stacktrace );
    };

    if ( defined %$old_form ) {

        for ( keys %$old_form )             { $form->{$_} = $old_form->{$_} }
        for (qw(printed queued audittrail)) { $form->{$_} = $status{$_} }

        &{"$display_form"};

    }

}

