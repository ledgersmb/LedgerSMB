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

package lsmb_legacy;
use LedgerSMB::AM;
use LedgerSMB::Form;
use LedgerSMB::User;
use LedgerSMB::GL;
use LedgerSMB::Template;
use LedgerSMB::Sysconfig;

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

sub form_footer_buttons {

    my ($hiddens, $buttons) = @_;
    $hiddens->{$_} = $form->{$_} foreach qw(callback path login sessionid);

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
        push @{$buttons}, {
            name => 'action',
            value => $_,
            accesskey => $button{$_}{key},
            title => "$button{$_}{value} [Alt-$button{$_}{key}]",
            text => $button{$_}{value},
            };
    }

}

sub add_gifi {
    $form->{title} = "Add";

    # construct callback
    $form->{callback} = "reports.pl?action=list_gifi";

    $form->{coa} = 1;

    my %hiddens;
    my @buttons;
    &gifi_header(\%hiddens);
    &gifi_footer(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-gifi-form');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });

}

sub edit_gifi {

    $form->{title} = "Edit";

    AM->get_gifi( \%myconfig, \%$form );

    $form->error( $locale->text('Account does not exist!') )
      unless $form->{accno};

    my %hiddens;
    my @buttons;
    &gifi_header(\%hiddens);
    &gifi_footer(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-gifi-form');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });

}

sub gifi_header {
    my $hiddens = shift;

    my $title_msg="$form->{title} GIFI";
    # $locale->text('Add GIFI')
    # $locale->text('Edit GIFI')

    $form->{title} = $locale->maketext($title_msg);

    for (qw(accno description)) { $form->{$_} = $form->quote( $form->{$_} ) }

    $hiddens->{id} = $form->{accno};
    $hiddens->{type} = 'gifi';

}

sub gifi_footer {
    my ($hiddens, $buttons) = @_;

    $hiddens->{$_} = $form->{$_} foreach qw(callback path login sessionid);

    # type=submit $locale->text('Save')
    # type=submit $locale->text('Copy to COA')
    # type=submit $locale->text('Delete')

    my %button = ();

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
        push @{$buttons}, {
            name => 'action',
            value => $_,
            accesskey => $button{$_}{key},
            title => "$button{$_}{value} [Alt-$button{$_}{key}]",
            text => $button{$_}{value},
            };
    }

}

sub save_gifi {

    $form->isblank( "accno", $locale->text('GIFI missing!') );
    AM->save_gifi( \%myconfig, \%$form );
    $form->redirect( $locale->text('GIFI saved!') );

}

sub delete_gifi {

    AM->delete_gifi( \%myconfig, \%$form );
    $form->redirect( $locale->text('GIFI deleted!') );

}

sub add_business {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add_business&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    my %hiddens;
    my @buttons;
    my $checked = &business_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-business-form');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });

}

sub edit_business {

    $form->{title} = "Edit";

    AM->get_business( \%myconfig, \%$form );

    $form->{orphaned} = 1;

    my %hiddens;
    my @buttons;
    my $checked = &business_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-business-form');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });
}

sub business_header {
    my $hiddens = shift;

    my $title_msg="$form->{title} Business";
    # $locale->text('Add Business')
    # $locale->text('Edit Business')
    $form->{title} = $locale->maketext($title_msg);

    $form->{description} = $form->quote( $form->{description} );
    $form->{discount} =
      $form->format_amount( \%myconfig, $form->{discount} * 100 );

    $hiddens->{id} = $form->{id};
    $hiddens->{type} = 'business';

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

    my %hiddens;
    my @buttons;
    my $checked = &sic_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-sic-form');
    $template->render({
        form => $form,
        heading => $checked,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });
}

sub edit_sic {

    $form->{title} = "Edit";

    $form->{code} =~ s/\\'/'/g;
    $form->{code} =~ s/\\\\/\\/g;

    AM->get_sic( \%myconfig, \%$form );
    $form->{id} = $form->{code};
    $form->{orphaned} = 1;

    my %hiddens;
    my @buttons;
    my $checked = &sic_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-sic-form');
    $template->render({
        form => $form,
        heading => $checked,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });

}

sub sic_header {
    my $hiddens = shift;

    my $title_msg="$form->{title} SIC";
    # $locale->text('Add SIC')
    # $locale->text('Edit SIC')
    $form->{title} = $locale->maketext($title_msg);

    for (qw(code description)) { $form->{$_} = $form->quote( $form->{$_} ) }

    $checked = ( $form->{sictype} eq 'H' ) ? "checked" : "";

    $hiddens->{type} = 'sic';
    $hiddens->{id} = $form->{code};

    $checked;
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

    my %hiddens;
    my @buttons;
    &language_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-language-form');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });

}


sub edit_language {

    $form->{title} = "Edit";

    $form->{code} =~ s/\\'/'/g;
    $form->{code} =~ s/\\\\/\\/g;

    AM->get_language( \%myconfig, \%$form );
    $form->{id} = $form->{code};
    $form->{orphaned} = 1;

    my %hiddens;
    my @buttons;
    &language_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-language-form');
    $template->render({
        form => $form,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });

}

sub language_header {
    my $hiddens = shift;

    my $title_msg="$form->{title} Language";
    # $locale->text('Add Language')
    # $locale->text('Edit Language')
    $form->{title} = $locale->maketext($title_msg);

    for (qw(code description)) { $form->{$_} = $form->quote( $form->{$_} ) }

    $hiddens->{type} = 'language';
    $hiddens->{id} = $form->{code};
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
    for (qw(action nextsub)) { delete $form->{$_} }

    my %hiddens;
    $hiddens{$_} = $form->{$_} foreach keys %$form;
    my @buttons = ({
        name => 'action',
        value => 'yes_delete_language',
        text => $locale->text('Delete Language'),
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
'Deleting a language will also delete the templates for the language [_1]',
            $form->{id}),
    });
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


sub taxes {

    # get tax account numbers
    AM->taxes( \%myconfig, \%$form );

    $i = 0;
    foreach $ref ( @{ $form->{taxrates} } ) {
        $i++;
        $form->{"minvalue_$i"} =
          $form->format_amount( \%myconfig, $ref->{minvalue}) || 0;

        $form->{"taxrate_$i"} =
          $form->format_amount( \%myconfig, $ref->{rate} );
        $form->{"taxdescription_$i"} = $ref->{description};

        for (qw(taxnumber validto pass taxmodulename)) {
            $form->{"${_}_$i"} = $ref->{$_};
        }
        $form->{"old_validto_$i"} = $ref->{validto};
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
          $form->format_amount( \%myconfig, $form->{"taxrate_$i"},3,'0');

        $hiddens{"taxdescription_$i"} = $form->{"taxdescription_$i"};
        $hiddens{"old_validto_$i"} = $form->{"old_validto_$i"};

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
    my $inserted=0;

    AM->taxes( \%myconfig, \%$form );

    foreach $item (@a) {
        ( $accno, $i ) = split /_/, $item;
        push @t, $accno;

    $i=$i+$inserted;

        $form->{"taxmodulename_$i"} =
          $form->{ "taxmodule_" . $form->{"taxmodule_id_$i"} };

        if ( $form->{"validto_$i"} ) {
            $j = $i + 1;
            if ( $form->{"taxdescription_$i"} ne $form->{"taxdescription_$j"} )
            {

                #insert line
                for ( $j = $ndx + 1 ; $j > $i ; $j-- ) {
                    $k = $j - 1;
                    for (qw(taxrate taxdescription taxnumber validto pass old_validto)) {
                        $form->{"${_}_$j"} = $form->{"${_}_$k"};
                    }
                }
                $ndx++;
                $inserted++;
                $k = $i + 1;
                for (qw(taxdescription taxnumber)) {
                    $form->{"${_}_$k"} = $form->{"${_}_$i"};
                }
                for (qw(taxrate validto pass old_validto)) { $form->{"${_}_$k"} = "" }
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
                    for (qw(taxrate taxdescription taxnumber validto pass old_validto)) {
                        $form->{"${_}_$j"} = $form->{"${_}_$k"};
                    }
                }
                $ndx--;
                $inserted--;
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

sub save_taxes {

    if ( AM->save_taxes( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Taxes saved!') );
    }
    else {
        $form->error( $locale->text('Cannot save taxes!') );
    }

}

sub add_warehouse {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add_warehouse&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    my %hiddens;
    my @buttons;
    my $rows = &warehouse_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-warehouse-form');
    $template->render({
        form => $form,
        row_count => $rows,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });

}

sub edit_warehouse {

    $form->{title} = "Edit";

    AM->get_warehouse( \%myconfig, \%$form );

    my %hiddens;
    my @buttons;
    my $rows = &warehouse_header(\%hiddens);
    &form_footer_buttons(\%hiddens, \@buttons);

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-warehouse-form');
    $template->render({
        form => $form,
        row_count => $rows,
        buttons => \@buttons,
        hiddens => \%hiddens,
    });
}

sub warehouse_header {
    my $hiddens = shift;

    my $title_msg="$form->{title} Warehouse";
    # $locale->text('Add Warehouse')
    # $locale->text('Edit Warehouse')
    $form->{title} = $locale->maketext($title_msg);

    $form->{description} = $form->quote( $form->{description} );

    $hiddens->{id} = $form->{id};
    $hiddens->{type} = 'warehouse';

    my $rows = $form->numtextrows( $form->{description}, 60 );
    $rows;
}

sub save_warehouse {

    $form->isblank( "description", $locale->text('Description missing!') );
    AM->save_warehouse( \%myconfig, \%$form );
    _warehouse_redirect();

}

sub delete_warehouse {

    AM->delete_warehouse( \%myconfig, \%$form );
    _warehouse_redirect();

}

sub _warehouse_redirect {
    use LedgerSMB::Scripts::reports;
    bless $form, 'LedgerSMB';
    LedgerSMB::Scripts::reports::list_warehouse($lsmb);
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

    my %hiddens;
    my %column_header;
    $form->{stylesheet} = $myconfig{stylesheet};

    $form->{title} = $locale->text('Recurring Transactions');

    $column_header{id} = "";

    AM->recurring_transactions( \%myconfig, \%$form );

    $href = "$form->{script}?action=recurring_transactions";
    for (qw(direction oldsort path login sessionid)) {
        $href .= qq|&$_=$form->{$_}|;
    }

    $form->sort_order();

    my @column_index = qw(ndx reference description);

    push @column_index,
      qw(nextdate enddate id amount curr repeat howmany recurringemail recurringprint);

    $column_header{reference} = {
        text => $locale->text('Reference'),
        href => "$href&sort=reference",
        };
    $column_header{ndx} = ' ';
    $column_header{id} = $locale->text('ID');
    $column_header{description} = $locale->text('Description');
    $column_header{nextdate} = {
        text => $locale->text('Next'),
        href => "$href&sort=nextdate",
        };
    $column_header{enddate} = {
        text => $locale->text('Ends'),
        href => "$href&sort=enddate",
        };
    $column_header{amount} = $locale->text('Amount');
    $column_header{curr} = ' ';
    $column_header{repeat} = $locale->text('Every');
    $column_header{howmany} = $locale->text('Times');
    $column_header{recurringemail} = $locale->text('E-mail');
    $column_header{recurringprint} = $locale->text('Print');

    my $i = 1;
    my %tr = (
        ar => $locale->text('AR'),
        ap => $locale->text('AP'),
        gl => $locale->text('GL'),
        so => $locale->text('Sales Orders'),
        po => $locale->text('Purchase Orders'),
    );

    my %f = &formnames;

    my @transactions;
    my $j;
    my $k;
    foreach my $transaction ( sort keys %{ $form->{transactions} } ) {
        my $transaction_count = scalar( @{ $form->{transactions}{$transaction} } );
        push @transactions, {type => $transaction,
            title => "$tr{$transaction} ($transaction_count)",
            transactions => [],
            };

        foreach my $ref ( @{ $form->{transactions}{$transaction} } ) {

            my %column_data;
            for (@column_index) {
                $column_data{$_} = "$ref->{$_}";
            }

            my $unit;
            my $repeat;
            if ( $ref->{repeat} > 1 ) {
                $unit   = $locale->maketext( ucfirst $ref->{unit} );
                $repeat = "$ref->{repeat} $unit";
            }
            else {
                chop $ref->{unit};
                $unit   = $locale->maketext( ucfirst $ref->{unit} );
                $repeat = $unit;
            }

            $column_data{ndx} = '';

            if ( !$ref->{expired} ) {
                if ( $ref->{overdue} <= 0 ) {
                    $k++;
                    $column_data{ndx} = {
                        name => "ndx_$k",
                        type => 'checkbox',
                        value => $ref->{id},
                        checked => 'checked',
                        };
                }
            }

            my $reference =
              ( $ref->{reference} )
              ? $ref->{reference}
              : $locale->text('Next Number');
            $column_data{reference} = {
                text => $reference,
                href => qq|$form->{script}?action=edit_recurring&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&module=$ref->{module}&invoice=$ref->{invoice}&transaction=$ref->{transaction}&recurringnextdate=$ref->{nextdate}|,
                };

            my $module = "$ref->{module}.pl";
            my $type   = "";
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

            $column_data{id} = {
                text => $ref->{id},
                href => qq|$module?action=edit&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$type&readonly=1|,
                };

            $column_data{repeat} = $repeat;
            $column_data{howmany} =
                $form->format_amount( \%myconfig, $ref->{howmany} );
            $column_data{amount} =
                $form->format_amount( \%myconfig, $ref->{amount}, 2 );

            my @temp_split;
            my @f = split /:/, $ref->{recurringemail};
            for ( 0 .. $#f ) {
                push @temp_split, $f{$f[$_]};
            }
            $column_data{recurringemail} = {
                text => (join ':', @temp_split),
                delimiter => ':',
                };

            @temp_split = ();
            @f = split /:/, $ref->{recurringprint};
            for ( 0 .. $#f ) {
                push @temp_split, $f{$f[$_]};
            }
            $column_data{recurringprint} = {
                text => (join ':', @temp_split),
                delimiter => ':',
                };

            $j++;
            $j %= 2;
            $column_data{i} = $j;

            push @{$transactions[$#transactions]{transactions}}, \%column_data;
        }
    }

    $hiddens{path} = $form->{path};
    $hiddens{login} = $form->{login};
    $hiddens{sessionid} = $form->{sessionid};
    $hiddens{lastndx} = $k;

    my @buttons;
    push @buttons, {
        name => 'action',
        value => 'process_transactions',
        text => $locale->text('Process Transactions'),
        type => 'submit',
        class => 'submit',
    };

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'am-list-recurring');
    $template->render({
        form => $form,
        buttons => \@buttons,
        columns => \@column_index,
        heading => \%column_header,
        transactions => \@transactions,
        hiddens => \%hiddens,
    });
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
            AM->recurring_details( \%myconfig, $pt, $id );


            # reset $form
            # XXX THIS IS A BUG FACTORY. PLEASE READ:
            # This is old code from SL, and it basically forces a reset of the
            # LedgerSMB::Form object by deleting all keys and then copying a few
            # back in.  This is error prone and buggy.  If you have issues with
            # recurring transactions, the first thing to do is to see if
            # something is not being copied back that needs to be.  Looking
            # forward to removing this code. --CT
            for ( keys %$form ) { delete $form->{$_}; }
            for (qw(header dbversion company dbh login path sessionid
                    stylesheet timeout id)
            ) {
                $form->{$_} = $pt->{$_};
            }
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

                    # tax accounts
                    $form->all_taxaccounts( \%myconfig, undef,
                        $form->{transdate} );
                    $form->{transdate} = $pt->{nextdate};
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

                $j = 0;
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
                $ok = GL->post_transaction( \%myconfig, \%$form, $locale );
                $form->info( " ..... " . $locale->text('done') );

            }

            AM->update_recurring( \%myconfig, \%$pt, $id ) if $ok;

        }
    }

    $form->{callback} =
"am.pl?action=recurring_transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&header=1";
    $form->redirect;

}

sub print_recurring {
    my ( $pt, $defaultprinter ) = @_;
    use List::Util qw(first);

    my $ref = $form->{reference};
    my %f  = (
        transaction    => $locale->text('Printing Transaction [_1]', $ref),
        invoice        => $locale->text('Printing Invoice [_1]', $ref),
        credit_invoice => $locale->text('Printing Credit Invoice [_1]', $ref),
        debit_invoice  => $locale->text('Printing Debit Invoice [_1]', $ref),
        packing_list   => $locale->text('Printing Packing List [_1]', $ref),
        pick_list      => $locale->text('Printing Pick List [_1]', $ref),
        sales_order    => $locale->text('Printing Sales Order [_1]', $ref),
        work_order     => $locale->text('Printing Work Order [_1]', $ref),
        purchase_order => $locale->text('Printing Purchase Order [_1]', $ref),
        bin_list       => $locale->text('Printing Bin List [_1]', $ref),
        );
    my $ok = 1;

    if ( $pt->{recurringprint} ) {
        my $orig_callback = $form->{callback};
        @f = split /:/, $pt->{recurringprint};
        for ( $j = 0 ; $j <= $#f ; $j += 3 ) {
            $media = $f[ $j + 2 ];
            $media ||= $myconfig->{printer}
              if ${LedgerSMB::Sysconfig::printer}{ $myconfig->{printer} };
            $media ||= $defaultprinter;



            $form->info( "\n" . $f{ $f[$j] } );
            $form->error( $locale->text('Invalid redirect') )
              unless first { $_ eq $form->{script} }
              @{LedgerSMB::Sysconfig::scripts};
            $form->{callback} = "$form->{script}?action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=$media&vc=$form->{vc}&ARAP=$form->{ARAP}";

            $form->info( " ..... " . $locale->text('done') );
        }
        $form->{callback} = $orig_callback;
    }

    $ok;

}

sub email_recurring {
    my ($pt) = @_;
    use List::Util qw(first);

    my $ref = $form->{reference};
    my %f  = (
        transaction    => $locale->text('Sending Transaction [_1]', $ref),
        invoice        => $locale->text('Sending Invoice [_1]', $ref),
        credit_invoice => $locale->text('Sending Credit Invoice [_1]', $ref),
        debit_invoice  => $locale->text('Sending Debit Invoice [_1]', $ref),
        packing_list   => $locale->text('Sending Packing List [_1]', $ref),
        pick_list      => $locale->text('Sending Pick List [_1]', $ref),
        sales_order    => $locale->text('Sending Sales Order [_1]', $ref),
        work_order     => $locale->text('Sending Work Order [_1]', $ref),
        purchase_order => $locale->text('Sending Purchase Order [_1]', $ref),
        bin_list       => $locale->text('Sending Bin List [_1]', $ref),
        );
    my $ok = 1;

    if ( $pt->{recurringemail} ) {
        my $orig_callback = $form->{callback};
        @f = split /:/, $pt->{recurringemail};
        for ( $j = 0 ; $j <= $#f ; $j += 2 ) {

            $form->info( "\n" . $f{ $f[$j] } );
            # no email, bail out
            if ( !$form->{email} ) {
                $form->info(
                    " ..... " . $locale->text('E-mail address missing!') );
                last;
            }

            $message = $form->escape( $pt->{message}, 1 );

            $form->error( $locale->text('Invalid redirect') )
              unless first { $_ eq $form->{script} }
              @{LedgerSMB::Sysconfig::scripts};
            $form->{callback} = "$form->{script}?action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=email&vc=$form->{vc}&ARAP=$form->{ARAP}&message=$message";
            $ok = !( $form->_redirect() );

            if ($ok) {
                $form->info( " ..... " . $locale->text('done') );
            }
            else {
                $form->info( " ..... " . $locale->text('failed') );
                last;
            }
        }
        $form->{callback} = $orig_callback;
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



sub add_taxform {

    $form->{title} = $locale->text("Add");

    $form->{callback} =
"$form->{script}?action=add_taxform&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    $form->info("Add Country Tax forms is Under Construction");

}


sub search_taxform {

    $form->{title} = "Edit";

    $form->{callback} =
"$form->{script}?action=search_taxform&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    $form->info("Search Country Tax forms is Under Construction");

}





sub continue { &{ $form->{nextsub} } }

