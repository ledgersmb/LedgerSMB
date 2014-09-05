=pod

=head1 NAME 

LedgerSMB::Scripts::import_trans

=head1 SYNPOSIS

This is a module that demonstrates how to set up scripts for importing bulk 
data.

=cut

package LedgerSMB::Scripts::import_csv;
use Moose;
use LedgerSMB::Template;
use LedgerSMB::Form;
use strict;

my $default_currency = 'USD';
our $cols = {
   gl       =>  ['accno', 'debit', 'credit', 'source', 'memo'],
   ap_multi =>  ['vendor', 'amount', 'account', 'ap', 'description', 
                 'invnumber', 'transdate'],
   ar_multi =>  ['customer', 'amount', 'account', 'ar', 'description', 
                 'invnumber', 'transdate'],
   timecard =>  ['employee', 'projectnumber', 'transdate', 'partnumber',
                 'description', 'qty', 'noncharge', 'sellprice', 'allocated',
                'notes'],
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

sub inventory_template_setup {
    my ($request) = @_;
    my $sth = $request->{dbh}->prepare(
        "SELECT concat(accno,'--',description) as value
             FROM chart_get_ar_ap(?)"
        );

    $sth->execute(1); # AP accounts
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @{$request->{AP_accounts}}, $row; 
    }
     

    $sth->execute(2); # AR accounts
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @{$request->{AR_accounts}}, $row; 
    }
};


our $template_setup = {
  inventory => \&inventory_template_setup,
  inventory_multi => \&inventory_template_setup,
};

sub map_columns_into_hash {
    my ($keys, $values) = @_;
    my %rv;

    @rv{@$keys} = @$values;

    return \%rv;
}



sub aa_multi {
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
        "select count(*) from account where accno = ?"
        );
    my $vcst = $request->{dbh}->prepare(
        "select count(*) from entity_credit_account where meta_number = ?"
        );
    for my $ref (@$entries){
        my $pass;
        next if $ref->[1] !~ /\d/;
        my ($acct) = split /--/, $ref->[2];
        $acst->execute($acct);
        ($pass) = $acst->fetchrow_array;
        $request->error("Account $acct not found") if !$pass;
        ($acct) = split /--/, $ref->[3];
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
        $form->{rowcount} = 1;
        $form->{ARAP} = uc($arap);
        $form->{batch_id} = $batch->{id};
        $form->{customernumber} = $form->{vendornumber} = shift @$ref;
        $form->{amount_1} = shift @$ref;
        next if $form->{amount_1} !~ /\d/;
        $form->{amount_1} = $form->parse_amount(
            $request->{_user}, $form->{amount_1}); 
        $form->{"$form->{ARAP}_amount_1"} = shift @$ref;
        $form->{vc} = ($arap eq "ar") ? "customer" : "vendor";
        $form->{arap} = $arap;
        $form->{uc($arap)} = shift @$ref;
        $form->{description_1} = shift @$ref;
        $form->{invnumber} = shift @$ref;
        $form->{transdate} = shift @$ref;
        $form->{currency} = $default_currency;
        $form->{approved} = '0';
        $form->{defaultcurrency} = $default_currency;
        my $sth = $form->{dbh}->prepare(
            "SELECT id FROM entity_credit_account
              WHERE entity_class = ? and meta_number = ?"
            );
        $sth->execute( ($arap eq 'ar') ? 2 : 1,
                       uc($form->{vendornumber}));
        ($form->{vendor_id}) = $sth->fetchrow_array;
        $form->{customer_id} = $form->{vendor_id};
        
        AA->post_transaction($request->{_user}, $form);
    }
    return 1;
};

sub inventory_single_date {
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
        "SELECT * FROM parts WHERE partnumber = ?"
        ) or $ap_form->dberror();
    my $ins_sth = $dbh->prepare(
        "INSERT INTO inventory_report_line
                (parts_id, counted, expected, adjust_id)
             VALUES (?, ?, ?, ?)"
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
        my ($dec) = ($adjust_form->{"sellprice_$rc"} =~ /\.(\d*)/);
        $adjust_form->{"precision_$rc"} = length($dec);
        $adjust_form->{"qty_$rc"} = abs($adjust);

        my $dbready_oh = $dbh->quote($line->{onhand});
        $ins_sth->execute($part->{id}, $dbready_oh,
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
    
    $ar_form->{id} = "NULL"
        if ! $ar_form->{id};
    $ap_form->{id} = "NULL"
        if ! $ap_form->{id};
    
    # Now, update the report record.
    $dbh->do( # These two params come from posting above, and from
              # the db.
              "UPDATE inventory_report
                       SET ar_trans_id = $ar_form->{id},
                           ap_trans_id = $ap_form->{id}
                     WHERE id = $report_id"
        ) or $ap_form->dberror();
};

our $process = {
   gl       => sub {
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
                          print STDERR "debits $ref->[1]\n";
                          $ref->[1] = $form->parse_amount(
                                         $request->{_user}, $ref->[1]
                          );
                       }
                       if ($ref->[2] !~ /\d/){
                          delete $ref->[2];
                       } else {
                          print STDERR "credits $ref->[2]\n";
                          $ref->[2] = $form->parse_amount(
                                         $request->{_user}, $ref->[2]
                          );
                       }
                       next if !$ref->[1] and !$ref->[2];
                       for my $col (@{$cols->{$request->{type}}}){
                           $form->{"${col}_$form->{rowcount}"} = shift @$ref;
                       }
                       ++$form->{rowcount};
                   }
                   GL->post_transaction($request->{_user}, $form);
                },
   ar_multi => sub { 
                   my  ($request, $entries) = @_;
                   return &aa_multi($request, $entries, 'ar');
               },
   ap_multi => sub { 
                   my  ($request, $entries) = @_;
                   return &aa_multi($request, $entries, 'ap');
               },
    chart => sub {
               use LedgerSMB::DBObject::Account;

               my ($request, $entries) = @_;

               foreach my $entry (@$entries){
                  my $account = LedgerSMB::DBObject::Account->new({base=>$request});
                  my $settings = {
                      accno => $entry->[0],
                      description => $entry->[1],
                      charttype => $entry->[2],
                      category => $entry->[3],
                      contra => $entry->[4],
                      tax => $entry->[5],
#                      heading => $entry->[7],
                      gifi_accno => $entry->[8],
                  };

                  if ($entry->[6] !~ /:/) {
                    $settings->{$entry->[6]} = 1
                      if ($entry->[6] ne "");
                  } else {
                    foreach my $link (split( /:/, $entry->[6])) {
                       $settings->{$link} = 1;
                    }
                  }

                  $account->merge($settings);
                  $account->save();
               }
             },
    gifi  => sub {
               my ($request, $entries) = @_;
               my $dbh = $request->{dbh};
               my $sth = $dbh->prepare('INSERT INTO gifi (accno, description) VALUES (?, ?)') || die $dbh->errstr;;

               foreach my $entry (@$entries) {
                 $sth->execute($entry->[0], $entry->[1]) || die $sth->errstr();
               }
             },
    sic   => sub {
               my ($request, $entries) = @_;
               my $dbh = $request->{dbh};
               my $sth = $dbh->prepare('INSERT INTO sic (code, sictype, description) VALUES (?, ?, ?)') || die $dbh->errstr;;

               foreach my $entry (@$entries) {
                 $sth->execute($entry->[0], $entry->[1], $entry->[2])
                    || die $sth->errstr();
               }
             },
 timecard => sub {
               use LedgerSMB::Timecard;
               my ($request, $entries) = @_;
               my $myconfig = {};
               my $jc = {};
               for my $entry (@$entries) {
                   my $counter = 0;
                   for my $col (@{$cols->{timecard}}){
                       $jc->{$col} = $entry->[$counter];
                       ++$counter;
                   }
                   LedgerSMB::Timecard->new(%$jc)->save;
               }
             },
   inventory => sub {
       my ($request, $entries) = @_;
       my $dbh = $request->{dbh};
       
       $dbh->do( # Not worth parameterizing for one input
              "INSERT INTO inventory_report 
                            (transdate, source)
                     VALUES (".$dbh->quote($request->{transdate}).
              ", 'CSV upload')"
        ) or $request->dberror();
    
       my ($report_id) = $dbh->selectrow_array(
           "SELECT currval('inventory_report_id_seq')"
           ) or $request->dberror();

       @$entries =
           map { map_columns_into_hash($cols->{inventory}, $_) } @$entries;
       &inventory_single_date($request, $entries,
                              $report_id, $request->{transdate});

   },
   inventory_multi => sub {
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
                     "INSERT INTO inventory_report 
                            (transdate, source)
                     VALUES (".$dbh->quote($key).
                     ", 'CSV upload (' || ".$dbh->quote($request->{transdate})
                     ." || ')')"
               ) or $request->dberror();
    
           my ($report_id) = $dbh->selectrow_array(
               "SELECT currval('inventory_report_id_seq')"
               ) or $request->dberror();

           &inventory_single_date($request, $dated_entries{$key},
                                  $report_id, $key);
       }

   },
};

=head2 parse_file

This parses a file, and returns a the csv in tabular format.

=cut

sub parse_file {
    my $self = shift @_;

    my $handle = $self->{_request}->upload('import_file');
    my $contents = join("\n", <$handle>);

    $self->{import_entries} = [];
    for my $line (split /(\r\n|\r|\n)/, $contents){
        next if ($line !~ /,/);
        my @fields;
        $line =~ s/[^"]"",/"/g;
        while ($line ne '') {
            if ($line =~ /^"/){
                $line =~ s/"(.*?)"(,|$)// 
                    || $self->error($self->{_locale}->text('Invalid file'));
                my $field = $1;
                $field =~ s/\s*$//;
                push @fields, $field;
            } else {
                $line =~ s/([^,]*),?//;
                my $field = $1;
                $field =~ s/\s*$//;
                push @fields, $field;
            }
        }
        push @{$self->{import_entries}}, \@fields;
    }     
    shift @{$self->{import_entries}}; # get rid of header line
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

    if (ref($template_setup->{$request->{type}}) eq "CODE") {
        $template_setup->{$request->{type}}($request);
    }

    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI/import_csv',
        template => $template_file,
        format => 'HTML'
    );
    $template->render($request);
}

=head2 run_import

run_import is the routine responsible for the primary work.  It accepts the 
data in $request and processes it according to the dispatch tables.

=cut

sub run_import {
    my ($request) = @_;
    my @entries = parse_file($request);
    if (ref($preprocess->{$request->{type}}) eq 'CODE'){
        $preprocess->{$request->{type}}($request, \@entries);
    }
    if ($process->{$request->{type}}($request, \@entries)){
        if (ref($postprocess->{$request->{type}}) eq 'CODE'){
            $postprocess->{$request->{type}}($request, \@entries);
        }
    }
    begin_import($request);
}

=head1 COPYRIGHT

Copyright(C) 2008-2013 The LedgerSMB Core Team.  This file may be re-used in 
accordance with the GNU General Public License (GNU GPL) v2 or at your option 
any later version.  Please see the included LICENSE.txt for more details.

=cut

eval { do 'scripts/custom/import_trans.pl'; };

1;
