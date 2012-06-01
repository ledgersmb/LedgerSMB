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
# Copyright (C) 2001
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# backend code for reports
#
#======================================================================

package RP;
use Log::Log4perl;
our $logger = Log::Log4perl->get_logger('LedgerSMB::Form');

sub inventory_activity {
    my ( $self, $myconfig, $form ) = @_;
    ( $form->{fromdate}, $form->{todate} ) =
      $form->from_to( $form->{fromyear}, $form->{frommonth}, $form->{interval} )
      if $form->{fromyear} && $form->{frommonth};

    my $dbh = $form->{dbh};

    unless ( $form->{sort_col} ) {
        $form->{sort_col} = 'partnumber';
    }

    my $where = '';
    if ( $form->{fromdate} ) {
        $where .=
          "AND coalesce(ar.transdate, ap.transdate) >= "
          . $dbh->quote( $form->{fromdate} );
    }
    if ( $form->{todate} ) {
        $where .=
          "AND coalesce(ar.transdate, ap.transdate) < "
          . $dbh->quote( $form->{todate} ) . " ";
    }
    if ( $form->{partnumber} ) {
        $where .=
          qq| AND p.partnumber ILIKE |
          . $dbh->quote( '%' . "$form->{partnumber}%" );
    }
    if ( $form->{description} ) {
        $where .=
          q| AND p.description ILIKE |
          . $dbh->quote( '%' . "$form->{description}%" );
    }
    $where =~ s/^\s?AND/WHERE/;

    my $query = qq|
		   SELECT min(p.description) AS description, 
		          min(p.partnumber) AS partnumber, sum(
		          CASE WHEN i.qty > 0 THEN i.qty ELSE 0 END) AS sold, 
		          sum (CASE WHEN i.qty > 0 
		                    THEN i.sellprice * i.qty 
		                    ELSE 0 END) AS revenue, 
		          sum(CASE WHEN i.qty < 0 THEN i.qty * -1 ELSE 0 END) 
		          AS received, sum(CASE WHEN i.qty < 0 
		                                THEN i.sellprice * i.qty * -1
		                                ELSE 0 END) as expenses, 
		          min(p.id) as id
		     FROM invoice i
		     JOIN parts p ON (i.parts_id = p.id)
		LEFT JOIN ar ON (ar.id = i.trans_id)
		LEFT JOIN ap ON (ap.id = i.trans_id)
		   $where
		 GROUP BY i.parts_id
		 ORDER BY $form->{sort_col}|;
    my $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute() || $form->dberror($query);
    @cols = qw(description sold revenue partnumber received expense);
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        $ref->{net_income} = $ref->{revenue} - $ref->{expense};
        map { $ref->{$_} =~ s/^\s*// } @cols;
        map { $ref->{$_} =~ s/\s*$// } @cols;
        push @{ $form->{TB} }, $ref;
    }
    $sth->finish;
    $dbh->commit;

}

sub yearend_statement {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    # if todate < existing yearends, delete GL and yearends
    my $query = qq|SELECT trans_id FROM yearend WHERE transdate >= ?|;
    my $sth   = $dbh->prepare($query);
    $sth->execute( $form->{todate} ) || $form->dberror($query);

    my @trans_id = ();
    my $id;
    while ( ($id) = $sth->fetchrow_array ) {
        push @trans_id, $id;
    }
    $sth->finish;

    my $last_period = 0;
    my @categories  = qw(I E);
    my $category;

    $form->{decimalplaces} *= 1;

    &get_accounts( $dbh, 0, $form->{fromdate}, $form->{todate}, $form,
        \@categories );

    $dbh->commit;

    # now we got $form->{I}{accno}{ }
    # and $form->{E}{accno}{  }

    my %account = (
        'I' => {
            'label'  => 'income',
            'labels' => 'income',
            'ml'     => 1
        },
        'E' => {
            'label'  => 'expense',
            'labels' => 'expenses',
            'ml'     => -1
        }
    );

    foreach $category (@categories) {
        foreach $key ( sort keys %{ $form->{$category} } ) {
            if ( $form->{$category}{$key}{charttype} eq 'A' ) {
                $form->{"total_$account{$category}{labels}_this_period"} +=
                  $form->{$category}{$key}{this} * $account{$category}{ml};
            }
        }
    }

    # totals for income and expenses
    $form->{total_income_this_period} =
      $form->round_amount( $form->{total_income_this_period},
        $form->{decimalplaces} );
    $form->{total_expenses_this_period} =
      $form->round_amount( $form->{total_expenses_this_period},
        $form->{decimalplaces} );

    # total for income/loss
    $form->{total_this_period} =
      $form->{total_income_this_period} - $form->{total_expenses_this_period};

}

sub income_statement {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $last_period = 0;
    my @categories  = qw(I E);
    my $category;

    $form->{decimalplaces} *= 1;

    if ( !( $form->{fromdate} || $form->{todate} ) ) {
        if ( $form->{fromyear} && $form->{frommonth} ) {
            ( $form->{fromdate}, $form->{todate} ) =
              $form->from_to( $form->{fromyear}, $form->{frommonth},
                $form->{interval} );
        }
    }
    
    &get_accounts( $dbh, $last_period, $form->{fromdate}, $form->{todate},
        $form, \@categories, 1 );

    if ( !( $form->{comparefromdate} || $form->{comparetodate} ) ) {
        if ( $form->{compareyear} && $form->{comparemonth} ) {
            ( $form->{comparefromdate}, $form->{comparetodate} ) =
              $form->from_to( $form->{compareyear}, $form->{comparemonth},
                $form->{interval} );
        }
    }

    # if there are any compare dates
    if ( $form->{comparefromdate} || $form->{comparetodate} ) {
        $last_period = 1;

        &get_accounts(
            $dbh, $last_period,
            $form->{comparefromdate},
            $form->{comparetodate},
            $form, \@categories, 1
        );
    }

    $dbh->commit;

    # now we got $form->{I}{accno}{ }
    # and $form->{E}{accno}{  }

    my %account = (
        'I' => {
            'label'  => 'income',
            'labels' => 'income',
            'ml'     => 1
        },
        'E' => {
            'label'  => 'expense',
            'labels' => 'expenses',
            'ml'     => -1
        }
    );

    my $str;

    foreach $category (@categories) {

        foreach $key ( sort keys %{ $form->{$category} } ) {

            # push description onto array

##            $str = ( $form->{l_heading} ) ? $form->{padding} : "";
            $str = "";

            if ( $form->{$category}{$key}{charttype} eq "A" ) {
                $str .=
                  ( $form->{l_accno} )
                  ? "$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}"
                  : "$form->{$category}{$key}{description}";
                $str = {account => $form->{$category}{$key}{accno}, text => $str };
                $str->{gifi_account} = 1 if $form->{accounttype} eq 'gifi';
            }
            if ( $form->{$category}{$key}{charttype} eq "H" ) {
                if (   $account{$category}{subtotal}
                    && $form->{l_subtotal} )
                {

                    $dash = "- ";
                    push(
                        @{ $form->{"$account{$category}{label}_account"} }, {
                            text => "$account{$category}{subdescription}",
                            subtotal => 1,
                            },
                    );

                    push(
                        @{
                            $form->{"$account{$category}{labels}_this_period"}
                          },
                        $form->format_amount(
                            $myconfig,
                            $account{$category}{subthis} *
                              $account{$category}{ml},
                            $form->{decimalplaces},
                            $dash
                        )
                    );

                    if ($last_period) {

                        # Chris T:  Giving up on
                        # Formatting this one :-(
                        push(
                            @{
                                $form->{
                                    "$account{$category}{labels}_last_period"}
                              },
                            $form->format_amount(
                                $myconfig,
                                $account{$category}{sublast} *
                                  $account{$category}{ml},
                                $form->{decimalplaces},
                                $dash
                            )
                        );
                    }

                }

                $str = {
                    text => "$form->{$category}{$key}{description}",
                    heading => 1,
                    };

                $account{$category}{subthis} = $form->{$category}{$key}{this};
                $account{$category}{sublast} = $form->{$category}{$key}{last};
                $account{$category}{subdescription} =
                  $form->{$category}{$key}{description};
                $account{$category}{subtotal} = 1;

                $form->{$category}{$key}{this} = 0;
                $form->{$category}{$key}{last} = 0;

                next unless $form->{l_heading};

                $dash = " ";
            }

            push( @{ $form->{"$account{$category}{label}_account"} }, $str );

            if ( $form->{$category}{$key}{charttype} eq 'A' ) {
                $form->{"total_$account{$category}{labels}_this_period"} +=
                  $form->{$category}{$key}{this} * $account{$category}{ml};

                $dash = "- ";
            }

            push(
                @{ $form->{"$account{$category}{labels}_this_period"} },
                $form->format_amount(
                    $myconfig,
                    $form->{$category}{$key}{this} * $account{$category}{ml},
                    $form->{decimalplaces}, $dash
                )
            );

            # add amount or - for last period
            if ($last_period) {
                $form->{"total_$account{$category}{labels}_last_period"} +=
                  $form->{$category}{$key}{last} * $account{$category}{ml};

                push(
                    @{ $form->{"$account{$category}{labels}_last_period"} },
                    $form->format_amount(
                        $myconfig,
                        $form->{$category}{$key}{last} *
                          $account{$category}{ml},
                        $form->{decimalplaces},
                        $dash
                    )
                );
            }
        }

##        $str = ( $form->{l_heading} ) ? $form->{padding} : "";
        $str = "";
        if ( $account{$category}{subtotal} && $form->{l_subtotal} ) {
            push(
                @{ $form->{"$account{$category}{label}_account"} }, {
                    text => "$account{$category}{subdescription}",
                    subtotal => 1,
                    },
            );
            push(
                @{ $form->{"$account{$category}{labels}_this_period"} },
                $form->format_amount(
                    $myconfig,
                    $account{$category}{subthis} * $account{$category}{ml},
                    $form->{decimalplaces}, $dash
                )
            );

            if ($last_period) {
                push(
                    @{ $form->{"$account{$category}{labels}_last_period"} },
                    $form->format_amount(
                        $myconfig,
                        $account{$category}{sublast} * $account{$category}{ml},
                        $form->{decimalplaces},
                        $dash
                    )
                );
            }
        }

    }

    # totals for income and expenses
    $form->{total_income_this_period} =
      $form->round_amount( $form->{total_income_this_period},
        $form->{decimalplaces} );
    $form->{total_expenses_this_period} =
      $form->round_amount( $form->{total_expenses_this_period},
        $form->{decimalplaces} );

    # total for income/loss
    $form->{total_this_period} =
      $form->{total_income_this_period} - $form->{total_expenses_this_period};

    if ($last_period) {

        # total for income/loss
        $form->{total_last_period} = $form->format_amount(
            $myconfig,
            $form->{total_income_last_period} -
              $form->{total_expenses_last_period},
            $form->{decimalplaces},
            "- "
        );

        # totals for income and expenses for last_period
        $form->{total_income_last_period} = $form->format_amount(
            $myconfig,
            $form->{total_income_last_period},
            $form->{decimalplaces}, "- "
        );
        $form->{total_expenses_last_period} = $form->format_amount(
            $myconfig,
            $form->{total_expenses_last_period},
            $form->{decimalplaces}, "- "
        );

    }

    $form->{total_income_this_period} = $form->format_amount(
        $myconfig,
        $form->{total_income_this_period},
        $form->{decimalplaces}, "- "
    );
    $form->{total_expenses_this_period} = $form->format_amount(
        $myconfig,
        $form->{total_expenses_this_period},
        $form->{decimalplaces}, "- "
    );
    $form->{total_this_period} = $form->format_amount(
        $myconfig,
        $form->{total_this_period},
        $form->{decimalplaces}, "- "
    );

}

sub balance_sheet {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $last_period = 0;
    my @categories  = qw(A L Q);

    my $null;

    if ( $form->{asofdate} ) {
        if ( $form->{asofyear} && $form->{asofmonth} ) {
            if ( $form->{asofdate} !~ /\W/ ) {
                $form->{asofdate} =
                  "$form->{asofyear}$form->{asofmonth}$form->{asofdate}";
            }
        }
    }
    else {
        if ( $form->{fromyear} && $form->{frommonth} ) {
            ( $null, $form->{asofdate} ) =
              $form->from_to( $form->{fromyear}, $form->{frommonth} );
        }
    }

    # if there are any dates construct a where
    if ( $form->{asofdate} ) {

        $form->{this_period} = "$form->{asofdate}";
        $form->{period}      = "$form->{asofdate}";

    }

    $form->{decimalplaces} *= 1;

    &get_accounts( $dbh, $last_period, "", $form->{asofdate}, $form,
        \@categories, 1 );

    if ( $form->{compareasofdate} ) {
        if ( $form->{compareasofyear} && $form->{compareasofmonth} ) {
            if ( $form->{compareasofdate} !~ /\W/ ) {
                $form->{compareasofdate} =
"$form->{compareasofyear}$form->{compareasofmonth}$form->{compareasofdate}";
            }
        }
    }
    else {
        if ( $form->{compareasofyear} && $form->{compareasofmonth} ) {
            ( $null, $form->{compareasofdate} ) =
              $form->from_to( $form->{compareasofyear},
                $form->{compareasofmonth} );
        }
    }

    # if there are any compare dates
    if ( $form->{compareasofdate} ) {

        $last_period = 1;
        &get_accounts( $dbh, $last_period, "", $form->{compareasofdate},
            $form, \@categories, 1 );

        $form->{last_period} = "$form->{compareasofdate}";

    }

    $dbh->commit;

    # now we got $form->{A}{accno}{ }    assets
    # and $form->{L}{accno}{ }           liabilities
    # and $form->{Q}{accno}{ }           equity
    # build asset accounts

    my $str;
    my $key;

    my %account = (
        'A' => {
            'label'  => 'asset',
            'labels' => 'assets',
            'ml'     => -1
        },
        'L' => {
            'label'  => 'liability',
            'labels' => 'liabilities',
            'ml'     => 1
        },
        'Q' => {
            'label'  => 'equity',
            'labels' => 'equity',
            'ml'     => 1
        }
    );

    foreach $category (@categories) {

        foreach $key ( sort keys %{ $form->{$category} } ) {

##            $str = ( $form->{l_heading} ) ? $form->{padding} : "";
            $str = "";

            if ( $form->{$category}{$key}{charttype} eq "A" ) {
                $str .=
                  ( $form->{l_accno} )
                  ? "$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}"
                  : "$form->{$category}{$key}{description}";
                $str = {account => $form->{$category}{$key}{accno}, text => $str};
                $str->{gifi_account} = 1 if $form->{accounttype} eq 'gifi';
            }
            elsif ( $form->{$category}{$key}{charttype} eq "H" ) {
                if (   $account{$category}{subtotal}
                    && $form->{l_subtotal} )
                {

                    $dash = "- ";
                    push(
                        @{ $form->{"$account{$category}{label}_account"} },
                        {
                            text => "$account{$category}{subdescription}",
                            subtotal => 1
                            },
                    );
                    push(
                        @{ $form->{"$account{$category}{label}_this_period"} },
                        $form->format_amount(
                            $myconfig,
                            $account{$category}{subthis} *
                              $account{$category}{ml},
                            $form->{decimalplaces},
                            $dash
                        )
                    );

                    if ($last_period) {
                        push(
                            @{
                                $form->{
                                    "$account{$category}{label}_last_period"}
                              },
                            $form->format_amount(
                                $myconfig,
                                $account{$category}{sublast} *
                                  $account{$category}{ml},
                                $form->{decimalplaces},
                                $dash
                            )
                        );
                    }
                }

                $str = {
                    text => "$form->{$category}{$key}{description}",
                    heading => 1
                    };

                $account{$category}{subthis} = $form->{$category}{$key}{this};
                $account{$category}{sublast} = $form->{$category}{$key}{last};
                $account{$category}{subdescription} =
                  $form->{$category}{$key}{description};
                $account{$category}{subtotal} = 1;

                $form->{$category}{$key}{this} = 0;
                $form->{$category}{$key}{last} = 0;

                next unless $form->{l_heading};

                $dash = " ";
            }

            # push description onto array
            push( @{ $form->{"$account{$category}{label}_account"} }, $str );

            if ( $form->{$category}{$key}{charttype} eq 'A' ) {
                $form->{"total_$account{$category}{labels}_this_period"} +=
                  $form->{$category}{$key}{this} * $account{$category}{ml};
                $dash = "- ";
            }

            push(
                @{ $form->{"$account{$category}{label}_this_period"} },
                $form->format_amount(
                    $myconfig,
                    $form->{$category}{$key}{this} * $account{$category}{ml},
                    $form->{decimalplaces}, $dash
                )
            );

            if ($last_period) {
                $form->{"total_$account{$category}{labels}_last_period"} +=
                  $form->{$category}{$key}{last} * $account{$category}{ml};

                push(
                    @{ $form->{"$account{$category}{label}_last_period"} },
                    $form->format_amount(
                        $myconfig,
                        $form->{$category}{$key}{last} *
                          $account{$category}{ml},
                        $form->{decimalplaces},
                        $dash
                    )
                );
            }
        }

	#$str = ( $form->{l_heading} ) ? $form->{padding} : "";
        $str = "";
        if ( $account{$category}{subtotal} && $form->{l_subtotal} ) {
            push(
                @{ $form->{"$account{$category}{label}_account"} }, {
                    text => "$account{$category}{subdescription}",
                    subtotal => 1,
                    },
            );
            push(
                @{ $form->{"$account{$category}{label}_this_period"} },
                $form->format_amount(
                    $myconfig,
                    $account{$category}{subthis} * $account{$category}{ml},
                    $form->{decimalplaces}, $dash
                )
            );

            if ($last_period) {
                push(
                    @{ $form->{"$account{$category}{label}_last_period"} },
                    $form->format_amount(
                        $myconfig,
                        $account{$category}{sublast} * $account{$category}{ml},
                        $form->{decimalplaces},
                        $dash
                    )
                );
            }
        }

    }

    # totals for assets, liabilities
    $form->{total_assets_this_period} =
      $form->round_amount( $form->{total_assets_this_period},
        $form->{decimalplaces} );
    $form->{total_liabilities_this_period} =
      $form->round_amount( $form->{total_liabilities_this_period},
        $form->{decimalplaces} );
    $form->{total_equity_this_period} =
      $form->round_amount( $form->{total_equity_this_period},
        $form->{decimalplaces} );

    # calculate earnings
    $form->{earnings_this_period} =
      $form->{total_assets_this_period} -
      $form->{total_liabilities_this_period} -
      $form->{total_equity_this_period};

    push(
        @{ $form->{equity_this_period} },
        $form->format_amount(
            $myconfig,              $form->{earnings_this_period},
            $form->{decimalplaces}, "- "
        )
    );

    $form->{total_equity_this_period} =
      $form->round_amount(
        $form->{total_equity_this_period} + $form->{earnings_this_period},
        $form->{decimalplaces} );

    # add liability + equity
    $form->{total_this_period} = $form->format_amount(
        $myconfig,
        $form->{total_liabilities_this_period} +
          $form->{total_equity_this_period},
        $form->{decimalplaces},
        "- "
    );

    if ($last_period) {

        # totals for assets, liabilities
        $form->{total_assets_last_period} =
          $form->round_amount( $form->{total_assets_last_period},
            $form->{decimalplaces} );
        $form->{total_liabilities_last_period} =
          $form->round_amount( $form->{total_liabilities_last_period},
            $form->{decimalplaces} );
        $form->{total_equity_last_period} =
          $form->round_amount( $form->{total_equity_last_period},
            $form->{decimalplaces} );

        # calculate retained earnings
        $form->{earnings_last_period} =
          $form->{total_assets_last_period} -
          $form->{total_liabilities_last_period} -
          $form->{total_equity_last_period};

        push(
            @{ $form->{equity_last_period} },
            $form->format_amount(
                $myconfig,              $form->{earnings_last_period},
                $form->{decimalplaces}, "- "
            )
        );

        $form->{total_equity_last_period} =
          $form->round_amount(
            $form->{total_equity_last_period} + $form->{earnings_last_period},
            $form->{decimalplaces} );

        # add liability + equity
        $form->{total_last_period} = $form->format_amount(
            $myconfig,
            $form->{total_liabilities_last_period} +
              $form->{total_equity_last_period},
            $form->{decimalplaces},
            "- "
        );

    }

    $form->{total_liabilities_last_period} = $form->format_amount(
        $myconfig,
        $form->{total_liabilities_last_period},
        $form->{decimalplaces}, "- "
    ) if ( $form->{total_liabilities_last_period} );

    $form->{total_equity_last_period} = $form->format_amount(
        $myconfig,
        $form->{total_equity_last_period},
        $form->{decimalplaces}, "- "
    ) if ( $form->{total_equity_last_period} );

    $form->{total_assets_last_period} = $form->format_amount(
        $myconfig,
        $form->{total_assets_last_period},
        $form->{decimalplaces}, "- "
    ) if ( $form->{total_assets_last_period} );

    $form->{total_assets_this_period} = $form->format_amount(
        $myconfig,
        $form->{total_assets_this_period},
        $form->{decimalplaces}, "- "
    );

    $form->{total_liabilities_this_period} = $form->format_amount(
        $myconfig,
        $form->{total_liabilities_this_period},
        $form->{decimalplaces}, "- "
    );

    $form->{total_equity_this_period} = $form->format_amount(
        $myconfig,
        $form->{total_equity_this_period},
        $form->{decimalplaces}, "- "
    );

}

sub get_accounts {
    my ( $dbh, $last_period, $fromdate, $todate, $form, $categories,
        $excludeyearend )
      = @_;

    my $department_id;
    my $project_id;

    ( $null, $department_id ) = split /--/, $form->{department};
    ( $null, $project_id )    = split /--/, $form->{projectnumber};

    my $query;
    my $dpt_where;
    my $dpt_join;
    my $project;
    my $where        = "1 = 1";
    my $glwhere      = "";
    my $subwhere     = "";
    my $yearendwhere = "1 = 1";
    my $item;

    my $category = "AND (";
    foreach $item ( @{$categories} ) {
        $category .= qq|c.category = | . $dbh->quote($item) . qq| OR |;
    }
    $category =~ s/OR $/\)/;

    # get headings
    $query = qq|
		  SELECT accno, description, category
		    FROM chart c
		   WHERE c.charttype = 'H' $category
		ORDER BY c.accno|;

    if ( $form->{accounttype} eq 'gifi' ) {
        $query = qq|
		  SELECT g.accno, g.description, c.category
		    FROM gifi g
		    JOIN chart c ON (c.gifi_accno = g.accno)
		   WHERE c.charttype = 'H' $category
		ORDER BY g.accno|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my @headingaccounts = ();
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{ $ref->{category} }{ $ref->{accno} }{description} =
          "$ref->{description}";

        $form->{ $ref->{category} }{ $ref->{accno} }{charttype} = "H";
        $form->{ $ref->{category} }{ $ref->{accno} }{accno}     = $ref->{accno};

        push @headingaccounts, $ref->{accno};
    }

    $sth->finish;

    if ( $form->{method} eq 'cash' && !$todate ) {
        ($todate) = $dbh->selectrow_array(qq|SELECT current_date|);
    }

    if ($fromdate) {
        if ( $form->{method} eq 'cash' ) {
            $subwhere .= " AND transdate >= " . $dbh->quote($fromdate);
            $glwhere = " AND ac.transdate >= " . $dbh->quote($fromdate);
        }
        else {
            $where .= " AND ac.transdate >= " . $dbh->quote($fromdate);
        }
    }

    if ($todate) {
        $where    .= " AND ac.transdate <= " . $dbh->quote($todate);
        $subwhere .= " AND transdate <= " . $dbh->quote($todate);
        $yearendwhere = "ac.transdate < " . $dbh->quote($todate);
    }

    if ($excludeyearend) {
        $ywhere = "
			AND ac.trans_id NOT IN (SELECT trans_id FROM yearend)";

        if ($todate) {
            $ywhere = " 
				AND ac.trans_id NOT IN 
				(SELECT trans_id FROM yearend
				  WHERE transdate <= " . $dbh->quote($todate) . ")";
        }

        if ($fromdate) {
            $ywhere = "
				AND ac.trans_id NOT IN 
				(SELECT trans_id FROM yearend
				  WHERE transdate >= " . $dbh->quote($fromdate) . ")";
            if ($todate) {
                $ywhere = " 
					AND ac.trans_id NOT IN
					(SELECT trans_id FROM yearend
					WHERE transdate >= "
                  . $dbh->quote($fromdate) . "
					      AND transdate <= " . $dbh->quote($todate) . ")";
            }
        }
    }

    if ($department_id) {
        $dpt_join = qq|
			JOIN department t ON (a.department_id = t.id)|;
        $dpt_where = qq|
			AND t.id = $department_id|;
    }

    if ($project_id) {
        $project = qq|
			AND ac.project_id = $project_id|;
    }
    if (!defined $form->{approved}){
        $approved = 'true';
    } elsif ($form->{approved} eq 'all')  {
        $approved = 'NULL';
    } else {
        $approved = $dbh->quote($form->{approved});
    }

    if ( $form->{accounttype} eq 'gifi' ) {

        if ( $form->{method} eq 'cash' ) {

            $query = qq|
				  SELECT g.accno, sum(ac.amount) AS amount,
				         g.description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				    JOIN ar a ON (a.id = ac.trans_id)
				    JOIN gifi g ON (g.accno = c.gifi_accno)
				    $dpt_join
				   WHERE $where $ywhere $dpt_where $category
				         AND ac.trans_id IN (
				         SELECT trans_id
				           FROM acc_trans
					   JOIN chart ON (chart_id = id)
				          WHERE link LIKE '%AR_paid%'
				                $subwhere)
				$project
				GROUP BY g.accno, g.description, c.category
		 
				UNION ALL

				  SELECT '' AS accno, SUM(ac.amount) AS amount,
				         '' AS description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				    JOIN ar a ON (a.id = ac.trans_id)
				    $dpt_join
				   WHERE $where $ywhere $dpt_where $category
				         AND c.gifi_accno = '' AND 
				         ac.trans_id IN
				         (SELECT trans_id FROM acc_trans
				            JOIN chart ON (chart_id = id)
				           WHERE link LIKE '%AR_paid%'
				         $subwhere) $project
				GROUP BY c.category

				UNION ALL

				  SELECT g.accno, sum(ac.amount) AS amount,
				         g.description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				    JOIN ap a ON (a.id = ac.trans_id)
				    JOIN gifi g ON (g.accno = c.gifi_accno)
				$dpt_join
				   WHERE $where $ywhere $dpt_where $category
				         AND ac.trans_id IN
				         (SELECT trans_id FROM acc_trans
				            JOIN chart ON (chart_id = id)
				           WHERE link LIKE '%AP_paid%'
				                 $subwhere) $project
				GROUP BY g.accno, g.description, c.category
		 
				UNION ALL
       
				  SELECT '' AS accno, SUM(ac.amount) AS amount,
				         '' AS description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				    JOIN ap a ON (a.id = ac.trans_id)
				 $dpt_join
				   WHERE $where $ywhere $dpt_where $category
				         AND c.gifi_accno = '' 
				         AND ac.trans_id IN
				         (SELECT trans_id FROM acc_trans
				            JOIN chart ON (chart_id = id)
				   WHERE link LIKE '%AP_paid%' $subwhere)
				         $project
				GROUP BY c.category

				UNION ALL

				  SELECT g.accno, sum(ac.amount) AS amount,
				         g.description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				    JOIN gifi g ON (g.accno = c.gifi_accno)
				    JOIN gl a ON (a.id = ac.trans_id)
				$dpt_join
				   WHERE $where $ywhere $glwhere $dpt_where
				         $category AND NOT 
				         (c.link = 'AR' OR c.link = 'AP')
				         $project
				GROUP BY g.accno, g.description, c.category
		 
				UNION ALL

				  SELECT '' AS accno, SUM(ac.amount) AS amount,
				         '' AS description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				    JOIN gl a ON (a.id = ac.trans_id)
				$dpt_join
				   WHERE $where $ywhere $glwhere $dpt_where
				         $category AND c.gifi_accno = ''
				         AND NOT 
				         (c.link = 'AR' OR c.link = 'AP')
				         $project
				GROUP BY c.category|;

            if ($excludeyearend) {

                $query .= qq|

					UNION ALL

					  SELECT g.accno, 
					         sum(ac.amount) AS amount,
					         g.description, c.category
					    FROM yearend y
					    JOIN gl a ON (a.id = y.trans_id)
					    JOIN acc_trans ac 
					         ON (ac.trans_id = y.trans_id)
					    JOIN chart c 
					         ON (c.id = ac.chart_id)
					    JOIN gifi g 
					         ON (g.accno = c.gifi_accno) 
					$dpt_join
					   WHERE $yearendwhere 
					         AND c.category = 'Q' 
					         $dpt_where $project
					GROUP BY g.accno, g.description, 
					         c.category|;
            }

        }
        else {

            if ($department_id) {
                $dpt_join = qq|
					JOIN dpt_trans t 
					     ON (t.trans_id = ac.trans_id)|;
                $dpt_where = qq|
					AND t.department_id = | . $dbh->quote($department_id);
            }

            $query = qq|
				  SELECT g.accno, SUM(ac.amount) AS amount,
				         g.description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				    JOIN gifi g ON (c.gifi_accno = g.accno)
				    JOIN (SELECT id, approved FROM gl UNION
				          SELECT id, approved FROM ar UNION
				          SELECT id, approved FROM ap) gl
				         ON (ac.trans_id = gl.id)
				         $dpt_join
				   WHERE $where $ywhere $dpt_where $category
				         AND gl.approved AND ac.approved
				         $project
				GROUP BY g.accno, g.description, c.category
	      
				UNION ALL
	   
				  SELECT '' AS accno, SUM(ac.amount) AS amount,
				         '' AS description, c.category
				    FROM acc_trans ac
				    JOIN chart c ON (c.id = ac.chart_id)
				         $dpt_join
				   WHERE $where $ywhere $dpt_where $category
				         AND c.gifi_accno = '' $project
				GROUP BY c.category|;

            if ($excludeyearend) {

                $query .= qq|

						UNION ALL

						  SELECT g.accno, 
						         sum(ac.amount) 
						         AS amount,
						         g.description, 
						         c.category
						    FROM yearend y
						    JOIN gl a 
						         ON (a.id = y.trans_id)
						    JOIN acc_trans ac 
						         ON (ac.trans_id = 
						         y.trans_id)
						    JOIN chart c 
						         ON 
						         (c.id = ac.chart_id)
						    JOIN gifi g 
						         ON (g.accno = 
						         c.gifi_accno)
						         $dpt_join
						   WHERE $yearendwhere
						         AND c.category = 'Q'
						         $dpt_where $project
						GROUP BY g.accno, 
						         g.description, 
						         c.category|;
            }
        }

    }
    else {    # standard account

        if ( $form->{method} eq 'cash' ) {

            $query = qq|
			  SELECT c.accno, sum(ac.amount) AS amount,
			         c.description, c.category
			    FROM acc_trans ac
			    JOIN chart c ON (c.id = ac.chart_id)
			    JOIN ar a ON (a.id = ac.trans_id) $dpt_join
			   WHERE $where $ywhere $dpt_where $category 
			         AND ac.trans_id IN (
			         SELECT trans_id FROM acc_trans
			           JOIN chart ON (chart_id = id)
			          WHERE link LIKE '%AR_paid%' $subwhere)
			         $project
			GROUP BY c.accno, c.description, c.category

			UNION ALL
	
			  SELECT c.accno, sum(ac.amount) AS amount,
			         c.description, c.category
			    FROM acc_trans ac
			    JOIN chart c ON (c.id = ac.chart_id)
			    JOIN ap a ON (a.id = ac.trans_id) $dpt_join
			   WHERE $where $ywhere $dpt_where $category
			         AND ac.trans_id IN (
			         SELECT trans_id FROM acc_trans
			           JOIN chart ON (chart_id = id)
			          WHERE link LIKE '%AP_paid%' $subwhere)
			         $project
			GROUP BY c.accno, c.description, c.category
		 
			UNION ALL

			  SELECT c.accno, sum(ac.amount) AS amount,
			         c.description, c.category
			    FROM acc_trans ac
			    JOIN chart c ON (c.id = ac.chart_id)
			    JOIN gl a ON (a.id = ac.trans_id) $dpt_join
			   WHERE $where $ywhere $glwhere $dpt_where $category
			         AND NOT (c.link = 'AR' OR c.link = 'AP')
			         $project
			GROUP BY c.accno, c.description, c.category|;

            if ($excludeyearend) {

                # this is for the yearend

                $query .= qq|

 					UNION ALL

					  SELECT c.accno, 
					         sum(ac.amount) AS amount,
					         c.description, c.category
					    FROM yearend y
					    JOIN gl a ON (a.id = y.trans_id)
					    JOIN acc_trans ac 
					         ON (ac.trans_id = y.trans_id)
					    JOIN chart c 
					         ON (c.id = ac.chart_id)
					         $dpt_join
					   WHERE $yearendwhere AND 
					         c.category = 'Q' $dpt_where
					         $project
					GROUP BY c.accno, c.description, 
					         c.category|;
            }

        }
        else {

            if ($department_id) {
                $dpt_join = qq|
					JOIN dpt_trans t 
					     ON (t.trans_id = ac.trans_id)|;
                $dpt_where =
                  qq| AND t.department_id = | . $dbh->quote($department_id);
            }

            $query = qq|
				  SELECT c.accno, sum(ac.amount) AS amount,
				         c.description, c.category
				    FROM acc_trans ac
				    JOIN (SELECT id, approved FROM ar
				          UNION
                                          SELECT id, approved FROM ap
                                          UNION
                                          SELECT id, approved FROM gl
                                          ) g ON (ac.trans_id = g.id)
				    JOIN chart c ON (c.id = ac.chart_id)
				         $dpt_join
				   WHERE $where $ywhere $dpt_where $category
				         $project
					  AND ($approved IS NULL OR
						$approved = 
					        (ac.approved AND g.approved))
				GROUP BY c.accno, c.description, c.category|;

            if ($excludeyearend) {

                $query .= qq|

					UNION ALL
       
					  SELECT c.accno, 
					         sum(ac.amount) AS amount,
					         c.description, c.category
					    FROM yearend y
					    JOIN gl a ON (a.id = y.trans_id)
					    JOIN acc_trans ac 
					         ON (ac.trans_id = y.trans_id)
					    JOIN chart c 
					         ON (c.id = ac.chart_id)
					         $dpt_join
					   WHERE $yearendwhere AND 
					         c.category = 'Q' $dpt_where
					         $project
					GROUP BY c.accno, c.description, 
					         c.category|;
            }
        }
    }

    my @accno;
    my $accno;
    my $ref;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {

        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        # get last heading account
        @accno = grep { $_ le "$ref->{accno}" } @headingaccounts;
        $accno = pop @accno;
        if ( $accno && ( $accno ne $ref->{accno} ) ) {
            if ($last_period) {
                $form->{ $ref->{category} }{$accno}{last} += $ref->{amount};
            }
            else {
                $form->{ $ref->{category} }{$accno}{this} += $ref->{amount};
            }
        }

        $form->{ $ref->{category} }{ $ref->{accno} }{accno} = $ref->{accno};
        $form->{ $ref->{category} }{ $ref->{accno} }{description} =
          $ref->{description};
        $form->{ $ref->{category} }{ $ref->{accno} }{charttype} = "A";

        if ($last_period) {
            $form->{ $ref->{category} }{ $ref->{accno} }{last} +=
              $ref->{amount};
        }
        else {
            $form->{ $ref->{category} }{ $ref->{accno} }{this} +=
              $ref->{amount};
        }
    }
    $sth->finish;

    # remove accounts with zero balance
    foreach $category ( @{$categories} ) {
        foreach $accno ( keys %{ $form->{$category} } ) {
            $form->{$category}{$accno}{last} =
              $form->round_amount( $form->{$category}{$accno}{last},
                $form->{decimalplaces} );
            $form->{$category}{$accno}{this} =
              $form->round_amount( $form->{$category}{$accno}{this},
                $form->{decimalplaces} );

            delete $form->{$category}{$accno}
              if ( $form->{$category}{$accno}{this} == 0
                && $form->{$category}{$accno}{last} == 0 );
        }
    }

}

sub trial_balance {
    my ( $self, $myconfig, $form ) = @_;
    my $p;
    my $year_end = $form->{ignore_yearend};
    ( $form->{fromdate}, $form->{todate} ) =
      $form->from_to( $form->{fromyear}, $form->{frommonth}, $form->{interval} )
      if $form->{fromyear} && $form->{frommonth};

    my $dbh = $form->{dbh};
    my $approved = 'FALSE';

    my ( $query, $sth, $ref );
    my %balance = ();
    my %trb     = ();
    my $null;
    my $department_id;
    my $project_id;
    my @headingaccounts = ();
    my $dpt_where;
    my $dpt_join;
    my $project;

    my $where    = "1 = 1";
    my $invwhere = $where;

    ( $null, $department_id ) = split /--/, $form->{department};
    ( $null, $project_id )    = split /--/, $form->{projectnumber};

    if ($department_id) {
        $dpt_join = qq|
			JOIN dpt_trans t ON (ac.trans_id = t.trans_id)|;
        $dpt_where = qq|
			AND t.department_id = | . $dbh->quote($department_id);
    }
    if ($project_id) {
        $project = qq|
			AND ac.project_id = | . $dbh->quote($project_id);
    }

    ( $form->{fromdate}, $form->{todate} ) =
      $form->from_to( $form->{year}, $form->{month}, $form->{interval} )
      if $form->{year} && $form->{month};
    my $amount_cast; # Whitelisted, safe for interpolation
    if ($form->{discrete_money}){
        $form->{calc_precision} = $LedgerSMB::Sysconfig::precision;
    }
    if ($form->{calc_precision} =~ /\D/){
        $form->error('Illegal calculation precision');
    }
    if ($form->{calc_precision} =~ /\d+/){
        $amount_cast = "NUMERIC(30,$form->{calc_precision})";
    } else {
        $amount_cast = "NUMERIC";
    }

    # get beginning balances
    if ( ($department_id or $form->{accounttype} eq 'gifi') and $form->{fromdate}) {
        if ( $form->{accounttype} eq 'gifi' ) {

            $query = qq|
				  SELECT g.accno, c.category, 
				         SUM(ac.amount::$amount_cast) AS amount,
				         g.description, c.contra
				    FROM acc_trans ac
				    JOIN chart c ON (ac.chart_id = c.id AND c.charttype = 'A')
				    JOIN gifi g ON (c.gifi_accno = g.accno)
				         $dpt_join
				    JOIN (SELECT id, approved FROM gl UNION
				          SELECT id, approved FROM ar UNION
				          SELECT id, approved FROM ap) gl
				         ON (ac.trans_id = gl.id)
				   WHERE ac.transdate < '$form->{fromdate}'
				         $dpt_where $project
				         AND ($approved OR ac.approved)
				         AND ($approved OR gl.approved)
				GROUP BY g.accno, c.category, g.description, 
				         c.contra|;

        }
        else {

            $query = qq|
				  SELECT c.accno, c.category, 
				         SUM(ac.amount::$amount_cast) AS amount,
				         c.description, c.contra
				    FROM acc_trans ac
				    JOIN chart c ON (ac.chart_id = c.id AND c.charttype = 'A')
				         $dpt_join
				    JOIN (SELECT id, approved FROM gl UNION
				          SELECT id, approved FROM ar UNION
				          SELECT id, approved FROM ap) gl
				         ON (ac.trans_id = gl.id)
				   WHERE ac.transdate < '$form->{fromdate}'
				         $dpt_where $project
				         AND ($approved OR ac.approved)
				         AND ($approved OR gl.approved)
				GROUP BY c.accno, c.category, c.description, 
				         c.contra|;

        }

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
            $balance{ $ref->{accno} } = $ref->{amount};

            if ( $form->{all_accounts} ) {
                $trb{ $ref->{accno} }{description} = $ref->{description};
                $trb{ $ref->{accno} }{charttype}   = 'A';
                $trb{ $ref->{accno} }{category}    = $ref->{category};
                $trb{ $ref->{accno} }{contra}      = $ref->{contra};
            }

        }
        $sth->finish;

    }

    # get headings
    $query = qq|
		  SELECT c.accno, c.description, c.category FROM chart c
		   WHERE c.charttype = 'H'
		ORDER by c.accno|;

    if ( $form->{accounttype} eq 'gifi' ) {
        $query = qq|
			  SELECT g.accno, g.description, c.category, c.contra
			    FROM gifi g
			    JOIN chart c ON (c.gifi_accno = g.accno)
			   WHERE c.charttype = 'H'
			ORDER BY g.accno|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        $trb{ $ref->{accno} }{description} = $ref->{description};
        $trb{ $ref->{accno} }{charttype}   = 'H';
        $trb{ $ref->{accno} }{category}    = $ref->{category};
        $trb{ $ref->{accno} }{accno}       = $ref->{accno};
        $trb{ $ref->{accno} }{contra}      = $ref->{contra};

        push @headingaccounts, $ref->{accno};
    }

    $sth->finish;
    my $yearend_filter;
    if (!$department_id and !$form->{gifi}){
        my $datefrom = $dbh->quote($form->{fromdate});
        my $dateto = $dbh->quote($form->{todate});
	my $safe_project_id = $dbh->quote($project_id);
        if ($datefrom eq "''") {
            $datefrom = "NULL";
        }
        if ($dateto eq "''") {
            $dateto = "NULL";
        }
        if ($year_end ne 'none'){
             if ($year_end eq 'last'){
                   # CT:  The coalesce below uses magic values but this should
                   # be safe because all automatically assigned transactions 
                   # should be positive integers.  In the long run though this
                   # is being moved into stored procedures.
                  $yearend_filter = "AND (ac.transdate < coalesce($datefrom, ac.transdate)  OR 
			ac.trans_id <> (select coalesce(max(trans_id), -1000) FROM yearend WHERE transdate <= coalesce($dateto, 'infinity'::timestamp)))";
             } elsif ($year_end eq 'all'){
                  $yearend_filter = "AND (y.trans_id is null or ac.transdate < coalesce($datefrom, ac.transdate))";
             } else {
                 $form->error($main::locale->text('Invalid Year-end filter request!'));
             }
        }
        $query = "SELECT c.id AS chart_id, c.accno, c.description, c.contra, 
                                c.category,
                                SUM(CASE WHEN ac.transdate < $datefrom
                                    THEN ac.amount::$amount_cast
                                    ELSE 0 END) AS balance,
                                SUM(CASE WHEN ac.transdate >= 
                                              coalesce($datefrom, ac.transdate)
                                              AND ac.amount > 0
                                    THEN ac.amount::$amount_cast
                                    ELSE 0 END) AS credit,
                                SUM(CASE WHEN ac.transdate >= 
                                              coalesce($datefrom, ac.transdate)
                                              AND ac.amount < 0
                                    THEN ac.amount::$amount_cast
                                    ELSE 0 END) * -1 AS debit,
                                SUM(CASE WHEN ac.transdate >=
                                              coalesce($datefrom, ac.transdate)
                                         THEN ac.amount::$amount_cast
                                         ELSE 0
                                    END) as amount
                                FROM acc_trans ac
                                JOIN (select id, approved FROM ap
                                        UNION ALL
                                        select id, approved FROM gl
                                        UNION ALL
                                        select id, approved FROM ar) g
                                        ON (g.id = ac.trans_id)
                                JOIN chart c ON (c.id = ac.chart_id AND c.charttype = 'A')
				LEFT JOIN yearend y ON (ac.trans_id = y.trans_id)
                                WHERE (ac.transdate <= $dateto OR $dateto IS NULL)
                                        AND ac.approved AND g.approved
                                        AND ($safe_project_id IS NULL
                                                OR $safe_project_id = ac.project_id)
				      $yearend_filter
                                GROUP BY c.id, c.accno, c.description, c.contra,
                                         c.category
				ORDER BY c.accno";
        my $sth = $dbh->prepare($query);
        $sth->execute();
        while ($ref = $sth->fetchrow_hashref('NAME_lc')){
            $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
            $trb{ $ref->{accno} }{accno}       = $ref->{accno};
            $trb{ $ref->{accno} }{description} = $ref->{description};
            $trb{ $ref->{accno} }{charttype}   = 'A';
            $trb{ $ref->{accno} }{amount}      = $ref->{amount};
            $trb{ $ref->{accno} }{debit}       = $ref->{debit};
            $trb{ $ref->{accno} }{credit}      = $ref->{credit};
            $trb{ $ref->{accno} }{category}    = $ref->{category};
            $trb{ $ref->{accno} }{contra}      = $ref->{contra};
            $trb{ $ref->{accno} }{balance}     = $ref->{balance};
        }
        $form->{TB} = [];
        foreach my $accno ( sort keys %trb ) {
           push @{$form->{TB}}, $trb{$accno};
        }
        return;
    } else {
        if ( $form->{fromdate} || $form->{todate} ) {
            if ( $form->{fromdate} ) {
                $where .=
                  " AND ac.transdate >= " . $dbh->quote( $form->{fromdate} );
                $invwhere .=
                  " AND a.transdate >= " . $dbh->quote( $form->{fromdate} );
            }
            if ( $form->{todate} ) {
                $where .= " AND ac.transdate <= " . $dbh->quote( $form->{todate} );
                $invwhere .=
                  " AND a.transdate <= " . $dbh->quote( $form->{todate} );
            }
        }

        if ( $form->{accounttype} eq 'gifi' ) {

            $query = qq|
			  SELECT g.accno, g.description, c.category,
			         SUM(ac.amount::$amount_cast) AS amount, c.contra
			    FROM acc_trans ac
			    JOIN chart c ON (c.id = ac.chart_id AND c.charttype = 'A')
			    JOIN gifi g ON (c.gifi_accno = g.accno)
			         $dpt_join
			    JOIN (SELECT id, approved FROM gl UNION
			          SELECT id, approved FROM ar UNION
			          SELECT id, approved FROM ap) gl
			         ON (ac.trans_id = gl.id)
			   WHERE $where $dpt_where $project
			         AND ($approved OR ac.approved)
			         AND ($approved OR gl.approved)
			GROUP BY g.accno, g.description, c.category, c.contra
			ORDER BY accno|;

        }
        else {

            $query = qq|
			  SELECT c.accno, c.description, c.category,
			         SUM(ac.amount::$amount_cast) AS amount, c.contra
			    FROM acc_trans ac
			    JOIN chart c ON (c.id = ac.chart_id AND c.charttype = 'A')
			         $dpt_join
			    JOIN (SELECT id, approved FROM gl UNION
			          SELECT id, approved FROM ar UNION
			          SELECT id, approved FROM ap) gl
			         ON (ac.trans_id = gl.id)
			   WHERE $where $dpt_where $project
			         AND ($approved OR ac.approved)
			         AND ($approved OR gl.approved)
			GROUP BY c.accno, c.description, c.category, c.contra
			ORDER BY accno|;

        }

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        # prepare query for each account
        $query = qq|
		SELECT (SELECT SUM(ac.amount::$amount_cast) * -1 FROM acc_trans ac
		          JOIN chart c ON (c.id = ac.chart_id)
		               $dpt_join
			  JOIN (SELECT id, approved FROM gl UNION
			        SELECT id, approved FROM ar UNION
			        SELECT id, approved FROM ap) gl
			       ON (ac.trans_id = gl.id)
		          WHERE $where $dpt_where $project AND ac.amount < 0
				 AND ($approved OR ac.approved)
			         AND ($approved OR gl.approved)
		                 AND c.accno = ?) AS debit,
		       (SELECT SUM(ac.amount::$amount_cast) FROM acc_trans ac
		          JOIN chart c ON (c.id = ac.chart_id AND c.charttype = 'A')
		               $dpt_join
			  JOIN (SELECT id, approved FROM gl UNION
			        SELECT id, approved FROM ar UNION
			        SELECT id, approved FROM ap) gl
			       ON (ac.trans_id = gl.id)
		         WHERE $where $dpt_where $project AND ac.amount > 0
			       AND ($approved OR ac.approved)
			       AND ($approved OR gl.approved)
		               AND c.accno = ?) AS credit |;

        if ( $form->{accounttype} eq 'gifi' ) {

            $query = qq|
		SELECT (SELECT SUM(ac.amount::$amount_cast) * -1
		          FROM acc_trans ac
		          JOIN chart c ON (c.id = ac.chart_id AND c.charttype = 'A')
		               $dpt_join
		         WHERE $where $dpt_where $project AND ac.amount < 0
				         AND ($approved OR ac.approved)
		               AND c.gifi_accno = ?) AS debit,
		
		       (SELECT SUM(ac.amount::$amount_cast)
		          FROM acc_trans ac
		          JOIN chart c ON (c.id = ac.chart_id AND c.charttype = 'A')
		               $dpt_join
		         WHERE $where $dpt_where $project AND ac.amount > 0
				         AND ($approved OR ac.approved)
		               AND c.gifi_accno = ?) AS credit|;

        }

        $drcr = $dbh->prepare($query);

        # calculate debit and credit for the period
        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
            $trb{ $ref->{accno} }{description} = $ref->{description};
            $trb{ $ref->{accno} }{charttype}   = 'A';
            $trb{ $ref->{accno} }{category}    = $ref->{category};
            $trb{ $ref->{accno} }{contra}      = $ref->{contra};
            $trb{ $ref->{accno} }{amount} += $ref->{amount};
        }
        $sth->finish;
    }
    my ( $debit, $credit );

    foreach my $accno ( sort keys %trb ) {
        $ref = ();

        $ref->{accno} = $accno;
        for (qw(description category contra charttype amount)) {
            $ref->{$_} = $trb{$accno}{$_};
        }

        $ref->{balance} = $balance{ $ref->{accno} };

        if ( $trb{$accno}{charttype} eq 'A' ) {
            if ($project_id) {

                if ( $ref->{amount} < 0 ) {
                    $ref->{debit} = $ref->{amount} * -1;
                }
                else {
                    $ref->{credit} = $ref->{amount};
                }
                next if $form->round_amount( $ref->{amount}, 2 ) == 0;

            }
            else {

                # get DR/CR
                $drcr->execute( $ref->{accno}, $ref->{accno} )
                  || $form->dberror($query);

                ( $debit, $credit ) = ( 0, 0 );
                while ( my @drcrlist = $drcr->fetchrow_array ) {
                    $form->db_parse_numeric(sth=>$drcr, arrayref=>\@drcrlist);
                    ($debit, $credit) = @drcrlist;
                    $ref->{debit}  += $debit;
                    $ref->{credit} += $credit;
                }
                $drcr->finish;

            }


            if ( !$form->{all_accounts} ) {
                next
                  if $form->round_amount( $ref->{debit} + $ref->{credit}, 2 ) ==
                  0;
            }
        }

        # add subtotal
        @accno = grep { $_ le "$ref->{accno}" } @headingaccounts;
        $accno = pop @accno;
        if ($accno) {
            $trb{$accno}{debit}  += $ref->{debit};
            $trb{$accno}{credit} += $ref->{credit};
        }

        push @{ $form->{TB} }, $ref;

    }

    $dbh->commit;

    # debits and credits for headings
    foreach $accno (@headingaccounts) {
        foreach $ref ( @{ $form->{TB} } ) {
            if ( $accno eq $ref->{accno} ) {
                $ref->{debit}  = $trb{$accno}{debit};
                $ref->{credit} = $trb{$accno}{credit};
            }
        }
    }

}

sub get_taxaccounts {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh  = $form->{dbh};
    my $ARAP = uc $form->{db};

    # get tax accounts
    my $query = qq|
		  SELECT DISTINCT a.accno, a.description
		    FROM account a
		   WHERE a.tax is true
                ORDER BY a.accno|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror;

    my $ref = ();
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{taxaccounts} }, $ref;
    }
    $sth->finish;

    # get gifi tax accounts
    $query = qq|
		  SELECT DISTINCT g.accno, g.description
		    FROM gifi g
		    JOIN chart c ON (c.gifi_accno= g.accno)
		    JOIN tax t ON (c.id = t.chart_id)
		   WHERE c.link LIKE '%${ARAP}_tax%'
		ORDER BY accno|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{gifi_taxaccounts} }, $ref;
    }
    $sth->finish;

    $dbh->commit;

}

sub tax_report {
    use strict;
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my ( $null, $department_id ) = split /--/, $form->{department};

    my $date_from = $form->{fromdate} || undef;
    my $date_to = $form->{todate} || undef;
    my $accno = $form->{accno} || undef;    
    my $account_class;
    if ($form->{db} eq 'ar'){
       $account_class = 2;
    } elsif ($form->{db} eq 'ap'){
       $account_class = 1;
    } else {
        $form->error('Invalid input db in RP::tax_report.');
    }

    my $query = qq|

   SELECT gl.transdate, gl.id, gl.invnumber, e.name, e.id as entity_id, 
          eca.id as credit_id, eca.meta_number, gl.netamount, 
          sum(CASE WHEN a.id IS NOT NULL then ac.amount ELSE 0 END) as tax, 
          gl.invoice, gl.netamount 
          + sum(CASE WHEN a.id IS NOT NULL then ac.amount ELSE 0 END) as total
     FROM (select id, transdate, amount, netamount, entity_credit_account,
                  invnumber, invoice
             from ar where ? = 2
          UNION
          select id, transdate, amount, netamount, entity_credit_account,
                 invnumber, invoice
            from ap where ? = 1) gl
     JOIN entity_credit_account eca ON eca.id = gl.entity_credit_account
     JOIN entity e ON eca.entity_id = e.id
     JOIN acc_trans ac ON ac.trans_id = gl.id
LEFT JOIN (select * from account where tax is true and accno = ?
           UNION
          SELECT * from account where tax is true and ? is null
          ) a on a.id = ac.chart_id
LEFT JOIN dpt_trans dpt ON (gl.id = dpt.trans_id)
    WHERE (? is null or dpt.department_id = ?)
          AND (gl.transdate >= ? or ? is null)
          AND (gl.transdate <= ? or ? is null)
 GROUP BY gl.transdate, gl.id, gl.invnumber, e.name, e.id, eca.id,
           eca.meta_number, gl.amount, gl.netamount, gl.invoice
   HAVING (sum(CASE WHEN a.id is not null then ac.amount else 0 end) 
           <> 0 AND ? IS NOT NULL) 
          OR (? IS NULL and sum(CASE WHEN a.id is not null then ac.amount
                                ELSE 0 END) = 0)|;

    my $sth = $dbh->prepare($query);
    $sth->execute($account_class, $account_class, 
                  $accno,         $accno, 
                  $department_id, $department_id,
                  $date_from,     $date_from,
                  $date_to,       $date_to,
                  $accno,         $accno)
                  || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        $ref->{tax} = $form->round_amount( $ref->{tax}, 2 );
        push @{ $form->{TR} }, $ref;
    }

    $sth->finish;

}

sub paymentaccounts {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $ARAP = uc $form->{db};

    # get A(R|P)_paid accounts
    my $query = qq|
		SELECT accno, description FROM chart
		 WHERE link LIKE '%${ARAP}_paid%'
		 ORDER BY accno|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{PR} }, $ref;
    }
    $sth->finish;

    $form->all_years( $myconfig, $dbh );

    $dbh->{dbh};

}

sub payments {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $ml = 1;
    if ( $form->{db} eq 'ar' ) {
        $table = 'customer';
        $account_class = 2;
        $ml    = -1;
    } else {
        $table = 'vendor';
        $account_class = 1;
        $form->{db} = 'ap';
    }

    my $query;
    my $sth;
    my $dpt_join;
    my $where;
    my $var;

    if ( $form->{department_id} ) {
        $dpt_join = qq| JOIN dpt_trans t ON (t.trans_id = ac.trans_id)|;

        $where =
          qq| AND t.department_id = | . $dbh->quote( $form->{department_id} );
    }

    ( $form->{fromdate}, $form->{todate} ) =
      $form->from_to( $form->{fromyear}, $form->{frommonth}, $form->{interval} )
      if $form->{fromyear} && $form->{frommonth};

    if ( $form->{fromdate} ) {
        $where .= " AND ac.transdate >= " . $dbh->quote( $form->{fromdate} );
    }
    if ($form->{meta_number} ) {
        $where .= " AND c.meta_number = " . $dbh->quote($form->{meta_number});
    }
    if ( $form->{todate} ) {
        $where .= " AND ac.transdate <= " . $dbh->quote( $form->{todate} );
    }
    if ( !$form->{fx_transaction} ) {
        $where .= " AND ac.fx_transaction = '0'";
    }

    if ( $form->{description} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{description} ) );
        $where .= " AND lower(ce.name) LIKE $var";
    }
    if ( $form->{source} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{source} ) );
        $where .= " AND lower(ac.source) LIKE $var";
    }
    if ( $form->{memo} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{memo} ) );
        $where .= " AND lower(ac.memo) LIKE $var";
    }

    my %ordinal = (
        'name'      => 1,
        'transdate' => 2,
        'source'    => 4,
        'employee'  => 6,
        'till'      => 7
    );

    my @a = qw(name transdate employee);
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $glwhere = $where;
    $glwhere =~ s/\(ce.name\)/\(g.description\)/;

    # cycle through each id
    foreach my $accno ( split( / /, $form->{paymentaccounts} ) ) {

        $query = qq|
			SELECT id, accno, description
			  FROM chart
			 WHERE accno = ?|;
        $sth = $dbh->prepare($query);
        $sth->execute($accno) || $form->dberror($query);

        my $ref = $sth->fetchrow_hashref(NAME_lc);
        push @{ $form->{PR} }, $ref;
        $sth->finish;

         $query = qq|
			   SELECT ce.name, ac.transdate, 
			          sum(ac.amount) * $ml AS paid, ac.source, 
			          ac.memo, ee.name AS employee, a.till, a.curr,
			          c.meta_number, 
			          b.control_code as batch_control,
			          b.description AS batch_description
			     FROM acc_trans ac
			     JOIN $form->{db} a ON (ac.trans_id = a.id)
			     JOIN entity_credit_account c ON 
				(c.id = a.entity_credit_account)
			     JOIN entity ce ON (ce.id = c.entity_id)
			LEFT JOIN entity_employee e ON 
					(a.person_id = e.entity_id)
			LEFT JOIN entity ee ON (e.entity_id = ee.id)
			LEFT JOIN voucher v ON (ac.voucher_id = v.id)
			LEFT JOIN batch b ON (b.id = v.batch_id)
			          $dpt_join
			    WHERE ac.chart_id = $ref->{id} 
			          AND ac.approved AND a.approved
			          $where|;

        if ( $form->{till} ne "" ) {
            $query .= " AND a.invoice = '1' AND NOT a.till IS NULL";

            if ( $myconfig->{role} eq 'user' ) {
                $query .= " AND e.login = '$form->{login}'";
            }
        }

        $query .= qq|
			GROUP BY ce.name, ac.transdate, ac.source, ac.memo,
			         ee.name, a.till, a.curr, c.meta_number, 
			         b.control_code, b.description|;

        if ( $form->{till} eq "" && !$form->{meta_number}) {

             $query .= qq|
 				UNION
				SELECT g.description, ac.transdate, 
				       sum(ac.amount) * $ml AS paid, ac.source,
				       ac.memo, ee.name AS employee, '' AS till,
				       '' AS curr, '' AS meta_number, 
			               b.control_code as batch_control,
			               b.description AS batch_description
				  FROM acc_trans ac
				  JOIN gl g ON (g.id = ac.trans_id)
				  LEFT 
				  JOIN entity_employee e ON 
					(g.person_id = e.entity_id)
				  JOIN entity ee ON (e.entity_id = ee.id)
				LEFT JOIN voucher v ON (ac.voucher_id = v.id)
				LEFT JOIN batch b ON (b.id = v.batch_id)
				       $dpt_join
				 WHERE ac.chart_id = $ref->{id} $glwhere
			               AND ac.approved AND g.approved
				       AND (ac.amount * $ml) > 0
				 GROUP BY g.description, ac.transdate, 
			               ac.source, ac.memo, ee.name, 
				       b.control_code, b.description|;

        }

        $query .= qq| ORDER BY $sortorder|;

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        while ( my $pr = $sth->fetchrow_hashref(NAME_lc) ) {
            $form->db_parse_numeric(sth=>$sth, hashref=>$pr);
            push @{ $form->{ $ref->{id} } }, $pr;
        }
        $sth->finish;

    }

    $dbh->commit;

}

sub inventory_accounts {
    my ( $self, $myconfig, $form ) = @_;
    my $dbh = $form->{dbh};
    my $query = qq|
		SELECT id, accno, description FROM chart
		 WHERE link = 'IC'
		 ORDER BY accno|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{selectIC} }, $ref;
    }
    $sth->finish;
    $dbh->{dbh};
}

sub inventory {
    my ( $self, $myconfig, $form ) = @_;
    my $dbh = $form->{dbh};
    my $where_date = '';
    my $where_date = '';
    my $where_date_acc = '';
    my $where_product = '';
    my $where_chart = '';
    if($form->{fromdate}) {
	$where_date.=" AND a.transdate>='".$form->{fromdate}."' ";
	$where_date_acc.=" AND acc.transdate>='".$form->{fromdate}."' ";
    }
    if($form->{todate}) {
	$where_date.=" AND a.transdate<='".$form->{todate}."' ";
	$where_date_acc.=" AND acc.transdate<='".$form->{todate}."' ";
    }

    if($form->{partnumber}) {
	$where_product.= " AND partnumber LIKE '%".$form->{partnumber}."%' ";
    } 
    if($form->{description}) {
	$where_product.= " AND description LIKE '%".$form->{description}."%' ";
    } 
    if($form->{inventory_account}) {
	$where_chart .= " AND p.inventory_accno_id = ".$form->{inventory_account}." ";
    }

    my $query = qq|
	SELECT id, description, partnumber, sum(qty) as qty, sum(exited) as exited, sum(entered) as entered, sum(entered)-sum(exited) as value FROM 
	(
	    SELECT p.id, p.description, p.partnumber, -sum(i.qty) as qty, 0 as exited, 0 as entered
	    FROM invoice i 
	    JOIN ar a ON (a.id=i.trans_id $where_date) 
	    JOIN parts p ON (i.parts_id=p.id AND p.inventory_accno_id>0 $where_chart) 
	    GROUP BY p.id, p.description, p.partnumber 
	    
	    UNION ALL 
	    
	    SELECT p.id, p.description, p.partnumber, 0, sum(acc.amount) as exited, 0 as entered
	    FROM acc_trans acc 
	    JOIN parts p ON (p.inventory_accno_id=acc.chart_id AND p.inventory_accno_id>0 $where_chart) 
	    JOIN invoice i ON (i.id=acc.invoice_id AND i.parts_id=p.id) 
	    WHERE acc.trans_id NOT IN (SELECT id FROM ap) $where_date_acc  
	    GROUP BY p.id, p.description, p.partnumber 
	    
	    UNION ALL 
	    
	    SELECT p.id, p.description, p.partnumber, -sum(i.qty) as qty, 0 as exited, -sum(i.qty*i.sellprice) as entered
	    FROM invoice i 
	    JOIN ap a ON (a.id=i.trans_id $where_date) 
	    JOIN parts p ON (i.parts_id=p.id AND p.inventory_accno_id>0 $where_chart) 
	    GROUP BY p.id, p.description, p.partnumber
	) AS temp WHERE 1=1 $where_product GROUP BY id, description, partnumber HAVING sum(entered)-sum(exited)!=0 OR sum(qty)!=0 ORDER BY description;|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{inventory} }, $ref;
    }
    $sth->finish;
    $dbh->{dbh};
}
1;
