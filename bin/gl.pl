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

use LedgerSMB::GL;
use LedgerSMB::PE;
use LedgerSMB::Template;

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
    require "pos.conf.pl";
    $form->{accno_1} = $pos_config{'close_cash_accno'};
    $form->{accno_2} = $pos_config{'coa_prefix'};
    $form->{accno_3} = $pos_config{'coa_prefix'};
}

sub edit_and_approve {
    use LedgerSMB::DBObject::Draft;
    use LedgerSMB;
    check_balanced($form);
    my $lsmb = LedgerSMB->new();
    $lsmb->merge($form);
    my $draft = LedgerSMB::DBObject::Draft->new({base => $lsmb});
    $draft->delete();
    GL->post_transaction( \%myconfig, \%$form, $locale);
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
     for my $row (1 .. $form->{rowcount}){
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

sub add {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &create_links;
    $form->{reference} = $form->update_defaults(\%myconfig, 'glnumber');
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
    #Add General Ledger Transaction
    $form->close_form;
    $form->open_form; 
    $form->{dbh}->commit;
    my ($init) = @_; 
    # Form header part begins -------------------------------------------
    if (@{$form->{all_department}}){
        unshift @{ $form->{all_department} }, {};
    }
    if (@{$form->{all_project}}){
       unshift @{ $form->{all_project} }, {};
    }
    $title = $form->{title};
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
    'action' => $form->{action},
    'direction' => $form->{direction},
    'oldsort' => $form->{oldsort},
    'path' => $form->{path},
    'login' => $form->{login},
    'sessionid' => $form->{sessionid},
    'batch_id' => $form->{batch_id},
    'id' => $form->{id},
    'transfer' => $form->{transfer},
    'closedto' => $form->{closedto},
    'locked' => $form->{locked},
    'oldtransdate' => $form->{oldtransdate},
    'recurring' => $form->{recurring},
    'title' => $title,
    'approved' => $form->{approved}
    );
        
   
    #Disply_Row Part  Begins-------------------------------------

    our @displayrows;
    &display_row($init);
   
    #Form footer  Begins------------------------------------------

  for (qw(totaldebit totalcredit)) {
      $form->{$_} =
	$form->format_amount( \%myconfig, $form->{$_}, 2, "0" );
  }

  $hiddens{sessionid}=$form->{sessionid};
  $hiddens{callback}=$form->{callback};
  $hiddens{form_id}= $form->{form_id};
  $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
  $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );
  my @buttons;
  if ( !$form->{readonly} ) {
	      my $i=1;
	      %button = (
		  'update' =>
		    { ndx => 1, key => 'U', value => $locale->text('Update') },
		  'post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
		  'post_as_new' =>
		    { ndx => 6, key => 'N', value => $locale->text('Post as new') },
		  'schedule' =>
		    { ndx => 7, key => 'H', value => $locale->text('Schedule') },
		  'delete' =>
		    { ndx => 8, key => 'D', value => $locale->text('Delete') },
                  'new' => 
                    { ndx => 9, key => 'N', value => $locale->text('New') },
	      );

	      if ($form->{separate_duties}){            
		  $hiddens{separate_duties}=$form->{separate_duties};
		  $button{post}->{value} = $locale->text('Save'); 
	      }
	      %a = ();
              if ($form->{id}){
                 $a{'new'} = 1;
                 
              } else {
                 $a{'update'} = 1;
              }
	      if ( $form->{id} && ($form->{approved} || !$form->{batch_id})) {

		  for ( 'post_as_new', 'schedule' ) { $a{$_} = 1 }

		  if ( !$form->{locked} ) {
		      if ( $transdate ge $closedto) {
			  for ( 'post', 'delete' ) { $a{$_} = 1 }
		      }
		  }

	      }
	      elsif (!$form->{id}){
		  if ( $transdate > $closedto ) {
		      for ( "post", "schedule" ) { $a{$_} = 1 }
		  }
	      }

	      if ($form->{id} && (!$form->{approved} && !$form->{batch_id})){
		$button{approve} = { 
			ndx   => 3, 
			key   => 'S', 
			value => $locale->text('Post as Saved') };
		$a{approve} = 1;
		$a{edit_and_approve} = 1;
		if (grep /^lsmb_$form->{company}__draft_modify$/, @{$form->{_roles}}){
		    $button{edit_and_approve} = { 
			ndx   => 4, 
			key   => 'O', 
			value => $locale->text('Post as Shown') };
		}
		delete $button{post_as_new};
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

  if ( $form->{lynx} ) {
      require "bin/menu.pl";
      &menubar;
  }

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
	if ($init)
	{
			      $temphash1->{accnoset}=0;   #use  @{ $form->{all_accno} }
			      $temphash1->{projectset}=0; #use  @{ $form->{all_project} }
			      $temphash1->{fx_transactionset}=0;    #use checkbox and value=1 if transfer=1
			      
        }
        else
	{	    
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


			      if ( $i < $form->{rowcount} )
			      {					      
						    $temphash1->{accno}=$form->{"accno_$i"};
						    $temhash1->{fx_transaction}=$form->{"fx_transaction_$i"};

						    if ( $form->{projectset} and $form->{"projectnumber_$i"} ) {
							$temphash1->{projectnumber}=$form->{"projectnumber_$i"}; 
							$temphash1->{projectnumber}=~ s/--.*//;
								
						    }
						    
						    if ( $form->{transfer} and $form->{"fx_transaction_$i"})
						    {
							  $hiddens{"fx_transaction_$i"}=1; 
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




sub search {

    $form->{title} = $locale->text('General Ledger Reports');

    $colspan = 5;

    $form->all_departments( \%myconfig );

    # departments
    if ( @{ $form->{all_department} } ) {
        unshift @{ $form->{all_department} }, {id => "", description => ""};
    }

    @{$form->{all_accounts}} = $form->all_accounts;
    unshift @{$form->{all_accounts}}, {id => "", accno => ""};

    if ( @{ $form->{all_years} } ) {
        # accounting years
        for ( @{ $form->{all_years} } ) {
             $_ = {year => $_};
        }
        unshift @{ $form->{all_years} }, {};
        $form->{accountingmonths} = [];
        for ( sort keys %{ $form->{all_month} } ) {
            push @{$form->{accountingmonths}}, 
                {id     => $_,
                 month  => $locale->text( $form->{all_month}{$_} )};
        }

    }
    
    my $template = LedgerSMB::Template->new(
        user => \%myconfig,
        locale => $locale,
        path => 'UI/journal',
        template => 'search',
        format => 'HTML',
        );
    $template->render($form);
    
}

sub generate_report {
    my $output_options = shift;
    if ($form->{account}){
        ($form->{accno}) = split /--/, $form->{account};
    }
    $form->{sort} = "transdate" unless $form->{sort};
    $form->{amountfrom} = $form->parse_amount(\%myconfig, $form->{amountfrom});
    $form->{amountto} = $form->parse_amount(\%myconfig, $form->{amountto});
    my ($totaldebit, $totalcredit)=(new Math::BigFloat(0),new Math::BigFloat(0));

    GL->all_transactions( \%myconfig, \%$form );

    $href =
"$form->{script}?action=generate_report&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $callback =
"$form->{script}?action=generate_report&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    my %hiddens = (
        'action' => 'generate_report',
        'direction' => $form->{direction},
        'oldsort' => $form->{oldsort},
        'path' => $form->{path},
        'login' => $form->{login},
        'sessionid' => $form->{sessionid},
        );
    %acctype = (
        'A' => $locale->text('Asset'),
        'L' => $locale->text('Liability'),
        'Q' => $locale->text('Equity'),
        'I' => $locale->text('Income'),
        'E' => $locale->text('Expense'),
    );
    my @options;
    if ($form->{chart_accno}){
        $form->{title} = $locale->text('General Ledger: [_1] [_2]', $form->{chart_accno}, $form->{chart_description});
    } else {
        $form->{title} = $locale->text('General Ledger');
    }
    $ml=new Math::BigFloat(($form->{category} =~ /(A|E)/)?-1:1);

    if (defined $form->{category} and $form->{category} ne 'X' ) {
        $form->{title} .=
          " : " . $locale->text( $acctype{ $form->{category} } );
    }
    if ( $form->{accno} ) {
        $href .= "&accno=" . $form->escape( $form->{accno} );
        $callback .= "&accno=" . $form->escape( $form->{accno}, 1 );
        $hiddens{accno} = $form->{accno};
        push @options, $locale->text('Account')
          . " : $form->{accno} $form->{account_description}";
    }
    if ( $form->{gifi_accno} ) {
        $href     .= "&gifi_accno=" . $form->escape( $form->{gifi_accno} );
        $callback .= "&gifi_accno=" . $form->escape( $form->{gifi_accno}, 1 );
        $hiddens{gifi_accno} = $form->{gifi_accno};
        push @options, $locale->text('GIFI')
          . " : $form->{gifi_accno} $form->{gifi_account_description}";
    }
    if ( $form->{source} ) {
        $href     .= "&source=" . $form->escape( $form->{source} );
        $callback .= "&source=" . $form->escape( $form->{source}, 1 );
        $hiddens{source} = $form->{source};
        push @options, $locale->text('Source') . " : $form->{source}";
    }
    if ( $form->{memo} ) {
        $href     .= "&memo=" . $form->escape( $form->{memo} );
        $callback .= "&memo=" . $form->escape( $form->{memo}, 1 );
        $hiddens{memo} = $form->{memo};
        push @options, $locale->text('Memo') . " : $form->{memo}";
    }
    if ( $form->{reference} ) {
        $href     .= "&reference=" . $form->escape( $form->{reference} );
        $callback .= "&reference=" . $form->escape( $form->{reference}, 1 );
        $hiddens{reference} = $form->{reference};
        push @options, $locale->text('Reference') . " : $form->{reference}";
    }
    if ( $form->{department} ) {
        $href .= "&department=" . $form->escape( $form->{department} );
        $callback .= "&department=" . $form->escape( $form->{department}, 1 );
        $hiddens{department} = $form->{department};
        ($department) = split /--/, $form->{department};
        push @options, $locale->text('Department') . " : $department";
    }

    if ( $form->{description} ) {
        $href     .= "&description=" . $form->escape( $form->{description} );
        $callback .= "&description=" . $form->escape( $form->{description}, 1 );
        $hiddens{description} = $form->{description};
        push @options, $locale->text('Description') . " : $form->{description}";
    }
    if ( $form->{notes} ) {
        $href     .= "&notes=" . $form->escape( $form->{notes} );
        $callback .= "&notes=" . $form->escape( $form->{notes}, 1 );
        $hiddens{notes} = $form->{notes};
        push @options, $locale->text('Notes') . " : $form->{notes}";
    }

    if ( $form->{datefrom} ) {
        $href     .= "&datefrom=$form->{datefrom}";
        $callback .= "&datefrom=$form->{datefrom}";
        $hiddens{datefrom} = $form->{datefrom};
        push @options, $locale->text('From') . " "
          . $locale->date( \%myconfig, $form->{datefrom}, 1 );
    }
    if ( $form->{dateto} ) {
        $href     .= "&dateto=$form->{dateto}";
        $callback .= "&dateto=$form->{dateto}";
        $hiddens{dateto} = $form->{dateto};
        my $option = $locale->text('To') . " "
          . $locale->date( \%myconfig, $form->{dateto}, 1 );
        if ( $form->{datefrom} ) {
            $options[$#options] .= " $option";
        }
        else {
            push @options, $option;
        }
    }

    if ( $form->{amountfrom} ) {
        $href     .= "&amountfrom=$form->{amountfrom}";
        $callback .= "&amountfrom=$form->{amountfrom}";
        $hiddens{amountfrom} = $form->{amountfrom};
        push @options, $locale->text('Amount') . " >= "
          . $form->format_amount( \%myconfig, $form->{amountfrom}, 2 );
    }
    if ( $form->{amountto} ) {
        $href     .= "&amountto=$form->{amountto}";
        $callback .= "&amountto=$form->{amountto}";
        $hiddens{amountto} = $form->{amountto};
        my $option .= $form->format_amount( \%myconfig, $form->{amountto}, 2 );
        if ( $form->{amountfrom} ) {
            $options[$#options] .= " <= $option";
        }
        else {
            push @options, $locale->text('Amount') . " <= $option";
        }
    }
    @columns =
      $form->sort_columns(
        qw(transdate id reference description notes source memo debit credit accno gifi_accno department)
      );
    if ($form->{bank_register_mode}){
        @columns = $form->sort_columns(
            qw(transdate id reference description notes source memo credit debit accno
               gifi_accno department)
        );
    }
    pop @columns if $form->{department};

    if ( $form->{link} =~ /_paid/ ) {
        @columns =
          $form->sort_columns(
            qw(transdate id reference description notes source memo cleared debit credit accno gifi_accno)
          );
        if ($form->{bank_register_mode}){
            @columns = $form->sort_columns(
                qw(transdate id reference description notes source memo cleared credit
                   debit accno gifi_accno)
            );
        }
        $form->{l_cleared} = "Y";
    }

    if ( $form->{chart_id} || $form->{gifi_accno} ) {
        @columns = grep !/(accno|gifi_accno)/, @columns;
        push @columns, "balance";
        $form->{l_balance} = "Y";
    }

    foreach $item (@columns) {
        if ( $form->{"l_$item"} eq "Y" ) {
            push @column_index, $item;

            # add column to href and callback
            $callback .= "&l_$item=Y";
            $href     .= "&l_$item=Y";
            $hiddens{"l_$item"} = 'Y';
        }
    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        $callback .= "&l_subtotal=Y";
        $href     .= "&l_subtotal=Y";
        $hiddens{l_subtotal} = 'Y';
    }

    $callback .= "&category=$form->{category}";
    $href     .= "&category=$form->{category}";
    $hiddens{category} = $form->{category};

    my $column_names = {
        id => 'ID',
        transdate => 'Date',
        reference => 'Reference',
        source => 'Source',
        memo => 'Memo',
        description => 'Description',
        department => 'Department',
        notes => 'Notes',
        debit => 'Debit',
        credit => 'Credit',
        accno => 'Account',
        gifi_accno => 'GIFI',
        balance => 'Balance',
        cleared => 'R'
    };
    if ($form->{bank_register_mode}){
        $column_names->{credit} = 'Debit';
        $column_names->{debit} = 'Credit';
    }
    my $sort_href = "$href&sort";
    my @sort_columns = qw(id transdate reference source memo description department accno gifi_accno);

    # add sort to callback
    $form->{callback} = "$callback&sort=$form->{sort}";
    $callback = $form->escape( $form->{callback} );
    $hiddens{sort} = $form->{sort};
    $hiddens{callback} = $form->{callback};

    $cml=new Math::BigFloat(1);

    # initial item for subtotals
    if ( @{ $form->{GL} } ) {
        $sameitem = $form->{GL}->[0]->{ $form->{sort} };
        $cml=new Math::BigFloat(-1) if $form->{contra};
    }

    my @rows;
    if ( ( $form->{accno} || $form->{gifi_accno} ) && $form->{balance} ) {
        my %column_data;

        for (@column_index) { $column_data{$_} = " " }
        $column_data{balance} = 
            $form->format_amount( \%myconfig, $form->{balance} * $ml * $cml,
            2, 0 );

	$column_data{i} = 1;
        push @rows, \%column_data;
    }

    # reverse href
    # XXX: should we use the reversed href as the sort_href url above ?
    $direction = ( $form->{direction} eq 'ASC' ) ? "ASC" : "DESC";
    $form->sort_order();
    $href =~ s/direction=$form->{direction}/direction=$direction/;

    my $i = 0;
    foreach $ref ( @{ $form->{GL} } ) {
        my %column_data;

        # if item ne sort print subtotal
        if ( $form->{l_subtotal} eq 'Y' ) {
            if ( $sameitem ne $ref->{ $form->{sort} } ) {
                push @rows, &gl_subtotal_tt();
            }
        }

        $form->{balance} += $ref->{amount};

        $subtotaldebit  += $ref->{debit};
        $subtotalcredit += $ref->{credit};

        $totaldebit  += $ref->{debit};
        $totalcredit += $ref->{credit};

        $ref->{debit} =
          $form->format_amount( \%myconfig, $ref->{debit}, 2);
        $ref->{credit} =
          $form->format_amount( \%myconfig, $ref->{credit}, 2);

        for (qw(id transdate)) { $column_data{$_} = "$ref->{$_}" }

        $column_data{reference} =
            {href => "$ref->{module}.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback",
            text => $ref->{reference}};

        #$ref->{notes} =~ s/\r?\n/<br>/g;
        for (qw(description source memo notes department)) {
            $column_data{$_} = "$ref->{$_} ";
        }

        $column_data{debit}  = "$ref->{debit}";
        $column_data{credit} = "$ref->{credit}";

        $column_data{accno} =
            {href => "$href&accno=$ref->{accno}&callback=$callback",
            text => "$ref->{accno} $ref->{accname}"};
        $column_data{gifi_accno} =
            {href => "$href&gifi_accno=$ref->{gifi_accno}&callback=$callback",
            text => $ref->{gifi_accno}};
        $column_data{balance} = $form->format_amount( \%myconfig, $form->{balance} * $ml * $cml,
            2, 0 );
        $column_data{cleared} =
          ( $ref->{cleared} ) ? "*" : " ";

        if ( $ref->{id} != $sameid ) {
            $i++;
            $i %= 2;
        }
	$column_data{'i'} = $i;
        push @rows, \%column_data;

        $sameid = $ref->{id};
    }

    push @rows, &gl_subtotal_tt() if ( $form->{l_subtotal} eq 'Y' );

    for (@column_index) { $column_data{$_} = " " }
    $column_data{debit} = $form->format_amount( \%myconfig, $totaldebit, 2, " " );
    $column_data{credit} = $form->format_amount( \%myconfig, $totalcredit, 2, " " );
    $column_data{balance} = $form->format_amount( \%myconfig, $form->{balance} * $ml * $cml, 2, 0 );

    $i = 1;
    my %button;
    if ( $myconfig{acs} !~ /General Ledger--General Ledger/ ) {
        $button{'General Ledger--Add Transaction'} = {
            name => 'action',
            value => 'gl_transaction',
            text => $locale->text('GL Transaction'),
            type => 'submit',
            class => 'submit',
            order => $i++};
    }
    if ( $myconfig{acs} !~ /AR--AR/ ) {
        $button{'AR--Add Transaction'} = {
            name => 'action',
            value => 'ar_transaction',
            text => $locale->text('AR Transaction'),
            type => 'submit',
            class => 'submit',
            order => $i++};
        $button{'AR--Sales Invoice'} = {
            name => 'action',
            value => 'sales_invoice_',
            text => $locale->text('Sales Invoice'),
            type => 'submit',
            class => 'submit',
            order => $i++};
    }
    if ( $myconfig{acs} !~ /AP--AP/ ) {
        $button{'AP--Add Transaction'} = {
            name => 'action',
            value => 'ap_transaction',
            text => $locale->text('AP Transaction'),
            type => 'submit',
            class => 'submit',
            order => $i++};
        $button{'AP--Vendor Invoice'} = {
            name => 'action',
            value => 'vendor_invoice_',
            text => $locale->text('Vendor Invoice'),
            type => 'submit',
            class => 'submit',
            order => $i++};
    }

    foreach $item ( split /;/, $myconfig{acs} ) {
        delete $button{$item};
    }

    my @buttons;
    foreach my $item ( sort { $a->{order} <=> $b->{order} } %button ) {
        push @buttons, $item if ref $item;
    }
    push @buttons, {
        name => 'action',
        value => 'csv_gl_report',
        text => $locale->text('CSV Report'),
        type => 'submit',
        class => 'submit',
    };
    push @buttons, {
        name => 'action',
        value => 'csv_email_gl_report',
        text => $locale->text('Email CSV Report'),
        type => 'submit',
        class => 'submit',
    };

##SC: Taking this out for now...
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my %row_alignment = (
        'balance' => 'right',
        'debit' => 'right',
        'credit' => 'right'
        );
    my $template;
    my $format = uc substr($form->{action}, 0, 3);
    my $template = LedgerSMB::Template->new(
        user => \%myconfig,
        locale => $locale,
        path => 'UI',
        template => 'form-dynatable',
        format => ($format ne 'CSV')? 'HTML': 'CSV',
        output_options => $output_options,
        );
    $template->{method} = 'email' if $output_options;
 
    my $column_heading = $template->column_heading($column_names,
        {href => $sort_href, columns => \@sort_columns}
    );

   $template->render({
        form => \%$form,
        buttons => \@buttons,
        hiddens => \%hiddens,
        options => \@options,
        columns => \@column_index,
        heading => $column_heading,
        rows => \@rows,
        row_alignment => \%row_alignment,
        totals => \%column_data,
    });


    $form->info($locale->text('GL report sent to [_1]', $form->{login}));

}



sub edit {

    &create_links;

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
    foreach $ref ( @{ $form->{GL} } ) {
        $form->{"accno_$i"} = "$ref->{accno}--$ref->{description}";
        $form->{"projectnumber_$i"} = "$ref->{projectnumber}--$ref->{project_id}";
        for (qw(fx_transaction source memo)) { $form->{"${_}_$i"} = $ref->{$_} }
        if ( $ref->{amount} < 0 ) {
            $form->{totaldebit} -= $ref->{amount};
            $form->{"debit_$i"} = $ref->{amount} * -1;
        }
        else {
            $form->{totalcredit} += $ref->{amount};
            $form->{"credit_$i"} = $ref->{amount};
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


    # departments
    if ( @{ $form->{all_department} } ) {
        $form->{departmentset} = 1;
        for ( @{ $form->{all_department} } ) {
            $_->{departmentstyle}=$_->{description}."--".$_->{id};
        }
    }

    # projects
    if ( @{ $form->{all_project} } ) {
       $form->{projectset}=1; 
       for ( @{ $form->{all_project} } ) {
	  $_->{projectstyle}=$_->{projectnumber}."--".$_->{id};
       }
    }

  

}

sub csv_gl_report { &generate_report }
sub csv_email_gl_report {
    ##SC: XXX hardcoded test values
    &generate_report({
        to => 'seneca@localhost',
        from => 'seneca@localhost',
        subject => 'CSV GL report',
    });
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

     if ( $form->{transdate} ne $form->{oldtransdate} ) {
         $form->{oldtransdate} = $form->{transdate};
     }

    @a     = ();
    $count = 0;
    @flds  = qw(accno debit credit projectnumber fx_transaction source memo);

    for $i ( 0 .. $form->{rowcount} ) {
        unless ( ( $form->{"debit_$i"} eq "" )
            && ( $form->{"credit_$i"} eq "" ) )
        {
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

    $form->{rowcount} = $count;
 
    GL->get_all_acc_dep_pro( \%myconfig, \%$form );
    
    
    &display_form;
}




sub delete {

    my %hiddens;
    delete $form->{action};
    foreach (keys %$form) {
        $hiddens{$_} = $form->{$_} unless ref $form->{$_};
    }

    $form->{title} = $locale->text('Confirm!');
    my $query = $locale->text(
        'Are you sure you want to delete Transaction [_1]',
        $form->{reference} );

    my @buttons = ({
        name => 'action',
        value => 'delete_transaction',
        text => $locale->text('Yes'),
        });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-confirmation',
        );
    $template->render({
        form => $form,
        query => $query,
        hiddens => \%hiddens,
        buttons => \@buttons,
    });
}

sub delete_transaction {

    if ( GL->delete_transaction( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Transaction deleted!') );
    }
    else {
        $form->error( $locale->text('Cannot delete transaction!') );
    }

}

sub post {
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

    if ( GL->post_transaction( \%myconfig, \%$form, $locale) ) {
        edit();
    }
    else {
        $form->error( $locale->text('Cannot post transaction!') );
    }

}

sub check_balanced {
    my ($form) = @_;
    # add up debits and credits
    for $i ( 0 .. $form->{rowcount} ) {
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

