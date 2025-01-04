=head1 NAME

LedgerSMB::IC - Inventory Control backend

=cut

#=====================================================================
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
#  Contributors:
#
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# Inventory Control backend
#
#======================================================================

package IC;

use Log::Any;
use LedgerSMB::File;

my $logger = Log::Any->get_logger(category => 'IC');

=over

=item get_files

Returns a list of files associated with the existing transaction.  This is
provisional, and wil change for 1.4 as the GL transaction functionality is
                  {ref_key => $self->{id}, file_class => 1}
rewritten

=back

=cut

sub get_files {
     my ($self, $form, $locale) = @_;
     my $file = LedgerSMB::File->new(%$form);
     @{$form->{files}} = $file->list({ref_key => $form->{id}, file_class => 3});
     @{$form->{file_links}} = $file->list_links(
                  {ref_key => $form->{id}, file_class => 3}
     );

}

sub get_part {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};
    my $i;

    my $query = qq|
           SELECT p.*, a1.accno AS inventory_accno,
                  a1.description AS inventory_description,
                  a2.accno AS income_accno,
                  a2.description AS income_description,
                  a3.accno AS expense_accno,
                  a3.description AS expense_description, pg.partsgroup
             FROM parts p
        LEFT JOIN account a1 ON (p.inventory_accno_id = a1.id)
        LEFT JOIN account a2 ON (p.income_accno_id = a2.id)
        LEFT JOIN account a3 ON (p.expense_accno_id = a3.id)
        LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
            WHERE p.id = ?|;
    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);
    my $ref = $sth->fetchrow_hashref(NAME_lc);
    $form->db_parse_numeric(sth => $sth, hashref => $ref);

    # copy to $form variables
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # part, service item or labor
    $form->{item} = ( $form->{inventory_accno_id} ) ? 'part' : 'service';
    $form->{item} = 'labor' if !$form->{income_accno_id};

    if ( $form->{assembly} ) {
        $form->{item} = 'assembly';

        # retrieve assembly items
        $query = qq|
               SELECT p.id, p.partnumber, p.description,
                      p.sellprice, p.weight, a.qty, a.bom, a.adj,
                      p.unit, p.lastcost, p.listprice,
                      pg.partsgroup, p.assembly, p.partsgroup_id
                 FROM parts p
                 JOIN assembly a ON (a.parts_id = p.id)
            LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
                WHERE a.id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $form->{assembly_rows} = 0;
        while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
            $form->db_parse_numeric(sth => $sth, hashref => $ref);
            $form->{assembly_rows}++;
            foreach my $key ( keys %{$ref} ) {
                $form->{"${key}_$form->{assembly_rows}"} = $ref->{$key};
            }
        }
        $sth->finish;

    }

    $logger->debug("item: $form->{item}");

    # setup accno hash for <option checked>
    # {amount} is used in create_links
    for (qw(inventory income expense returns)) {
        $form->{amount}{"IC_$_"} = {
            accno       => $form->{"${_}_accno"},
            description => $form->{"${_}_description"}
        };
    }

    if ( $form->{item} =~ /(part|assembly)/ ) {

        if ( $form->{makemodel} ne "" ) {
            $query = qq|
                SELECT make, model, barcode
                  FROM makemodel
                 WHERE parts_id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);

            while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
                push @{ $form->{makemodels} }, $ref;
            }
            $sth->finish;
        }
    }

    # now get accno for taxes
    $query = qq|
        SELECT c.accno FROM account c, partstax pt
         WHERE pt.chart_id = c.id AND pt.parts_id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    while ( ($key) = $sth->fetchrow_array ) {
        $form->{amount}{$key} = $key;
    }

    $sth->finish;

    my $id = $dbh->quote( $form->{id} );

    # is it an orphan
    $query = qq|
        SELECT parts_id FROM invoice WHERE parts_id = $id
        UNION
        SELECT parts_id FROM orderitems WHERE parts_id = $id
        UNION
        SELECT parts_id FROM assembly WHERE parts_id = $id
        UNION
        SELECT parts_id FROM jcitems WHERE parts_id = $id|;
    ( $form->{orphaned} ) = $dbh->selectrow_array($query);
    $form->{orphaned} = !$form->{orphaned};

    $form->{orphaned} = 0 if $form->{project_id};

    if ( $form->{item} eq 'assembly' ) {
        if ( $form->{orphaned} ) {
            $form->{orphaned} = !$form->{onhand};
        }
    }

    if ( $form->{item} =~ /(part|service)/ ) {

        # get vendors
        $query = qq|
              SELECT v.id, e.name, pv.partnumber,
                     pv.lastcost, pv.leadtime,
                     pv.curr AS vendorcurr, v.meta_number
                FROM partsvendor pv
                JOIN entity_credit_account v
                                 ON (v.id = pv.credit_id)
                            JOIN entity e ON (e.id = v.entity_id)
               WHERE pv.parts_id = ?
            ORDER BY 2|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
            $form->db_parse_numeric(sth => $sth, hashref => $ref);
            push @{ $form->{vendormatrix} }, $ref;
        }
        $sth->finish;
    }

    # get matrix
    if ( $form->{item} ne 'labor' ) {
        $query = qq|
               SELECT pc.pricebreak, pc.sellprice AS customerprice,
                      pc.curr AS customercurr, pc.validfrom,
                      pc.validto, e.name, c.id AS cid,
                      g.pricegroup, g.id AS gid, c.meta_number, pc.qty
                 FROM partscustomer pc
            LEFT JOIN entity_credit_account c
                                  ON (c.id = pc.credit_id)
            LEFT JOIN pricegroup g ON (g.id = pc.pricegroup_id)
                        LEFT JOIN entity e ON (e.id = c.entity_id)
                WHERE pc.parts_id = ?
             ORDER BY e.name, g.pricegroup, pc.qty asc, pc.pricebreak|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
            $form->db_parse_numeric(sth => $sth, hashref => $ref);
            push @{ $form->{customermatrix} }, $ref;
        }
        $sth->finish;
    }
}

sub save {
    my ( $self, $myconfig, $form ) = @_;
    $form->{partnumber} =
      $form->update_defaults( $myconfig, "partnumber", $dbh)
      if $form->should_update_defaults('partnumber');

    ( $form->{inventory_accno} ) = split( /--/, $form->{IC_inventory} );
    ( $form->{expense_accno} )   = split( /--/, $form->{IC_expense} );
    ( $form->{income_accno} )    = split( /--/, $form->{IC_income} );
    ( $form->{returns_accno} )    = split( /--/, $form->{IC_returns} );

    my $dbh = $form->{dbh};

    # undo amount formatting
    for (qw(rop weight listprice sellprice lastcost stock)) {
        $form->{$_} = $form->parse_amount( $myconfig, $form->{$_} );
    }

    $form->{makemodel} =
      ( ( $form->{make_1} ) || ( $form->{model_1} ) ) ? 1 : 0;

    $form->{assembly} = ( $form->{item} eq 'assembly' ) ? 1 : 0;
    for (qw(alternate obsolete onhand)) { $form->{$_} *= 1 }

    my $query;
    my $sth;
    my $i;
    my $null;
    my $vendor_id;
    my $customer_id;

    if ( $form->{id} ) {

        # get old price
        $query = qq|
            SELECT id, listprice, sellprice, lastcost, weight
              FROM parts
             WHERE id = ?|;
        my $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} );
        my ( $id, $listprice, $sellprice, $lastcost, $weight) =
          $sth->fetchrow_array();

        if ($id) {

            if ( !$project_id ) {

                # if item is part of an assembly
                # adjust all assemblies
                $query = qq|
                    SELECT id, qty, adj
                      FROM assembly
                     WHERE parts_id = ?|;
                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id} )
                  || $form->dberror($query);
                while ( my ( $id, $qty, $adj ) = $sth->fetchrow_array ) {

                    &update_assembly(
                        $dbh,           $form,
                        $id,            $qty,
                        $adj,           $listprice * 1,
                        $sellprice * 1, $lastcost * 1,
                        $weight * 1
                    );
                }
                $sth->finish;
            }

            if ( $form->{item} =~ /(part|service)/ ) {

                # delete partsvendor records
                $query = qq|
                    DELETE FROM partsvendor
                          WHERE parts_id = ?|;
                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id} )
                  || $form->dberror($query);
            }

            if ( $form->{item} !~ /(service|labor)/ ) {

                # delete makemodel records
                $query = qq|
                    DELETE FROM makemodel
                          WHERE parts_id = ?|;
                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id} )
                  || $form->dberror($query);
            }

            if ( $form->{item} eq 'assembly' ) {

                if ( $form->{onhand} ) {
                    &adjust_inventory( $dbh, $form, $form->{id},
                        $form->{onhand} * -1 );
                }

                if ( $form->{orphaned} ) {

                    # delete assembly records
                    $query = qq|
                        DELETE FROM assembly
                              WHERE id = ?|;
                    $sth = $dbh->prepare($query);
                    $sth->execute( $form->{id} )
                      || $form->dberror($query);
                }
                else {

                    foreach my $i ( 1 .. $form->{assembly_rows} - 1 ) {

                        # update BOM, A only
                        for (qw(bom adj)) {
                            $form->{"${_}_$i"} *= 1;
                        }

                        $query = qq|
                            UPDATE assembly
                               SET bom = ?,
                                   adj = ?
                             WHERE id = ?
                                   AND parts_id = ?|;
                        $sth = $dbh->prepare($query);
                        $sth->execute(
                            $form->{"bom_$i"}, $form->{"adj_$i"},
                            $form->{id},       $form->{"id_$i"}
                        ) || $form->dberror($query);
                    }
                }

                $form->{onhand} += $form->{stock};

            }

            # delete tax records
            $query = qq|DELETE FROM partstax WHERE parts_id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);

            # delete matrix
            $query = qq|
                DELETE FROM partscustomer
                      WHERE parts_id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);
        }
        else {
            $query = qq|INSERT INTO parts (id) VALUES (?)|;
            $sth   = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);
        }

    }

    if ( !$form->{id} ) {
        my $uid = localtime;
        $uid .= "$$";

        $query = qq|INSERT INTO parts (partnumber) VALUES ('$uid')|;
        $dbh->do($query) || $form->dberror($query);

        $query = qq|SELECT id FROM parts WHERE partnumber = '$uid'|;
        $sth   = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);
        ( $form->{id} ) = $sth->fetchrow_array;
        $sth->finish;

        $form->{orphaned} = 1;
        $form->{onhand}   = ( $form->{stock} * 1 )
          if $form->{item} eq 'assembly';
    }

    my $partsgroup_id;
    ( $null, $partsgroup_id ) = split /--/, $form->{partsgroup};


    if ( !$form->{priceupdate} ) {
        $form->{priceupdate} = 'now';
    }
    $query = qq|
        UPDATE parts
           SET partnumber = ?,
               description = ?,
               makemodel = ?,
               alternate = ?,
               assembly = ?,
               listprice = ?,
               sellprice = ?,
               lastcost = ?,
               weight = ?,
               priceupdate = ?,
               unit = ?,
               notes = ?,
               rop = ?,
               bin = ?,
               inventory_accno_id = (SELECT id FROM account
                                      WHERE accno = ?),
               income_accno_id = (SELECT id FROM account
                                   WHERE accno = ?),
               expense_accno_id = (SELECT id FROM account
                                    WHERE accno = ?),
                       returns_accno_id = (SELECT id FROM account
                                            WHERE accno = ?),
               obsolete = ?,
               image = ?,
               drawing = ?,
               microfiche = ?,
               partsgroup_id = ?
         WHERE id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute(
        $form->{partnumber},      $form->{description},
        $form->{makemodel},       $form->{alternate},
        $form->{assembly},        $form->{listprice},
        $form->{sellprice},       $form->{lastcost},
        $form->{weight},          $form->{priceupdate},
        $form->{unit},            $form->{notes},
        $form->{rop},             $form->{bin},
        $form->{inventory_accno}, $form->{income_accno},
        $form->{expense_accno},   $form->{returns_accno},
        $form->{obsolete},
        $form->{image},           $form->{drawing},
        $form->{microfiche},      $partsgroup_id,
        $form->{id}
    ) || $form->dberror($query);

    # insert makemodel records
    if ( $form->{item} =~ /(part|assembly)/ ) {
        my $have_barcodes = 0;
        $query = qq|
            INSERT INTO makemodel (parts_id, make, model, barcode)
                 VALUES (?, ?, ?, ?)|;
        $sth = $dbh->prepare($query) || $form->dberror($query);
        foreach my $i ( 1 .. $form->{makemodel_rows} ) {
            if (   ( $form->{"make_$i"} ne "" )
                   || ( $form->{"model_$i"} ne "" ) ) {
                $have_barcodes ||= $form->{"barcode_$i"};
                $sth->execute( $form->{id}, $form->{"make_$i"},
                    $form->{"model_$i"} , $form->{"barcode_$i"})
                  || $form->dberror($query);
            }
        }
        if ($have_barcodes) {
            # If there's already a record, if it's "auto", there's nothing to do
            # If it's "yes", we don't want to change it to "auto" and
            # If it's "no", we don't want to enable it...
            $query = q|
            INSERT INTO defaults (setting_key, value)
                  VALUES ('have_barcodes', 'auto')
                  ON CONFLICT DO NOTHING
|;
            $sth = $dbh->prepare($query) || $form->dberror($query);
            $sth->execute || $form->dberror($query);
        }
    }

    # insert taxes
    $query = qq|
         INSERT INTO partstax (parts_id, chart_id)
         VALUES (?, (SELECT id FROM account WHERE accno = ?))|;
    $sth = $dbh->prepare($query);
    for ( split / /, $form->{taxaccounts} ) {
        if ( $form->{"IC_tax_$_"} ) {
            $sth->execute( $form->{id}, $_ )
              || $form->dberror($query);
        }
    }

    @a = localtime;
    $a[5] += 1900;  ## no critic (ProhibitMagicNumbers) sniff
    $a[4]++;  ## no critic (ProhibitMagicNumbers) sniff
    $a[4] = substr( "0$a[4]", -2 );  ## no critic (ProhibitMagicNumbers) sniff
    $a[3] = substr( "0$a[3]", -2 );  ## no critic (ProhibitMagicNumbers) sniff
    my $shippingdate = "$a[5]$a[4]$a[3]";

    ( $form->{employee}, $form->{employee_id} ) = $form->get_employee;

    # add assembly records
    if ( $form->{item} eq 'assembly' && !$project_id ) {

        if ( $form->{orphaned} ) {
            $query = qq|
                INSERT INTO assembly
                            (id, parts_id, qty, bom, adj)
                     VALUES (?, ?, ?, ?, ?)|;
            $sth = $dbh->prepare($query);
            foreach my $i ( 1 .. $form->{assembly_rows} - 1) {
                $form->{"qty_$i"} =
                  $form->parse_amount( $myconfig, $form->{"qty_$i"} );
                if ( !$form->{"bom_$i"} ) {
                    $form->{"bom_$i"} = undef;
                }

                if ( $form->{"id_$i"} && $form->{"qty_$i"} ) {
                    $sth->execute(
                        $form->{id}, $form->{"id_$i"},
                        $form->{"qty_$i"}, $form->{"bom_$i"} || 0,
                        $form->{"adj_$i"}
                    ) || $form->dberror($query);
                }
            }
        }

        # adjust onhand for the parts
        if ( $form->{onhand} ) {
            &adjust_inventory( $dbh, $form, $form->{id}, $form->{onhand} );
        }
    }

    # add vendors
    if ( $form->{item} ne 'assembly' ) {
        $updparts{ $form->{id} } = 1;

        foreach my $i ( 1 .. $form->{vendor_rows} ) {
            if ( ( $form->{"vendor_$i"} ne "" )
                && $form->{"lastcost_$i"} )
            {

                ( $null, $vendor_id ) = split /--/, $form->{"vendor_$i"};

                for (qw(lastcost leadtime)) {
                    $form->{"${_}_$i"} =
                      $form->parse_amount( $myconfig, $form->{"${_}_$i"} );
                }

                $query = qq|
                    INSERT INTO partsvendor
                                (credit_id, parts_id,
                                partnumber, lastcost,
                                leadtime, curr)
                         VALUES (?, ?, ?, ?, ?, ?)|;
                $sth = $dbh->prepare($query);
                $sth->execute(
                    $vendor_id,               $form->{id},
                    $form->{"partnumber_$i"}, $form->{"lastcost_$i"},
                    $form->{"leadtime_$i"},   $form->{"vendorcurr_$i"}
                ) || $form->dberror($query);
            }
        }
    }

    # add pricematrix
    foreach my $i ( 1 .. $form->{customer_rows} ) {

        for (qw(pricebreak customerprice)) {
            $form->{"${_}_$i"} =
              $form->parse_amount( $myconfig, $form->{"${_}_$i"} );
        }

        if ( $form->{"customerprice_$i"} || $form->{"pricebreak_$i"} ) {

            ( $null, $customer_id ) = split /--/, $form->{"customer_$i"};
            $customer_id *= 1;
            $customer_id ||= undef; # 0 id is invalid anyway.

            ( $null, $pricegroup_id ) = split /--/, $form->{"pricegroup_$i"};

            my $validfrom;
            my $validto;
            my $customerqty;
            $validfrom = $form->{"validfrom_$i"} if $form->{"validfrom_$i"};
            $validto   = $form->{"validto_$i"}   if $form->{"validto_$i"};
            $customerqty =
                $form->{"customerqty_$i"} if $form->{"customerqty_$i"};
            $query     = qq|
                INSERT INTO partscustomer
                            (parts_id, credit_id,
                            pricegroup_id, pricebreak,
                            sellprice, curr,
                            validfrom, validto, qty)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)|;
            $sth = $dbh->prepare($query);
            $sth->execute(
                $form->{id},                 $customer_id,
                $pricegroup_id,              $form->{"pricebreak_$i"},
                $form->{"customerprice_$i"}, $form->{"customercurr_$i"},
                $validfrom,                  $validto,
                $customerqty
            ) || $form->dberror($query);
        }
    }
    $rc;
}

sub update_assembly {
    my (
        $dbh,       $form,      $id,       $qty, $adj,
        $listprice, $sellprice, $lastcost, $weight
    ) = @_;

    my $formlistprice = $form->{listprice};
    my $formsellprice = $form->{sellprice};

    if ( !$adj ) {
        $formlistprice = $listprice;
        $formsellprice = $sellprice;
    }

    my $query = qq|SELECT id, qty, adj FROM assembly WHERE parts_id = ?|;
    my $sth   = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    $form->{$id} = 1;    # Not sure what this is for...
                         # In fact, we don't seem to use it... Chris T

    while ( my ( $pid, $aqty, $aadj ) = $sth->fetchrow_array ) {
        &update_assembly(
            $dbh,       $form,      $pid,      $aqty * $qty, $aadj,
            $listprice, $sellprice, $lastcost, $weight
        ) if !$form->{$pid};
    }
    $sth->finish;
    $qty           = $dbh->quote($qty);
    $formlistprice = $dbh->quote( $formlistprice - $listprice );
    $formsellprice = $dbh->quote( $formsellprice - $sellprice );
    $formlastcost  = $dbh->quote( $form->{lastcost} - $lastcost );
    $weight        = $dbh->quote( $form->{weight} - $weight );
    $id            = $dbh->quote($id);

    $query = qq|
        UPDATE parts
           SET listprice = listprice +
               $qty * cast($formlistprice AS numeric),
               sellprice = sellprice +
               $qty * cast($formsellprice AS numeric),
               lastcost = lastcost +
               $qty * cast($formlastcost AS numeric),
               weight = weight +
               $qty * cast($weight AS numeric)
         WHERE id = $id|;
    $dbh->do($query) || $form->dberror($query);

    delete $form->{$id};

}

sub retrieve_assemblies {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $where = '1 = 1';

    if ( $form->{partnumber} ne "" ) {
        my $partnumber = $dbh->quote( $form->like( lc $form->{partnumber} ) );
        $where .= " AND lower(p.partnumber) LIKE $partnumber";
    }

    if ( $form->{description} ne "" ) {
        my $description = $dbh->quote( $form->like( lc $form->{description} ) );
        $where .= " AND lower(p.description) LIKE $description";
    }
    $where .= qq| AND not p.obsolete |;

    my %ordinal = (
        'partnumber'  => 2,
        'description' => 3,
        'bin'         => 4
    );

    my @a = qw(partnumber description bin);
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    # retrieve assembly items
    my $query = qq|
          SELECT p.id, p.partnumber, p.description, p.bin, p.onhand,
                 p.rop
            FROM parts p
            WHERE $where
                 AND p.assembly = '1'
         ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $query = qq|
          SELECT sum(p.inventory_accno_id), p.assembly
            FROM parts p
            JOIN assembly a ON (a.parts_id = p.id)
           WHERE a.id = ?
        GROUP BY p.assembly|;
    my $svh = $dbh->prepare($query) || $form->dberror($query);

    my $inh;
    if ( $form->{checkinventory} ) {
        $query = qq|
            SELECT p.id, p.onhand, a.qty
              FROM parts p
              JOIN assembly a ON (a.parts_id = p.id)
             WHERE (p.inventory_accno_id > 0 OR p.assembly)
                   AND p.income_accno_id > 0 AND a.id = ?|;
        $inh = $dbh->prepare($query) || $form->dberror($query);
    }

    my %available = ();
    my %required;
    my $ref;
    my $aref;
    my $stock;
    my $howmany;
    my $ok;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $svh->execute( $ref->{id} );
        ( $ref->{inventory}, $ref->{assembly} ) = $svh->fetchrow_array;
        $svh->finish;

        if ( $ref->{inventory} || $ref->{assembly} ) {
            $ok = 1;
            if ( $form->{checkinventory} ) {
                $inh->execute( $ref->{id} )
                  || $form->dberror($query);
                $ok       = 0;
                %required = ();

                while ( $aref = $inh->fetchrow_hashref(NAME_lc) ) {

                    $available{ $aref->{id} } =
                      ( exists $available{ $aref->{id} } )
                      ? $available{ $aref->{id} }
                      : $aref->{onhand};
                    $required{ $aref->{id} } = $aref->{qty};

                    if ( $available{ $aref->{id} } >= $aref->{qty} ) {

                        $howmany =
                          ( $aref->{qty} )
                          ? int $available{ $aref->{id} } / $aref->{qty}
                          : 1;
                        if ($stock) {
                            $stock =
                              ( $stock > $howmany )
                              ? $howmany
                              : $stock;
                        }
                        else {
                            $stock = $howmany;
                        }
                        $ok = 1;

                        $available{ $aref->{id} } -= $aref->{qty} * $stock;

                    }
                    else {
                        $ok = 0;
                        for ( keys %required ) {
                            $available{$_} += $required{$_} * $stock;
                        }
                        $stock = 0;
                        last;
                    }
                }
                $inh->finish;
                $ref->{stock} = $stock;

            }
            push @{ $form->{assembly_items} }, $ref if $ok;
        }
    }
    $sth->finish;


}

sub restock_assemblies {
    my ( $self, $myconfig, $form ) = @_;

    my $sth;
    for my $loop ( 1 .. $form->{rowcount} ){
       my ($id, $qty) = ($form->{"id_$loop"}, $form->{"qty_$loop"});
       $sth = $form->{dbh}->prepare('SELECT assembly__stock(?, ?)');
       if ($qty){
           $sth->execute($id, $qty);
           $form->dberror() if $form->{dbh}->err;
       }
    }
    $form->{dbh}->commit;

    1;

}

sub adjust_inventory {

    my ( $dbh, $form, $id, $qty ) = @_;

    my $query = qq|
        SELECT p.id, p.inventory_accno_id, p.assembly, a.qty
          FROM parts p
          JOIN assembly a ON (a.parts_id = p.id)
         WHERE a.id = ?|;
    my $sth = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {

        # is it a service item then loop
        if ( !$ref->{inventory_accno_id} ) {
            next if !$ref->{assembly};
        }

        # adjust parts onhand
        $form->update_balance(
            $dbh, "parts", "onhand",
            qq|id = $ref->{id}|,
            $qty * $ref->{qty} * -1
        );
    }

    $sth->finish;

    # update assembly
    $form->update_balance( $dbh, "parts", "onhand", qq|id = $id|, $qty );

}

sub delete {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query;

    $query = qq|DELETE FROM parts WHERE id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|DELETE FROM partstax WHERE parts_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    if ( $form->{item} ne 'assembly' ) {
        $query = qq|DELETE FROM partsvendor WHERE parts_id = ?|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);
    }

    # check if it is a part, assembly or service
    if ( $form->{item} ne 'service' ) {
        $query = qq|DELETE FROM makemodel WHERE parts_id = ?|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);
    }

    if ( $form->{item} eq 'assembly' ) {
        $query = qq|DELETE FROM assembly WHERE id = ?|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);
    }

    $query = qq|DELETE FROM partscustomer WHERE parts_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|DELETE FROM parts_translation WHERE trans_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);


    1;

}

sub assembly_item {
    my ( $self, $myconfig, $form ) = @_;
    my $dbh = $form->{dbh};

    my $i = $form->{assembly_rows};
    my $var;
    my $null;
    my $where = "p.obsolete = '0'";

    if ( $form->{"partnumber_$i"} ne "" ) {
        $var = $dbh->quote( $form->{"partnumber_$i"} );
        $where .= " AND p.partnumber = $var";
    }

    my $query = qq|
           SELECT p.id, p.partnumber, p.description, p.sellprice,
                  p.weight, p.onhand, p.unit, p.lastcost, p.listprice,
                  pg.partsgroup, p.partsgroup_id
             FROM parts p
        LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
            WHERE $where|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{item_list} }, $ref;
    }

    $sth->finish;

}

sub create_links {
    my ( $self, $module, $myconfig, $form ) = @_;

    $logger->debug('start');

    my $dbh = $form->{dbh};

    my $ref;

    my $query = qq|
        SELECT a.accno, a.description, array_agg(l.description) as link
          FROM account a
          JOIN account_link l ON a.id = l.account_id
         WHERE l.description LIKE ?
         GROUP BY a.accno, a.description
         ORDER BY a.accno|;
    my $sth = $dbh->prepare($query)
        or $form->dberror($query);
    $sth->execute("$module%") || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        for my $key (@{$ref->{link}}){
            push @{ $form->{"${module}_links"}{$key} },
                  {
                    accno       => $ref->{accno},
                    description => $ref->{description}
                  };
        }
    }
    $sth->finish;

    my $vclimit = $form->get_setting('vclimit');
    if ( $form->{item} ne 'assembly' ) {
        $query = qq|SELECT count(*) FROM entity_credit_account
                     WHERE entity_class = 1|;
        my ($count) = $dbh->selectrow_array($query);

        if ( defined $vclimit and $count < $vclimit ) {
            $query = qq|SELECT v.id, e.name
                FROM entity_credit_account v
                join entity e on e.id = v.entity_id
               WHERE v.entity_class = 1
                ORDER BY e.name|;
            $sth   = $dbh->prepare($query)
                or $form->dberror($query);
            $sth->execute || $form->dberror($query);

            while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
                push @{ $form->{all_vendor} }, $ref;
            }
            $sth->finish;
        }
    }

    # pricegroups, customers
    $query = qq|SELECT count(*) FROM entity_credit_account
                where entity_class = 2|;
    ($count) = $dbh->selectrow_array($query);

    if ( defined $vclimit and $count < $vclimit ) {
        $query = qq|SELECT c.id, e.name
            FROM entity_credit_account c
            join entity e on e.id = c.entity_id
           WHERE c.entity_class = 2
            ORDER BY e.name|;
        $sth   = $dbh->prepare($query)
            or $form->dberror($query);
        $sth->execute || $form->dberror($query);

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            push @{ $form->{all_customer} }, $ref;
        }
        $sth->finish;
    }

    $query = qq|SELECT id, pricegroup FROM pricegroup ORDER BY pricegroup|;
    $sth   = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_pricegroup} }, $ref;
    }
    $sth->finish;

    if ( $form->{id} ) {
        $form->{weightunit} = $form->get_setting( 'weightunit' );
    }
}

sub get_warehouses {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|SELECT id, description FROM warehouse|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_warehouse} }, $ref;
    }
    $sth->finish;


}

1;
