#!perl

use v5.32;

use Test2::V0;
use Test2::Mock;

my $todo;

BEGIN {
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($OFF);
}

use Workflow;
use Workflow::Persister;
use LedgerSMB::Workflow::Action::Reconciliation;

package TestFactory {};

my $f  = bless {}, 'TestFactory';
my $wf = Workflow->new( 'id', 'INITIAL', { type => 'test' }, [], $f );



ok lives {
    #
    # Tests:
    #  1. non-merged remaining items
    #  2. merged remaining items
    #  3. non-merged items part of payments
    #  4. merged items part of a payment
    #  5. pending items merged with existing todo items

    my $action = LedgerSMB::Workflow::Action::Reconciliation->new(
        $wf,
        { entrypoint => 'add_pending_items' }
        );
    my $c = Workflow::Context->new();

    ##############################################
    #
    # 1. pending items: non-merged remaining lines
    #
    ##############################################

    # 1a. No source

    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_book_todo' => []);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => []);
    $c->param(
        '_pending_items'    => [
            {
                source    => '',
                entry_id  => 1,
                transdate => '2022-12-15',
                amount_tc => 5.00,
                amount_bc => 7.00,
            },
            {   # this line should not be merged with the one before
                source    => '',
                entry_id  => 2,
                transdate => '2022-12-15',
                amount_tc => 2.00,
                amount_bc => 3.00,
            },
        ]);

    $action->execute( $wf );
    my $bt = $c->param('_book_todo');
    is( scalar($bt->@*), 2, 'Pending items are not merged' );
    is( scalar($bt->[0]->{links}->@*), 1, 'Pending item has links' );
    is( $bt->[0]->{amount} + $bt->[1]->{amount}, 10, 'Amount gets filled correctly' );
    is( $bt->[0]->{post_date}, '2022-12-15', 'Posting date correctly passed' );


    # 1b. Same source, but different dates

    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_book_todo' => []);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => []);
    $c->param(
        '_pending_items'    => [
            {
                source    => 'abc',
                entry_id  => 1,
                transdate => '2022-12-15',
                amount_tc => 5.00,
                amount_bc => 7.00,
            },
            {   # this line should not be merged with the one before
                source    => 'abc',
                entry_id  => 2,
                transdate => '2022-12-17',
                amount_tc => 2.00,
                amount_bc => 3.00,
            },
        ]);

    $action->execute( $wf );
    $bt = $c->param('_book_todo');
    is( scalar($bt->@*), 2, 'Pending items are not merged' );
    is( scalar($bt->[0]->{links}->@*), 1, 'Pending item has links' );
    is( $bt->[0]->{amount} + $bt->[1]->{amount}, 10, 'Amount gets filled correctly' );


    #############################################
    #
    # 2. pending items: merged remaining lines
    #
    #############################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_book_todo' => []);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => []);
    $c->param(
        '_pending_items'    => [
            {
                source    => 'source',
                entry_id  => 1,
                transdate => '2022-12-15',
                amount_tc => 5.00,
                amount_bc => 7.00,
            },
            {   # this line should be merged with the one before
                source    => 'source',
                entry_id  => 2,
                transdate => '2022-12-15',
                amount_tc => 2.00,
                amount_bc => 3.00,
            },
        ]);

    $action->execute( $wf );
    $bt = $c->param('_book_todo');
    is( scalar($bt->@*), 1, 'Pending items are merged' );
    is( scalar($bt->[0]->{links}->@*), 2, 'Pending item has links to all items' );
    is( $bt->[0]->{amount}, 10, 'Amount gets filled correctly' );
    is( $bt->[0]->{post_date}, '2022-12-15', 'Posting date correctly passed' );


    #############################################
    #
    # 3. pending items: non-merged payment lines
    #
    #############################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_book_todo' => []);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => []);
    $c->param(
        '_pending_items', [
            {
                source    => 'source',
                entry_id  => 1,
                payment_id => 1,
                transdate => '2022-12-15',
                paymentdate => '2022-12-15',
                amount_tc   => 5.00,
                amount_bc   => 7.00,
            },
            {   # this line should not be merged with the one before
                source    => 'source',
                entry_id  => 2,
                payment_id => 2,
                transdate => '2022-12-15',
                paymentdate => '2022-12-15',
                amount_tc   => 2.00,
                amount_bc   => 3.00,
            },
        ]);

    $action->execute( $wf );
    $bt = $c->param('_book_todo');
    is( scalar($bt->@*), 2, 'Pending payment items are not merged' );
    is( scalar($bt->[0]->{links}->@*), 1, 'Pending item has links to itself' );
    is( $bt->[0]->{amount} + $bt->[1]->{amount}, 10, 'Amount gets filled correctly' );
    is( $bt->[0]->{post_date}, '2022-12-15', 'Posting date correctly passed' );
    is( $bt->[1]->{post_date}, '2022-12-15', 'Posting date correctly passed' );

    #############################################
    #
    # 4. pending items: merged payment lines
    #
    #############################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_book_todo' => []);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => []);
    $c->param(
        '_pending_items', [
            {
                source    => 'source1', # contrived: same sources expected, but unused
                entry_id  => 1,
                payment_id => 1,
                transdate => '2022-12-15',
                paymentdate => '2022-12-15',
                amount_tc   => 5.00,
                amount_bc   => 7.00,
            },
            {   # this line should be merged with the one before
                source    => 'source2',
                entry_id  => 2,
                payment_id => 1,
                transdate => '2022-12-15',
                paymentdate => '2022-12-15',
                amount_tc   => 2.00,
                amount_bc   => 3.00,
            },
        ]);

    $action->execute( $wf );
    $bt = $c->param('_book_todo');
    is( scalar($bt->@*), 1, 'Pending payment items are merged' );
    is( scalar($bt->[0]->{links}->@*), 2, 'Pending item has links to itself' );
    is( $bt->[0]->{amount}, 10, 'Amount gets filled correctly' );
    is( $bt->[0]->{post_date}, '2022-12-15', 'Posting date correctly passed' );

    #############################################
    #
    # 5. pending items: merged with existing _book_todo items
    #
    #############################################


    # a. Single pending line merged to single todo item

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'source1',
                       payment_id => 1,
                       post_date  => '2022-12-17',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => []);
    $c->param(
        '_pending_items', [
            {   # this line should be merged with the book_todo line
                # it should *not* have any payment parameters, because if
                # so, it'll be considered a separate payment item, which
                # can't be a correction on an earlier payment.
                source    => 'source1',
                entry_id  => 2,
                transdate => '2022-12-17',
                amount_tc   => 2.00,
                amount_bc   => 3.00,
            },
        ]);

    $action->execute( $wf );
    $bt = $c->param('_book_todo');
    is( scalar($bt->@*), 1, 'Pending item has been merged with todo item' );
    is( scalar($bt->[0]->{links}->@*), 2, 'Todo item now has 2 links' );
    is( $bt->[0]->{amount}, 9, 'Amount gets filled correctly' );
    is( $bt->[0]->{post_date}, '2022-12-17', 'Posting date correctly passed' );

}, '"add_pending_items" action', $@;

ok lives {
    my $action = LedgerSMB::Workflow::Action::Reconciliation->new(
        $wf,
        { entrypoint => 'approve' }
        );
    $wf->{context} = Workflow::Context->new();

    $action->execute( $wf );
    is( $wf->context->param( 'approved' ), 1, '"approved" context parameter is true-ish');
}, '"approve" action', $@;

ok lives {
    my $action = LedgerSMB::Workflow::Action::Reconciliation->new(
        $wf,
        { entrypoint => 'delete' }
        );
    $wf->{context} = Workflow::Context->new();

    $action->execute( $wf );
    is( $wf->context->param( 'deleted' ), 1, '"deleted" context parameter is true-ish');
}, '"delete" action', $@;

ok lives {
    my $action = LedgerSMB::Workflow::Action::Reconciliation->new(
        $wf,
        { entrypoint => 'reconcile' }
        );

    ####################################
    #
    # Tests:
    #  1. Statement lines without source identifier
    #     a. Same amount, different dates
    #     b. Same amount, same date
    #  2. Statement lines with numeric-only source identifier
    #     a. same source, different dates
    #     b. same source, same date, mismatching amounts
    #     c. different source, same date, same amounts
    #     d. same source, same date, matching amounts
    #     e. same source (no prefix), same date, matching amounts
    #  3. Statement lines with alphanumeric source identifier
    #     a. same source, different dates
    #     b. same source, same date, mismatching amounts
    #     c. different source, same date, same amounts
    #     d. same source, same date, matching amounts
    #
    ####################################


    ####################################
    #
    # 1a. Statement and book line without source identifier, same amount different dates
    # --> don't get matched!
    #
    ####################################

    my $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( 'prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       payment_id => 1,
                       post_date  => '2022-12-17',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    my $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items remain to be matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items remain to be matched' );
    is( scalar($rd->@*), 0, 'No items matched' );


    ####################################
    #
    # 1b. Statement and book line without source identifier, same amount, same date
    # --> *do* get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_recon_done'    => []);
    $c->param( '_book_todo'     => [
                   {
                       amount => 6,
                       payment_id => 1,
                       post_date  => '2022-12-17',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_stmt_todo' => [
                   {
                       amount => 6,
                       post_date => '2022-12-17',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 0, 'Statement item is matched' );
    is( scalar($c->param( '_book_todo' )->@*), 0, 'Book item is matched' );
    is( scalar($rd->@*), 1, 'Matched items added to "done" list' );


    ####################################
    #
    # 2a. Statement and book line with source identifier, same amount different dates
    # --> don't get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'check 123',
                       payment_id => 1,
                       post_date  => '2022-12-17',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => '123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items remain to be matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items remain to be matched' );
    is( scalar($rd->@*), 0, 'No items matched' );

    ####################################
    #
    # 2b. Statement and book line with source identifier, different amounts same date
    # --> don't get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 1,
                       source => 'check 123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => '123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );

    ###BUG!!!
    ###But it's a one-to-one copy of the SQL code... / probably a bug there too
    $todo = todo('fails to see amounts do not match');
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items remain to be matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items remain to be matched' );
    is( scalar($rd->@*), 0, 'No items matched' );
    $todo = undef;

    ####################################
    #
    # 2c. Statement and book line with difference source, same amounts same date
    # --> don't get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'check 123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => '124',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items remain to be matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items remain to be matched' );
    is( scalar($rd->@*), 0, 'No items matched' );

    ####################################
    #
    # 2d. Statement and book line with same source, same amounts, same date
    # --> *do* get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'check 123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => '123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 0, 'Statement items are matched' );
    is( scalar($c->param( '_book_todo' )->@*), 0, 'Book items are matched' );
    is( scalar($rd->@*), 1, 'Items matched' );

    ####################################
    #
    # 2e. Statement and book line with same source (no prefix), same amounts, same date
    # --> don't get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => '123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => '123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items are not matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items are not matched' );
    is( scalar($rd->@*), 0, 'Items are not matched' );

    ####################################
    #
    # 3a. Statement and book line with source identifier, same amount different dates
    # --> don't get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'source123',
                       payment_id => 1,
                       post_date  => '2022-12-17',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => 'source123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items remain to be matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items remain to be matched' );
    is( scalar($rd->@*), 0, 'No items matched' );

    ####################################
    #
    # 3b. Statement and book line with source identifier, different amounts same date
    # --> don't get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 1,
                       source => 'source123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => 'source123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );

    ###BUG!!!
    ###But it's a one-to-one copy of the SQL code... / probably a bug there too
    $todo = todo('fails to see amounts do not match');
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items remain to be matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items remain to be matched' );
    is( scalar($rd->@*), 0, 'No items matched' );
    $todo = undef;

    ####################################
    #
    # 3c. Statement and book line with difference source, same amounts same date
    # --> don't get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'source123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => 'source124',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 1, 'Statement items remain to be matched' );
    is( scalar($c->param( '_book_todo' )->@*), 1, 'Book items remain to be matched' );
    is( scalar($rd->@*), 0, 'No items matched' );

    ####################################
    #
    # 3d. Statement and book line with same source, same amounts, same date
    # --> *do* get matched!
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'source123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => 'source123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 0, 'Statement items are matched' );
    is( scalar($c->param( '_book_todo' )->@*), 0, 'Book items are matched' );
    is( scalar($rd->@*), 1, 'Items matched' );


    ####################################
    #
    # 4a. Multiple matched statement lines and book lines
    # --> correctly updates _stmt_todo
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 6,
                       source => 'source123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   },
                   {
                       amount => 7,
                       source => 'source1234',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 2 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => 'source1234',
                       amount => 7,
                       post_date => '2022-12-15',
                   },
                   {
                       source => 'source123',
                       amount => 6,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 0, 'Statement items are matched' );
    is( scalar($c->param( '_book_todo' )->@*), 0, 'Book items are matched' );
    is( scalar($rd->@*), 2, 'Items matched' );

    ####################################
    #
    # 4b. Multiple matched statement lines and book lines (reverse order)
    # --> correctly updates _stmt_todo
    #
    ####################################

    $c = Workflow::Context->new();
    $wf->{context} = $c;
    $c->param( 'recon_fx'   => 0 );
    $c->param( '_prefix'     => 'check' );
    $c->param( '_pending_items' => []);
    $c->param( '_book_todo' => [
                   {
                       amount => 7,
                       source => 'source1234',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 2 } ]
                   },
                   {
                       amount => 6,
                       source => 'source123',
                       payment_id => 1,
                       post_date  => '2022-12-15',
                       links      => [ { entry_id => 1 } ]
                   }
               ]);
    $c->param( '_recon_done' => []);
    $c->param( '_stmt_todo' => [
                   {
                       source => 'source123',
                       amount => 6,
                       post_date => '2022-12-15',
                   },
                   {
                       source => 'source1234',
                       amount => 7,
                       post_date => '2022-12-15',
                   }
               ]);

    $action->execute( $wf );
    $rd = $c->param( '_recon_done' );
    is( scalar($c->param( '_stmt_todo' )->@*), 0, 'Statement items are matched' );
    is( scalar($c->param( '_book_todo' )->@*), 0, 'Book items are matched' );
    is( scalar($rd->@*), 2, 'Items matched' );

}, '"reconcile" action', $@;

ok lives {
    my $action = LedgerSMB::Workflow::Action::Reconciliation->new(
        $wf,
        { entrypoint => 'reject' }
        );
    $wf->{context} = Workflow::Context->new();

    $action->execute( $wf );
    is( $wf->context->param( 'rejected' ), 1, '"rejected" context parameter is true-ish');
}, '"reject" action', $@;

ok lives {
    my $action = LedgerSMB::Workflow::Action::Reconciliation->new(
        $wf,
        { entrypoint => 'submit' }
        );
    $wf->{context} = Workflow::Context->new();

    $action->execute( $wf );
    is( $wf->context->param( 'submitted' ), 1, '"submitted" context parameter is true-ish');
}, '"submit" action', $@;


done_testing;
