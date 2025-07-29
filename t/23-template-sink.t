#!perl

use v5.32;
use Test2::V0;

#######################################
#
#  LedgerSMB::Template::Sink::Email
#
#######################################

use lib 't/lib';

BEGIN {
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($OFF);
}

use Beam::Wire;
use Workflow::Factory qw(FACTORY);

use LedgerSMB::Template::Sink::Email;


FACTORY()->add_config(
    action => [
        {
            name => 'attach',
            class => 'Workflow::Action::Null',
        },
    ],
    persister => {
        name => 'memory-persister',
        class => 'TestPersister',
    },
    workflow => {
        type => 'Email',
        persister => 'memory-persister',
        initial_state => 'INITIAL',
        state => [
            {
                name => 'INITIAL',
                action => [
                    {
                        name => 'attach',
                        resulting_state => 'INITIAL',
                    },
                    ]
            }
            ],
    }
    );


my $wire = Beam::Wire->new(
    config => {
        workflows => FACTORY(),
    }
    );

my $sink;

ok lives {
    $sink = LedgerSMB::Template::Sink::Email->new(
        wire => $wire,
        from => 'me@example.com',
        to   => [],
        cc   => [],
        bcc  => [],
        );
}, 'Email: Instantiation with target mail addresses';

ok lives {
    $sink = LedgerSMB::Template::Sink::Email->new(
        wire => $wire,
        from => 'me@example.com',
        );
}, 'Email: Instantiation without target mail addresses';


my $template = { output => '', mime_type => 'text/plain' };

ok lives {
    $sink->append(
        $template,
        callback       => 'callback',
        filename       => 'the-file.txt',
        name           => 'name',
        credit_account => 'description',
        to   => [],
        cc   => [],
        bcc  => [],
        );
}, 'Email: append with mail addresses';

ok lives {
    $sink->append(
        $template,
        callback       => 'callback',
        filename       => 'the-file.txt',
        name           => 'name',
        credit_account => 'description',
        );
}, 'Email: append without mail addresses';


#######################################
#
#  LedgerSMB::Template::Sink::Printer
#
#######################################


use LedgerSMB::Template::Sink::Printer;

ok lives {
    $sink = LedgerSMB::Template::Sink::Printer->new(
        command => '/bin/cat >/dev/null',
        printer => 'the-printer'
        );
}, 'Printer: instantiation';

ok lives {
    $sink->append(
        { output => 'the printable output' }
        );
}, 'Printer: appending a template output';

ok lives {
    $sink = LedgerSMB::Template::Sink::Printer->new(
        printer => 'the-printer'
        );
    $sink->append(
        { output => 'the printable output' }
        );
}, 'Printer: appending a template output; no command set';

ok lives {
    $sink->render;
}, 'Printer: render printer job UI output';


#######################################
#
#  LedgerSMB::Template::Sink::Screen
#
#######################################


use LedgerSMB::Template::Sink::Screen;


ok lives {
    $sink = LedgerSMB::Template::Sink::Screen->new( archive_name => 'abc.zip' );
}, 'Screen: Instantiation';

ok lives {
    $sink->append(
        { output => 'the printable output', mime_type => 'text/plain' },
        filename => 'abc.txt'
        );
}, 'Screen: appending one template output';

ok lives {
    $sink->render;
}, 'Screen: render single template UI output';

ok lives {
    $sink->append(
        { output => 'the printable output', mime_type => 'text/plain' },
        filename => 'def.txt'
        );
}, 'Screen: appending two template outputs';

ok lives {
    $sink->render;
}, 'Screen: render two templates UI output';


done_testing;
