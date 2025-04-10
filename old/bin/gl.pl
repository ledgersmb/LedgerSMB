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
use LedgerSMB::Template::UI;
use LedgerSMB::Setting::Sequence;
use LedgerSMB::Legacy_Util;
use LedgerSMB::DBObject::Draft;
use LedgerSMB::DBObject::TransTemplate;

require "old/bin/arap.pl";

# end of main

sub edit_and_save {
    check_balanced($form);
    my $draft = LedgerSMB::DBObject::Draft->new(%$form);
    $draft->delete();
    GL->post_transaction( \%myconfig, \%$form, $locale);
    edit();
}

sub approve {
    my $draft = LedgerSMB::DBObject::Draft->new(%$form);
    $draft->approve();
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


sub new {
     for my $row (0 .. $form->{rowcount}){
         for my $fld(qw(accno projectnumber acc debit credit source memo)){
            delete $form->{"${fld}_${row}"};
         }
     }
     delete $form->{description};
     delete $form->{reference};
     delete $form->{rowcount};
     delete $form->{id};
     add();
}

sub copy_to_new {
     delete $form->{reference};
     delete $form->{id};
     delete $form->{approved};
     update();
}

sub add {

    $form->{title} = "Add";

    my $transfer
        = ($form->{transfer}) ? "&transfer=$form->{transfer}" : '';
    $form->{callback} = "$form->{script}?action=add$transfer"
      unless $form->{callback};

    if (!$form->{rowcount}){
        $form->{rowcount} = ( $form->{transfer} ) ? 3 : 9;
    }
    $form->{oldtransdate} = $form->{transdate};
    $form->{focus}        = "reference";
    &create_links;
    display_form(1);

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

    if (!defined $form->{approved}){
        $form->{approved} = '1';
    }

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
    );


    #Disply_Row Part  Begins-------------------------------------

    our @displayrows;
    &display_row($init);

    #Form footer  Begins------------------------------------------

  for (qw(totaldebit totalcredit)) {
      $form->{$_} =
    $form->format_amount( \%myconfig, $form->{$_}, LedgerSMB::Setting->new(%$form)->get('decimal_places'), "0" );
  }

  $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
  my @buttons;
  if ( !$form->{readonly} ) {
      my $i;

      $i=1;
      @buttons = (
          { action => 'update',
            value => $locale->text('Update') },
          { action => 'post',
            value =>
                ($form->{separate_duties}
                 ? $locale->text('Save') : $locale->text('Post')),
            class => 'post' },
          { action => 'approve', value => $locale->text('Post'),
            class => 'post' },
          { action => 'edit_and_save',
            value => $locale->text('Save Draft') },
          { action => 'save_temp',
            value => $locale->text('Save Template') },
          { action => 'save_as_new',
            value => $locale->text('Save as new') },
          { action => 'schedule',
            value => $locale->text('Schedule') },
          { action => 'new',
            value => $locale->text('New') },
          { action => 'copy_to_new',
            value => $locale->text('Copy to New') },
          );

      %a = ();
      $a{'save_temp'} = 1;

      if ( $form->{id}) {
          for ( 'new', 'save_as_new', 'schedule', 'copy_to_new' ) {
              $a{$_} = 1;
          }
          if (!$form->{approved} && !$form->{batch_id}) {
            #   Need to check for draft_modify and draft_post
            if ($form->is_allowed_role(['draft_post'])) {
                $a{approve} = 1;
            }
            if ($form->is_allowed_role(['draft_modify'])) {
                $a{edit_and_save} = 1;
            }
              $a{update} = 1;
          }
      } else {
          $a{'update'} = 1;
          if ( not $form->is_closed( $transdate ) ) {
              for ( 'post', 'schedule' ) { $a{$_} = 1 }
          }
      }

      $i=1;
      @buttons = map {
          {
              name => 'action',
              value => $_->{action},
              text => $_->{value},
              type => 'submit',
              class => $_->{class} // 'submit',
              order => $i++
          }
      }
      grep { $a{$_->{action}} } @buttons;
  }

  $form->{recurringset}=0;
  if ( $form->{recurring} ) {
      $form->{recurringset}=1;
  }

    my $template = LedgerSMB::Template::UI->new_UI;
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


sub save_temp {
    my ($department_name, $department_id) = split/--/, $form->{department};

    my $data = {
        dbh => $form->{dbh},
        department_id => $department_id,
        reference => $form->{reference},
        description => $form->{description},
        department_id => $department_id,
        post_date => $form->{transdate},
        type => 'gl',
        journal_lines => [],
    };

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
             push @{$data->{journal_lines}},
                  {accno => $acc_id,
                   amount => $amount,
                   amount_fx => $amount_fx,
                   curr => $form->{"curr_$iter"},
                   cleared => 'false',
                  };
        }
    }

    $template = LedgerSMB::DBObject::TransTemplate->new(%$data);
    $template->save;
    $form->redirect( $locale->text('Template Saved!') );
}


sub display_row {
  my ($init) = @_;
  $form->{totaldebit}  = 0;
  $form->{totalcredit} = 0;

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
                LedgerSMB::PGNumber->from_input($form->{"debit_$i"});
            $form->{"credit_$i"} =
                LedgerSMB::PGNumber->from_input($form->{"credit_$i"});
            $form->{totaldebit}  += ($form->{"debit_$i"} // 0);
            $form->{totalcredit} += ($form->{"credit_$i"} // 0);

            for (qw(debit debit_fx credit credit_fx)) {
                $form->{"${_}_$i"} = ($form->{"${_}_$i"})
                    ? $form->format_amount( \%myconfig, $form->{"${_}_$i"}, LedgerSMB::Setting->new(%$form)->get('decimal_places') )
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

    # readonly
    if ( !$form->{readonly} ) {
        $form->{readonly} = 1
            if ($myconfig{acs}
                and $myconfig{acs} =~ /General Ledger--Add Transaction/);
    }
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

sub gl_subtotal_tt {

    my %column_data;
    $subtotaldebit =
      $form->format_amount( \%myconfig, $subtotaldebit, LedgerSMB::Setting->new(%$form)->get('decimal_places'), " " );
    $subtotalcredit =
      $form->format_amount( \%myconfig, $subtotalcredit, LedgerSMB::Setting->new(%$form)->get('decimal_places'), " " );

    for (@column_index) { $column_data{$_} = " " }
    $column_data{class} = 'subtotal';

    $column_data{debit} = $subtotaldebit;
    $column_data{credit} = $subtotalcredit;

    $subtotaldebit  = 0;
    $subtotalcredit = 0;

    $sameitem = $ref->{ $form->{sort} };

    return \%column_data;
}

sub gl_subtotal {
    $subtotaldebit =
      $form->format_amount( \%myconfig, $subtotaldebit, LedgerSMB::Setting->new(%$form)->get('decimal_places'), "&nbsp;" );
    $subtotalcredit =
      $form->format_amount( \%myconfig, $subtotalcredit, LedgerSMB::Setting->new(%$form)->get('decimal_places'), "&nbsp;" );

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{debit} =
      "<th align=right class=listsubtotal>$subtotaldebit</td>";
    $column_data{credit} =
      "<th align=right class=listsubtotal>$subtotalcredit</td>";

    print "<tr class=listsubtotal>";
    for (@column_index) { print "$column_data{$_}\n" }
    print "</tr>";

    $subtotaldebit  = 0;
    $subtotalcredit = 0;

    $sameitem = $ref->{ $form->{sort} };

}


sub update {
    &create_links;
     my $min_lines = $form->get_setting('min_empty');
     $form->open_form unless $form->check_form;

     $form->{transdate} = LedgerSMB::PGDate->from_input($form->{transdate})->to_output();
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




sub post {
    if ($form->{id}){
       $form->error($locale->text('Cannot Repost Transaction'));
    }
    if (!$form->close_form){
        &update;
        $form->finalize_request();
    };
    $form->isblank( "transdate", $locale->text('Transaction Date missing!') );

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

sub delete {
    $form->error($locale->text('Cannot delete posted transaction'))
       if ($form->{approved});
    my $draft = LedgerSMB::DBObject::Draft->new(%$form);
    $draft->delete();
    delete $form->{id};
    delete $form->{reference};
    add();
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
    for (qw(id printed emailed)) { delete $form->{$_} }
    $form->{approved} = 0;
    &post;
}

1;
