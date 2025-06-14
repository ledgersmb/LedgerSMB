#!/usr/bin/perl

use strict;
use warnings;

use Capture::Tiny ':all';
use File::Spec;
use Test2::V0;
use List::Util qw(sum);

my $tempdir  = File::Spec->tmpdir();
my $testfile = "$tempdir/extract-tests.pl";
my $pofile   = "$tempdir/extract-tests.po";

use Locale::Maketext::Simple;

my @tests = (
    { statement => "=pod\nLine1\nLine2\n=cut\n# text('Comment test')",
      results => [ 'Comment test' ] },
    { statement => 'my $a = marktext($a+$b);',
      results => [],
      fail => "$tempdir/extract-tests.pl:1: marktext() called with non string first argument; resetting scan (consider using maketext('') directly!" },
    { statement => 'my $a = text("$form->{title}");',
      results => [],
      fail => "$tempdir/extract-tests.pl:1: Direct variable interpolation not supported; use bracketed ([_1]) syntax for '\$form->{title}'!" },
    { statement => 'my $b = Text("Can\'t void a voided invoice!");',
      results => [ "Can't void a voided invoice!" ] },
    { statement => 'my $b = marktext("Disposal Report [_1] on date [_2]");',
      results => [ 'Disposal Report [_1] on date [_2]' ],
      arguments => [ '[_1]', '[_2]' ]},
    { statement => 'my $c = MarkText("There shouldn\'t be reconciliations on non-bank accounts.<br>");',
      results => [ "There shouldn't be reconciliations on non-bank accounts.<br>" ] },
    { statement => "my \@d = ( text(\n'Exchange rate hasn\\'t been defined!'),",
      results => [ "Exchange rate hasn't been defined!" ] },
    { statement => 'text(\'GIFI accounts not in "gifi" table\'),',
      results => [ 'GIFI accounts not in "gifi" table'] },
    { statement => 'text("Testing \\"quote string\\" here"),',
      results => [ 'Testing \"quote string\" here' ] },
    { statement => 'text(q(A quoting style with \' and " embedded)),',
      results => [ q(A quoting style with ' and " embedded) ] },
    { statement => 'text(qq(Another quoting style with \' and " embedded))',
      results => [ qq(Another quoting style with ' and " embedded)] },
    { statement => 'text(q(A quoting style with a literal which shouldn\'t be interpolated $a() nor bug)),',
      results => [ q(A quoting style with a literal which shouldn't be interpolated $a() nor bug)] },
    { statement => 'text(qq(Another quoting style with a forbidden interpolation $b->{c}))',
      results => [],
      fail => "$tempdir/extract-tests.pl:1: Direct variable interpolation not supported; use bracketed ([_1]) syntax for '\$b->{c}'!" },
    { statement => "my \$d = text('Continue') .\n\t\ttext('Ok') .\ntext('Continue');",
      results => [ 'Continue', 'Ok' ] },

    { statement => "my \$g = text(<<\"END\";\nA heredoc string\nwith many lines\n"
                                  . "and a forbidden interpolation \$b->{c}\nEND\n);",
      results => [],
      fail => "$tempdir/extract-tests.pl:1: Direct variable interpolation not supported; use bracketed ([_1]) syntax for '\$b->{c}'!" },
    { statement => "my \$f = text(<<END;\nA heredoc string\nwith many lines\nEND\n);",
      results => [ "A heredoc string\nwith many lines" ] },
    { statement => "my \$f = text(<<'END';\nA heredoc string\nwith single quotes\nEND\n);",
      results => [ "A heredoc string\nwith single quotes" ] },
    { statement => "my \$f = text(<<\"END\";\nA heredoc string\nwith double quotes\nEND\n);",
      results => [ "A heredoc string\nwith double quotes" ] },
    { statement => "my \$f = text(<<`END`;\nA heredoc string\nwith back ticks\nEND\n);",
      results => [ "A heredoc string\nwith back ticks" ] },
    { statement => "my \$e = text(<<'END'; #Comment\nA heredoc string\nwith many lines\n"
                                  . "and a literal which shouldn't be interpolated \$a\nEND\n);",
      results => [ "A heredoc string\nwith many lines\n"
                                  . "and a literal which shouldn't be interpolated \$a" ] },
);

for my $test (@tests) {

    # Set the source file
    open(my $SOURCE, '>', $testfile)
        or die "failed opening $testfile : $!";
    print $SOURCE $test->{statement} . "\n"
        or die "error writing to $testfile : $!";
    close $SOURCE
        or die "error closing $testfile after writing : $!";

    # Produce a PO file
    my ($stderr,$exit) = capture_stderr {
        local $ENV{PERL5OPT} = undef;
        system("echo \"$testfile\" | utils/devel/extract-perl > $pofile");
    };
    my @stat = stat $pofile;
    if ( $stat[7] > 0 && scalar @{$test->{results}}) {
        # Read it back
        #TODO: Find a way to know if strings were loaded
        Locale::Maketext::Simple->import(
            {
                Path  => "$pofile",
                Style => "gettext"
            }
        );
        loc_lang("en");
        for my $result (@{$test->{results}}) {
            is(loc($result,@{$test->{arguments}}),$result,$test->{statement})
                if !defined $test->{fail};
        }
        Locale::Maketext::Simple->reload_loc;
    }
    elsif ( $test->{fail} ) {
        $stderr =~ s/^Parsing: $testfile\n//;
        chomp $stderr;
        ok($test->{fail} eq $stderr,$stderr);
    }
    elsif ($stat[7] == 0) {
        fail("Translation done for $test->{statement}");
    }
    elsif ( $stderr ) {
        ok($exit,$stderr);  # Unknown error
    }
}

unlink $testfile;

done_testing;
