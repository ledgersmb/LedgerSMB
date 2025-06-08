=pod

=head1 NAME

LedgerSMB::AA - Contains the routines for managing AR and AP transactions.

=head1 SYNOPSIS

This module contains the routines for managing AR and AP transactions and
many of the reorts (a few others are found in LedgerSMB::RP.pm).

All routines require $form->{dbh} to be set so that database actions can
be performed.

This module is due to be deprecated for active development as soon as a
replacement is available.

=cut

#=====================================================================
#
# AR/AP backend routines
# common routines
#
#======================================================================



package AA;
use Log::Any;
use LedgerSMB::File;
use LedgerSMB::PGNumber;
use LedgerSMB::Setting;

my $logger = Log::Any->get_logger(category => "AA");

=pod

=over

=item post_transaction()
Post transaction uses the following variables in the $form variable:
 * dbh - the database connection handle
 * currency - The current users' currency
 * defaultcurrency - The "normal" currency
 * department - Unknown
 * department_id - ID for the department
 * exchangerate - Conversion between currency and defaultcurrency
 * invnumber - invoice number
 * reverse - ?
 * rowcount - Number of rows in the invoice
 * taxaccounts - Apply taxes?
 * taxincluded - ?
 * transdate - Date of the transaction
 * vc - Vendor or customer - determines transaction type

=cut

sub post_transaction {
    use strict;

    my ( $self, $myconfig, $form ) = @_;
    $form->all_business_units;

    my $batch_class;
    my %paid;
    my $paidamount;
    for (1 .. $form->{rowcount}){
        $form->{"amount_$_"} = $form->parse_amount(
               $myconfig, $form->{"amount_$_"}
         );
        $form->{"amount_$_"} *= -1 if $form->{reverse};
    }

    $form->{crdate} ||= 'now';

    my $dbh = $form->{dbh};

    my $query;
    my $sth;

    my $null;
    ( $null, $form->{department_id} ) = split( /--/, $form->{department} );
    $form->{department_id} *= 1;

    my $ml        = 1;
    my $table     = 'ar';
    my $buysell   = 'buy';
    my $ARAP      = 'AR';
    my $invnumber = "sinumber";
    my $keepcleared;

    if ( $form->{vc} eq 'vendor' ) {
        $table     = 'ap';
        $buysell   = 'sell';
        $ARAP      = 'AP';
        $ml        = -1;
        $invnumber = "vinumber";
    }
    $form->{invnumber} = $form->update_defaults( $myconfig, $invnumber )
      if $form->should_update_defaults('invnumber');

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        $form->{exchangerate} = 1;
    }
    else {

        $form->{exchangerate} =
          $form->parse_amount( $myconfig, $form->{exchangerate} );
    }

    my @taxaccounts = split / /, $form->{taxaccounts};
    my $tax         = 0;
    my $fxtax       = 0;
    my $amount;
    my $diff        = 0;


    my %tax = ();
    my $accno;
    # add taxes
    foreach my $accno (@taxaccounts) {
        #tshvr HV parse first or problem at aa.pl create_links $form->{"${akey}_$form->{acc_trans}{$key}->[$i-1]->{accno}"}=$form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * $ml; 123,45 * -1  gives 123 !!
        $form->{"tax_$accno"}=$form->parse_amount($myconfig,$form->{"tax_$accno"});
        $form->{"tax_$accno"} *= -1 if $form->{reverse};
        $tax{fxamount}{$accno} = $form->{"tax_$accno"};
        $fxtax += $tax{fxamount}{$accno};
        $tax += $tax{fxamount}{$accno};
        $amount = $tax{fxamount}{$accno} * $form->{exchangerate};
        $tax{amount}{$accno} = $form->round_amount( $amount - $diff, 2 );
        $diff = $tax{amount}{$accno} - ( $amount - $diff );
        $amount = $tax{amount}{$accno} - $tax{fxamount}{$accno};
        $tax += $amount;

            push @{ $form->{acc_trans}{taxes} },
              {
                  accno          => $accno,
                  source         => $form->{"taxsource_$accno"},
                  amount_bc      => $tax{amount}{$accno},
                  amount_tc      => $tax{fxamount}{$accno},
                  curr           => $form->{currency},
                  project_id     => undef,
              };

    }

    my %amount      = ();
    my $fxinvamount = 0;
    for ( 1 .. $form->{rowcount} ) {
        $fxinvamount += $amount{fxamount}{$_} = $form->{"amount_$_"};
    }

    $form->{taxincluded} *= 1;

    my $i;
    my $project_id;
    my $cleared = 0;

    $diff = 0;

    # deduct tax from amounts if tax included
    foreach my $i ( 1 .. $form->{rowcount} ) {

        if ( $amount{fxamount}{$i} ) {

            # deduct tax from amounts if tax included
            if ( $form->{taxincluded} ) {
                $amount =
                  ($fxinvamount)
                  ? $fxtax * $amount{fxamount}{$i} / $fxinvamount
                  : 0;
                $amount{fxamount}{$i} -= $amount;
            }

            # multiply by exchangerate
            $amount = $amount{fxamount}{$i} * $form->{exchangerate};

        # The following line used to be
        # $amount{amount}{$i} =  $form->round_amount( $amount - $diff, 2 );
        # but that causes problems when processing the payments
        # due to the fact that the payments are un-rounded
            $amount{amount}{$i} = $amount;
            $diff = $amount{amount}{$i} - ( $amount - $diff );

            ( $null, $project_id ) = split /--/, $form->{"projectnumber_$i"};
            $project_id ||= undef;
            ($accno) = split /--/, $form->{"${ARAP}_amount_$i"};

            if ($keepcleared) {
                $cleared = ( $form->{"cleared_$i"} ) ? 1 : 0;
            }

            push @{ $form->{acc_trans}{lineitems} },
              {
                row_num        => $i,
                accno          => $accno,
                amount_tc      => $amount{fxamount}{$i},
                curr           => $form->{currency},
                amount_bc      => $amount{amount}{$i},
                project_id     => $project_id,
                description    => $form->{"description_$i"},
                taxformcheck   => $form->{"taxformcheck_$i"},
                cleared        => $cleared,
              };
        }
    }

    my $invnetamount = 0;
   my $fxinvnetamount = 0;
   for ( @{ $form->{acc_trans}{lineitems} } )
   {
       $invnetamount += $_->{amount_bc};
       $fxinvnetamount += $_->{amount_tc};
   }
    my $invamount = $invnetamount + $tax;
    $form->{invtotal} = $invnetamount;

    # adjust paidaccounts if there is no date in the last row
    $form->{paidaccounts}--
      unless ( $form->{"datepaid_$form->{paidaccounts}"} );

    if ( $form->{vc} ne "customer" ) {
        $form->{vc} = "vendor";
    }

    my $paid = 0;
    my $fxamount;

    $diff = 0;

    # add payments
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        $form->{"paid_$i"} = $form->parse_amount(
              $myconfig, $form->{"paid_$i"}
        );
        $form->{"paid_$i"} *= -1 if $form->{reverse};
        $fxamount = $form->{"paid_$i"};

        if ($fxamount) {
            $paid += $fxamount;

            $paidamount = $fxamount * $form->{exchangerate};

            $amount = $form->round_amount( $paidamount - $diff, 2 );
            $diff = $amount - ( $paidamount - $diff );

            $form->{datepaid} = $form->{"datepaid_$i"};

            $paid{fxamount}{$i} = $fxamount;
            $paid{amount}{$i}   = $amount;
        }
    }

    $fxinvamount += $fxtax unless $form->{taxincluded};
#   These lines are commented out because payments get posted without
#   rounding. Having rounded amounts on the AR/AP creation side leads
#   to unmatched payments
#    $fxinvamount = $form->round_amount( $fxinvamount, 2 );
#    $invamount   = $form->round_amount( $invamount,   2 );
#    $paid        = $form->round_amount( $paid,        2 );

    $paid =
      ( $fxinvamount == $paid )
      ? $invamount
      : $form->round_amount( $paid * $form->{exchangerate}, 2 );

    my $setting = LedgerSMB::Setting->new(%$form);
    $form->{$_} = $setting->get($_)
        for (qw/ fxgain_accno_id fxloss_accno_id /);

    #tshvr4 trunk svn-revison 6589,$form->login seems to contain id instead of name or '',so person_id not found,thus reports with join on person_id not working,quick fix,use employee_name
    #( $null, $form->{employee_id} ) = split /--/, $form->{employee};
    ( $form->{employee_name}, $form->{employee_id} ) = split /--/, $form->{employee};
    unless ( $form->{employee_id} ) {
        ( $form->{employee}, $form->{employee_id} ) = $form->get_employee;
    }

    # check if id really exists
    if ( $form->{id} ) {
        # delete detail records
        $query = qq|SELECT draft__delete_lines(?)|;
        $dbh->do($query, {}, $form->{id}) || $form->dberror($query);
    }
    else {
        my $uid = localtime;
        $uid .= "$$";

        $query = qq|
            INSERT INTO $table (invnumber, person_id, entity_credit_account)
                 VALUES ('$uid', ?, ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{employee_id}, $form->{"$form->{vc}_id"}) || $form->dberror($query);

        $query = qq|SELECT id FROM $table WHERE invnumber = '$uid'|;
        $sth   = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        ( $form->{id} ) = $sth->fetchrow_array;

        $query = q|UPDATE transactions SET workflow_id = ?, reversing = ? WHERE id = ? AND workflow_id IS NULL|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{workflow_id}, $form->{reversing}, $form->{id} )
            || $form->dberror($query);
    }


   if ($table eq 'ar') {
    $query = qq|
      UPDATE ar
         SET invnumber = ?,
             description = ?,
             ordnumber = ?,
             transdate = ?,
             taxincluded = ?,
             amount_bc = ?,
             netamount_bc = ?,
             curr = ?,
             amount_tc = ?,
             netamount_tc = ?,
             duedate = ?,
             notes = ?,
             intnotes = ?,
             ponumber = ?,
             crdate = ?,
             reverse = ?,
             person_id = ?,
             entity_credit_account = ?,
             approved = ?,
             setting_sequence = ?
       WHERE id = ?
    |;
   }
   else {
    $query = qq|
      UPDATE $table
         SET invnumber = ?,
             description = ?,
             ordnumber = ?,
             transdate = ?,
             taxincluded = ?,
             amount_bc = ?,
             netamount_bc = ?,
             curr = ?,
             amount_tc = ?,
             netamount_tc = ?,
             duedate = ?,
             notes = ?,
             intnotes = ?,
             ponumber = ?,
             crdate = ?,
             reverse = ?,
             person_id = ?,
             entity_credit_account = ?,
             approved = ?
       WHERE id = ?
    |;
   }

    $form->{invnumber} = undef if $form->{invnumber} eq '';
    $form->{datepaid} = $form->{transdate} unless $form->{datepaid};
    my $datepaid = ($paid) ? qq|'$form->{datepaid}'| : undef;
    my $approved = 1;
    $approved = 0 if $form->get_setting('separate_duties');

    my @queryargs = (
        $form->{invnumber},        $form->{description},
        $form->{ordnumber},        $form->{transdate},
        $form->{taxincluded},
        $invamount,                $invnetamount,
        $form->{currency},
        $fxinvamount,              $fxinvnetamount,
        $form->{duedate},
        $form->{notes},            $form->{intnotes},
        $form->{ponumber},         $form->{crdate},
        $form->{reverse},          $form->{employee_id},
        $form->{"$form->{vc}_id"},
        $approved
        );
    if ($table eq 'ar') {
        push @queryargs, $form->{setting_sequence}
    }
    push @queryargs, $form->{id};

    $sth = $dbh->prepare($query) or $form->dberror($query);
    $sth->execute(@queryargs) or $form->dberror($query);

    if (defined $form->{approved}) {
        if (!$form->{approved} && $form->{batch_id}){
           if ($form->{ARAP} eq 'AR'){
               $batch_class = 'ar';
           } else {
               $batch_class = 'ap';
           }
           my $vqh = $dbh->prepare('SELECT * FROM batch__lock_for_update(?)');
           $vqh->execute($form->{batch_id});
           my $bref = $vqh->fetchrow_hashref('NAME_lc');
           # Change the below to die with localization in 1.4
           $form->error('Approved Batch') if $bref->{approved_by};
           $form->error('Locked Batch') if $bref->{locked_by};
           $query = qq|
        INSERT INTO voucher (batch_id, trans_id, batch_class)
        VALUES (?, ?, (select id from batch_class where class = ?))|;
           $dbh->prepare($query)->execute($form->{batch_id}, $form->{id},
                $batch_class) || $form->dberror($query);
        }

    }

    my $ref;

    # add individual transactions

    my $taxformfound=AA->taxform_exist($form,$form->{"$form->{vc}_id"});


    my $b_unit_sth = $dbh->prepare(
         "INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
          VALUES (currval('acc_trans_entry_id_seq'), ?, ?)"
    );

    foreach my $ref ( @{ $form->{acc_trans}{lineitems} } ) {
        # insert detail records in acc_trans
        if ( $ref->{amount_bc} ) {
            $query = qq|
                INSERT INTO acc_trans
                        (trans_id, chart_id, amount_bc, curr, amount_tc,
                        transdate, approved, memo, cleared)
                VALUES  (?, (SELECT id FROM account
                                  WHERE accno = ?),
                         ?, ?, ?, ?, ?, ?, ?)|;

            @queryargs = (
                $form->{id},            $ref->{accno},
                $ref->{amount_bc} * $ml, $ref->{curr},
                $ref->{amount_tc} * $ml,
                $form->{transdate},
                $approved,
                $ref->{description},
                $ref->{cleared}
            );
           $dbh->prepare($query)->execute(@queryargs)
              || $form->dberror($query);
           if ($ref->{row_num} and !$ref->{fx_transaction}){
              my $i = $ref->{row_num};
              for my $cls(@{$form->{bu_class}}){
                  if ($form->{"b_unit_$cls->{id}_$i"}){
                     $b_unit_sth->execute($cls->{id}, $form->{"b_unit_$cls->{id}_$i"});
                  }
              }
           }

           if($taxformfound)
           {
            $query="select max(entry_id) from acc_trans;";
            my $sth1=$dbh->prepare($query);
            $sth1->execute();
            my $entry_id=$sth1->fetchrow()  || $form->dberror($query);
            my $report=($taxformfound and $ref->{taxformcheck})?"true":"false";
            AA->update_ac_tax_form($form,$dbh,$entry_id,$report);
           }
           else
           {
            $logger->debug("skipping ac_tax_form because no tax_form");
           }
        }
    }#foreach

    # save taxes
    foreach my $ref ( @{ $form->{acc_trans}{taxes} } ) {
        if ( $ref->{amount_bc} ) {
            $query = qq|
                INSERT INTO acc_trans
                        (trans_id, chart_id, amount_bc, curr, amount_tc,
                            transdate, approved, source)
                     VALUES (?, (SELECT id FROM account
                              WHERE accno = ?),
                        ?, ?, ?, ?, ?, ?)|;

            @queryargs = (
                $form->{id}, $ref->{accno}, $ref->{amount_bc} * $ml,
                $form->{currency}, $ref->{amount_tc} * $ml,
                $form->{transdate},
                $approved,
                $ref->{source}
            );
            $dbh->prepare($query)->execute(@queryargs)
              || $form->dberror($query);
        }
    }

    my $arap;

    # record ar/ap
    if ( ( $arap = $invamount ) ) {
        ($accno) = split /--/, $form->{$ARAP};
        $query = qq|
            INSERT INTO acc_trans
                     (trans_id, chart_id, amount_bc, curr, amount_tc,
                      transdate, approved)
              VALUES (?, (SELECT id FROM account
                              WHERE accno = ?),
                           ?, ?, ?, ?, ?)|;
        @queryargs =
            ( $form->{id}, $accno,
              $invamount * -1 * $ml, $form->{currency},
              $invamount * -1 * $ml / $form->{exchangerate},
              $form->{transdate},
              $approved,
            );

        $dbh->prepare($query)->execute(@queryargs)
          || $form->dberror($query);
        # if ($form->{exchangerate} != 1){
        #    $dbh->prepare($query)->execute($form->{id}, $accno,
        #           ($invamount * -1 * $ml) -
        #           ($invamount * -1 * $ml / $form->{exchangerate}),
        #           $form->{transdate} );
        # }
    }

    # if there is no amount force ar/ap
    if ( $fxinvamount == 0 ) {
        $arap = 1;
    }

    IIAA->process_form_payments($myconfig, $form);

    # save printed
    $form->save_status($dbh);
    return 1 unless $dbh->errstr;
}

=item get_files

Returns a list of files associated with the existing transaction.  This is
provisional, and will change for 1.4 as the GL transaction functionality is
                  {ref_key => $self->{id}, file_class => 1}
rewritten

=cut

sub get_files {
     my ($self, $form, $locale) = @_;
     return if !$form->{id};
     my $file = LedgerSMB::File->new(%$form);
     @{$form->{files}} = $file->list({ref_key => $form->{id}, file_class => 1});
     @{$form->{file_links}} = $file->list_links(
                  {ref_key => $form->{id}, file_class => 1}
     );

}

=item transactions(\%myconfig, $form)

Generates the transaction and outstanding reports.  Form variables used in this
function are:

approved: whether or not transactions must be approved to show up

transdatefrom: Earliest day of transactions

transdateto:  Latest day of transactions

month, year, interval:  Used in palce of transdatefrom and transdate to

vc:  'customer' for ar, 'vendor' for ap.

meta_number:  customer/vendor number

entity_id:  A specific entity id

parts_id:  Show transactions including a specific part

department_id:  Transactions for a department

entity_credit_account: As an alternate for meta_number to identify a customer
of vendor credit account

invoice_type:  3 for on-hold, 2 for active

The transaction list is stored at:
@{$form->{transactions}}

=cut

sub get_name {

    my ( $self, $myconfig, $form ) = @_;

    # sanitize $form->{vc}
    if ( $form->{vc} ne 'customer' ) {
        $form->{vc} = 'vendor';
    }
    else {
        $form->{vc} = 'customer';
    }

    my $dbh = $form->{dbh};

    my $dateformat = $myconfig->{dateformat};

    if ( $myconfig->{dateformat} !~ /^y/ ) {
        my @a = split /\W/, $form->{transdate};
        $dateformat .= "yy" if ( length $a[2] > 2 );
    }

    if ( defined $from->{transdate} and $form->{transdate} !~ /\W/ ) {
        $dateformat = 'yyyymmdd';
    }

    if ( defined $form->{transdate}
         and $form->{transdate} =~ m/\d\d\d\d-\d\d-\d\d/ ) {
        $dateformat = 'yyyy-mm-dd';
    }

    my $duedate;

    $dateformat = $dbh->quote($dateformat);
    my $tdate = $dbh->quote( $form->{transdate} );
    $duedate = ( $form->{transdate} )
      ? "to_date($tdate, $dateformat)
            + c.terms"
      : "current_date + c.terms";

    $form->{"$form->{vc}_id"} //= 0;
    $form->{"$form->{vc}_id"} *= 1;


    # get customer/vendor
    my $query = qq/
           SELECT entity.name AS $form->{vc}, c.discount,
                  c.creditlimit,
                  c.terms, c.taxincluded,
                  c.curr AS currency,
                  c.language_code, $duedate AS duedate,
              b.discount AS tradediscount,
                  b.description AS business,
              entity.control_code AS entity_control_code,
                          co.tax_id AS tax_id,
              c.meta_number, ctf.default_reportable,
              aa.accno || '--' || aa.description as arap_accno,
                          c.cash_account_id, ca.accno as cash_accno,
                          c.id as eca_id,
                          coalesce(ecl.address, el.address) as address,
                          coalesce(ecl.city, el.city) as city,
                          coalesce(ecl.zipcode, el.zipcode) as zipcode,
                          coalesce(ecl.state, el.state) as state,
                          coalesce(ecl.country, el.country) as country
             FROM entity_credit_account c
             JOIN entity ON (entity.id = c.entity_id)
                LEFT JOIN account ca ON c.cash_account_id = ca.id
                LEFT JOIN account aa ON c.ar_ap_account_id = aa.id
        LEFT JOIN business b ON (b.id = c.business_id)
                LEFT JOIN country_tax_form ctf ON ctf.id = c.taxform_id
                LEFT JOIN company co ON co.entity_id = c.entity_id
                LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.credit_id, mail_code as zipcode,
                               state, (select short_name from country
                                        where id=l.country_id) as country
                          FROM eca_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) ecl
                        ON (c.id = ecl.credit_id)
                LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.entity_id, mail_code as zipcode,
                               state, (select short_name from country
                                        where id=l.country_id) as country
                          FROM entity_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) el
                        ON (c.entity_id = el.entity_id)
            WHERE c.id = ?/;

    @queryargs = ( $form->{"$form->{vc}_id"} );
    my $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);
    $ref = $sth->fetchrow_hashref(NAME_lc);
    $form->{$form->{ARAP}} = $ref->{arap_accno};
    delete $ref->{arap_accno};
    $form->db_parse_numeric(sth => $sth, hashref => $ref);
    if ( $form->{id} ) {
        for (qw(currency employee employee_id intnotes)) {
            delete $ref->{$_};
        }
    }
    delete $ref->{duedate} if $form->{duedate};

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # get customer e-mail accounts
    $query = qq|SELECT * FROM eca__list_contacts(?)
                      WHERE class_id BETWEEN 12 AND ?
                      ORDER BY class_id DESC;|;
    my %id_map = ( 12 => 'email',  ## no critic (ProhibitMagicNumbers) sniff
               13 => 'cc',  ## no critic (ProhibitMagicNumbers) sniff
               14 => 'bcc',  ## no critic (ProhibitMagicNumbers) sniff
               15 => 'email',  ## no critic (ProhibitMagicNumbers) sniff
               16 => 'cc',  ## no critic (ProhibitMagicNumbers) sniff
               17 => 'bcc' );  ## no critic (ProhibitMagicNumbers) sniff
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{eca_id}, 17) || $form->dberror( $query );  ## no critic (ProhibitMagicNumbers) sniff

    my $ctype;
    my $billing_email = 0;

    # Set these variables to empty, otherwise in some cases it keeps earlier values and cause doubled
    # values, ie. when emailing invoice
    $form->{email} = '';
    $form->{cc} = '';
    $form->{bcc} = '';

    while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        $ctype = $ref->{class_id};
        $ctype = $id_map{$ctype};
        $billing_email = 1
        if $ref->{class_id} == 15;  ## no critic (ProhibitMagicNumbers) sniff

        # If there's an explicit billing email, don't use
        # the standard email addresses; otherwise fall back to standard
        $form->{$ctype} .= ($form->{$ctype} ? ", " : "") . $ref->{contact}
        if (($ref->{class_id} < 15 && ! $billing_email)  ## no critic (ProhibitMagicNumbers) sniff
            || $ref->{class_id} >= 15);  ## no critic (ProhibitMagicNumbers) sniff
    }
    $sth->finish;

    my $buysell = ( $form->{vc} eq 'customer' ) ? "buy" : "sell";

    # if no currency use defaultcurrency
    $form->{currency} =
      ( $form->{currency} )
      ? $form->{currency}
      : $form->{defaultcurrency};
    $form->{exchangerate} = 0
      if $form->{currency} eq $form->{defaultcurrency};

    # if no employee, default to login
    ( $form->{employee}, $form->{employee_id} ) = $form->get_employee
      unless $form->{employee_id};

    my $arap = ( $form->{vc} eq 'customer' ) ? 'ar' : 'ap';
    my $ARAP = uc $arap;

    if (LedgerSMB::Setting->new(%$form)->get('show_creditlimit')){
        $form->{creditlimit} = $form->parse_amount( $myconfig, '0') unless
          $form->{creditlimit} > 0;
        $form->{creditremaining} = $form->{creditlimit};
        # acc_trans.approved is only false in the case of batch payments which
        # have not yet been approved.  Unapproved transactions set approved on
        # the ar or ap record level.  --CT

        $query = q|SELECT credit_limit__used(?)|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{"$form->{vc}_id"})
           || $form->dberror($query);
        my ($credit_rem) = $sth->fetchrow_array;
        $credit_rem = LedgerSMB::PGNumber->new($credit_rem // 0);
        $form->{creditremaining} =
            ($credit_rem && $credit_rem->is_nan) ? 'Currency rate missing'
            : ($form->{creditremaining} - $credit_rem);

        $sth->finish;
    }

    # get taxes
    $query = qq|
        SELECT c.accno
          FROM account c
          JOIN eca_tax ct ON (ct.chart_id = c.id)
         WHERE ct.eca_id = ? AND NOT obsolete |;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{"$form->{vc}_id"} ) || $form->dberror($query);

    my %tax;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $tax{ $ref->{accno} } = 1;
    }

    $sth->finish;
    $transdate = $dbh->quote( $form->{transdate} );
    my $where = $form->{transdate}
              ? qq|WHERE (t.validto >= $transdate OR t.validto IS NULL)|
              : '';

    # get tax rates and description
    $query = qq|
           SELECT c.accno, c.description, t.rate, t.taxnumber
             FROM account c
             JOIN tax t ON (c.id = t.chart_id)
                  $where
         ORDER BY accno, validto|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $form->{taxaccounts} = "";
    my %a = ();

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth => $sth, hashref => $hashref);

        if ( $tax{ $ref->{accno} } ) {
            if ( not exists $a{ $ref->{accno} } ) {
                for (qw(rate description taxnumber)) {
                    $form->{"$ref->{accno}_$_"} = $ref->{$_};
                }
                $form->{taxaccounts} .= "$ref->{accno} ";
                $a{ $ref->{accno} } = 1;
            }
        }
    }
    #$logger->trace("\$form->{taxaccounts}=$form->{taxaccounts}");

    $sth->finish;
    chop $form->{taxaccounts};

}

=item taxform_exist($form, $cv_id)

Determines if a taxform attached to the entity_credit_account record (where
the id field is the same as $cv_id) exists. Returns true if it exists, false
if not.

=cut



sub taxform_exist
{

   my ( $self,$form,$cv_id) = @_;

   my $query = "select taxform_id from entity_credit_account where id=?";

   my $sth = $form->{dbh}->prepare($query);

   $sth->execute($cv_id) || $form->dberror($query);

   my $retval=0;

   while(my $val=$sth->fetchrow())
   {
        $retval=1;
   }

   return $retval;


}

=item update_ac_tax_form($form,$dbh,$entry_id,$report)

Updates the ac_tax_form checkbox for the acc_trans.entry_id (where it is the
same as $entry_id).  If $report is true, sets it to true, if false, sets it to
false.  $report must be a valid *postgresql* bool value (0/1, t/f,
'true'/'false').

=cut

sub update_ac_tax_form
{

   my ( $self,$form,$dbh,$entry_id,$report) = @_;

   my $query=qq|select count(*) from ac_tax_form where entry_id=?|;
   my $sth=$dbh->prepare($query);
   $sth->execute($entry_id) ||  $form->dberror($query);

   my $found=0;

   while(my $ret1=$sth->fetchrow())
   {
      $found=1;

   }

   if($found)
   {
      my $query = qq|update ac_tax_form set reportable=? where entry_id=?|;
          my $sth = $dbh->prepare($query);
          $sth->execute($report,$entry_id) || $form->dberror($query);
   }
  else
   {
          my $query = qq|insert into ac_tax_form(entry_id,reportable) values(?,?)|;
          my $sth = $dbh->prepare($query);
          $sth->execute($entry_id,$report) || $form->dberror("Sada $query");
   }


}

=item get_taxchech($entry_id,$dbh)

Returns true if the acc_trans record has been set to reportable in the past
false otherwise.

=cut

sub get_taxcheck
{

   my ( $self,$entry_id,$dbh) = @_;

   my $query=qq|select reportable from ac_tax_form where entry_id=?|;
   my $sth=$dbh->prepare($query);
   $sth->execute($entry_id) ||  $form->dberror($query);

   my $found=0;

   while(my $ret1=$sth->fetchrow())
   {

      if($ret1 eq "t" || $ret1)   # this if is not required because when reportable is false, control would not come inside while itself.
      { $found=1;  }

   }

   return($found);

}

=item save_intnotes($form)

Saves the $form->{intnotes} into the ar/ap.intnotes field.

=cut

sub save_intnotes {
    my ($self,$form) = @_;
    my $table;
    if ($form->{arap} eq 'ar') {
        $table = 'ar';
    } elsif ($form->{arap} eq 'ap') {
        $table = 'ap';
    } else {
        $form->error('Bad arap in save_intnotes');
    }
    my $sth = $form->{dbh}->prepare("UPDATE $table SET intnotes = ? " .
                                      "where id = ?");
    $sth->execute($form->{intnotes}, $form->{id});
}

=item save_employee($form)

Saves the $form->{employee} into the ar/ap.person_id field.

=cut

sub save_employee {
    my ($self,$form) = @_;
    my $table;
    if ($form->{arap} eq 'ar') {
        $table = 'ar';
    } elsif ($form->{arap} eq 'ap') {
        $table = 'ap';
    } else {
        $form->error('Bad arap in save_employee');
    }
    my $sth = $form->{dbh}->prepare("UPDATE $table SET person_id = ? " .
                                    "where id = ?");
    my ($name, $person_id) = split(/--/, $form->{employee}, 2);
    $sth->execute($person_id, $form->{id});
}

=item get_overpayments

This wraps LedgerSMB::DBObject::Payments->get_unused_overpayments to retrieve 
overpayments for display on AR, AP, and invoice screens.

=cut

sub get_overpayments {
    my ($mod, $form) = @_;
    $form->{account_class} = ($form->{vc} == 'vendor') ? 1 : 2;
    $form->{entity_credit_id} = $form->{"$form->{vc}_id"};

    my $payments = LedgerSMB::DBObject::Payments->new($form);
    $form->{overpayments} = [$payments->get_unused_overpayments()];
}

=back

=head1 COPYRIGHT

# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# Copyright (C) 2006-2010
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
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#
# See COPYRIGHT file for copyright information

=cut

1;
