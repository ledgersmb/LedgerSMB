#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use File::Compare;

my $built_dojo_config   = 'doc/conf/ledgersmb.conf.default';
my $unbuilt_dojo_config = 'doc/conf/ledgersmb.conf.unbuilt-dojo';

# Basic check that files exist
ok(-f $built_dojo_config, 'default built dojo config file exists');
ok(-f $unbuilt_dojo_config, 'default unbuilt dojo config file exists');

# Both example configuration files should be identical, apart from
# the dojo_built=X line. This ensures that any changes during development
# have been applied to both files.
is(
    compare(
        $built_dojo_config,
        $unbuilt_dojo_config,
        sub {
            # Line comparison function
            $_[0] eq $_[1] and return 0;
            $_[0] =~ m/^#dojo_built = 1$/ && $_[1] =~ m/^dojo_built = 0$/ and return 0;
            return 1; # no match
        }
    ),
    0,
    'default built/unbuilt config files differ only by dojo_built=X line'
);
