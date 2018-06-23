
package LedgerSMB::Scripts::import_csv;

=head1 NAME

LedgerSMB::Scripts::import_csv - web entry points for various csv uploads

=head1 DESCRIPTION

This is a module that demonstrates how to set up scripts for importing bulk
data.

=head1 METHODS

This module doesn't specify any methods.

=cut

use strict;
use warnings;

use List::MoreUtils qw{ any };
use Text::CSV;

use LedgerSMB::Template;
use LedgerSMB::Form;
use LedgerSMB::Setting;
use LedgerSMB::Magic qw( EC_VENDOR EC_CUSTOMER );

our $cols = {
   gl       =>  ['accno', 'debit', 'credit', 'source', 'memo'],
   ap_multi =>  ['vendor', 'amount', 'account', 'ap', 'description',
                 'invnumber', 'transdate'],
   ar_multi =>  ['customer', 'amount', 'account', 'ar', 'description',
                 'invnumber', 'transdate'],
   timecard =>  ['employee', 'business_unit_id', 'transdate', 'partnumber',
                 'description', 'qty', 'non_billable', 'sellprice', 'allocated',
                'notes', 'jctype', 'curr'],
   inventory => ['partnumber', 'onhand', 'purchase_price'],
   inventory_multi => ['date', 'partnumber', 'onhand', 'purchase_price'],
};

my %template_file = (
   inventory => 'import_inventory_csv',
   inventory_multi => 'import_inventory_csv',
);


our $ap_eca_for_inventory = '00000'; # Built in inventory adjustment accounts
our $ar_eca_for_inventory = '00000';
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
    use LedgerSMB::AA;
    use LedgerSMB::Batch;
    my ($request, $entries, $arap) = @_;
    my $batch = LedgerSMB::Batch->new({base => $request});
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
    for my $ref (@$entries){
        my $pass;
        next if $ref->[1] !~ /\d/;
        my ($acct) = split /--/, $ref->[2];
        $acst->execute($acct);
        ($pass) = $acst->fetchrow_array;
        $request->error("Account $acct not found") if !$pass;
        ($acct) = split /--/, $ref->[3];  ## no critic (ProhibitMagicNumbers) sniff
        $acst->execute($acct);
        ($pass) = $acst->fetchrow_array;
        $request->error("Account $acct not found") if !$pass;
        $vcst->execute(uc($ref->[0]));
        ($pass) = $vcst->fetchrow_array;
        if (! $pass) {
            if ($arap eq 'ar') {
                $request->error("Customer $ref->[0] not found");
            } else {
                $request->error("Vendor $ref->[0] not found");
            }
        }
    }
    for my $ref (@$entries){
        my $form = Form->new();
        $form->{dbh} = $request->{dbh};
        my $default_currency = LedgerSMB::Setting->get('curr');
        $form->{rowcount} = 1;
        $form->{ARAP} = uc($arap);
        $form->{batch_id} = $batch->{id};
        $form->{customernumber} = $form->{vendornumber} = shift @$ref;
        $form->{amount_1} = shift @$ref;
        next if $form->{amount_1} !~ /\d/;
        $form->{amount_1} = $form->parse_amount(
            $request->{_user}, $form->{amount_1});
        $form->{"$form->{ARAP}_amount_1"} = shift @$ref;
        $form->{vc} = ($arap eq 'ar') ? 'customer' : 'vendor';
        $form->{arap} = $arap;
        $form->{uc($arap)} = shift @$ref;
        $form->{description_1} = shift @$ref;
        $form->{invnumber} = shift @$ref;
        $form->{transdate} = shift @$ref;
        $form->{currency} = $default_currency;
        $form->{approved} = '0';
        $form->{defaultcurrency} = $default_currency;
        my $sth = $form->{dbh}->prepare(
            'SELECT id FROM entity_credit_account
              WHERE entity_class = ? and meta_number = ?'
            );
        $sth->execute( ($arap eq 'ar') ? 2 : 1,
                       uc($form->{vendornumber}));
        ($form->{vendor_id}) = $sth->fetchrow_array;
        $form->{customer_id} = $form->{vendor_id};

        AA->post_transaction($request->{_user}, $form);
    }
    return 1;
}

sub _inventory_single_date {
    my ($request, $entries, $report_id, $transdate) = @_;
    use LedgerSMB::IS;
    use LedgerSMB::IR;
    my $ar_form = Form->new();
    my $ap_form = Form->new();
    my $dbh = $request->{dbh};

    $ar_form->{dbh} = $ap_form->{dbh} = $dbh;

    # Needs to come *after* form initialization
    my ($curr) = split /:/, $ap_form->get_setting('curr');


    $ar_form->{rowcount} = $ap_form->{rowcount} = 0;
    $ar_form->{transdate} = $ap_form->{transdate} = $transdate;
    $ar_form->{defaultcurrency} = $ar_form->{currency} = $curr;
    $ap_form->{defaultcurrency} = $ap_form->{currency} = $curr;
    $ar_form->{type} = $ap_form->{type} = 'invoice';
    # Intentionally not setting CRDATE here

    my $p_info_sth = $dbh->prepare(
        'SELECT * FROM parts WHERE partnumber = ?'
        ) or $ap_form->dberror();
    my $ins_sth = $dbh->prepare(
        'INSERT INTO inventory_report_line
                (parts_id, counted, expected, adjust_id)
             VALUES (?, ?, ?, ?)'
        ) or $ap_form->dberror();

    my $adjustment = ($request->{stock_type} ne 'relative') ?
        sub { my ($target, $part_info) = @_;
              return ($target - $part_info->{onhand}); }
        : sub { my ($target) = @_;
                return $target; };

    for my $line (@$entries){
        next if $line->{onhand} !~ /\d/;

        $p_info_sth->execute($line->{partnumber});
        my $part = $p_info_sth->fetchrow_hashref('NAME_lc');
        die "Part $line->{partnumber} not found."
            unless $part;
        my $adjust = &$adjustment( $line->{onhand}, $part);
        my $adjust_form = ($adjust > 0) ? $ap_form : $ar_form;

        my $rc = ++$adjust_form->{rowcount};
        $adjust_form->{"id_$rc"} = $part->{id};
        $adjust_form->{"sellprice_$rc"} = $line->{purchase_price};
        $adjust_form->{"discount_$rc"} = 0;
        $adjust_form->{"qty_$rc"} = abs($adjust);

        $ins_sth->execute($part->{id}, $line->{onhand},
                          $part->{onhand}, $report_id)
            or $ap_form->dberror();

    }
    $ar_form->{ARAP} = 'AR';
    $ar_form->{AR} = $request->{AR};
    $ap_form->{ARAP} = 'AP';
    $ap_form->{AP} = $request->{AP};

    # ECA
    $ar_form->{'customernumber'} = $ar_eca_for_inventory;
    $ap_form->{'vendornumber'} = $ap_eca_for_inventory;
    $ar_form->get_name(undef, 'customer', 'today', 2);
    $ap_form->get_name(undef, 'vendor', 'today', 1);
    my $ar_eca = shift @{$ar_form->{name_list}};
    my $ap_eca = shift @{$ap_form->{name_list}};
    $ar_form->{customer_id} = $ar_eca->{id};
    $ap_form->{vendor_id} = $ap_eca->{id};

    # POST
    IS->post_invoice(undef, $ar_form) if $ar_form->{rowcount};
    IR->post_invoice(undef, $ap_form) if $ap_form->{rowcount};

    $ar_form->{id} = 'NULL'
        if ! $ar_form->{id};
    $ap_form->{id} = 'NULL'
        if ! $ap_form->{id};

    # Now, update the report record.
    return ($dbh->do( # These two params come from posting above, and from
              # the db.
              "UPDATE inventory_report
                       SET ar_trans_id = $ar_form->{id},
                           ap_trans_id = $ap_form->{id}
                     WHERE id = $report_id"
        ) or $ap_form->dberror());
}

sub _process_ar_multi {
    my  ($request, $entries) = @_;
    return &_aa_multi($request, $entries, 'ar');
}

sub _process_ap_multi {
    my  ($request, $entries) = @_;
    return &_aa_multi($request, $entries, 'ap');
}

sub _process_gl {
    use LedgerSMB::GL;
    my ($request, $entries) = @_;
    my $form = Form->new();
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
    return GL->post_transaction($request->{_user}, $form,
                         $request->{_locale});
}

sub _process_chart {
    use LedgerSMB::DBObject::Account;

    my ($request, $entries) = @_;

    use constant ACCNO          => 0;
    use constant DESCRIPTION    => 1;
    use constant CHARTTYPE      => 2;
    use constant CATEGORY       => 3;
    use constant CONTRA         => 4;
    use constant TAX            => 5;
    use constant LINK           => 6;
    use constant HEADING        => 7;
    use constant GIFI_ACCNO     => 8;

    foreach my $entry (@$entries){
        my $account = LedgerSMB::DBObject::Account->new({base=>$request});
        my $settings = {
            accno => $entry->[ACCNO],
            description => $entry->[DESCRIPTION],
            charttype => $entry->[CHARTTYPE],
            category => $entry->[CATEGORY],
            contra => $entry->[CONTRA],
            tax => $entry->[TAX],
#            heading => $entry->[7],
            gifi_accno => $entry->[GIFI_ACCNO],
        };
        my @link = split /:/, $entry->[LINK];
        @$settings{ @link } = ( (1) x @link);

        $account->merge($settings);
        $account->save();
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
    use LedgerSMB::Timecard;
    my ($request, $entries) = @_;
    my @floats = qw {qty non_billable sellprice allocated};
    for my $entry (@$entries) {
        my $jc = {};
        my $counter = 0;
        for my $col (@{$cols->{timecard}}){
            if ($request->{sep} eq ';' &&
                any { $_ eq $col } @floats) {
                $entry->[$counter] =~ s/,/./;
                $entry->[$counter] = 0 if $entry->[$counter] eq '';
            }
            $jc->{$col} = $entry->[$counter];
            ++$counter;
        }
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
    my $dbh = $request->{dbh};

    $dbh->do( # Not worth parameterizing for one input
              'INSERT INTO inventory_report
                            (transdate, source)
                     VALUES ('.$dbh->quote($request->{transdate}).
              q{, 'CSV upload')}
        ) or $request->dberror();

    my ($report_id) = $dbh->selectrow_array(
        q{SELECT currval('inventory_report_id_seq')}
        ) or $request->dberror();

    @$entries =
        map { map_columns_into_hash($cols->{inventory}, $_) } @$entries;

    return _inventory_single_date($request, $entries,
                            $report_id, $request->{transdate});
}

sub _process_inventory_multi {
    my ($request, $entries) = @_;
    my $dbh = $request->{dbh};

    @$entries =
        map { map_columns_into_hash($cols->{inventory_multi}, $_) }
        @$entries;
    my %dated_entries;
    for my $entry (@$entries) {
        push @{$dated_entries{$entry->{date}}}, $entry;
    }

    for my $key (keys %dated_entries) {
        $dbh->do( # Not worth parameterizing for one input
                  'INSERT INTO inventory_report
                            (transdate, source)
                     VALUES ('.$dbh->quote($key).
                  q{, 'CSV upload (' || }.$dbh->quote($request->{transdate})
                  .q{ || ')')}
            ) or $request->dberror();

        my ($report_id) = $dbh->selectrow_array(
            q{SELECT currval('inventory_report_id_seq')}
            ) or $request->dberror();

        &_inventory_single_date($request, $dated_entries{$key},
                                $report_id, $key);
    }
    return;
}

our $process = {
    gl              => \&_process_gl,
    ar_multi        => \&_process_ar_multi,
    ap_multi        => \&_process_ap_multi,
    chart           => \&_process_chart,
    gifi            => \&_process_gifi,
    sic             => \&_process_sic,
    timecard        => \&_process_timecard,
    inventory       => \&_process_inventory,
    inventory_multi => \&_process_inventory_multi,
};

=head2 _parse_file

This parses a file, and returns a the csv in tabular format.

=cut

sub _parse_file {
    my $self = shift @_;

    my $handle = $self->upload('import_file');
    my $csv = Text::CSV->new;
    $csv->header($handle);
    $self->{import_entries} = $csv->getline_all($handle);

    return @{$self->{import_entries}};
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

    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI/import_csv',
        template => $template_file,
        format => 'HTML'
    );
    # $request->{page_id} = $request->{type};
    # $request->{page_id} =~ s/_/-/;
    # $request->{page_id} .= '-import';
    $request->{page_id} = 'batch-import';
    return $template->render({ request => $request });
}

=head2 run_import

run_import is the routine responsible for the primary work.  It accepts the
data in $request and processes it according to the dispatch tables.

=cut

sub run_import {
    my ($request) = @_;

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

=head1 LICENSE AND COPYRIGHT

Copyright(C) 2008-2013 The LedgerSMB Core Team.  This file may be re-used in
accordance with the GNU General Public License (GNU GPL) v2 or at your option
any later version.  Please see the included LICENSE.txt for more details.

=cut

{
    local ($!, $@) = ( undef, undef);
    my $do_ = 'scripts/custom/import_trans.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die ( "Status: 500 Internal server error (import_csv.pm)\n\n" );
            }
        }
    }
};

1;
