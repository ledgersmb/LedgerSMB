#!perl

use v5.32;

use Test2::V0;
use Test2::Mock;

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
    $c->param( '_book_done' => []);
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
    $c->param( '_book_done' => []);
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
    $c->param( '_book_done' => []);
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
    $c->param( '_book_done' => []);
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
    $c->param( '_book_done' => []);
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
    $c->param( '_book_done' => []);
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
    $wf->{context} = Workflow::Context->new();

#    $action->execute( $wf );
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
