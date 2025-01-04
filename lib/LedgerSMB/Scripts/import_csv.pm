
use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::Scripts::import_csv;

=head1 NAME

LedgerSMB::Scripts::import_csv - web entry points for various csv uploads

=head1 DESCRIPTION

This is a module that demonstrates how to set up scripts for importing bulk
data.

=head1 METHODS

This module doesn't specify any methods.

=cut

use JSON::PP;

use LedgerSMB::AA;
use LedgerSMB::Batch;
use LedgerSMB::Company::Configuration;
use LedgerSMB::Form;
use LedgerSMB::GL;
use LedgerSMB::Inventory::Adjust;
use LedgerSMB::Inventory::Adjust_Line;
use LedgerSMB::IR;
use LedgerSMB::IS;
use LedgerSMB::Magic qw( EC_VENDOR EC_CUSTOMER );
use LedgerSMB::Setting::Sequence;
use LedgerSMB::Timecard;

use List::MoreUtils qw{ any };
use Text::CSV;

our $cols = {
    gl              =>  ['accno', 'debit', 'credit', 'curr', 'debit_fx',
                         'credit_fx', 'source', 'memo'],
    gl_multi        =>  ['debit_accno', 'credit_accno', 'amount', 'curr',
                         'amount_fx', 'reference', 'transdate', 'description',
                         'source_debit', 'source_credit', 'memo'],
    ap_multi        =>  ['vendor', 'amount', 'curr', 'fx_rate', 'account', 'ap',
                        'description', 'invnumber', 'transdate'],
    ar_multi        =>  ['customer', 'amount', 'curr', 'fx_rate', 'account', 'ar',
                        'description', 'invnumber', 'transdate'],
    timecard        =>  ['employee', 'business_unit_id', 'transdate',
                        'partnumber', 'description', 'qty', 'non_billable',
                        'sellprice', 'allocated', 'notes', 'jctype', 'curr'],
    inventory       => ['partnumber', 'onhand', 'purchase_price'],
    inventory_multi => ['date', 'partnumber', 'onhand', 'purchase_price'],
    goods           => [ qw/ partnumber description unit listprice sellprice
                         lastcost weight notes makemodel assembly alternate
                         rop inventory_accno income_accno expense_accno
                         returns_accno bin bom image drawing microfiche
                         partsgroup avgcost taxaccnos / ],
    services        => [ qw/ partnumber description unit listprice sellprice
                         lastcost notes income_accno expense_accno
                         partsgroup taxaccnos / ],
    overhead        => [ qw/ partnumber description unit listprice sellprice
                         lastcost notes inventory_accno expense_accno
                         bom partsgroup / ],
};

my %template_file = (
   inventory => 'import_inventory_csv',
   inventory_multi => 'import_inventory_csv',
);


our $preprocess = {};
our $postprocess = {};

sub _inventory_template_setup {
    my ($request) = @_;
    my $sth = $request->{dbh}->prepare(
        q{SELECT concat(accno,'--',description) as value
             FROM chart_get_ar_ap(?)}
        );

    $sth->execute(EC_VENDOR);
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @{$request->{AP_accounts}}, $row;
    }


    $sth->execute(EC_CUSTOMER);
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @{$request->{AR_accounts}}, $row;
    }
    return;
}


our $template_setup = {
  inventory => \&_inventory_template_setup,
  inventory_multi => \&_inventory_template_setup,
};

=head2 map_columns_into_hash($keys, $values)

Takes two arrayrefs and returns a hashref as you'd expect from the args.

=cut

sub map_columns_into_hash {
    my ($keys, $values) = @_;
    my %rv;

    @rv{@$keys} = @$values;

    return \%rv;
}



sub _aa_multi {
    my ($request, $entries, $arap) = @_;
    my $batch = LedgerSMB::Batch->new(%$request);
    $batch->{batch_number} = $request->{reference};
    $batch->{batch_date} = $request->{transdate};
    $batch->{batch_class} = $arap;
    $batch->create();
    # Necessary to test things are found before starting to
    # import! -- CT
    my $acst = $request->{dbh}->prepare(
        'select count(*) from account where accno = ?'
        );
    my $vcst = $request->{dbh}->prepare(
        'select count(*) from entity_credit_account where meta_number = ?'
        );
    my $currst = $request->{dbh}->prepare(
        'select count(*) from currency where curr = ?'
    );
    for my $ref (@$entries){
        my %entry;
        # Reference with name instead of index for better readability
        @entry{qw( vc amount curr fx_rate account arap
                    description invnumber transdate )} = @$ref;
        my $pass;
        next if $entry{amount} !~ /\d/;
        my ($acct) = split /--/, $entry{account};
        $acst->execute($acct);
        ($pass) = $acst->fetchrow_array;
        $request->error("Account $acct not found") if !$pass;
        ($acct) = split /--/, $entry{arap};  ## no critic (ProhibitMagicNumbers) sniff
        $acst->execute($acct);
        ($pass) = $acst->fetchrow_array;
        $request->error("Account $acct not found") if !$pass;
        $vcst->execute($entry{vc});
        ($pass) = $vcst->fetchrow_array;
        if (! $pass) {
            if ($arap eq 'ar') {
                $request->error("Customer $entry{vc} not found");
            } else {
                $request->error("Vendor $entry{vc} not found");
            }
        }
        # Check currency is defined in the system
        $currst->execute($entry{curr});
        ($pass) = $currst->fetchrow_array;
        $request->error("Currency $entry{curr} not found") if !$pass;
    }
    for my $ref (@$entries){
        my %entry;
        @entry{qw( vc amount curr fx_rate account arap
                    description invnumber transdate )} = @$ref;

        my $form = Form->new(); ## no critic
        $form->{dbh} = $request->{dbh};
        my $default_currency = $request->setting->get('curr');
        $form->{rowcount} = 1;
        $form->{ARAP} = uc($arap);
        $form->{batch_id} = $batch->{id};
        $form->{customernumber} = $form->{vendornumber} = $entry{vc};
        $form->{amount_1} = $entry{amount};
        next if $form->{amount_1} !~ /\d/;
        $form->{amount_1} = $form->parse_amount(
            $request->{_user}, $form->{amount_1});
        $form->{"$form->{ARAP}_amount_1"} = $entry{account};
        $form->{vc} = ($arap eq 'ar') ? 'customer' : 'vendor';
        $form->{arap} = $arap;
        $form->{uc($arap)} = $entry{arap};
        $form->{description_1} = $entry{description};
        $form->{invnumber} = $entry{invnumber};
        $form->{transdate} = $entry{transdate};
        $form->{currency} = $entry{curr};
        $form->{exchangerate} = $entry{fx_rate};
        $form->{approved} = '0';
        $form->{defaultcurrency} = $default_currency;
        # need to fetch due date by terms set on the ECA
        # otherwise transaction posted with empty due date
        my $sth = $form->{dbh}->prepare(
            'SELECT id,
              (?::date + (concat(
                  (CASE WHEN terms IS NULL THEN 1 ELSE terms END),
                  \' days\'))::interval) as duedate
              FROM entity_credit_account
              WHERE entity_class = ? and meta_number = ?'
            );
        $sth->execute( $form->{transdate},
            ($arap eq 'ar') ? 2 : 1,
            $form->{vendornumber} );
        ($form->{vendor_id}, $form->{duedate}) = $sth->fetchrow_array;
        $form->{customer_id} = $form->{vendor_id};

        # The 'AA' package is used as 'LedgerSMB::AA'
        # which is a problem for Perl::Critic
        AA->post_transaction($request->{_user}, $form); ## no critic
    }
    return 1;
}

sub _inventory_single_date {
    my ($request, $entries, $transdate) = @_;
    # NOTE ! This implementation largely mirrors the one
    #  in LedgerSMB::Scripts::inventory::_lines_from_form()

    my $adjustment = LedgerSMB::Inventory::Adjust->new(
        transdate => $request->parse_date( $transdate ),
        source    => 'CSV upload',
        dbh       => $request->{dbh},
        );

    my @rows;
    for my $entry ($entries->@*) {
        my $part =
            $adjustment->get_part_at_date($transdate, $entry->{partnumber});
        my $counted  = $request->parse_amount( $entry->{onhand} );
        my $expected = $request->parse_amount( $part->{onhand} );
        push @rows, LedgerSMB::Inventory::Adjust_Line->new(
            parts_id    => $part->{id},
            partnumber  => $entry->{partnumber},
            counted     => $counted,
            expected    => $expected,
            variance    => $expected - $counted
            );
    }
    $adjustment->rows(\@rows);
    $adjustment->save;
}

sub _process_ar_multi {
    my  ($request, $entries) = @_;
    return &_aa_multi($request, $entries, 'ar');
}

sub _process_ap_multi {
    my  ($request, $entries) = @_;
    return &_aa_multi($request, $entries, 'ap');
}

sub _process_gl_multi {
    my ($request, $entries) = @_;
    my $dbh = $request->{dbh};
    my $batch = LedgerSMB::Batch->new(
        dbh => $dbh,
        batch_class  => 'gl',
        batch_date   => $request->{transdate},
        batch_number => $request->{reference},
        description  => $request->{description},
        );
    my $batch_id = $batch->create;

    my $sth_voucher = $dbh->prepare(q{
         INSERT INTO voucher (batch_id, trans_id, batch_class)
               VALUES (?, ?, (select id FROM batch_class
                                      WHERE class = 'gl'))
         RETURNING id
                                 });

    my $sth_acc = $dbh->prepare(q{
        INSERT INTO acc_trans (trans_id, transdate, source, memo, chart_id,
                               curr, voucher_id, amount_bc, amount_tc)
               VALUES (?, ?, ?, ?, (select id from account where accno = ?),
                       ?, ?, ?, ?)
                                })
        or die $dbh->errstr;
    my $sth_gl = $dbh->prepare(q{
        INSERT INTO gl (transdate, reference, description)
               VALUES (?, ?, ?)
        RETURNING id })
        or die $dbh->errstr;
    for my $entry (@$entries) {
        # $entry holds:
        # ['debit_accno', 'credit_accno', 'amount', 'curr',
        #  'amount_fx', 'reference', 'transdate', 'description',
        #  'source_debit', 'source_credit', 'memo']

        my %entry;
        @entry{@{$cols->{gl_multi}}} = @$entry;
        delete $entry{reference} if $entry{reference} eq '';
        $entry{reference} =
            LedgerSMB::Setting::Sequence->increment('glnumber', $request)
            unless defined $entry{reference};

        $sth_gl->execute(@entry{('transdate', 'reference', 'description')})
            or die $sth_gl->errstr;
        my ($trans_id) = $sth_gl->fetchrow_array;
        $sth_gl->finish;

        $sth_voucher->execute($batch_id, $trans_id)
            or die $sth_voucher->errstr;
        my ($voucher_id) = $sth_voucher->fetchrow_array;

        # debit row
        $sth_acc->execute($trans_id, @entry{qw(transdate source_debit memo
                                               debit_accno curr )},
                          $voucher_id, -1*$entry{amount}, -1*$entry{amount_fx})
            or die $sth_acc->errstr;
        # credit row
        $sth_acc->execute($trans_id, @entry{qw(transdate source_credit memo
                                               credit_accno curr )},
                          $voucher_id, $entry{amount}, $entry{amount_fx})
            or die $sth_acc->errstr;
    }
}

sub _process_gl {
    my ($request, $entries) = @_;
    my $form = Form->new(); ## no critic
    $form->{reference} = $request->{reference};
    $form->{description} = $request->{description};
    $form->{transdate} = $request->{transdate};
    $form->{rowcount} = 0;
    $form->{approved} = '0';
    $form->{dbh} = $request->{dbh};
    for my $ref (@$entries){
        if ($ref->[1] !~ /\d/){
            delete $ref->[1];
        } else {
            $ref->[1] = $form->parse_amount(
                $request->{_user}, $ref->[1]
                );
        }
        if ($ref->[2] !~ /\d/){
            delete $ref->[2];
        } else {
            $ref->[2] = $form->parse_amount(
                $request->{_user}, $ref->[2]
                );
        }
        next if not $ref->[1] and not $ref->[2];
        for my $col (@{$cols->{$request->{type}}}){
            $form->{"${col}_$form->{rowcount}"} = shift @$ref;
        }
        ++$form->{rowcount};
    }
    return GL->post_transaction( ## no critic
        $request->{_user}, $form, $request->{_locale});
}

sub _process_chart {
    my ($request, $entries) = @_;

    my %imported;
    my $cfg = LedgerSMB::Company::Configuration->new(dbh => $request->{dbh});
    foreach my $entry (@$entries){
        my %settings;

        ###BUG missing import settings: 'recon' and "is_temp"
        @settings{qw( accno description charttype
                      category contra tax link heading gifi_accno )} = @$entry;
        if ($settings{charttype} eq 'A') {
            $settings{type} = 'account';
        }
        elsif ($settings{charttype} eq 'H') {
            $settings{type} = 'heading';
        }
        $settings{link} = [ split /:/, $settings{link} ];

        die "Unable to resolve heading $settings{heading} to its id; available: " . join(' ', sort keys %imported)
            if ($settings{heading}
                and not exists $imported{$settings{heading}});
        $settings{heading_id} = $imported{$settings{heading}}->{id};

        $settings{gifi_id} = $settings{gifi_accno};
        my $account = $cfg->coa_nodes->create(%settings);
        $account->save();
        $imported{$settings{accno}} = $account;
    }
    return;
}

sub _process_gifi {
    my ($request, $entries) = @_;
    my $dbh = $request->{dbh};
    my $sth =
        $dbh->prepare('INSERT INTO gifi (accno, description) VALUES (?, ?)')
        || die $dbh->errstr;;

    foreach my $entry (@$entries) {
        $sth->execute($entry->[0], $entry->[1]) || die $sth->errstr();
    }
    return;
}

sub _process_sic {
    my ($request, $entries) = @_;
    my $dbh = $request->{dbh};
    my $sth =
        $dbh->prepare('INSERT INTO sic (code, sictype, description) VALUES (?, ?, ?)') || die $dbh->errstr;;

    foreach my $entry (@$entries) {
        $sth->execute($entry->[0], $entry->[1], $entry->[2])
            || die $sth->errstr();
    }
    return;
}

sub _process_timecard {
    my ($request, $entries) = @_;
    for my $entry (@$entries) {
        my $jc = {};
        my $counter = 0;
        for my $col (@{$cols->{timecard}}){
            $jc->{$col} = $entry->[$counter];
            ++$counter;
        }
        for my $col (qw( qty non_billable sellprice allocated )) {
            $jc->{$col} = $request->parse_amount( $jc->{$col} );
        }
        $jc->{transdate} = $request->parse_date( $jc->{transdate} );
        $jc->{total} = $jc->{qty} + $jc->{non_billable}
            if !$jc->{total};
        $jc->{checkedin} = $jc->{transdate} if !$jc->{checkedin};
        $jc->{checkedout} = $jc->{transdate} if !$jc->{checkedout};
        LedgerSMB::Timecard->new(%$jc)->save;
    }
    return;
}

sub _process_inventory {
    my ($request, $entries) = @_;
    @$entries =
        map { map_columns_into_hash($cols->{inventory}, $_) } @$entries;

    return _inventory_single_date($request, $entries, $request->{transdate});
}

sub _process_inventory_multi {
    my ($request, $entries) = @_;

    @$entries =
        map { map_columns_into_hash($cols->{inventory_multi}, $_) }
        @$entries;
    my %dated_entries;
    for my $entry (@$entries) {
        push @{$dated_entries{$entry->{date}}}, $entry;
    }

    for my $transdate (keys %dated_entries) {
        &_inventory_single_date($request,
                                $dated_entries{$transdate}, $transdate);
    }
    return;
}

sub _process_parts {
    my ($request, $entries, $columns, $acc_types) = @_;
    my %table_columns =
        map { $_ => ($_ =~ s/(_accno|partsgroup)$/$1_id/r) }
        grep { $_ ne 'taxaccnos' }
        @{$columns};
    my %column_placeholders =
        map { $_ => (
                  m/_accno$/ ?
                   '(SELECT id FROM account
                     WHERE accno = ?
                           AND EXISTS (SELECT 1 FROM account_link al
                                        WHERE al.account_id = account.id
                                              AND al.description = ? ))'
                  : ($_ eq 'partsgroup' ?
                     '(SELECT id FROM partsgroup WHERE partsgroup = ?)'
                     : '?'))}
        keys %table_columns;

    my $stmt =
        'INSERT INTO parts (' . join(', ',
                                     map { $table_columns{$_} }
                                     keys %table_columns)
                            . ')
         VALUES (' .
                 join(', ',
                      map { $column_placeholders{$_} }
                      keys %table_columns)
                 . ')';
    my $i_sth = $request->{dbh}->prepare($stmt)
        or die $request->{dbh}->errstr;

    my $ti_sth = $request->{dbh}->prepare(
        q{INSERT INTO partstax (parts_id, chart_id)
          VALUES (currval('parts_id_seq'),
                  (SELECT id FROM account
                    WHERE accno = ?
                          AND EXISTS (SELECT 1 FROM account_link al
                                       WHERE al.account_id = account.id
                                             AND al.description = ? )))});

    @$entries =
        map { map_columns_into_hash($columns, $_) }
        @$entries;

    for my $entry (@$entries) {
        for my $k (keys %$entry) {
            delete $entry->{$k}
            if defined $entry->{$k} and $entry->{$k} eq '';
        }
        $i_sth->execute(map { m/_accno$/ ?
                                  ($entry->{$_}, $acc_types->{$_})
                                  : $entry->{$_} }
                        keys %table_columns)
            or die $i_sth->errstr;

        if (exists $acc_types->{tax_accno}) {
            for my $taxaccno (split /:/, $entry->{taxaccnos}) {
                $ti_sth->execute($taxaccno, $acc_types->{tax_accno});
            }
        }
    }
}

sub _process_goods {
    return _process_parts(@_, $cols->{goods},
        { income_accno    => 'IC_sale',
          expense_accno   => 'IC_cogs',
          inventory_accno => 'IC',
          return_accno    => 'IC_returns',
          tax_accno       => 'IC_taxpart' });
}

sub _process_services {
    return _process_parts(@_, $cols->{services},
        { income_accno  => 'IC_income',
          expense_accno => 'IC_expense',
          tax_accno     => 'IC_taxservice' });
}

sub _process_overhead {
    return _process_parts(@_, $cols->{overhead},
        { inventory_accno => 'IC',
          expense_accno   => 'IC_expense' });
}

our $process = {
    gl              => \&_process_gl,
    gl_multi        => \&_process_gl_multi,
    ar_multi        => \&_process_ar_multi,
    ap_multi        => \&_process_ap_multi,
    chart           => \&_process_chart,
    gifi            => \&_process_gifi,
    sic             => \&_process_sic,
    timecard        => \&_process_timecard,
    inventory       => \&_process_inventory,
    inventory_multi => \&_process_inventory_multi,
    parts           => \&_process_goods,
    services        => \&_process_services,
    overhead        => \&_process_overhead,
};

=head2 _parse_file

This parses a file, and returns a the csv in tabular format.

=cut

sub _parse_file {
    my $self = shift @_;

    my $handle = $self->upload('import_file');
    my $csv = Text::CSV->new({ blank_is_undef => 1 });
    $csv->header($handle);
    $self->{import_entries} = $csv->getline_all($handle);

    return ([$csv->fields], @{$self->{import_entries}});
}



=head2 begin_import
This displays the begin data entry screen.
=cut

sub begin_import {
    my ($request) = @_;
    my $template_file =
        ($template_file{$request->{type}}) ?
        $template_file{$request->{type}} : 'import_csv';

    if (ref($template_setup->{$request->{type}}) eq 'CODE') {
        $template_setup->{$request->{type}}($request);
    }
    return [ 200, [ 'Content-Type' => 'application/json' ], [ '{}' ] ];
}



=head2 run_import

run_import is the routine responsible for the primary work.  It accepts the
data in $request and processes it according to the dispatch tables.

=cut

my $json = JSON::PP->new;

sub run_import {
    my ($request) = @_;

    try {
        my @entries = _parse_file($request);
        my $headers = shift @entries;
        if (ref($preprocess->{$request->{type}}) eq 'CODE'){
            $preprocess->{$request->{type}}($request, \@entries, $headers);
        }
        if ($process->{$request->{type}}($request, \@entries)){
            if (ref($postprocess->{$request->{type}}) eq 'CODE'){
                $postprocess->{$request->{type}}($request, \@entries);
            }
        }
        return begin_import($request);
    }
    catch ($e) {
        return [ 500,
                 [ 'Content-Type' => 'application/json' ],
                 [ $json->encode({ error => "$e" }) ] ];
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2013 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
