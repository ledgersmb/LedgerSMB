
=head1 NAME

LedgerSMB::AM - This module provides some administrative functions

=head1 SYNOPSIS

This module provides some administrative functions

=head1 COPYRIGHT

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006
 # This work contains copyrighted information from a number of sources
 # all used with permission.
 #
 # This file contains source code included with or based on SQL-Ledger
 # which is Copyright Dieter Simader and DWS Systems Inc. 2000-2005
 # and licensed under the GNU General Public License version 2 or, at
 # your option, any later version.  For a full list including contact
 # information of contributors, maintainers, and copyright holders,
 # see the CONTRIBUTORS file.
 #
 # Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
 # Copyright (C) 2000
 #
 #  Author: DWS Systems Inc.
 #     Web: http://www.sql-ledger.org
 #
 #  Contributors: Jim Rawlings <jim@your-dba.com>
 #
 #====================================================================
 #
 # This file has undergone whitespace cleanup.
 #
 #====================================================================
 #
 # Administration module
 #    Chart of Accounts
 #    template routines
 #    preferences
 #
 #====================================================================

=head1 METHODS

=over

=cut

package AM;
use LedgerSMB::Tax;
use LedgerSMB::Sysconfig;
use Log::Log4perl;

my $logger = Log::Log4perl->get_logger('AM');

=item AM->get_gifi($myconfig, $form);

Sets $form->{description} to the description of the GIFI number $form->{accno}.
Sets $form->{orphaned} to true if there are no entries in acc_trans that refer
to this GIFI and to false otherwise.

$myconfig is not used.

=cut

sub get_gifi {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $sth;

    my $query = qq|
        SELECT accno, description
          FROM gifi
         WHERE accno = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{accno} ) || $form->dberror($query);
    ( $form->{accno}, $form->{description} ) = $sth->fetchrow_array();

    $sth->finish;

    # check for transactions
    $query = qq|
        SELECT count(*)
          FROM acc_trans a
          JOIN account c ON (a.chart_id = c.id)
          JOIN gifi g ON (c.gifi_accno = g.accno)
         WHERE g.accno = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{accno} ) || $form->dberror($query);
    ($numrows) = $sth->fetchrow_array;
    if ( ( $numrows * 1 ) == 0 ) {
        $form->{orphaned} = 1;
    }
    else {
        $form->{orphaned} = 0;
    }


}

=item AM->save_gifi($myconfig, $form);

Adds or updates a GIFI record.  If $form->{id} is set, update the gifi record
that has that as an account number.  The new values for an added or updated
record are stored in $form->{accno} and $form->{description}.

$myconfig is not used.

=cut

sub save_gifi {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $form->{accno} =~ s/( |')//g;

    foreach my $item (qw(accno description)) {
        $form->{$item} =~ s/-(-+)/-/g;
        $form->{$item} =~ s/ ( )+/ /g;
    }

    my @queryargs = ( $form->{accno}, $form->{description} );

    # id is the old account number!
    if ( $form->{id} ) {
        $query = qq|
            UPDATE gifi
               SET accno = ?,
                   description = ?
             WHERE accno = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|
            INSERT INTO gifi (accno, description)
                 VALUES (?, ?)|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);
    $sth->finish;

}

=item AM->delete_gifi($myconfig, $form);

Deletes the gifi record with the GIFI number $form->{id}.

$myconfig is not used.

=cut

sub delete_gifi {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    # id is the old account number!
    $query = qq|
        DELETE FROM gifi
              WHERE accno = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);
    $sth->finish;

}

=item AM->get_warehouse($myconfig, $form);

Sets $form->{description} to the name of the warehouse $form->{id}.  If no
inventory is currently linked to the warehouse, set $form->{orphaned} to true,
otherwise $form->{orphaned} is false.

$myconfig is not used.

=cut

sub get_warehouse {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $sth;

    my $query = qq|
        SELECT description
          FROM warehouse
         WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);
    ( $form->{description} ) = $sth->fetchrow_array;
    $sth->finish;

    # see if it is in use
    $query = qq|
        SELECT count(*)
          FROM warehouse_inventory
         WHERE warehouse_id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );

    ( $form->{orphaned} ) = $sth->fetchrow_array;
    if ( ( $form->{orphaned} * 1 ) == 0 ) {
        $form->{orphaned} = 1;
    }
    else {
        $form->{orphaned} = 0;
    }

}

=item AM->save_warehouse($myconfig, $form);

Add or update a warehouse.  If $form->{id} is set, that warehouse is updated
instead of adding a new warehouse.  In both cases, the description of the
warehouse is set to $form->{description}.

$myconfig is not used.

=cut

sub save_warehouse {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $sth;
    my @queryargs = ( $form->{description} );

    $form->{description} =~ s/-(-)+/-/g;
    $form->{description} =~ s/ ( )+/ /g;

    if ( $form->{id} ) {
        $query = qq|
            UPDATE warehouse
               SET description = ?
             WHERE id = ?|;
        push @queryargs, $form->{id};
    }
    else {
        $query = qq|
            INSERT INTO warehouse (description)
                 VALUES (?)|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);
    $sth->finish;

}

=item AM->delete_warehouse($myconfig, $form);

Deletes the warehouse with the id $form->{id}.

$myconfig is not used.

=cut

sub delete_warehouse {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $query = qq|
        DELETE FROM warehouse
              WHERE id = ?|;

    $dbh->prepare($query)->execute( $form->{id} ) || $form->dberror($query);

}

=item AM->get_business($myconfig, $form);

Places the description and discount for the business with an id of $form->{id}
into $form->{description} and $form->{discount}.

$myconfig is unused.

=cut

sub get_business {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
        SELECT description, discount
          FROM business
         WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );
    ( $form->{description}, $form->{discount} ) = $sth->fetchrow_array();

}

=item AM->save_business($myconfig, $form);

Adds or updates a type of business.  If $form->{id} is set, the business type
with a corresponding id is updated, otherwise a new type is added.  The new
description is $form->{description}.  The discount taken as a percentage stored
in $form->{discount}, which then value is divided by 100 in place and the
multiplier is stored.  As an example, if $form->{discount} is 10 when this
function is called, it is changed to 0.1 and stored as 0.1.

$myconfig is unused.

=cut

sub save_business {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->{description} =~ s/-(-)+/-/g;
    $form->{description} =~ s/ ( )+/ /g;
    $form->{discount} /= 100;

    my $sth;
    my @queryargs = ( $form->{description}, $form->{discount} );

    if ( $form->{id} ) {
        $query = qq|
            UPDATE business
               SET description = ?,
                   discount = ?
             WHERE id = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|INSERT INTO business (description, discount)
                         VALUES (?, ?)|;
    }

    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
    if (!$form->{id}){
        my $sth = $dbh->prepare("SELECT currval('business_id_seq')");
        $sth->execute();
        ($form->{id}) = $sth->fetchrow_array;
    }

}

=item AM->delete_business($myconfig, $form);

Deletes the business type with the id $form->{id}.

$myconfig is unused.

=cut

sub delete_business {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $query = qq|
        DELETE FROM business
              WHERE id = ?|;

    $dbh->prepare($query)->execute( $form->{id} ) || $form->dberror($query);

}

=item AM->get_sic($myconfig, $form);

Retrieves the sictype and description for the SIC indicated by
$form->{code} and places the retrieved values into $form->{sictype} and
$form->{description}.

$myconfig is unused

=cut

sub get_sic {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
        SELECT code, sictype, description
          FROM sic
         WHERE code = | . $dbh->quote( $form->{code} );

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;

}

=item AM->save_sic($myconfig, $form);

Add or update a SIC entry.  If $form->{id} is set, take it as the original code
to identify the entry update, otherwise treat it as a new entry.  $form->{code},
$form->{description}, and $form->{sictype} contain the new values.  sictype is
a single character to flag whether or not the entry is for a header ('H').

$myconfig is unused.

=cut

sub save_sic {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    foreach my $item (qw(code description)) {
        $form->{$item} =~ s/-(-)+/-/g;
    }
    my $sth;
    @queryargs = ( $form->{code}, $form->{sictype}, $form->{description} );

    # if there is an id
    if ( $form->{id} ) {
        $query = qq|
            UPDATE sic
               SET code = ?,
                   sictype = ?,
                   description = ?
             WHERE code = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|
        INSERT INTO sic (code, sictype, description)
             VALUES (?, ?, ?)|;

    }

    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);

}

=item AM->delete_sic($myconfig, $form);

Deletes the SIC entry with the code $form->{code}.

$myconfig is unused.

=cut

sub delete_sic {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $query = qq|
        DELETE FROM sic
              WHERE code = ?|;

    $dbh->prepare($query)->execute( $form->{code} );

}

=item AM->get_language($myconfig, $form);

Sets $form->{description} to the description of the language that has the code
$form->{code}.

$myconfig is unused.

=cut

sub get_language {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
        SELECT code, description
          FROM language
         WHERE code = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{code} ) || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;

}

=item AM->save_language($myconfig, $form);

Add or update a language entry.  If $form->{id} is set, the language entry that
has that as a code is updated, otherwise a new entry is added.  $form->{code}
and $form->{description} contain the new values for the entry.

$myconfig is unused.

=cut

sub save_language {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->{code} =~ s/ //g;

    foreach my $item (qw(code description)) {
        $form->{$item} =~ s/-(-)+/-/g;
        $form->{$item} =~ s/ ( )+/-/g;
    }
    my $sth;
    my @queryargs = ( $form->{code}, $form->{description} );

    # if there is an id
    if ( $form->{id} ) {
        $query = qq|
            UPDATE language
               SET code = ?,
                   description = ?
             WHERE code = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|
            INSERT INTO language (code, description)
                 VALUES (?, ?)|;
    }

    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);

}

=item AM->delete_language($myconfig, $form);

Deletes the language entry with the code $form->{code}.

$myconfig is unused.

=cut

sub delete_language {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $query = qq|
        DELETE FROM language
              WHERE code = | . $dbh->quote( $form->{code} );

    $dbh->do($query) || $form->dberror($query);

}

=item AM->recurring_transactions($myconfig, $form);

Populates lists referred to in the form of $form->{transactions}{$type}, where
the possible values for $type are 'ar', 'ap', 'gl', 'so', and 'po', with hashes
containing details about recurring transactions of the $type variety.  These
hashes have the fields module (the frontend script that governs the transaction
type), transaction (the transaction type), invoice (true if the transaction is
an invoice), description (a field that is a customer, vendor, or in the case of
a GL transaction, an arbitrary text field), amount (the cash value of the
transaction), id (the id of the recurring transaction), reference (the
reference value for the transaction), startdate (the date the recurring
sequence started), nextdate (the date of the next occurrence of the event),
enddate (the date the sequence ends), repeat (the number of units involved in
the recurrence frequency), unit (the base recurrence unit), howmany (how many
times the event occurs), payment (whether or not the event involves a payment),
recurringemail (a colon separated list of forms to email as part of the event),
recurringprint (a colon separated list of forms to print as part of the event),
overdue (how many days until the next repetition of the event), vc (vendor,
customer, or empty), exchangerate (the exchangerate involved on the day of the
original transaction), curr (the currency of the event), and expired (if there
will be no more recurrences).

By default, these lists are sorted in order of the date of the next occurrence
of the transaction.  This order can be affected by the usual attributes used
by $form->sort_order.

$myconfig is unused.

=cut

sub recurring_transactions {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|SELECT value FROM defaults where setting_key = 'curr'|;

    my ($defaultcurrency) = $dbh->selectrow_array($query);
    $defaultcurrency = $dbh->quote( $defaultcurrency =~ s/:.*//g );

    $form->{sort} ||= "nextdate";
    my @a         = ( $form->{sort} );
    my $sortorder = $form->sort_order( \@a );

    $query = qq|
           SELECT 'ar' AS module, 'ar' AS transaction, a.invoice,
                  e.name AS description, a.amount,
                          extract(days from recurring_interval) as days,
                extract(months from recurring_interval) as months,
                extract(years from recurring_interval) as years,
                  s.*, se.formname AS recurringemail,
                  sp.formname AS recurringprint,
                  s.nextdate - current_date AS overdue,
                  'customer' AS vc,
                  ex.buy AS exchangerate, a.curr,
                      (s.nextdate IS NULL OR s.nextdate > s.enddate)
                          AS expired
             FROM recurring s
             JOIN ar a ON (a.id = s.id)
                     JOIN entity_credit_account eca
                          ON a.entity_credit_account = eca.id
             JOIN entity e ON (eca.entity_id = e.id)
        LEFT JOIN recurringemail se ON (se.id = s.id)
        LEFT JOIN recurringprint sp ON (sp.id = s.id)
        LEFT JOIN exchangerate ex
                  ON (ex.curr = a.curr AND a.transdate = ex.transdate)

            UNION

          SELECT 'ap' AS module, 'ap' AS transaction, a.invoice,
                  e.name AS description, a.amount,
                          extract(days from recurring_interval) as days,
                extract(months from recurring_interval) as months,
                extract(years from recurring_interval) as years,
                  s.*, se.formname AS recurringemail,
                  sp.formname AS recurringprint,
                  s.nextdate - current_date AS overdue, 'vendor' AS vc,
                  ex.sell AS exchangerate, a.curr,
                  (s.nextdate IS NULL OR s.nextdate > s.enddate)
                  AS expired
             FROM recurring s
             JOIN ap a ON (a.id = s.id)
                     JOIN entity_credit_account eca
                          ON a.entity_credit_account = eca.id
             JOIN entity e ON (eca.entity_id = e.id)
        LEFT JOIN recurringemail se ON (se.id = s.id)
        LEFT JOIN recurringprint sp ON (sp.id = s.id)
        LEFT JOIN exchangerate ex ON
                  (ex.curr = a.curr AND a.transdate = ex.transdate)

            UNION

           SELECT 'gl' AS module, 'gl' AS transaction, FALSE AS invoice,
                  a.description, (SELECT SUM(ac.amount)
             FROM acc_trans ac
            WHERE ac.trans_id = a.id
              AND ac.amount > 0) AS amount,
                          extract(days from recurring_interval) as days,
                extract(months from recurring_interval) as months,
                extract(years from recurring_interval) as years,
                  s.*, se.formname AS recurringemail,
                  sp.formname AS recurringprint,
                  s.nextdate - current_date AS overdue, '' AS vc,
                  '1' AS exchangerate, $defaultcurrency AS curr,
                  (s.nextdate IS NULL OR s.nextdate > s.enddate)
                  AS expired
             FROM recurring s
             JOIN gl a ON (a.id = s.id)
        LEFT JOIN recurringemail se ON (se.id = s.id)
        LEFT JOIN recurringprint sp ON (sp.id = s.id)

            UNION

           SELECT 'oe' AS module, 'so' AS transaction, FALSE AS invoice,
                  e.name AS description, a.amount,
                          extract(days from recurring_interval) as days,
                extract(months from recurring_interval) as months,
                extract(years from recurring_interval) as years,
                  s.*, se.formname AS recurringemail,
                  sp.formname AS recurringprint,
                  s.nextdate - current_date AS overdue,
                  'customer' AS vc,
                  ex.buy AS exchangerate, a.curr,
                  (s.nextdate IS NULL OR s.nextdate > s.enddate)
                  AS expired
             FROM recurring s
             JOIN oe a ON (a.id = s.id)
             JOIN entity e ON (a.entity_id = e.id)
        LEFT JOIN recurringemail se ON (se.id = s.id)
        LEFT JOIN recurringprint sp ON (sp.id = s.id)
        LEFT JOIN exchangerate ex ON
                  (ex.curr = a.curr AND a.transdate = ex.transdate)
            WHERE a.quotation = '0'

            UNION

           SELECT 'oe' AS module, 'po' AS transaction, FALSE AS invoice,
                  e.name AS description, a.amount,
                          extract(days from recurring_interval) as days,
                extract(months from recurring_interval) as months,
                extract(years from recurring_interval) as years,
                  s.*, se.formname AS recurringemail,
                  sp.formname AS recurringprint,
                  s.nextdate - current_date AS overdue, 'vendor' AS vc,
                  ex.sell AS exchangerate, a.curr,
                  (s.nextdate IS NULL OR s.nextdate > s.enddate)
                  AS expired
             FROM recurring s
             JOIN oe a ON (a.id = s.id)
             JOIN entity e ON (a.entity_id = e.id)
        LEFT JOIN recurringemail se ON (se.id = s.id)
        LEFT JOIN recurringprint sp ON (sp.id = s.id)
        LEFT JOIN exchangerate ex ON
                  (ex.curr = a.curr AND a.transdate = ex.transdate)
            WHERE a.quotation = '0'

         ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $id;
    my $transaction;
    my %e = ();
    my %p = ();

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {

        $ref->{exchangerate} ||= 1;
        $form->db_parse_numeric(sth => $sth, hashref => $ref);

        if ( $ref->{years} ) {
            $ref->{unit} = 'years';
            $ref->{repeat} = $ref->{years};
        }
        elsif ( $ref->{months} ) {
            $ref->{unit} = 'months';
            $ref->{repeat} = $ref->{months};
        }
        elsif ( $ref->{days} && ( $ref->{days} % 7 == 0 )) {
            $ref->{unit} = 'weeks';
            $ref->{repeat} = $ref->{days} / 7;
        }
        elsif ( $ref->{days} ) {
            $ref->{unit} = 'days';
            $ref->{repeat} = $ref->{days};
        }


        if ( $ref->{id} != $id ) {

            if (%e) {
                $form->{transactions}{$transaction}->[$i]->{recurringemail} =
                  "";
                for ( keys %e ) {
                    $form->{transactions}{$transaction}->[$i]
                      ->{recurringemail} .= "${_}:";
                }
                chop $form->{transactions}{$transaction}->[$i]
                  ->{recurringemail};
            }

            if (%p) {
                $form->{transactions}{$transaction}->[$i]->{recurringprint} =
                  "";
                for ( keys %p ) {
                    $form->{transactions}{$transaction}->[$i]
                      ->{recurringprint} .= "${_}:";
                }
                chop $form->{transactions}{$transaction}->[$i]
                  ->{recurringprint};
            }

            %e = ();
            %p = ();

            push @{ $form->{transactions}{ $ref->{transaction} } }, $ref;

            $id = $ref->{id};
            $i  = $#{ $form->{transactions}{ $ref->{transaction} } };

        }

        $transaction = $ref->{transaction};

        $e{ $ref->{recurringemail} } = 1 if $ref->{recurringemail};
        $p{ $ref->{recurringprint} } = 1 if $ref->{recurringprint};

    }

    $sth->finish;

    # this is for the last row
    if (%e) {
        $form->{transactions}{$transaction}->[$i]->{recurringemail} = "";
        for ( keys %e ) {
            $form->{transactions}{$transaction}->[$i]->{recurringemail} .=
              "${_}:";
        }
        chop $form->{transactions}{$transaction}->[$i]->{recurringemail};
    }

    if (%p) {
        $form->{transactions}{$transaction}->[$i]->{recurringprint} = "";
        for ( keys %p ) {
            $form->{transactions}{$transaction}->[$i]->{recurringprint} .=
              "${_}:";
        }
        chop $form->{transactions}{$transaction}->[$i]->{recurringprint};
    }


}

=item AM->recurring_details($myconfig, $form, $id);

Retrieves details about the recurring transaction $id and places them into
attributes of $form.  Sets id (the transaction id passed in, $id), reference
(a reference string for the recurring transaction), startdate (the date the
recurrence series started on), nextdate (the date of the next occurrence of the
event), enddate (the date of the final occurrence of the event), repeat (the
number of units involved in a recurrence period), unit (the recurrence unit),
howmany (the total number of recurrences in the recurrence series), payment
(whether or not the transaction is associated with a payment), arid (true if an
ar event), apid (true if an ap event), overdue (number of days an ar event was
to the duedate), paid (number of days after an ar event it was paid), req (days
until the requirement date from the transdate of an oe event), oeid (true if an
oe event), customer_id (vendor id if sales order), vendor_id (vendor id if
puchase order), vc ('customer' if customer_id set, 'vendor' if vendor_id set),
invoice (true if both arid and arinvoice set or if both apid and apinvoice set),
recurringemail (colon separated list of forms and formats to be emailed),
message (the non-attachement message body for the emails), and recurringprint
(colon separated list of form names, formats, and printer names).

$myconfig is unused.

=cut

sub recurring_details {

    my ( $self, $myconfig, $form, $id ) = @_;

    my $dbh   = $form->{dbh};
    my $query = qq|
           SELECT s.*, ar.id AS arid, ar.invoice AS arinvoice,
                  ap.id AS apid, ap.invoice AS apinvoice,
                  ar.duedate - ar.transdate AS overdue,
                  ar.datepaid - ar.transdate AS paid,
                  oe.reqdate - oe.transdate AS req,
                  oe.id AS oeid,
                          CASE oe.oe_class_id
                             WHEN 1 THEN oe.entity_credit_account
                             ELSE NULL
                             END AS customer_id,
                          CASE oe.oe_class_id
                             WHEN 2 THEN oe.entity_credit_account
                             ELSE NULL
                             END AS vendor_id
             FROM recurring s
        LEFT JOIN ar ON (ar.id = s.id)
        LEFT JOIN ap ON (ap.id = s.id)
        LEFT JOIN oe ON (oe.id = s.id)
            WHERE s.id = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    $form->{vc} = "customer" if $ref->{customer_id};
    $form->{vc} = "vendor"   if $ref->{vendor_id};
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    $form->{invoice} = ( $form->{arid} && $form->{arinvoice} );
    $form->{invoice} = ( $form->{apid} && $form->{apinvoice} )
      unless $form->{invoice};

    $query = qq|
        SELECT *
          FROM recurringemail
         WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    $form->{recurringemail} = "";

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{recurringemail} .= "$ref->{formname}:$ref->{format}:";
        $form->{message} = $ref->{message};
    }

    $sth->finish;

    $query = qq|
        SELECT *
          FROM recurringprint
         WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    $form->{recurringprint} = "";
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{recurringprint} .=
          "$ref->{formname}:$ref->{format}:$ref->{printer}:";
    }

    $sth->finish;

    chop $form->{recurringemail};
    chop $form->{recurringprint};

    for (qw(arinvoice apinvoice invnumber)) { delete $form->{$_} }



}

=item AM->update_recurring($myconfig, $form, $id)

Updates nextdate for the recurring transaction $id to the next date of the
sequence.  If the new value for nextdate is after enddate, nextdate is set to
NULL.

$myconfig is unused.

=cut

sub update_recurring {

    my ( $self, $myconfig, $form, $id ) = @_;

    my $dbh = $form->{dbh};

    $id = $dbh->quote($id);
    my $query = qq|
                SELECT nextdate, recurring_interval
          FROM recurring
         WHERE id = $id|;

    my ( $nextdate, $recurring_interval ) = $dbh->selectrow_array($query);

    $nextdate = $dbh->quote($nextdate);
    my $interval = $dbh->quote($recurring_interval);

    # check if it is the last date
    $query = qq|
        SELECT (date $nextdate + interval $interval) > enddate
          FROM recurring
         WHERE id = $id|;

    my ($last_repeat) = $dbh->selectrow_array($query);
    if ($last_repeat) {
        $query = qq|
            UPDATE recurring
               SET nextdate = NULL
             WHERE id = $id|;
    } else {
        $query = qq|
            UPDATE recurring
               SET nextdate = (date $nextdate + interval $interval)
             WHERE id = $id|;
    }

    $dbh->do($query) || $form->dberror($query);


}

=item AM->check_template_name($myconfig, $form);

Performs some sanity checking on the filename $form->{file} and calls
$form->error if the filename is disallowed.

=cut

sub check_template_name {

    my ( $self, $myconfig, $form ) = @_;

    my @allowedsuff = qw(css tex txt html xml);
    my $test = $form->{file};
    $test =~ s|^$LedgerSMB::Sysconfig::fs_cssdir||;
    if ($LedgerSMB::Sysconfig::fs_cssdir
           and $LedgerSMB::Sysconfig::fs_cssdir !~ m|/$|){
         $test =~ s|^/||;
    }
    if ($LedgerSMB::Sysconfig::templates =~ /^(.:)*?\//){
        $test =~ s#^$LedgerSMB::Sysconfig::templates/?\\?##;
    }
    if ( $test =~ /^(.:)*?\/|:|\.\.\// ) {
        $form->error("Directory transversal not allowed.");
    }
    if ( $form->{file} =~ /^${LedgerSMB::Sysconfig::backuppath}\// ) {
        $form->error(
"Not allowed to access ${LedgerSMB::Sysconfig::backuppath}/ with this method"
        );
    }
    my $whitelisted = 0;
    for (@allowedsuff) {
        if ( $form->{file} =~ /$_$/ ) {
            $whitelisted = 1;
        }
    }
    if ( !$whitelisted ) {
        $form->error("Error:  File is of type that is not allowed.");
    }

    if ( $form->{file} !~ /^$myconfig->{templates}\// ) {
        $form->error("Not in a whitelisted directory: $form->{file}")
          unless $form->{file} =~ /^$LedgerSMB::Sysconfig::fs_cssdir\//;
    }
}

=item AM->taxes($myconfig, $form);

Retrieve details about all taxes in the database.  $form->{taxrates} refers to a
list containing hashes with the chart id (id), account number (accno),
description, rate, taxnumber, validto, pass, and taxmodulename for a tax.
$form->{taxmodule_B<id>}, where B<id> is a taxmodule_id, is set to that
taxmodule's name.

$myconfig is unused.

=cut

sub taxes {

    my ( $self, $myconfig, $form ) = @_;
    my $taxaccounts = '';

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
          SELECT c.id, c.accno, c.description,
                 t.rate * 100 AS rate, t.taxnumber, t.validto::date,
             t.minvalue, t.pass, m.taxmodulename
            FROM account c
            LEFT JOIN
                     (tax t JOIN taxmodule m
                            ON (t.taxmodule_id = m.taxmodule_id))
                    ON (c.id = t.chart_id)
                    WHERE c.tax
        ORDER BY 3, 6|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        push @{ $form->{taxrates} }, $ref;
        $taxaccounts .= " " . $ref{accno};
    }

    $sth->finish;

    $query = qq|
        SELECT taxmodule_id, taxmodulename FROM taxmodule
        ORDER BY 2|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{ "taxmodule_" . $ref->{taxmodule_id} } = $ref->{taxmodulename};
    }

    $sth->finish;


}

=item AM->save_taxes($myconfig, $form);

Deletes B<all> entries from the tax table then re-inserts all taxes whose
accounts are part of the space separated list $form->{taxaccounts}.  Each
element of $form->{taxaccounts} is of the form 'chartid_I<i>' where chartid is
the id of the chart entry for the tax and I<i> is a numeric index.  The values
inserted for each tax are chart_id (from taxaccounts), rate (
form->{taxrate_I<i>} / 100), validto ($form->{validto_I<i>}), taxnumber
($form->{taxnumber_I<i>}), pass ($form->{pass_I<i>}), and taxmodule_id
($form->{taxmodule_id_I<i>}).

=cut

sub save_taxes {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    foreach my $item ( split / /, $form->{taxaccounts} ) {
        my ( $chart_id, $i ) = split /_/, $item;

        my $rate=$form->{"taxrate_$i"};
        $rate=~s/^\s+|\s+$//g;
        $rate=$form->parse_amount( $myconfig, $form->{"taxrate_$i"} ) / 100;
        my $validto=$form->{"validto_$i"};
        $validto=~s/^\s+|\s+$//g;
        my $pass=$form->{"pass_$i"};
        $pass=~s/^\s+|\s+$//g;
        my $taxnumber=$form->{"taxnumber_$i"};
        $taxnumber=~s/^\s+|\s+$//g;
        my $old_validto=$form->{"old_validto_$i"};
        $old_validto=~s/^\s+|\s+$//g;
        if($rate==0  && $validto eq '' && $pass eq '' && $taxnumber eq '')
        {
         $logger->debug("skipping chart_id=$chart_id i=$i rate=$rate validto=$validto pass=$pass taxnumber=$taxnumber old_validto=$old_validto skipping");
         next;
        }
        if($old_validto eq '')
        {
         $logger->info("will insert new chart_id=$chart_id i=$i rate=$rate validto=$validto pass=$pass taxnumber=$taxnumber old_validto=$old_validto");
        }

        #$rate=$form->parse_amount( $myconfig, $form->{"taxrate_$i"} ) / 100;
        $validto = $form->{"validto_$i"};
        $validto = 'infinity' if not $validto;
        $form->{"pass_$i"} = 0 if not $form->{"pass_$i"};
        delete $form->{"old_validto_$i"} if ! $form->{"old_validto_$i"};

        $sth = $dbh->prepare('select account__save_tax(?,?,?,?,?,?,?,?,?)');
        my @queryargs = (
            $chart_id, $validto, $rate,
            $form->{"minvalue_$i"}, $form->{"maxvalue_$i"},
            $form->{"taxnumber_$i"}, $form->{"pass_$i"},
            $form->{"taxmodule_id_$i"}, $form->{"old_validto_$i"}
        );
       $sth->execute(@queryargs) ||$form->dberror($query);
       $sth->finish;
    }


    1;

}


1;

=back

