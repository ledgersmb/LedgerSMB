=head1 NAME

LedgerSMB::IIAA - Common code abstracted out of IS, IR and AA

=cut
#====================================================================
# LedgerSMB
# Small Medium Business Accounting software
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
# Copyright (C) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: Jim Rawlings <jim@your-dba.com>
#
#======================================================================
#
# Commonality between IR, IS and AA
#
#======================================================================


package IIAA;

use Math::BigFloat;
use warnings;
use diagnostics;
use strict;

use LedgerSMB::PGDate;
use LedgerSMB::Setting;

sub process_form_barcode {
    my ($self, $myconfig, $form, $row, $barcode) = @_;
    my $dbh = $form->{dbh};
    my $query = q|
SELECT partnumber
  FROM parts
  JOIN makemodel ON parts.id = makemodel.parts_id
 WHERE barcode = ?
|;

    my $sth = $dbh->prepare($query)
        or $form->dberror($dbh->errstr);
    $sth->execute( $barcode )
        or $form->dberror($sth->errstr);
    my ($partnumber) = $sth->fetchrow_array;
    if ($sth->err) {
        $form->dberror($sth->errstr);
    }
    if (not $partnumber) {
        die "No part with barcode $barcode";
    }

    $form->{"partnumber_$row"} = $partnumber;
}

sub process_form_payments {

    my ($self, $myconfig, $form) = @_;
    my $dbh = $form->{dbh};
    my $query = q|
SELECT payment_post(?, ?, ?, ?, ?,
                    ?, ?, ARRAY[(select id from account where accno = ?)], ?,
                    ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?)
|;

    my $sth = $dbh->prepare($query)
        or $form->dberror($dbh->errstr);

    # add paid transactions
    if ($form->{paidaccounts} and $form->{paidaccounts} > 0) {
        for my $i ( 1 .. $form->{paidaccounts} ) {

            if ( $form->{"paid_$i"} ) {
                # variables in same order as arguments of payment_post sproc
                my $datepaid = $form->{"datepaid_$i"};
                my $eca_class = ($form->{vc} eq 'vendor') ? 1 : 2;
                my $eca_id = $form->{"$form->{vc}_id"};
                my $curr = $form->{currency};
                my $exchangerate;
                # no 'notes'
                # no 'gl description'
                my ($cashaccno) = split( /--/, $form->{"$form->{ARAP}_paid_$i"} );
                my $amount =
                    $form->parse_amount( $myconfig, $form->{"paid_$i"})->to_db;
                # no 'cash approved'
                my $source = $form->{"source_$i"};
                my $memo = $form->{"memo_$i"};
                my $trans_id = $form->{id};
                # none of the in_op_*
                # ###Verify that there's no overpayment going on!!

                if ( $form->{currency} eq $form->{defaultcurrency} ) {
                    $exchangerate = 1;
                }
                else {
                    $exchangerate =
                        $form->parse_amount( $myconfig,
                                             $form->{"exchangerate_$i"} )->to_db();
                }

                $sth->execute($datepaid, $eca_class, $eca_id, $curr,
                              $exchangerate, undef, undef, $cashaccno,
                              [$amount],
                              [$source], [$memo], [$trans_id], undef, undef,
                              undef, undef, undef, undef,

                              # Post payment lines as 'approved':
                              # the total transaction will be approved at some
                              # point; at that point, all lines will be
                              # considered to be approved too (unless they are
                              # explicitly *not* approved).
                              1)
                    or $form->dberror($sth->errstr);
            }
        }
    }
}


sub post_form_manual_tax {
    my ($self, $myconfig, $form, $sign, $pay_rec) = @_;
    my $dbh = $form->{dbh};
    my $invamount = 0;

    my $ac_sth = $dbh->prepare(
        "INSERT INTO acc_trans (chart_id, trans_id, transdate,
                                amount_bc, curr, amount_tc, source, memo)
                    VALUES ((select id from account where accno = ?),
                            ?, ?, ?, ?, ?, ?, ?)"
        ) or $form->dberror($dbh->errstr);
    my $tax_sth = $dbh->prepare(
        "INSERT INTO tax_extended (entry_id, tax_basis, rate)
                    VALUES (currval('acc_trans_entry_id_seq'), ?, ?)"
        ) or $form->dberror($dbh->errstr);
    for my $taccno (split / /, $form->{taxaccounts}){
        my $taxamount;
        my $taxbasis;
        my $taxrate;
        my $fx = $form->{exchangerate} || 1;
        $taxamount = $form->parse_amount($myconfig,
                                         $form->{"mt_amount_$taccno"})
            * ($form->{reverse} ? -1 : 1);
        $taxbasis = $form->parse_amount($myconfig,
                                        $form->{"mt_basis_$taccno"})
            * ($form->{reverse} ? -1 : 1);
        $taxrate=$form->parse_amount($myconfig,$form->{"mt_rate_$taccno"});
        my $fx_taxamount = $taxamount * $fx;
        my $fx_taxbasis = $taxbasis * $fx;
        $form->{$pay_rec} += $fx_taxamount * $sign * -1;
        $invamount += $fx_taxamount;

        if ($fx_taxamount != 0 or $fx_taxbasis != 0) {
            $ac_sth->execute($taccno, $form->{id}, $form->{transdate},
                             $fx_taxamount * $sign,
                             $form->{defaultcurrency},
                             $fx_taxamount * $sign,
                             $form->{"mt_ref_$taccno"},
                             $form->{"mt_desc_$taccno"})
                or $form->dberror($ac_sth->errstr);
            $tax_sth->execute($fx_taxbasis * $sign, $taxrate)
                or $form->dberror($tax_sth->errstr);
        }
    }
    $ac_sth->finish;
    $tax_sth->finish;

    return $invamount;
}

sub createlocation
{


  my ( $self,$form ) = @_;

  my $dbh=$form->{dbh};

  my $query="select * from eca__location_save(?,?,?,?,?,?,?,?,?,?, null);";

  my $sth=$dbh->prepare("$query");

   $sth->execute($form->{"customer_id"} // $form->{"vendor_id"},
         undef,
         3,  ## no critic (ProhibitMagicNumbers) sniff
         $form->{"shiptoaddress1_new"},
         $form->{"shiptoaddress2_new"},
         $form->{"shiptoaddress3_new"},
         $form->{"shiptocity_new"},
         $form->{"shiptostate_new"},
         $form->{"shiptozipcode_new"},
         $form->{"shiptocountry_new"}
            ) || $form->dberror($query);
  my ($l_id) = $sth->fetchrow_array;
  $sth->finish();
  return $l_id;
}



sub createcontact
{

  my ( $self,$form ) = @_;

  my $dbh=$form->{dbh};

  my $query="select * from eca__save_contact(?,?,?,?,?,?);";

  my $sth=$dbh->prepare("$query");

  $sth->execute($form->{"customer_id"} // $form->{"vendor_id"},
                $form->{"shiptotype_new"},
                $form->{"shiptodescription_new"},
                $form->{"shiptocontact_new"},
                $form->{"shiptocontact_new"},
                $form->{"shiptotype_new"})
      || $form->dberror($query);

  $sth->finish();

}


sub trans_taxaccounts {
    my ($self, $form) = @_;
    if (not $form->{id}) {
        return ();
    }

    my $dbh   = $form->{dbh};
    my $query = q|
       select distinct accno
         from account
         join acc_trans on account.id = acc_trans.chart_id
        where account.tax
               and acc_trans.trans_id = ?|;
    my $sth   = $dbh->prepare($query)
        or die $form->dberror($query);

    $sth->execute( $form->{id} )
        or die $form->dberror($query);

    my @accounts;
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        push @accounts, $ref->{accno};
    }

    return @accounts;
}


sub prepare_invoice {
    my ($self, $form, $myconfig, %args)            = @_;
    $form->{type}       = "invoice";

    my $i = 0;
    $form->{currency} =~ s/ //g;
    $form->{oldcurrency} = $form->{currency};

    if ( $form->{id} ) {
        unless ($args{unquoted}) {
            for (qw(invnumber ordnumber ponumber quonumber shippingpoint
                    shipvia notes intnotes)) {
                $form->{$_} = $form->quote( $form->{$_} );
            }
        }

        foreach my $ref ( @{ $form->{invoice_details} } ) {
            $i++;
            for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }

            $form->{"projectnumber_$i"} =
              qq|$ref->{projectnumber}--$ref->{project_id}|
              if $ref->{project_id};
            $form->{"partsgroup_$i"} =
              qq|$ref->{partsgroup}--$ref->{partsgroup_id}|
              if $ref->{partsgroup_id};

            $form->{"discount_$i"} =
              $form->format_amount( $myconfig, $form->{"discount_$i"} * 100 );

            my $moneyplaces = LedgerSMB::Setting->new(%$form)->get('decimal_places');
            my ($dec) = ($form->{"sellprice_$i"} =~/\.(\d*)/);
            $dec = length $dec;
            my $decimalplaces = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;
            $form->{"precision_$i"} = $decimalplaces;

            $form->{"sellprice_$i"} =
              $form->format_amount( $myconfig, $form->{"sellprice_$i"},
                $decimalplaces );
            $form->{"qty_$i"} =
              $form->format_amount( $myconfig, $form->{"qty_$i"} );
            $form->{"oldqty_$i"} = $form->{"qty_$i"};

        $form->{"taxformcheck_$i"}=1 if($args{module}->get_taxcheck($form,$form->{"invoice_id_$i"},$form->{dbh}));


            unless ($args{unquoted}) {
                for (qw(partnumber sku description unit)) {
                    $form->{"${_}_$i"} = $form->quote( $form->{"${_}_$i"} );
                }
            }
            $form->{rowcount} = $i;
        }
    }
}

sub print_wf_history_table {
    my ($self, $form, $type) = @_;
    my $locale = $form->{_locale};

    print sprintf(q|
        <table width=100%>
         <caption>History</caption>
           <tr><th>%s</th><th>%s</th><th>%s</th></tr>
         <tbody>
|, $locale->text('Action'), $locale->text('User Name'), $locale->text('Time'));
    # insert history items
    my $wf = $form->{_wire}->get('workflows')
        ->fetch_workflow( $type, $form->{workflow_id} );
    if ($wf) {
        my @history = $wf->get_history;
        for my $h (sort { $a->id <=> $b->{id} } @history) {
            my ($desc, $addn) = split( /[|]/, $h->description, 2);
            my $link = '';
            if ($addn) {
                my %items = split(/[|:]/, $addn);
                my %links = (
                    'AR/AP|customer' => 'is.pl?__action=edit&amp;workflow_id=',
                    'AR/AP|vendor'   => 'ir.pl?__action=edit&amp;workflow_id=',
                    'Order/Quote'    => 'oe.pl?__action=edit&amp;workflow_id=',
                    'Email'          => 'email.pl?__action=render&amp;id=',
                    );
                my ($id, $workflow) = split(/,/, $items{spawned_workflow}, 2);
                $link = ($links{$workflow}
                         // $links{"$workflow|$form->{vc}"}) . $id;
                $link .= "&amp;callback=$form->{script}%3Faction%3D$form->{__action}%26id%3D$form->{id}";
            }
            my $user = $h->user;
            my $timestamp = $h->date;
            my $dt = LedgerSMB::PGDate->from_db($timestamp . "")->to_output();
            if ($link) {
                print qq|<tr><td><a href="$link">$desc</a></td><td>$user</td><td>$dt</td></tr>|;
            }
            else {
                print qq|<tr><td>$desc</td><td>$user</td><td>$dt</td></tr>|;
            }
        }
    }
    print qq|
      </tbody>
      </table>
|;
}


1;
