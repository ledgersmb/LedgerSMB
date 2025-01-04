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

package lsmb_legacy;
use LedgerSMB::PE;
use LedgerSMB::AA;
use LedgerSMB::OE;
use LedgerSMB::Setting;

# end of main

sub add {

    # construct callback
    $form->{callback} = "$form->{script}?__action=add&type=$form->{type}"
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
    PE->get_partsgroup(\%$form)
      if $form->{id};
}

sub save {

    if ( $form->{translation} ) {
        PE->save_translation( \%myconfig, \%$form );
        $form->redirect( $locale->text('Translations saved!') );
        $form->finalize_request();
    }

    if ( $form->{type} eq 'partsgroup' ) {
        $form->isblank( "partsgroup", $locale->text('Group missing!') );
        PE->save_partsgroup( \%myconfig, \%$form );
        $form->redirect( $locale->text('Group saved!') );
    }

}

sub delete {

    if ( $form->{translation} ) {
        PE->delete_translation( \%myconfig, \%$form );
        $form->redirect( $locale->text('Translation deleted!') );

    }
    else {

        if ( $form->{type} eq 'partsgroup' ) {
            PE->delete_partsgroup( \%myconfig, \%$form );
            $form->redirect( $locale->text('Group deleted!') );
        }
    }

}

sub partsgroup_header {

    $form->{__action} =~ s/_.*//;
    # $locale->text('Add Group')
    # $locale->text('Edit Group')
    $form->{title} = $locale->maketext( ucfirst $form->{__action} . " Group" );


    $form->{partsgroup} = $form->quote( $form->{partsgroup} );
    PE->partsgroups(\%myconfig, $form);

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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
          <th align="right">| . $locale->text('Parent') . qq|</th>
          <td><select data-dojo-type="dijit/form/Select"
                      id='parent' name='parent'>
              <option>&nbsp;</option>|;
              for my $pg (@{$form->{item_list}}){
                  my $selected = '';
                  $selected = 'SELECTED="SELECTED"'
                         if $form->{parent} == $pg->{id};
                  print qq|<option value='$pg->{id}' $selected>
                                  $pg->{partsgroup} </option>|;
              }
      print qq|</select>
          <th align="right">| . $locale->text('Group') . qq|</th>

          <td><input data-dojo-type="dijit/form/TextBox" name=partsgroup size=30 value="$form->{partsgroup}"></td>
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

    print qq|
<button data-dojo-type="dijit/form/Button" type="submit" class="submit" name="__action" value="save">|
          . $locale->text('Save')
          . qq|</button>
|;

    if ( $form->{id} && $form->{orphaned} ) {
        print qq|
<button data-dojo-type="dijit/form/Button" type="submit" class="submit" name="__action" value="delete">|
              . $locale->text('Delete')
              . qq|</button>|;
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
          <td><input data-dojo-type="dijit/form/TextBox" name=partnumber size=20></td>
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
          <td><input data-dojo-type="dijit/form/TextBox" name=projectnumber size=20></td>
        </tr>
|;
    }

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">
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
          <td colspan=3><input data-dojo-type="dijit/form/TextBox" name=description size=40></td>
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
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continue">|
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
"$form->{script}?__action=list_translations&translation=$form->{translation}&number=$form->{number}&title=$title";

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
<body class="lsmb">

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

    foreach my $ref ( @{ $form->{translations} } ) {

        $ref->{description} =~ s/\r?\n/<br>/g;

        for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

        $column_data{description} =
"<td><a href=$form->{script}?__action=edit_translation&translation=$form->{translation}&number=$form->{number}&id=$ref->{id}&callback=$callback>$ref->{description}&nbsp;</a></td>";

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

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

<input name=callback type=hidden value="$form->{callback}">
|;

    $form->hide_form(qw(path login sessionid));

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

    $form->{selectlanguage} = qq|<option></option>\n|;
    for ( @{ $form->{all_language} } ) {
        $form->{selectlanguage} .=
          qq|<option value="$_->{code}">$_->{description}</option>\n|;
    }

    $form->{"$form->{number}"} =
      $form->{translations}->[0]->{"$form->{number}"};
    $form->{description} = $form->{translations}->[0]->{description};
    $form->{description} =~ s/\r?\n/<br>/g;

    shift @{ $form->{translations} };

    $i = 1;
    foreach my $row ( @{ $form->{translations} } ) {
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
    foreach my $i ( 1 .. $form->{translation_rows} ) {
        $form->{"selectlanguage_$i"} = $form->{selectlanguage};
        if ( $form->{"language_code_$i"} ) {
            $form->{"selectlanguage_$i"} =~
              s/(<option value="\Q$form->{"language_code_$i"}\E")/$1 selected/;
        }
    }

    $form->{selectlanguage} = $form->escape( $form->{selectlanguage}, 1 );

    $form->header;

    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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

    foreach my $i ( 1 .. $form->{translation_rows} ) {

        if ( ( $rows = $form->numtextrows( $form->{"translation_$i"}, 40 ) ) >
            1 )
        {
            $translation =
qq|<textarea data-dojo-type="dijit/form/Textarea" name="translation_$i" rows=$rows cols=40 wrap=soft>$form->{"translation_$i"}</textarea>|;
        }
        else {
            $translation =
qq|<input data-dojo-type="dijit/form/TextBox" name="translation_$i" size=40 value="$form->{"translation_$i"}">|;
        }

        print qq|
    <tr valign=top>
      <td><select data-dojo-type="dijit/form/Select" id="language-code-$i" name="language_code_$i">$form->{"selectlanguage_$i"}</select></td>
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
        foreach my $i ( 1 .. $form->{translation_rows} ) {
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

    &display_form;

}

sub select_name {

    $label = ucfirst $form->{vc};

    @column_index = qw(ndx name address);
    $column_data{ndx} = qq|<th>&nbsp;</th>|;
    $column_data{name} =
      qq|<th class=listheading>| . $locale->maketext($label) . qq|</th>|;
    $column_data{address} =
        qq|<th class=listheading colspan=5>|
      . $locale->text('Address')
      . qq|</th>|;

    $form->header;
    $title = $locale->text('Select from one of the names below');
    print qq|
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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
    foreach my $ref ( @{ $form->{name_list} } ) {
        $checked = ( $i++ ) ? "" : "checked";

        $ref->{name} = $form->quote( $ref->{name} );

        $column_data{ndx} =
qq|<td><input name=ndx class=radio type=radio data-dojo-type="dijit/form/RadioButton" value=$i $checked></td>|;
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
    for (qw(nextsub name_list)) { delete $form->{$_} }

    $form->hide_form;

    print qq|
<input type="hidden" name="nextsub" value="name_selected">
<br>
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continue">|
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
    foreach my $i ( 1 .. $form->{lastndx} ) {
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

sub project_sales_order {

    PE->project_sales_order( \%myconfig, \%$form );

    if ( @{ $form->{all_years} } ) {
        $form->{selectaccountingyear} = "<option></option>\n";
        for ( @{ $form->{all_years} } ) {
            $form->{selectaccountingyear} .= qq|<option>$_</option>\n|;
        }

        $form->{selectaccountingmonth} = "<option></option>\n";
        for ( sort keys %{ $form->{all_month} } ) {
            $form->{selectaccountingmonth} .=
              qq|<option value=$_>|
              . $locale->maketext( $form->{all_month}{$_} ) . qq|</option>\n|;
        }

        $selectfrom = qq|
        <tr>
      <th align=right>| . $locale->text('Period') . qq|</th>
      <td colspan=3>
      <select data-dojo-type="dijit/form/Select" id=month name=month>$form->{selectaccountingmonth}</select>
      <select data-dojo-type="dijit/form/Select" id=year name=year>$form->{selectaccountingyear}</select>
      <input name=interval class=radio type=radio data-dojo-type="dijit/form/RadioButton" value=0 checked>&nbsp;|
          . $locale->text('Current') . qq|
      <input name=interval class=radio type=radio data-dojo-type="dijit/form/RadioButton" value=1>&nbsp;|
          . $locale->text('Month') . qq|
      <input name=interval class=radio type=radio data-dojo-type="dijit/form/RadioButton" value=3>&nbsp;|
          . $locale->text('Quarter') . qq|
      <input name=interval class=radio type=radio data-dojo-type="dijit/form/RadioButton" value=12>&nbsp;|
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
      . qq| <input class="date" data-dojo-type="lsmb/DateTextBox" name=transdatefrom size=11 title="$myconfig{dateformat}">
      |
      . $locale->text('To')
      . qq| <input class="date" data-dojo-type="lsmb/DateTextBox" name=transdateto size=11 title="$myconfig{dateformat}"></td>
    </tr>
    $selectfrom
|;

    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option></option>\n";
        for ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$_->{control_code}--$_->{id}">$_->{control_code}--$_->{description}</option>\n|;
        }
    }
    else {
        $form->error( $locale->text('No open Projects!') );
    }

    if ( @{ $form->{all_employee} } ) {
        $form->{selectemployee} = "<option></option>\n";
        for ( @{ $form->{all_employee} } ) {
            $form->{selectemployee} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}</option>\n|;
        }

        $employee = qq|
              <tr>
            <th align=right nowrap>| . $locale->text('Employee') . qq|</th>
        <td><select data-dojo-type="dijit/form/Select" id=employee name=employee>$form->{selectemployee}</select></td>
          </tr>
|;
    }

    $form->{title} = $locale->text('Generate Sales Orders');
    $form->{vc}    = "customer";
    $form->{type}  = "sales_order";

    $form->header;

    print qq|
<body class="lsmb">

<form id="timecard-generate-salesorders" method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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
      <td colspan=3><select data-dojo-type="dijit/form/Select" id=projectnumber name=projectnumber>$form->{selectprojectnumber}</select></td>
    </tr>
    $employee
    $fromto
    <tr>
      <th></th>
        <td><input name=summary type=radio data-dojo-type="dijit/form/RadioButton" class=radio value=1> |
      . $locale->text('Summary') . qq|
        <input name=summary type=radio data-dojo-type="dijit/form/RadioButton" class=radio value=0 checked> |
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
<button data-dojo-type="dijit/form/Button" type="submit" class="submit" name="__action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>

</form>
|;

    print qq|

</body>
</html>
|;

}

sub project_jcitems_list {

    $form->{projectnumber} = $form->unescape( $form->{projectnumber} );
    $form->{employee}      = $form->unescape( $form->{employee} );
    $form->{callback}      = "$form->{script}?__action=project_jcitems_list";
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
    foreach my $ref ( @{ $form->{jcitems} } ) {
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

    foreach my $i ( 1 .. $form->{rowcount} ) {
        for (qw(qty allocated)) {
            $form->{"${_}_$i"} =
              $form->format_amount( \%myconfig, $form->{"${_}_$i"} );
        }
        for (qw(amount sellprice)) {
            $form->{"${_}_$i"} =
              $form->format_amount( \%myconfig, $form->{"${_}_$i"}, $form->get_setting('decimal_places') );
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
<body class="lsmb">

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

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

    foreach my $i ( 1 .. $form->{rowcount} ) {

        for (@column_index) {
            $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>|;
        }
        for (qw(qty amount)) {
            $column_data{$_} = qq|<td align=right>$form->{"${_}_$i"}</td>|;
        }

        $checked = ( $form->{"checked_$i"} ) ? "checked" : "";
        $column_data{id} =
qq|<td><input name="checked_$i" class=checkbox type=checkbox data-dojo-type="dijit/form/CheckBox" value="1" $checked></td>|;

        if ( $form->{"$form->{vc}_id_$i"} ) {
            $column_data{name} = qq|<td>$form->{"$form->{vc}_$i"}</td>|;
            $form->hide_form( "$form->{vc}_id_$i", "$form->{vc}_$i" );
        }
        else {
            $column_data{name} =
qq|<td><input name="ndx_$i" class=checkbox type=checkbox data-dojo-type="dijit/form/CheckBox" value="1"></td>|;
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
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="generate_sales_orders">|
          . $locale->text('Generate Sales Orders')
          . qq|</button>|;

        print qq|
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="select_customer">|
          . $locale->text('Select Customer')
          . qq|</button>|;

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
<body class="lsmb $form->{dojo_theme}" onLoad="document.forms[0].$form->{vc}.focus()" />

<form method="post" data-dojo-type="lsmb/Form" action="$form->{script}">

<b>$label</b> <input data-dojo-type="dijit/form/TextBox" name=$form->{vc} size=40>

|;

    $form->{nextsub} = "$form->{vc}_selected";
    $form->{__action}  = "$form->{vc}_selected";

    $form->hide_form;

    print qq|
<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="__action" value="continue">|
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
        $form->error($msg);
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

    foreach my $i ( 1 .. $form->{rowcount} ) {
        $form->error( $locale->text('Customer missing!') )
          if ( $form->{"checked_$i"} && !$form->{"customer_$i"} );
    }

    foreach my $i ( 1 .. $form->{rowcount} ) {
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

    $order = Form->new;
    for ( keys %{ $form->{order} } ) {
        $order->{dbh} = $form->{dbh};

        for (qw(type vc defaultcurrency login)) { $order->{$_} = $form->{$_} }
        for ( split / /, $form->{taxaccounts} ) {
            $order->{"${_}_rate"} = $form->{"${_}_rate"};
        }

        $i = 0;
        $order->{"$order->{vc}_id"} = $_;

        AA->get_name( \%myconfig, \%$order );

        foreach my $ref ( @{ $form->{order}{$_} } ) {
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
                OE->delete( \%myconfig, \%$order );
            }
        }
        else {
            $order->error( $locale->text('Failed to save order!') );
        }

        for ( keys %$order ) { delete $order->{$_} }

    }

    $form->redirect( $locale->text('Orders generated!') );

}

1;
