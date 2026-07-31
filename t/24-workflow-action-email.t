#!perl

use v5.32;

use Test2::V0;
use Test2::Mock;

BEGIN {
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($OFF);
}

use Beam::Wire;
use Carp::Always;
use Email::Sender::Transport::DevNull;

use LedgerSMB::Company;
use LedgerSMB::Workflow;
use Workflow::Persister;


use LedgerSMB::Workflow::Action::Email;


package TestPersister {
    sub handle { 1 };
}
package TestFactory {
    sub get_persister_for_workflow_type {
        return bless {}, 'TestPersister';
    }
};

my $c  = Workflow::Context->new();
my $f  = bless {}, 'TestFactory';
my $wf = LedgerSMB::Workflow->new( 'id', 'INITIAL', { type => 'test' }, [], $f );
my $app = LedgerSMB::Company->new(
    wire => Beam::Wire->new(
        config => {
            mail => {
                transport => {
                    '$class' => 'Email::Sender::Transport::DevNull'
                }
            }
        }),
    dbh => 1);
$wf->{app} = $app;
$wf->context( $c );

ok lives {
    $c->param( 'to'         => 'you@example.com, him@example.com' );
    $c->param( 'from'       => 'me@example.com' );
    $c->param( 'cc'         => 'them@example.com' );
    $c->param( 'bcc'        => 'them@example.org,they@example.com' );
    $c->param( 'subject'    => 'About us...' );
    $c->param( 'body'       => 'What about us?' );

    my $action = LedgerSMB::Workflow::Action::Email->new( $wf, { action => 'send' } );
    $action->execute( $wf );
}, '"send" action', $@;

ok lives {
    $c->param( 'expansions', { abc => 'def' } );
    $c->param( 'body', 'this <% abc %> replaces' );
    my $action = LedgerSMB::Workflow::Action::Email->new( $wf, { action => 'expand' } );
    $action->execute( $wf );
    is $c->param( 'body' ),
        'this def replaces',
        'Text replacement during expansion';
}, '"expand" action', $@;

ok lives {
    my $action = LedgerSMB::Workflow::Action::Email->new( $wf, { action => 'attach' } );
    $action->execute( $wf );
}, '"attach" action', $@;


done_testing;
