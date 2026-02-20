                                                          # -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


my $recon_acc = 0;

Given qr/a fresh reconciliation account/ => sub {
    # create a new GL account
    # mark it for reconcilitation
    # store its data in the stash

    my $conf = S->{ext_lsmb}->admin_conn->configuration;

    my $heading = $conf->coa_nodes->get(by => (accno => '1000'));
    $recon_acc++;
    my $acc = $conf->coa_nodes->create(
        type        => 'account',
        accno       => '1070-' . $recon_acc,
        heading_id  => ($heading->id =~ s/^H-//r),
        description => 'Reconciliation account ' . $recon_acc,
        category    => 'A',
        recon       => 1,
        );
    $acc->save;

    S->{recon_account} = $acc;
    ok(1);
};

my $trx_cnt = 0;
sub _uncleared_journal_line {
    my $posting_date = shift;

    my $dbh               = S->{ext_lsmb}->admin_dbh;
    my $conf              = S->{ext_lsmb}->admin_conn->configuration;
    my $primary_account   = S->{recon_account};
    my $secondary_account = $conf->coa_nodes->get(by => (accno => '1060'));
    my $reference         = 'ref-' . $trx_cnt++;

    $dbh->do(q{INSERT INTO transactions (id, reference, transdate, table_name, trans_type_code, approved)
               VALUES (nextval('id'), ?, ?, 'gl', 'gl', true)},
             {},
             $reference,
             $posting_date)
        or die $dbh->errstr;
    my $trx = $dbh->selectrow_hashref(
        <<~'STMT',
        INSERT INTO gl (id, reference, transdate)
            VALUES(currval('id'), ?, ?)
        RETURNING *
        STMT
        {},
        $reference,
        $posting_date
        )
        or die $dbh->errstr;
    $dbh->do(q|UPDATE transactions SET description = 'uncleared journal line' WHERE id = ?|,
             {},
             $trx->{id})
        or die $dbh->errstr;

    my $sth = $dbh->prepare(<<~'STMT') or die $dbh->errstr;
        INSERT INTO acc_trans (trans_id, chart_id, amount_bc, amount_tc,
                               curr, transdate, approved)
          VALUES (?, ?, ?, ?, 'USD', ?, true)
        RETURNING *
        STMT

    for my $row ([($secondary_account->id =~ s/^A-//r), -5],
                 [($primary_account->id =~ s/^A-//r), 5]) {
        $sth->execute(
                $trx->{id}, $row->[0], $row->[1], $row->[1],
                $posting_date
            ) or die $sth->errstr;
        S->{journal_line} = $sth->fetchrow_hashref('NAME_lc');
    }
}

Given qr/an uncleared journal line on (\d{4}-\d\d-\d\d)/, sub {
    # create a transaction
    # with at least a line on the recon_account

    _uncleared_journal_line($1);
    ok(1);
};

Given qr/a cleared journal line on (\d{4}-\d\d-\d\d)/, sub {
    my $posting_date = $1;

    _uncleared_journal_line($posting_date);
    my $recon_account = S->{recon_account};
    my $dbh           = S->{ext_lsmb}->admin_dbh;
    $dbh->do(<<~'STMT');
        INSERT INTO workflow (type, state, workflow_id)
        VALUES ('reconciliation', 'SAVED', nextval('workflow_seq'))
        STMT
    my $recon         = $dbh->selectrow_hashref(
        <<~'STMT',
        INSERT INTO cr_report (chart_id, their_total, end_date, workflow_id)
               values (?, ?, ?, currval('workflow_seq'))
        RETURNING *
        STMT
        {},
        ($recon_account->id =~ s/A-//r),
        5,
        $posting_date)
        or die $dbh->errstr;
    my $recon_line    = $dbh->selectrow_hashref(
        <<~'STMT',
        INSERT INTO cr_report_line (report_id, "user")
            VALUES (?, person__get_my_entity_id())
        RETURNING *
        STMT
        {},
        $recon->{id})
        or die $dbh->errstr;
    my $recon_link    = $dbh->selectrow_hashref(
        <<~'STMT',
        INSERT INTO cr_report_line_links (report_line_id, entry_id)
            VALUES (?, ?)
        RETURNING *
        STMT
        {},
        $recon_line->{id},
        S->{journal_line}->{entry_id}) or die $dbh->errstr;
    $dbh->do('select reconciliation__save_set(?, ?)',
             {},
             $recon->{id},
             [ $recon_line->{id} ]
        ) or die $dbh->errstr;
    $dbh->do('select reconciliation__submit_set(?)',
             {},
             $recon->{id}
        ) or die $dbh->errstr;
    $dbh->do('select reconciliation__report_approve(?)',
             {}, $recon->{id}) or die $dbh->errstr;
    ok(1);
};

sub _create_recon {
    my $end_date      = shift;
    my $dbh           = S->{ext_lsmb}->admin_dbh;
    my $recon_account = S->{recon_account};
    $dbh->do(<<~'STMT');
        INSERT INTO workflow (type, state, workflow_id)
        VALUES ('reconciliation', 'SAVED', nextval('workflow_seq'))
        STMT
    my ($id) = $dbh->selectrow_array(
        q|select reconciliation__new_report(?, ?, ?, false, currval('workflow_seq'))|,
        {},
        ($recon_account->id =~ s/A-//r),
        5,
        $end_date
        ) or die $dbh->errstr;

    $dbh->do('select reconciliation__pending_transactions(?, ?)',
             {},
             $id,
             5) or $dbh->errstr;


    return $id;
}

Given qr/(a|one|two) reconciliations? ending on (\d{4}-\d\d-\d\d)/ => sub {
    my $count = ($1 eq 'two') ? 2 : 1;
    my $end_date = $2;

    S->{'the reconciliation'} =
        S->{'the first reconciliation'} =
        _create_recon($end_date);
    S->{'the second reconciliation'} = _create_recon($end_date)
};

When qr/I create (a|one|two) reconciliations? ending on (\d{4}-\d\d-\d\d)/ => sub {
    my $count = ($1 eq 'two') ? 2 : 1;
    my $end_date = $2;

    S->{'the reconciliation'} =
        S->{'the first reconciliation'} =
        _create_recon($end_date);
    S->{'the second reconciliation'} = _create_recon($end_date)
};

When qr/(the (?:first |second )?reconciliation) is submitted/ => sub {
    my $recon_name = $1;
    my $recon_id   = S->{$recon_name};
    my $dbh        = S->{ext_lsmb}->admin_dbh;

    $dbh->do(
        <<~'STMT',
        select reconciliation__submit_set(?)
        STMT
        {},
        $recon_id,
        ) or die $dbh->errstr;

    ok(1);
};

Then qr/(the (?:first |second )?reconciliation) can( also| not|\'t)? be submitted/ => sub {
    my $a = $2;
    my $negate     = (not $2 or ($2 eq ' not' or $2 eq q{'t}));
    my $recon_name = $1;
    my $recon_id   = S->{$recon_name};
    my $dbh        = S->{ext_lsmb}->admin_dbh;

    local $dbh->{RaiseError} = 0;
    my $succeed = defined $dbh->do(
        <<~'STMT',
        select reconciliation__submit_set(?)
        STMT
        {},
        $recon_id,
        );

    ### NOTE!! This leaves the current transaction cancelled!
    ### There's no way to execute further steps after this step.

    if ($negate) {
        ok(!$succeed, "$recon_name cannot be submitted");
    }
    else {
        ok($succeed, "$recon_name can be submitted");
    }
};

When qr/the journal line is cleared in (the (?:first |second )?reconciliation)/ => sub {
    my $recon_name = $1;
    my $recon_id   = S->{$recon_name};
    my $dbh        = S->{ext_lsmb}->admin_dbh;

    $dbh->do(
        <<~'STMT',
        select reconciliation__save_set(
                   ?,
                   ARRAY[(select report_line_id
                            from cr_report_line_links rll
                            join cr_report_line rl on rll.report_line_id = rl.id
                            join cr_report r on rl.report_id = r.id
                           where entry_id = ? and r.id = ?)]::int[]
        )
        STMT
        {},
        $recon_id,
        S->{journal_line}->{entry_id},
        $recon_id
        ) or die $dbh->errstr;

    ok(1);
};

Then qr/the journal line is (not )?in (the (?:first |second )?reconciliation)/ => sub {
    my $negate     = $1;
    my $recon_name = $2;
    my $recon_id   = S->{$recon_name};
    my $dbh        = S->{ext_lsmb}->admin_dbh;
    my ($count)    = $dbh->selectrow_array(
        <<~'STMT',
        select count(*)
          from cr_report r join cr_report_line rl on r.id = rl.report_id
          join cr_report_line_links rll on rl.id = rll.report_line_id
         where r.id = ? and rll.entry_id = ?
        STMT
        {},
        $recon_id,
        S->{journal_line}->{entry_id}
        ) or die $dbh->errstr;

    if ($negate) {
        is($count, 0, 'The entry_id is not in the reconciliation');
    }
    else {
        is($count, 1, 'The entry_id is in the reconciliation');
    }
};


1;
