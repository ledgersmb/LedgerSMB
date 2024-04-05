#!perl

use Test2::V0;
use Test2::Mock;

BEGIN {
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($OFF);
}

use Data::Dumper;
use Workflow::Factory;
use LedgerSMB::Workflow::Loader;


my $instance = Workflow::Factory->instance;

my $config_callback;
my @config_args;
my $mock = Test2::Mock->new(
    class => 'Workflow::Factory',
    override => [
        add_config_from_file => sub {
            shift; # drop the factory
            @config_args = @_;
        },
        config_callback => sub {
            $config_callback = $_[1];
        },
    ]);

ok lives {
    LedgerSMB::Workflow::Loader->load(
        directories => [ 't/data/workflow-loader/empty/' ],
        );
}, 'Initialize the workflow loader', $@;

ok $config_callback, 'a config callback was set';

ok lives {
    is( $config_callback->('non-existing'),
        hash {
            field persister => [];
            field workflow  => [];
            field action    => [];
            field validator => [];
            field condition => [];
        },
        'callback arguments for non-existent workflow type'
        );
}, 'callback with nonexisting workflow type', $@;

ok lives {
    is( $config_callback->('test'),
        hash {
            field persister => [ 't/data/workflow-loader/empty/test.persisters.xml' ];
            field workflow  => [ 't/data/workflow-loader/empty/test.workflow.xml'   ];
            field action    => [ 't/data/workflow-loader/empty/test.actions.xml'    ];
            field validator => [ 't/data/workflow-loader/empty/test.validators.xml' ];
            field condition => [ 't/data/workflow-loader/empty/test.conditions.xml' ];
        },
        'callback arguments for existing workflow type',
        Dumper { @config_args }
        );
}, 'callback with existing workflow type', $@;

ok lives {
    is( $config_callback->('test/lazy'),
        hash {
            field persister => [ 't/data/workflow-loader/empty/test-lazy.persisters.xml' ];
            field workflow  => [ 't/data/workflow-loader/empty/test-lazy.workflow.xml'   ];
            field action    => [ 't/data/workflow-loader/empty/test-lazy.actions.xml'    ];
            field validator => [ 't/data/workflow-loader/empty/test-lazy.validators.xml' ];
            field condition => [ 't/data/workflow-loader/empty/test-lazy.conditions.xml' ];
        },
        'callback arguments for workflow type with mapped name ("test/lazy" -> "test-lazy")',
        Dumper { @config_args }
        );
}, 'callback with existing (mapped) workflow type', $@;



$config_callback = undef;
ok lives {
    LedgerSMB::Workflow::Loader->load(
        directories => [
            't/data/workflow-loader/empty/',
            't/data/workflow-loader/empty-custom/',
        ],
        );
}, 'Initialize a workflow loader with custom directory', $@;


ok lives {
    is( $config_callback->('test'),
        hash {
            field persister => [ 't/data/workflow-loader/empty/test.persisters.xml' ];
            field workflow  => [ 't/data/workflow-loader/empty-custom/test.workflow.xml'   ];
            field action    => [ 't/data/workflow-loader/empty/test.actions.xml'    ];
            field validator => [ 't/data/workflow-loader/empty/test.validators.xml' ];
            field condition => [ 't/data/workflow-loader/empty/test.conditions.xml' ];
        },
        'callback arguments for existing workflow type',
        Dumper { @config_args }
        );
}, 'callback with customized workflow type', $@;


done_testing;
