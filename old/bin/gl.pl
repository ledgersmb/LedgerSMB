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
# Contributors:
#
#
#  Author: DWS Systems Inc.
#     Web: http://www.ledgersmb.org/
#
# Contributors:
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
# Genereal Ledger
#
#======================================================================

package lsmb_legacy;
use LedgerSMB::GL;
use LedgerSMB::PE;
use LedgerSMB::Setting::Sequence;
use LedgerSMB::Legacy_Util;
use LedgerSMB::Num2text;

require "old/bin/arap.pl"; # for: Schedule action

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


sub edit_and_save {
    check_balanced($form);
    $form->call_procedure(funcname=>'draft_delete', args => [ $form->{id} ]);
    GL->post_transaction( \%myconfig, \%$form, $locale);
    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
            'GL', $form->{workflow_id}
            );
        $wf->context->param( transdate => $form->{transdate} );
        $wf->execute_action( $form->{__action} );
    }
    edit();
}

sub save_info {
    GL->save_notes( \%myconfig, \%$form, $locale);
    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
            'GL', $form->{workflow_id}
            );
        $wf->context->param( transdate => $form->{transdate} );
        $wf->execute_action( $form->{__action} );
    }
    edit();
}

sub approve {
    my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
        'GL', $form->{workflow_id}
        );
    die q|No workflow found to approve| unless $wf;

    $wf->context->param( transdate => $form->{transdate} );
    $wf->execute_action( $form->{__action} );

    if ($form->{callback}){
        print "Location: $form->{callback}\n";
        print "Status: 302 Found\n\n";
        print qq|<html><body class="lsmb">|;
        my $url = $form->{callback};
        print qq|If you are not redirected automatically, click <a href="$url">|
                . qq|here</a>.</body></html>|;

    } else {
        new();
    }
}

sub new {
    for my $row (0 .. $form->{rowcount}){
        for my $fld (
            qw(accno projectnumber acc debit credit source memo )
            ) {
            delete $form->{"${fld}_${row}"};
        }
    }
    for my $fld (
        qw(description reference rowcount id workflow_id
           notes reversing reversing_reference )
        ) {
        delete $form->{$fld};
    }
    add();
}

sub copy_to_new {
    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
            'GL', $form->{workflow_id}
            );
        $wf->context->param( transdate => $form->{transdate} );
        $wf->execute_action( $form->{__action} );
    }
    delete $form->{reference};
    delete $form->{id};
    delete $form->{approved};
    delete $form->{workflow_id};
    update();
}

sub add {

    $form->{title} = "Add";

    my $transfer
        = ($form->{transfer}) ? "&transfer=$form->{transfer}" : '';
    $form->{callback} = "$form->{script}?__action=add$transfer"
      unless $form->{callback};

    if (!$form->{rowcount}){
        $form->{rowcount} = ( $form->{transfer} ) ? 3 : 9;
    }
    $form->{oldtransdate} = $form->{transdate};
    $form->{focus}        = "reference";
    &create_links;
    display_form(1);

}


sub _reverse_amounts {
    # swap debits and credits
    for my $rownum (0 .. $form->{rowcount}) {
        my $credit = $form->{"credit_$rownum"};
        my $credit_fx = $form->{"credit_fx_$rownum"};
        $form->{"credit_$rownum"} = $form->{"debit_$rownum"};
        $form->{"credit_fx_$rownum"} = $form->{"debit_fx_$rownum"};
        $form->{"debit_$rownum"} = $credit;
        $form->{"debit_fx_$rownum"} = $credit_fx;
    }
}

sub reverse {
    $form->{title}     = "Reverse";
    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
            'GL', $form->{workflow_id}
            );
        $wf->context->param( transdate => $form->{transdate} );
        $wf->execute_action( $form->{__action} );
    }

    &create_links; # runs GL->transaction()
    _reverse_amounts();

    $form->{reversing} = delete $form->{id};
    $form->{reversing_reference} = $form->{reference};
    delete $form->{approved};
    delete $form->{workflow_id};

    display_form();
}


sub post_reversing {
    # we should save only the reference, sequence, transdate, description and notes.

    $form->error(
        $locale->text('Cannot post transaction for a closed period!') )
        if ( $transdate and $form->is_closed( $transdate ) );
    if (not $form->{id}) {
        do {
            local $form->{id} = $form->{reversing};

            # save data we want to use from the posted form,
            # not from the reversed transaction.
            local $form->{reversing};
            local $form->{notes};
            local $form->{description};
            local $form->{reference};
            local $form->{reversing_reference} = $form->{reference};
            local $form->{approved};
            local $form->{workflow_id};

            &create_links; # create_links overwrites 'reversing'
        };
        my $wf = $form->{_wire}->get('workflows')
            ->create_workflow( 'GL',
                               Workflow::Context->new(
                                   'transdate' => $form->{transdate},
                                   'batch-id' => $form->{batch_id},
                                   'table_name' => 'gl',
                                   'reversing' => $form->{reversing}
                               ) );
        $form->{workflow_id} = $wf->id;
        $wf->execute_action( $form->{__action} );

        # Why do I not need _reverse_amounts here???
        # _reverse_amounts();
        GL->post_transaction( \%myconfig, \%$form, $locale);
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

        $form->{dbh}->do(
            $query,
            {},
            $form->{reference},
            $form->{description},
            $form->{transdate},
            $form->{notes},

            $form->{id})
            or $form->dberror($query);
    }

    display_form();
}

sub display_form
{
    $form->{separate_duties} = $form->get_setting('separate_duties');
    #Add General Ledger Transaction

    # filter out '' transdates
    my $transdate = ($form->{transdate}) ? $from->{transdate} : undef;
    $form->all_business_units($transdate, undef, 'GL');
    @{$form->{sequences}} = LedgerSMB::Setting::Sequence->list('glnumber')
         unless $form->{id};
    $form->close_form;
    $form->open_form;
    my ($init) = @_;
    # Form header part begins -------------------------------------------
    if ($form->{all_department}){
        unshift @{ $form->{all_department} }, {};
    }
    $title = $locale->maketext($form->{title});
    if ( $form->{transfer} ) {
        $form->{title} = $locale->text("[_1] Cash Transfer Transaction", $title);
    }
    else {
        $form->{title} = $locale->text("[_1] General Ledger Transaction", $title);
    }

    if ( ( $rows = $form->numtextrows( $form->{description}, 50 ) ) > 1 ) {
         $form->{rowsdesc}=$rows; $form->{colsdesc}=50;
         $form->{colrowdesc}=1;
    }
    else {
         $form->{colrowdesc}=0;
     }

    if ( ( $rows = $form->numtextrows( $form->{notes}, 50 ) ) > 1 ) {
        $form->{rowsnotes}=$rows;$form->{colsnotes}=50;
    $form->{colrownotes}=1;
    }
    else {
               $form->{colrownotes}=0;
    }

    my $wf;
    if($form->{workflow_id}) {
        $wf = $form->{_wire}->get('workflows')
            ->fetch_workflow( 'GL', $form->{workflow_id} );
    }
    else {
        $wf = $form->{_wire}->get('workflows')
            ->create_workflow( 'GL',
                               Workflow::Context->new(
                                   'batch-id' => $form->{batch_id},
                                   'table_name' => 'gl',
                                   'reversing' => $form->{reversing}
                               ) );
        $form->{workflow_id} = $wf->id;
    }
    $wf->context->param( transdate => $form->{transdate} );
    $form->{status} = $wf->state;
    $focus = ( $form->{focus} ) ? $form->{focus} : "debit_$form->{rowcount}";
    our %hiddens = (
        'direction' => $form->{direction},
        'oldsort' => $form->{oldsort},
        'batch_id' => $form->{batch_id},
        'id' => $form->{id},
        'transfer' => $form->{transfer},
        'oldtransdate' => $form->{oldtransdate},
        'recurring' => $form->{recurring},
        'title' => $title,
        'approved' => $form->{approved},
        'callback' => $form->{callback},
        'form_id' => $form->{form_id},
        'separate_duties' => $form->{separate_duties},
        'reversing' => $form->{reversing},
        'reversing_reference' => $form->{reversing_reference},
        'workflow_id' => $form->{workflow_id}
    );


    #Disply_Row Part  Begins-------------------------------------

    our @displayrows;
    &display_row($init);

    #Form footer  Begins------------------------------------------

    $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    for (qw(totaldebit totalcredit)) {
        $form->{$_} =
            $form->format_amount( \%myconfig, $form->{$_},
                                  $form->{_setting_decimal_places}, "0" );
    }

  $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
  my @buttons;
    %button_types = (
        print => 'lsmb/PrintButton'
        );
    for my $action_name ( $wf->get_current_actions ) {
        my $action = $wf->get_action( $action_name );

        next if ($action->ui // '') eq 'none';
        push @buttons, {
            ndx   => $action->order,
            name  => $action->name,
            text => $locale->maketext($action->text),
            doing => ($action->doing ? $locale->maketext($action->doing) : ''),
            done  => ($action->done ? $locale->maketext($action->done) : ''),
            type  => $button_types{$action->ui},
            tooltip => ($action->short_help ? $locale->maketext($action->short_help) : '')
        };
    }

    @buttons = map {
        {
            name => '__action',
            value => $_->{name},
            text => $_->{text},
            type => 'submit',
            class => $_->{class} // 'submit',
            order => $_->{ndx},
            'data-lsmb-doing' => $_->{doing},
            'data-lsmb-done' => $_->{done},
            'data-dojo-type' => $_->{type} // 'dijit/form/Button',
            'data-dojo-props' => $_->{type} ? 'minimalGET: false' : '',
        }
    } sort { $a->{ndx} <=> $b->{ndx} } @buttons;

  $form->{recurringset}=0;
  if ( $form->{recurring} ) {
      $form->{recurringset}=1;
  }

    my $template = $form->{_wire}->get('ui');
    LedgerSMB::Legacy_Util::render_psgi(
        $form,
        $template->render($form, 'journal/journal_entry',
                          {
                              form => $form,
                              buttons => \@buttons,
                              hiddens => \%hiddens,
                              displayrows => \@displayrows
                          }));
}


sub save_as_template {
    my ($department_name, $department_id) = split/--/, $form->{department};

    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
            'GL', $form->{workflow_id}
            );
        $wf->context->param( transdate => $form->{transdate} );
        $wf->execute_action( $form->{__action} );
    }
    my @lines;
    for my $iter (0 .. $form->{rowcount}){
        if ($form->{"accno_$iter"} and
            (($form->{"credit_$iter"} != 0) or
             ($form->{"debit_$iter"} != 0) or
             ($form->{"credit_fx_$iter"} != 0) or
             ($form->{"debit_fx_$iter"} != 0))){
             my ($acc_id, $acc_name) = split /--/, $form->{"accno_$iter"};
             my $amount = $form->{"credit_$iter"} ||
                 ( $form->{"debit_$iter"} * -1 );
             my $amount_fx = $form->{"credit_fx_$iter"} ||
                 ( $form->{"debit_fx_$iter"} * -1 );
             push @lines, {
                 accno => $acc_id,
                 amount => $form->parse_amount( \%my_config, $amount),
                 amount_fx => $form->parse_amount( \%my_config, $amount_fx),
                 curr => $form->{"curr_$iter"},
             };
        }
    }

    my ($journal) = $form->call_procedure(
        funcname => 'journal__add',
        args     => [
            $form->{reference},
            $form->{description},
            1, # GJ journal
            $form->{transdate},
            0,
            1,
            $form->{curr_0} ###BUG: Sets a currency that doesn't exist on the GL screen!
        ]);
    for my $line (@lines) {
        my ($acc) = $form->call_procedure(
            funcname => 'account__get_from_accno',
            args     => [ $line->{accno} ]);
        $form->call_procedure(
            funcname => 'journal__add_line',
            args     => [
                $acc->{id},
                $journal->{id},
                $line->{amount},
                $line->{amount_fx},
                $line->{curr},
                'false',
                undef, ###BUG: discards the 'memo' text!
                undef ###BUG: discards selected reporting units!
            ]);
    }
    $form->redirect( $locale->text('Template Saved!') );
}


sub display_row {
  my ($init) = @_;
  $form->{totaldebit}  = 0;
  $form->{totalcredit} = 0;

    $form->{_setting_decimal_places} //= $form->get_setting('decimal_places');
    for my $i ( 0 .. $form->{rowcount} ) {

        my $temphash1;
        $temphash1->{index}=$i;
        $temphash1->{source}=$form->{"source_$i"};#input box
    $temphash1->{memo}=$form->{"memo_$i"}; #input box;
        $temphash1->{curr}=$form->{"curr_$i"};
    $temphash1->{accnoset}=1;
        $temphash1->{projectset}=1;
        $temphash1->{fx_transactionset} = 1;
        if (!defined $form->{"accno_$i"} || ! $form->{"accno_$i"}) {
                  $temphash1->{accnoset}=0;   #use  @{ $form->{all_accno} }
                  $temphash1->{fx_transactionset}=0;    #use checkbox and value=1 if transfer=1

        }
        else {
            $form->{"debit_$i"} =
                $form->parse_amount( \%myconfig,$form->{"debit_$i"});
            $form->{"credit_$i"} =
                $form->parse_amount( \%myconfig,$form->{"credit_$i"});
            $form->{totaldebit}  += ($form->{"debit_$i"} // 0);
            $form->{totalcredit} += ($form->{"credit_$i"} // 0);

            for (qw(debit debit_fx credit credit_fx)) {
                $form->{"${_}_$i"} = ($form->{"${_}_$i"})
                    ? $form->format_amount( \%myconfig, $form->{"${_}_$i"}, $form->{_setting_decimal_places} )
                    : "";
                $temphash1->{$_} = $form->{"${_}_$i"};
            }

            for my $cls(@{$form->{bu_class}}){
                $temphash1->{"b_unit_$cls->{id}"} =
                    $form->{"b_unit_$cls->{id}_$i"};
            }

            if ( $i < $form->{rowcount} ) {
                $temphash1->{accno}=$form->{"accno_$i"};

                if ( $form->{projectset} and $form->{"projectnumber_$i"} ) {
                    $temphash1->{projectnumber}=$form->{"projectnumber_$i"};
                    $temphash1->{projectnumber}=~ s/--.*//;
                }

                $hiddens{"accno_$i"}=$form->{"accno_$i"};
                $hiddens{"projectnumber_$i"}=$form->{"projectnumber_$i"};

            }
            else {
                $temphash1->{accnoset}=0;   #use  @{ $form->{all_accno} }
                $temphash1->{projectset}=0;   #use  @{ $form->{all_accno} }
            }
        }

        push @displayrows,$temphash1;
    }

  $hiddens{rowcount}=$form->{rowcount};
}

sub edit {

    &create_links;

    $form->all_business_units($form->{transdate}, undef, 'GL');

    $form->{title} = "Edit";
    if ($form->{department_id}) {
         $form->{department}=$form->{departmentdesc}."--".$form->{department_id};
    }

    my $i = 0;
    my $minusOne = LedgerSMB::PGNumber->new(-1); #HV make sure BigFloat stays BigFloat
    my $plusOne  = LedgerSMB::PGNumber->new(1);  #HV make sure BigFloat stays BigFloat

    foreach my $ref (@{ $form->{GL} }) {
        $form->{"accno_$i"} = "$ref->{accno}--$ref->{description}";
        $form->{"projectnumber_$i"} =
            "$ref->{projectnumber}--$ref->{project_id}"
            if $ref->{projectnumber};
        for (qw(curr source memo)) { $form->{"${_}_$i"} = $ref->{$_} }
        if ( $ref->{amount_bc} < 0 ) {
            $form->{totaldebit} -= $ref->{amount_bc};
            $form->{"debit_$i"} =  $ref->{amount_bc} * $minusOne;
            $form->{"debit_fx_$i"} =  $ref->{amount_tc} * $minusOne;
        }
        else {
            $form->{totalcredit} += $ref->{amount_bc};
            $form->{"credit_$i"} =  $ref->{amount_bc} * $plusOne;
            $form->{"credit_fx_$i"} =  $ref->{amount_tc} * $plusOne;
        }
        for my $cls (@{$form->{bu_class}}){
            $form->{"b_unit_$cls->{id}_$i"} = $ref->{"b_unit_$cls->{id}"};
        }

        $i++;
    }

   if ($form->{id}){
       GL->get_files($form, $locale);
   }
   $form->{rowcount} = $i;
   $form->{focus}    = "debit_$i";
   &display_form;
}

sub create_links {

    GL->transaction( \%myconfig, \%$form );

}

sub update {
    &create_links;
    my $min_lines = $form->get_setting('min_empty');
    $form->open_form unless $form->check_form;

    $form->{transdate} = $form->parse_date( \%myconfig, $form->{transdate} )->to_output();
    if ( $form->{transdate} ne $form->{oldtransdate} ) {
        $form->{oldtransdate} = $form->{transdate};
    }

    $form->all_business_units($form->{transdate}, undef, 'GL');
    GL->get_all_acc_dep_pro( \%myconfig, \%$form );

    @a     = ();
    $count = 0;
    @flds  = qw(accno debit debit_fx credit credit_fx curr
                projectnumber source memo);
    for my $cls (@{$form->{bu_class}}){
        if (scalar @{$form->{b_units}->{$cls->{id}}}){
           push @flds, "b_unit_$cls->{id}";
        }
    }

    for my $i ( 0 .. $form->{rowcount} ) {
        $form->{"debit_$i"} =~ s/\s+//g;
        $form->{"credit_$i"} =~ s/\s+//g;
        $form->{"debit_fx_$i"} =~ s/\s+//g;
        $form->{"credit_fx_$i"} =~ s/\s+//g;
        unless ( ( $form->{"debit_$i"} eq "" )
            && ( $form->{"credit_$i"} eq "" )
            && ( $form->{"debit_fx_$i"} eq "" )
            && ( $form->{"credit_fx_$i"} eq "" ) )
        {
            my $found_acc = 0;
            for my $acc(@{ $form->{all_accno} }){
                if ($form->{"accno_$i"} eq $acc->{accstyle}){
                    $found_acc = 1;
                }
                elsif ($form->{"accno_$i"} eq $acc->{accno}) {
                    $form->{"accno_$i"} = $acc->{accstyle};
                    $found_acc = 1;
                }
           }

            if (not $found_acc){
                $form->error($locale->text('Account [_1] not found',
                                           $form->{"accno_$i"}));
            }
            for my $tx_type (qw(debit credit debit_fx credit_fx)) {
                $form->{"${tx_type}_$i"} =
                    $form->parse_amount( \%myconfig, $form->{"${tx_type}_$i"} );
            }

            push @a, {};
            my $j = $#a;

            for my $field (@flds) {
                $a[$j]->{$field} = $form->{"${field}_$i"};
            }
            $count++;
        }
    }

    for my $i (1 .. $count) {
        my $j = $i - 1;
        for (@flds) { $form->{"${_}_$j"} = $a[$j]->{$_} }
    }

    for my $i ($count .. $form->{rowcount}) {
        for (@flds) { delete $form->{"${_}_$i"} }
    }

    $form->{rowcount} = $count + $min_lines;

    &display_form;
}


sub post_and_approve {
    post();
    $form->call_procedure(funcname=>'draft_approve', args => [ $form->{id} ]);
}

sub post {
    if ($form->{id}){
       $form->error($locale->text('Cannot Repost Transaction'));
    }
    if (!$form->close_form){
        &update;
        $form->finalize_request();
    };
    $form->isblank( "transdate", $locale->text('Transaction Date missing!') );
    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
            'GL', $form->{workflow_id}
            );
        $wf->context->param( transdate => $form->{transdate} );
        $wf->execute_action( $form->{__action} );
    }

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );

    $form->error(
        $locale->text('Cannot post transaction for a closed period!') )
        if ( $transdate and $form->is_closed( $transdate ) );

    check_balanced($form);
    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            &repost;
            $form->finalize_request();
        }
    }

    GL->post_transaction( \%myconfig, \%$form, $locale);
    edit();

}

sub del {
    my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
        'GL', $form->{workflow_id}
        );
    die 'No workflow to mark deleted' unless $wf;
    $wf->context->param( transdate => $form->{transdate} );
    $wf->execute_action( $form->{__action} );

    delete $form->{id};
    delete $form->{reference};
    new();
}


sub check_balanced {
    my ($form) = @_;
    # add up debits and credits
    for my $i ( 0 .. $form->{rowcount} ) {
        $form->{"debit_$i"} =~ s/\s+//g;
        $form->{"credit_$i"} =~ s/\s+//g;
        $dr = $form->parse_amount( \%myconfig, $form->{"debit_$i"} );
        $cr = $form->parse_amount( \%myconfig, $form->{"credit_$i"} );

        if ( $dr && $cr ) {
            $form->error(
                $locale->text(
'Cannot post transaction with a debit and credit entry for the same account!'
                )
            );
        }
        $debit  += $dr;
        $credit += $cr;
    }

    if ($form->round_amount($debit, 2) != $form->round_amount($credit, 2)) {
        $form->error( $locale->text('Out of balance transaction!') );
    }
}

sub save_as_new {
    for (qw(id)) { delete $form->{$_} }
    if ($form->{workflow_id}) {
        my $wf = $form->{_wire}->get('workflows')->fetch_workflow(
            'GL', $form->{workflow_id}
            );
        $wf->context->param( transdate => $form->{transdate} );
        $wf->execute_action( $form->{__action} );
    }
    delete $form->{approved};
    &post;
}

sub print {
    # Get all the business units required to render
    $form->all_business_units($form->{transdate}, undef, 'GL');
    # Get the actual je transaction
    &display_row(@_);

    my $templateName = "print_journal_entry";
    my $filename = "Journal_Entry_" . $form->{id} . ".html";
    $form->{print_title} = "Journal Entry Transaction";

    if($form->{transfer}) {
        $templateName = "print_cash_transfer";
        $filename = "Cash_Transfer_" . $form->{id} . ".html";
        $form->{print_title} = "Transfer Voucher";

        my $amount = $form->{"debit_0"} eq "" ? $form->{"credit_0"} : $form->{"debit_0"};
        my $amount_fx = $form->{"debit_fx_0"} eq "" ? $form->{"credit_fx_0"} : $form->{"debit_fx_0"};

        $form->{exchange_rate} = $form->parse_amount( \%myconfig,$amount) / $form->parse_amount( \%myconfig,$amount_fx);
        $form->{exchange_rate} = $form->format_amount( \%myconfig, $form->{exchange_rate},
                                                       $form->get_setting('decimal_places') );

        $form->{curr} = $form->{"curr_0"};;

        $form->{amount} = $form->{totaldebit};
        my $fmt = LedgerSMB::Num2text->new($form->{_locale});
        $form->{text_amount} = $fmt->num2text($form->parse_amount( \%myconfig,$form->{amount}));
    } else {
        # render the code--description for all business unit instead of id
        for my $drow (@displayrows) {
            for my $cls (@{$form->{bu_class}}) {
                if(scalar @{$form->{b_units}->{$cls->{id}}}) {
                    for my $bu (@{$form->{b_units}->{"$cls->{id}"}}) {
                        if ($drow->{"b_unit_$cls->{id}"} eq $bu->{id}) {
                            $drow->{"b_unit_$cls->{id}"} = $bu->{control_code} . '--' . $bu->{description};
                            last;
                        }
                    }
                }
            }
        }
    }

    my %copy_settings = (
        email => 'company_email',
        company => 'company_name',
        businessnumber => 'businessnumber',
        address => 'company_address',
        tel => 'company_phone',
        fax => 'company_fax',
    );
    while (my ($key, $setting) = each %copy_settings ) {
        $form->{$key} = $form->get_setting($setting);
    }

    my %output_options = (
        filename => $filename
    );
    my $template = LedgerSMB::Template->new(
        user => \%myconfig,
        template => $templateName,
        dbh => $form->{dbh},
        path => 'DB',
        locale => $locale,
        output_options => \%output_options,
        formatter_options => $form->formatter_options,
        format_plugin => $form->{_wire}->get( 'output_formatter' )->get( 'HTML' ),
    );
    $template->render(
        {
            form => $form,
            displayrows => \@displayrows
        }
    );
    LedgerSMB::Legacy_Util::output_template($template, $form);
}

1;
