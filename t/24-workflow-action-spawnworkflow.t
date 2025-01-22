#!perl

use v5.32;

use Test2::V0;
use Test2::Mock;

BEGIN {
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($OFF);
}

use Workflow;
use Workflow::History;
use Workflow::Persister;
use LedgerSMB::Workflow::Action::SpawnWorkflow;

package TestFactory {};

my $c  = Workflow::Context->new();
my $f  = bless {}, 'TestFactory';
my $wf = Workflow->new(
    'id', 'INITIAL', { type => 'test',
                       history_class => 'Workflow::History' }, [], $f );
my $wf2 = Workflow->new(
    'id2', 'INITIAL', { type => 'test',
                        history_class => 'Workflow::History' }, [], $f );

$wf->context( $c );


my $mock_wf = Test2::Mock->new(
    class => 'Workflow',
    override => [
        _factory => sub { $f },
    ],
    );

my ($created_workflow, $passed_context);
my $mock_fact = Test2::Mock->new(
    class => 'TestFactory',
    add => [
        create_workflow => sub {
            shift;
            ($created_workflow, $passed_context) = @_;
            $wf2
        },
    ],
    );

ok lives {
    my $action = LedgerSMB::Workflow::Action::SpawnWorkflow->new( $wf, { spawn_type => 'W/F' } );
    $action->execute( $wf );

    ok !$passed_context,
        'No context passed without context_param';
    is $wf->context->param( 'spawned_workflow' ), 'id2',
        'Workflow spawned and ID set in context';
}, 'No exceptions thrown -- no context parameter', $@;

ok lives {
    my $action = LedgerSMB::Workflow::Action::SpawnWorkflow->new(
        $wf,
        { spawn_type => 'W/F', context_param => 'cp' } );
    $c->param( 'cp', { a => 1 } );
    $action->execute( $wf );

    ok $passed_context, 'Context passed with context_param';
    is $wf->context->param( 'spawned_workflow' ), 'id2',
        'Workflow spawned and ID set in context';
}, 'No exceptions thrown -- with context parameter', $@;


done_testing;
