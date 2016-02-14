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
use LedgerSMB::Template;
use LedgerSMB::Setting::Sequence;
use LedgerSMB::Company_Config;

require 'bin/bridge.pl'; # needed for voucher dispatches
require "bin/arap.pl";

$form->{login} = 'test';
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

sub pos_adjust {
    $form->{rowcount} = 3;
    eval {require "pos.conf.pl"} || $form->error($locale->text(
      "Could not open pos.conf.pl in [_1] line [_2]: [_3]",
       __FILE__, __LINE__, $!));
    $form->{accno_1} = $pos_config{'close_cash_accno'};
    $form->{accno_2} = $pos_config{'coa_prefix'};
    $form->{accno_3} = $pos_config{'coa_prefix'};
}

sub edit_and_save {
    use LedgerSMB::DBObject::Draft;
    use LedgerSMB;
    check_balanced($form);
    my $lsmb = LedgerSMB->new();
    $lsmb->merge($form);
    my $draft = LedgerSMB::DBObject::Draft->new({base => $lsmb});
    $draft->delete();
    GL->post_transaction( \%myconfig, \%$form, $locale);
    edit();
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
        print qq|<html><body class="lsmb $form->{dojo_theme}">|;
        my $url = $form->{callback};
        print qq|If you are not redirected automatically, click <a href="$url">|
                . qq|here</a>.</body></html>|;

    } else {
        $form->info($locale->text('Draft Posted'));
    }
}

sub add_pos_adjust {
    $form->{pos_adjust} = 1;
    $form->{reference} =
      $locale->text("Adjusting Till: (till) Source: (source)");
    $form->{description} =
      $locale->text("Adjusting till due to data entry error.");
    $form->{callback} =
"$form->{script}?action=add_pos_adjust&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};
    &add;
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
     update();
}

sub add {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    if (!$form->{rowcount}){
        $form->{rowcount} = ( $form->{transfer} ) ? 3 : 9;
    }
    if ( $form->{pos_adjust} ) {
        &pos_adjust;
    }
    $form->{oldtransdate} = $form->{transdate};
    $form->{focus}        = "reference";
    display_form(1);

}


sub display_form
{
    $form->{separate_duties}
        = $LedgerSMB::Company_Config::settings->{separate_duties};
    #Add General Ledger Transaction
    $form->all_business_units($form->{transdate}, undef, 'GL');
    @{$form->{sequences}} = LedgerSMB::Setting::Sequence->list('glnumber')
         unless $form->{id};
    $form->close_form;
    $form->open_form;
    my ($init) = @_;
    # Form header part begins -------------------------------------------
    if (@{$form->{all_department}}){
        unshift @{ $form->{all_department} }, {};
    }
    if (@{$form->{all_project}}){
       unshift @{ $form->{all_project} }, {};
    }
    $title = $locale->text("$form->{title}");
    if ( $form->{transfer} ) {
        $form->{title} = $locale->text("[_1] Cash Transfer Transaction", $title);
    }
    else {
        $form->{title} = $locale->text("[_1] General Ledger Transaction", $title);
    }

    for (qw(reference description notes)) {
        $form->{$_} = $form->quote( $form->{$_} );
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
    'path' => $form->{path},
    'login' => $form->{login},
    'session_id' => $form->{session_id},
    'batch_id' => $form->{batch_id},
    'id' => $form->{id},
    'transfer' => $form->{transfer},
    'closedto' => $form->{closedto},
    'locked' => $form->{locked},
    'oldtransdate' => $form->{oldtransdate},
    'recurring' => $form->{recurring},
    'title' => $title,
    'approved' => $form->{approved},
     'callback' => $form->{callback},
     'form_id' => $form->{form_id},
    );


    #Disply_Row Part  Begins-------------------------------------

    our @displayrows;
    &display_row($init);

    #Form footer  Begins------------------------------------------

  for (qw(totaldebit totalcredit)) {
      $form->{$_} =
    $form->format_amount( \%myconfig, $form->{$_}, 2, "0" );
  }

  $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
  $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );
  my @buttons;
  if ( !$form->{readonly} ) {
          my $i=1;
          %button = (
          'update' =>
            { ndx => 1, key => 'U', value => $locale->text('Update') },
          'post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
                  'edit_and_save' => {ndx => 4, key => 'V',
                          value => $locale->text('Save Draft') },
                  'save_temp' =>
                    { ndx   => 9,
                      key   => 'T',
                      value => $locale->text('Save Template') },
          'save_as_new' =>
            { ndx => 6, key => 'N', value => $locale->text('Save as new') },
          'schedule' =>
            { ndx => 7, key => 'H', value => $locale->text('Schedule') },
          'new' =>
            { ndx => 9, key => 'N', value => $locale->text('New') },
          'copy_to_new' =>
            { ndx => 10, key => 'C', value => $locale->text('Copy to New') },
	 );

          if ($form->{separate_duties}){
          $hiddens{separate_duties}=$form->{separate_duties};
          $button{post}->{value} = $locale->text('Save');
          }
          %a = ();
              $a{'save_temp'} = 1;

          if ( $form->{id}) {
              $a{'new'} = 1;

              for ( 'save_as_new', 'schedule', 'copy to new' ) { $a{$_} = 1 }

              for ( 'post', 'delete' ) { $a{$_} = 1 }
          } else {
              $a{'update'} = 1;
              if ( $transdate > $closedto ) {
                  for ( "post", "schedule" ) { $a{$_} = 1 }
              }
          }

          if ($form->{id} && (!$form->{approved} && !$form->{batch_id})){
        $button{approve} = {
            ndx   => 3,
            key   => 'S',
            value => $locale->text('Post') };
        $a{approve} = 1;
        $a{edit_and_save} = 1;
        $a{update} = 1;
        if (grep /__draft_edit$/, @{$form->{_roles}}){
            $button{edit_and_save} = {
            ndx   => 4,
            key   => 'O',
            value => $locale->text('Save Draft') };
        }
        delete $button{post};
          }
          if ($form->{id} && ($form->{approved} || $form->{batch_id})) {
          delete $button{post};
          }

          for ( keys %button ) { delete $button{$_} if !$a{$_} }
          my $i=1;
          for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
          {
                  push @buttons, {
                  name => 'action',
                  value => $_ ,
                  text => $button{$_}->{value},
                  type => 'submit',
                  class => 'submit',
                  accesskey => $button{$_}->{key},
                  order => $i
                        };
                  $i++;
          }

  }

  $form->{recurringset}=0;
  if ( $form->{recurring} ) {
      $form->{recurringset}=1;
  }
  my $template;
  my $template = LedgerSMB::Template->new(
                user => \%myconfig,
                locale => $locale,
                path => 'UI/journal',
                template => 'journal_entry',
                format => 'HTML',
                    );

  $template->render({
            form => \%$form,
            buttons => \@buttons,
            hiddens => \%hiddens,
            displayrows => \@displayrows
                   });

}


sub save_temp {
    use LedgerSMB;
    use LedgerSMB::DBObject::TransTemplate;
    my $lsmb = LedgerSMB->new();
    my ($department_name, $department_id) = split/--/, $form->{department};
    $lsmb->{department_id} = $department_id;
    $lsmb->{reference} = $form->{reference};
    $lsmb->{description} = $form->{description};
    $lsmb->{department_id} = $department_id;
    $lsmb->{post_date} = $form->{transdate};
    $lsmb->{type} = 'gl';
    $lsmb->{journal_lines} = [];
    for my $iter (0 .. $form->{rowcount}){
        if ($form->{"accno_$iter"} and
                  (($form->{"credit_$iter"} != 0) or ($form->{"debit_$iter"} != 0))){
             my ($acc_id, $acc_name) = split /--/, $form->{"accno_$iter"};
             my $amount = $form->{"credit_$iter"} || ( $form->{"debit_$iter"}
                                                     * -1 );
             push @{$lsmb->{journal_lines}},
                  {accno => $acc_id,
                   amount => $amount,
                   cleared => false,
                  };
        }
    }
    $template = LedgerSMB::DBObject::TransTemplate->new({base => $lsmb});
    $template->save;
    $form->redirect( $locale->text('Template Saved!') );
}


sub display_row
{

  my ($init) = @_;
  $form->{totaldebit}  = 0;
  $form->{totalcredit} = 0;

  for $i ( 0 .. $form->{rowcount} )
  {

        my $temphash1;
        $temphash1->{index}=$i;
        $temphash1->{source}=$form->{"source_$i"};#input box
    $temphash1->{memo}=$form->{"memo_$i"}; #input box;
    $temphash1->{accnoset}=1;
        $temphash1->{projectset}=1;
        $temphash1->{fx_transactionset}=1;
    if (!defined $form->{"accno_$i"} || ! $form->{"accno_$i"})
    {
                  $temphash1->{accnoset}=0;   #use  @{ $form->{all_accno} }
                  $temphash1->{projectset}=0; #use  @{ $form->{all_project} }
                  $temphash1->{fx_transactionset}=0;    #use checkbox and value=1 if transfer=1

        }
        else
    {
                              $form->{"debit_$i"} = LedgerSMB::PGNumber->from_input($form->{"debit_$i"});
                              $form->{"credit_$i"}= LedgerSMB::PGNumber->from_input($form->{"credit_$i"});
                  $form->{totaldebit}  += $form->{"debit_$i"};
                  $form->{totalcredit} += $form->{"credit_$i"};
                  for (qw(debit credit)) {
                  $form->{"${_}_$i"} =
                    ( $form->{"${_}_$i"} )
                    ? $form->format_amount( \%myconfig, $form->{"${_}_$i"}, 2 )
                    : "";
                  }

                  $temphash1->{debit}=$form->{"debit_$i"};
                  $temphash1->{credit}=$form->{"credit_$i"};
                              for my $cls(@{$form->{bu_class}}){
                                  $temphash1->{"b_unit_$cls->{id}"} =
                                         $form->{"b_unit_$cls->{id}_$i"};
                              }

                  if ( $i < $form->{rowcount} )
                  {
                            $temphash1->{accno}=$form->{"accno_$i"};

                            if ( $form->{projectset} and $form->{"projectnumber_$i"} ) {
                            $temphash1->{projectnumber}=$form->{"projectnumber_$i"};
                            $temphash1->{projectnumber}=~ s/--.*//;

                            }

                            if ( $form->{transfer} and $form->{"fx_transaction_$i"})
                            {
                            $temphash1->{fx_transactionset}=1;
                            }
                            else
                            {

                            $temphash1->{fx_transactionset}=0;
                            }
                            $hiddens{"accno_$i"}=$form->{"accno_$i"};
                            $hiddens{"projectnumber_$i"}=$form->{"projectnumber_$i"};

                  }
                  else
                  {
                            $temphash1->{accnoset}=0;   #use  @{ $form->{all_accno} }
                            $temphash1->{projectset}=0;   #use  @{ $form->{all_accno} }
                            $temphash1->{fx_transactionset}=0;

                  }

         }

         push @displayrows,$temphash1;

 }

$hiddens{rowcount}=$form->{rowcount};
$hiddens{pos_adjust}=$form->{pos_adjust};

}

sub edit {

    &create_links;

    $form->all_business_units($form->{transdate}, undef, 'GL');

    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );
    # readonly
    if ( !$form->{readonly} ) {
        $form->{readonly} = 1
          if $myconfig{acs} =~ /General Ledger--Add Transaction/;
    }
    $form->{title} = "Edit";
    if($form->{department_id})
    {
         $form->{department}=$form->{departmentdesc}."--".$form->{department_id};
    }
    $i = 0;

    my $minusOne    = new LedgerSMB::PGNumber(-1);#HV make sure BigFloat stays BigFloat
    my $plusOne     = new LedgerSMB::PGNumber(1);#HV make sure BigFloat stays BigFloat

    foreach $ref ( @{ $form->{GL} } ) {
        $form->{"accno_$i"} = "$ref->{accno}--$ref->{description}";
        $form->{"projectnumber_$i"} = "$ref->{projectnumber}--$ref->{project_id}";
        for (qw(fx_transaction source memo)) { $form->{"${_}_$i"} = $ref->{$_} }
        if ( $ref->{amount} < 0 ) {
            $form->{totaldebit} -= $ref->{amount};
            $form->{"debit_$i"} =  $ref->{amount} * $minusOne;
        }
        else {
            $form->{totalcredit} += $ref->{amount};
            $form->{"credit_$i"} =  $ref->{amount} * $plusOne;
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
      $form->format_amount( \%myconfig, $subtotaldebit, 2, " " );
    $subtotalcredit =
      $form->format_amount( \%myconfig, $subtotalcredit, 2, " " );

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
      $form->format_amount( \%myconfig, $subtotaldebit, 2, "&nbsp;" );
    $subtotalcredit =
      $form->format_amount( \%myconfig, $subtotalcredit, 2, "&nbsp;" );

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
     my $min_lines = $LedgerSMB::Company_Config::settings->{min_empty};

     $form->{transdate} = LedgerSMB::PGDate->from_input($form->{transdate})->to_output();
     if ( $form->{transdate} ne $form->{oldtransdate} ) {
         $form->{oldtransdate} = $form->{transdate};
     }

    $form->all_business_units($form->{transdate}, undef, 'GL');
    GL->get_all_acc_dep_pro( \%myconfig, \%$form );

    @a     = ();
    $count = 0;
    @flds  = qw(accno debit credit projectnumber fx_transaction source memo);
    for my $cls (@{$form->{bu_class}}){
        if (scalar @{$form->{b_units}->{$cls->{id}}}){
           push @flds, "b_unit_$cls->{id}";
        }
    }

    for $i ( 0 .. $form->{rowcount} ) {
        $form->{"debit_$i"} =~ s/\s+//g;
        $form->{"credit_$i"} =~ s/\s+//g;
        unless ( ( $form->{"debit_$i"} eq "" )
            && ( $form->{"credit_$i"} eq "" ) )
        {
            my $found_acc = 0;
            for my $acc(@{ $form->{all_accno} }){
                if ($form->{"accno_$i"} eq $acc->{accstyle}){
                    $found_acc = 1;
                } elsif ($form->{"accno_$i"} eq $acc->{accno}){
                    $form->{"accno_$i"} = $acc->{accstyle};
                    $found_acc = 1;
                }

           }
           if (not $found_acc){
               $form->error($locale->text('Account [_1] not found.', $form->{"accno_$i"}));
           }
            for (qw(debit credit)) {
                $form->{"${_}_$i"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }

            push @a, {};
            $j = $#a;

            for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
            $count++;
        }
    }

    for $i ( 1 .. $count ) {
        $j = $i - 1;
        for (@flds) { $form->{"${_}_$j"} = $a[$j]->{$_} }
    }

    for $i ( $count  .. $form->{rowcount} ) {
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
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    $form->error(
        $locale->text('Cannot post transaction for a closed period!') )
      if ( $transdate <= $closedto );

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
    my $lsmb = LedgerSMB->new();
    $lsmb->merge($form);
    my $draft = LedgerSMB::DBObject::Draft->new({base => $lsmb});
    $draft->delete();
    delete $form->{id};
    delete $form->{reference};
    add();
}


sub check_balanced {
    my ($form) = @_;
    # add up debits and credits
    for $i ( 0 .. $form->{rowcount} ) {
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

    if ( $form->round_amount( $debit, 2 ) != $form->round_amount( $credit, 2 ) )
    {
        $form->error( $locale->text('Out of balance transaction!') );
    }
}

sub save_as_new {
    for (qw(id printed emailed queued)) { delete $form->{$_} }
    $form->{approved} = 0;
    &post;
}
