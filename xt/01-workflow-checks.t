#!perl

use Test2::V0;

use File::Find;
use Workflow::Config;

use LedgerSMB::Workflow::Loader;

if ($ENV{COVERAGE} && $ENV{CI}) {
    skip_all q{CI && COVERAGE excludes source code checks};
}

my @on_disk = ();

sub collect {
    return if $File::Find::name !~ m/\.xml$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'workflows/');


my $parser = Workflow::Config->new( 'xml' );

sub test_config_type {
    my $config_type = shift;
    my $config_name = $config_type . (($config_type eq 'workflow') ? '' : 's');

    for my $w_fn (grep { /\Q.$config_name.xml\E$/ } @on_disk) {
        my @conf = $parser->parse( $config_type => $w_fn );
        is( scalar @conf, 1,
            "Parsing a single config file returns a single config: $w_fn" );
        my $conf = pop @conf;

        my $type = $conf->{type};
        my $type_fn = LedgerSMB::Workflow::Loader::_type_to_fn( $type );
        ok( $w_fn =~ m|\Q/$type_fn.$config_name.xml\E$|,
            "Workflow type maps to config file (for lazy loading): $type (via $type_fn) -> $w_fn");
    }
}

sub test_persisters {
    my @persisters = $parser->parse( persister => 'workflows/persisters.xml' );
    my %global_persisters = map { $_->{name} => 1 } @persisters;

    for my $w_fn (grep { /\Q.workflow.xml\E$/ } @on_disk) {
        my ($workflow) = $parser->parse( workflow => $w_fn );
        my $type = $workflow->{type};
        my $type_fn = LedgerSMB::Workflow::Loader::_type_to_fn( $type );

        my $wf_persister = { name => '' };
        my $persister_fn = "workflows/$type_fn.persisters.xml";
        if (-e $persister_fn) {
            ($wf_persister) = $parser->parse( persister => $persister_fn );
        }
        my $persister_type =
            $global_persisters{$workflow->{persister}} ?
            "global" : ($wf_persister->{name} eq $workflow->{persister}) ?
            "lazy" : "not found";
        ok( $persister_type ne 'not found',
            "Workflow $type uses global or lazy-loadable persister ($persister_type)" );
    }
}

test_config_type( 'workflow' );
test_config_type( 'action' );
test_config_type( 'condition' );
test_config_type( 'validator' );
test_persisters();



done_testing;
