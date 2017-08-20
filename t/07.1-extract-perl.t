#!/usr/bin/perl

use strict;
use warnings;

use LedgerSMB::Sysconfig;

my $tempdir  = $LedgerSMB::Sysconfig::tempdir;
my $testfile = "$tempdir/extract-tests.pl";
my $pofile   = "$tempdir/extract-tests.po";

use Locale::Maketext::Simple(
    Path => $tempdir
);
use Test::More;
use List::Util qw(sum);

my @tests = (
    { statement => "# text('Comment test')",
      results => [ 'Comment test' ] },
    { statement => 'my a$ = text("$form->{title}");',
      results => [],
      fail => "?" },
    { statement => 'my b$ = Text("Can\'t void a voided invoice!");',
      results => [ "Can't void a voided invoice!" ] },
    { statement => 'my b$ = marktext("Disposal Report [_1] on date [_2]");',
      results => [ 'Disposal Report [_1] on date [_2]' ],
      arguments => [ '[_1]', '[_2]' ]},
    { statement => 'my c$ = MarkText("There shouldn\'t be reconciliations on non-bank accounts.<br>");',
      results => [ "There shouldn't be reconciliations on non-bank accounts.<br>" ] },
    { statement => "my \@d = ( text('Exchange rate hasn\\'t been defined!'),",
      results => [ "Exchange rate hasn't been defined!" ] },
    { statement => 'text(\'GIFI accounts not in "gifi" table\'),',
      results => [ 'GIFI accounts not in "gifi" table'] },
    { statement => 'text("Testing \\"quote string\\" here"),',
      results => [ 'Testing \"quote string\" here' ] },
    { statement => 'text(q(A quoting style with \' and " embedded)),',
      results => [ q(A quoting style with ' and " embedded) ] },
    { statement => 'text(qq(Another quoting style with \' and " embedded))',
      results => [ qq(Another quoting style with ' and " embedded)] },
    { statement => 'text(q(A quoting style with a literal which shouldn\'t be interpolated $a)),',
      results => [ q(A quoting style with a literal which shouldn't be interpolated $a)] },
    { statement => 'text(qq(Another quoting style with a forbidden interpolation $b->{c}))',
      results => [],
      fail => "?" },
    { statement => "my \$d = text('Continue') .\n\t\ttext('Ok') .\ntext('Continue');",
      results => [ 'Continue', 'Ok' ] },
    { statement => "my f\$ = test(<<END;\nA heredoc string\nwith many lines\nEND\n);",
      results => [ "A heredoc string\nwith many lines" ] },
    { statement => "my e\$ = test(<<'END';\nA heredoc string\nwith many lines\n"
                                  . "and a literal which shouldn't be interpolated \$a\nEND\n);",
      results => [ "A heredoc string\nwith many lines\n"
                                  . "and a literal which shouldn't be interpolated \$a" ] },
#TODO: Enable heredocs with doublequotes once PPR is ok with them
#    { statement => "my g\$ = test(<<\"END\";\nA heredoc string\nwith many lines\n"
#                                  . "and a forbidden interpolation \$b->{c}\nEND\n);",
#      results => [],
#      fail => "?" },
);

plan tests => sum map { (scalar @{$_->{results}}) + (defined $_->{fail} ? 1 : 0)} @tests;

for my $test (@tests) {

    # Set the source file
    open(SOURCE, '>', $testfile)
         or die "Could not open file '$testfile' $!";
    print SOURCE $test->{statement} . "\n";
    close SOURCE;

    # Produce a PO file
    system("echo \"$testfile\" | utils/devel/extract-perl > $pofile");
    my $exit = $?;

    # Read it back
    Locale::Maketext::Simple->import(
        {
            '*'     => [ Gettext => "$pofile", ],
            _auto   => 1,
            _decode => 1,
        }
    );

    my @results = defined $test->{results}
                ? @{$test->{results}}
                : [];

    for my $result (@results) {

        my $text = loc($result,@{$test->{arguments}});

        ok($text eq $result,$test->{statement})
            if !defined $test->{fail};

        if ( $test->{comments} ) {
            TODO: {
                local $TODO = "Comments not implemented yet";
            }
        }
    }
    if ( $test->{fail} ) {
        ok($exit != 0,$test->{statement})
    }
}

unlink $testfile;

done_testing;
